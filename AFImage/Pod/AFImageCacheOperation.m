//#define DEBUG_IMAGE_CACHE_OPERATION


#import <CommonCrypto/CommonDigest.h>
#import "AFImageCacheOperation.h"
#import "AFFileHelper.h"


#pragma mark Constants

static NSString * const IsFinishedKeyPath = @"isFinished";
static NSString * const IsExecutingKeyPath = @"isExecuting";


#pragma mark - Class Definition

@implementation AFImageCacheOperation
{
	@private __strong AFImageTransform *_transform;
    @private __strong NSHTTPURLResponse *_response;
    @private __strong NSPurgeableData *_imageData;
	@private __strong NSCache *_cache;
	
	@private BOOL _refresh;
	@private BOOL _executing;
	@private BOOL _finished;
	
	@private AFImageCompletionBlock _completionBlock;
	@private AFImageCacheResult _result;
}


#pragma mark - Properties

- (NSURL *)url
{
	return _request.URL;
}

- (void)setIsExecuting: (BOOL)executing
{
	[self willChangeValueForKey: IsExecutingKeyPath];
	
	@synchronized(self)
	{
		_executing = executing;
	}
	
	[self didChangeValueForKey: IsExecutingKeyPath];
}

- (BOOL)isExecuting
{
	return _executing;
}

- (void)setIsFinished: (BOOL)finished
{
	[self willChangeValueForKey: IsFinishedKeyPath];
	
	@synchronized(self)
	{
		_finished = YES;
	}		
	
	[self didChangeValueForKey: IsFinishedKeyPath];
}

- (BOOL)isFinished
{
	return _finished;
}

- (BOOL)isConcurrent
{
	return YES;
}

- (NSString *)cacheKey
{
	NSString *cacheKey = [AFImageCacheOperation _cacheKeyForURL: _request.URL
		transform: _transform];
	
	return cacheKey;
}


#pragma mark - Constructors

- (id)initWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
    completionBlock: (AFImageCompletionBlock)completionBlock
{
    // Abort if base initializer fails.
	if ((self = [super init]) == nil)
	{
		return nil;
	}
	
	if (transform == nil)
	{
		// Use the identity transform.
		transform = [AFImageTransform identity];
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
		cachePolicy: NSURLRequestUseProtocolCachePolicy
		timeoutInterval: 60.0];
	
	// Initialize instance variables.
    _request = request;
	_transform = transform;
    _completionBlock = completionBlock != nil
		? [completionBlock copy]
		: nil;
	_result = AFImageCacheResultUnknown;
	_refresh = refresh;
	_cache = cache;

	return self;
}


#pragma mark - Public Methods

+ (NSString *)_cacheKeyForURL: (NSURL *)url
	transform: (AFImageTransform *)transform
{
	NSString *cacheKey = [NSString stringWithFormat: @"%@_%@",
		[url absoluteString], transform.key];
		
	return cacheKey;
}


#pragma mark - Overridden Methods

+ (UIImage *)imageWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform
{
	UIImage *image = nil;
	
	// Get the cache key.
	NSString *cacheKey = [self _cacheKeyForURL: url
		transform: transform];
	
	if ([[cache objectForKey: cacheKey] beginContentAccess] == YES)
	{
		// Set the image data from the cache.
		NSData *data = [cache objectForKey: cacheKey];
		
		// Cached data is pre-transformed.
		image = [UIImage imageWithData: data];
	}
	
	return image;
}

- (void)start
{
	// Abort if cancelled.
	if (self.isCancelled == YES)
	{
		// Raise finished notification.
		self.isFinished = YES;
		
		// Callback delegate.
		_result = AFImageCacheResultFailed;
		[self _raiseCompletionWithImage: nil];
		
		// Stop processing.
		return;
	}

	// Start main execution.
	self.isExecuting = YES;
	
	// Use the concurrent global queue to make requests.
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^
    {
        [self main];
    });
}

