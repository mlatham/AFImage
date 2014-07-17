#import "AFImageCache.h"


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
		AFImageCacheOperation *operation = [[AFImageCacheOperation alloc]
			initWithURL: url
			cache: _cache
			transform: transform
			refresh: refresh
			completionBlock: completionBlock];
			
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