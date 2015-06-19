//#define DEBUG_IMAGE_CACHE_OPERATION

#import <CommonCrypto/CommonDigest.h>
#import "AFImageCache.h"
#import "AFFileHelper.h"


#pragma mark Class Variables

static AFImageCache *_sharedInstance;


#pragma mark - Class Definition

@implementation AFImageCache
{
	@private __strong NSOperationQueue *_operationQueue;
	@private __strong NSCache *_cache;
}


#pragma mark - Constructors

+ (void)initialize
{
	static BOOL classInitialized = NO;
	
	// If this class has not been initialized then create the shared instance.
	if (classInitialized == NO)
	{
		_sharedInstance = [[AFImageCache alloc]
			init];
		
		classInitialized = YES;
	}
}

- (id)init
{
	// Abort if base initializer fails.
	if ((self = [super init]) == nil)
	{
		return nil;
	}
	
	// Initialize instance variables.
	_operationQueue = [[NSOperationQueue alloc]
		init];
	_operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
	_cache = [[NSCache alloc]
		init];
		
	// Initialize the default image cache operation create block.
	_imageCacheOperationCreateBlock = ^(NSURL *url, AFImageTransform *transform,
		NSCache *cache, BOOL refresh, AFImageCompletionBlock completionBlock)
		{
			return [[AFImageCacheOperation alloc]
				initWithURL: url
				cache: cache
				transform: transform
				refresh: refresh
				useDiskCache: NO // Don't use an on-disk cache by default.
				completionBlock: completionBlock];
		};
	
	// Return initialized instance.
	return self;
}


#pragma mark - Public Methods

+ (id)sharedInstance
{
	return _sharedInstance;
}

- (NSOperation *)imageWithURL: (NSURL *)url
	completionBlock: (AFImageCompletionBlock)completionBlock
{
	// Add the operation.
	return [self _addOperationWithURL: url
		transform: nil
		refresh: NO
		completionBlock: completionBlock];
}

- (NSOperation *)imageWithURL: (NSURL *)url
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock
{
	// Add the operation.
	return [self _addOperationWithURL: url
		transform: nil
		refresh: refresh
		completionBlock: completionBlock];
}

- (NSOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	completionBlock: (AFImageCompletionBlock)completionBlock
{
	// Add the operation.
	return [self _addOperationWithURL: url
		transform: transform
		refresh: NO
		completionBlock: completionBlock];
}

- (NSOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock
{
	// Add the operation.
	return [self _addOperationWithURL: url
		transform: transform
		refresh: refresh
		completionBlock: completionBlock];
}

+ (NSString *)cacheKeyForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
	NSString *cacheKey = [NSString stringWithFormat: @"%@_%@",
		[url absoluteString], transform.key];
		
	return cacheKey;
}

+ (NSString *)cacheFilenameForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
    const char *cStr = [[self cacheKeyForURL: url transform: transform] UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];

    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );

    return [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
        result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15] ];
}

+ (NSPurgeableData *)diskCacheDataForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
	// Get the disk cache url.
	NSURL *diskCacheURL = [AFImageCache diskCacheURLForURL: url
		transform: transform];
	
	// Attempt to get the cached data.
	NSPurgeableData *data = [NSPurgeableData dataWithContentsOfURL: diskCacheURL];
	return data;
}

+ (NSURL *)diskCacheURLForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
	// Generate the disk cache filename.
	NSString *diskCacheFilename = [self cacheFilenameForURL: url
		transform: transform];
	
	// Format the disk cache path.
	NSString *diskCachePath = [NSString stringWithFormat: @"%@/%@",
		[[NSBundle mainBundle] bundleIdentifier], diskCacheFilename];
		
	// Get the local cache URL.
	NSURL *localCacheURL = [AFFileHelper cacheURLByAppendingPath: diskCachePath];
	return localCacheURL;
}

+ (BOOL)diskCacheDataExistsForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
	// Get the cache url.
	NSURL *diskCacheURL = [self diskCacheURLForURL: url
		transform: transform];
	
	// Get whether or not the cache file exists.
	BOOL exists = [AFFileHelper fileExists: diskCacheURL];
	return exists;
}

+ (BOOL)writeDataToDiskCache: (NSPurgeableData *)data
	url: (NSURL *)url
	overwrite: (BOOL)overwrite
	transform: (AFImageTransform *)transform
{
	BOOL exists = NO;
	BOOL wrote = NO;

	// Only verify existence if overwrite is not specified.
	if (overwrite == NO)
	{
		exists = [self diskCacheDataExistsForURL: url
			transform: transform];
	}

	// Write the data.
	if (overwrite == YES
		|| exists == NO)
	{
		// Get the cache url.
		NSURL *diskCacheURL = [self diskCacheURLForURL: url
			transform: transform];
		
		// Write the data.
		BOOL wrote = [data writeToURL: diskCacheURL
			atomically: YES];
	
		if (wrote == NO)
		{
			AFLog(@"Failed to cache: %@", url);
		}
#ifdef DEBUG_IMAGE_CACHE_OPERATION
		else
		{
			AFLog(AFLogLevelDebug, @"Cached: %@", url);
		}
#endif
	}
	
	return wrote;
}


#pragma mark - Private Methods

- (NSOperation *)_addOperationWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock
{
	if (transform == nil)
	{
		// Use the identity transform if unspecified.
		transform = [AFImageTransform identity];
	}

	// Queue an operation to load the image.
	@synchronized(_operationQueue)
	{
		NSOperation *existingOperation = nil;
	
		// If there's an existing operation, find it.
		for (AFImageCacheOperation *operation in _operationQueue.operations)
		{
			if ([operation.url isEqual: url])
			{
				existingOperation = operation;
			}
		}
		
		// Check for a previously cached copy.
		if (existingOperation == nil)
		{
			UIImage *image = nil;
		
			// Skip cache check for refresh requests.
			if (refresh == NO)
			{
				// Attempt to get the image from the in-memory cache. NOTE: This occurs on the UI-thread.
				image = [AFImageCacheOperation imageWithURL: url
					cache: _cache
					transform: transform];
			}
				
			// If there was an image, use it.
			if (image != nil)
			{
				// Call completion, if provided.
				if (completionBlock != nil)
				{
					completionBlock(AFImageCacheResultSuccessFromMemoryCache, image);
				}
			
				// Early out.
				return nil;
			}
		}
		
		// Create the operation.
		AFImageCacheOperation *operation = _imageCacheOperationCreateBlock(url, transform, _cache, refresh, completionBlock);
			
		// If there's an existing operation or the cached file exists, give the dependent operation a high priority.
		if (existingOperation != nil
			&& [existingOperation isCancelled] == NO)
		{
			operation.threadPriority = 1.0;
			
			// Add a dependency on the existing operation.
			[operation addDependency: existingOperation];
		}
		
		// Add the operation.
		[_operationQueue addOperation: operation];
		
		// Return the operation.
		return operation;
	}
}


@end // @implementation AFImageCache