- (void)main
{
	@autoreleasepool 
    {
		// Create the connection.
        NSURLConnection *connection = nil;
        
		@try
        {
			// If image data exists in the cache, use it.
			if (_refresh == NO && [[_cache objectForKey: self.cacheKey] beginContentAccess] == YES)
			{
				// Set the image data from the cache.
				_imageData = [_cache objectForKey: self.cacheKey];
				_result = AFImageCacheResultSuccessFromMemoryCache;
				_response = nil;
			}
		
			// Otherwise, download and cache the image.
			else
			{
				// Create a new connection for the request (starts immediately).
				connection = [[NSURLConnection alloc]
					initWithRequest: _request 
					delegate: self];
					
				// Abort if connection failed.
				if (connection == nil)
				{
					// Log error.
					AFLog(@"Cannot create connection to %@", [_request.URL absoluteString]);
					
					// Stop processing - the finally ends the operation.
					return;
				}				

				NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
				BOOL running = YES;

				// Start the run loop.
				while (self.isCancelled == NO
					&& running == YES)
				{
					// Give each run loop 1-second to block or run.
					NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow: 1.0];
					
					// Run the run loop.
					running = [runLoop runMode: NSDefaultRunLoopMode
						beforeDate: untilDate];
				}
			}
        }
        
        // Log and suppress any exceptions.
        @catch (NSException *e) 
        {
            AFLog(@"Unexpected exception during download: %@", e.reason);
        }
        
        // Complete operation.
        @finally
        {
            // Handle cancellation.
            if (self.isCancelled == YES)
            {
				// Raise completion (overrides result with cancelled).
                [self _raiseCompletionWithImage: nil];
            }
			
			// Otherwise, try to get image.
			else
			{
				UIImage *image = nil;
				
				if (_result == AFImageCacheResultFailed
					|| _imageData != nil
					|| [_imageData length] == 0)
				{
					// Returns nil if the cache data doesn't exist.
					_imageData = [self _readCacheImageData];
					
					// Successfully read the file from disk.
					_result = AFImageCacheResultSuccessFromDiskCache;
				}
				
				if (_result != AFImageCacheResultFailed
					&& _imageData != nil
					&& [_imageData length] > 0)
				{
					if (_result == AFImageCacheResultSuccessFromURL)
					{
						// Decode the image using the transform.
						image = [_transform transformData: _imageData];
						
						// Convert to PNG and apply it to the purgeable data.
						NSData *data = UIImagePNGRepresentation(image);
						[_imageData setData: data];
					}
					else
					{
						// Set the image.
						image = [UIImage imageWithData: _imageData];
					}
				
					// Cache the data in memory, if required.
					if (_result == AFImageCacheResultSuccessFromDiskCache
						|| _result == AFImageCacheResultSuccessFromURL)
					{
						[_cache setObject: _imageData
							forKey: self.cacheKey];
					}
					
					// Cache the data to disk, if it doesn't exist.
					if ([self _cacheImageDataExists] == NO)
					{
						BOOL wrote = [self _writeCacheImageData: _imageData];
							
						if (wrote == NO)
						{
							AFLog(@"Failed to cache: %@", _request.URL);
						}
#ifdef DEBUG_IMAGE_CACHE_OPERATION
						else
						{
							AFLog(AFLogLevelDebug, @"Cached: %@", _request.URL);
						}
#endif
					}
											
					// End content access, if it was loaded from the cache.
					if (_result == AFImageCacheResultSuccessFromMemoryCache)
					{
						[_imageData endContentAccess];
					}
					
					// Raise completion.
					[self _raiseCompletionWithImage: image];
				}
				
				// Failure.
				else
				{
					_result = AFImageCacheResultFailed;
					
					// Raise completion.
					[self _raiseCompletionWithImage: nil];
				}
			}
        
            // Raise executing/finished notifcations.
            [self willChangeValueForKey: IsFinishedKeyPath];
            [self willChangeValueForKey: IsExecutingKeyPath];
            
			@synchronized(self)
            {
                _executing = NO;
                _finished = YES;
            }
			
            [self didChangeValueForKey: IsExecutingKeyPath];
            [self didChangeValueForKey: IsFinishedKeyPath];
            
            // Stop connection (if still open).
            if (connection != nil)
            {
                [connection cancel];
            }
        }        
    }
}


#pragma mark - Private Methods

- (NSString *)_cacheFilename
{
    const char *cStr = [self.cacheKey UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];

    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );

    return [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
        result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15] ];
}

- (NSURL *)_localCacheURL
{
	// Generate the disk cache filename.
	NSString *diskCacheFilename = [self _cacheFilename];
		
	// Format the disk cache path.
	NSString *diskCachePath = [NSString stringWithFormat: @"%@/%@",
		[[NSBundle mainBundle] bundleIdentifier], diskCacheFilename];
		
	// Get the local cache URL.
	NSURL *localCacheURL = [AFFileHelper cacheURLByAppendingPath: diskCachePath];
	return localCacheURL;
}

- (BOOL)_cacheImageDataExists
{
	// Get the cache url.
	NSURL *localCacheURL = [self _localCacheURL];
	
	// Get whether or not the cache file exists.
	BOOL exists = [AFFileHelper fileExists: localCacheURL];
	return exists;
}

- (NSPurgeableData *)_readCacheImageData
{
	// Get the cache url.
	NSURL *localCacheURL = [self _localCacheURL];
	
	// Attempt to get the cached data.
	NSPurgeableData *data = [NSPurgeableData dataWithContentsOfURL: localCacheURL];
	return data;
}

- (BOOL)_writeCacheImageData: (NSPurgeableData *)data
{
	// Get the cache url.
	NSURL *localCacheURL = [self _localCacheURL];
	
	// Write the data.
	return [data writeToURL: localCacheURL
		atomically: YES];
}

- (void)_raiseCompletionWithImage: (UIImage *)image
{
    if (_completionBlock != nil)
    {
		if ([self isCancelled] == YES)
		{
			// Override the result with cancellation.
			_result = AFImageCacheResultCancelled;
		}
	
		// Call completion on the main thread.
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_sync(mainQueue, ^
        {
            _completionBlock(_result, image);
        });
    }
}


#pragma mark - NSURLConnectionDelegate Methods

- (void)connection: (NSURLConnection *)connection 
	didReceiveResponse: (NSURLResponse *)response
{
    // Cache response.
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _response = httpResponse;    
    
	// Cancel connection, if operation is cancelled.
	if (self.isCancelled == YES)
	{
		[connection cancel];
	}
    
    // Otherwise, create data container.
    else
    {    
        // Create the data container.
        _imageData = [[NSPurgeableData alloc]
            init];
    }
}

- (void)connection: (NSURLConnection *)connection 
	didReceiveData: (NSData *)data
{
	// Cancel if operation is cancelled.
	if (self.isCancelled == YES)
    {
		[connection cancel];
	}	
	
	// Or continue download.
	else 
	{
        [_imageData appendData: data];
	}
}

- (void)connection: (NSURLConnection *)connection 
	didFailWithError: (NSError *)error
{
	AFLog(@"Failed to download image: %@", _request.URL);
	
	// Mark that the request failed.
	_result = AFImageCacheResultFailed;
}

- (void)connectionDidFinishLoading: (NSURLConnection *)connection
{
	// Set result.
	if (_response.statusCode == 200)
	{
		_result = AFImageCacheResultSuccessFromURL;
	}
	else
	{
		_result = AFImageCacheResultFailed;
	}
}


@end // @implementation AFImageCacheOperation