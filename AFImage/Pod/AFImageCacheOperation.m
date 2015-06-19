#import "AFImageCacheOperation.h"
#import "AFImageCache.h"


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
	
	@private BOOL _useDiskCache;
	@private BOOL _executing;
	@private BOOL _finished;
	@private BOOL _refresh;
	
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


#pragma mark - Constructors

- (id)initWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	useDiskCache: (BOOL)useDiskCache
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
		timeoutInterval: 10.0];
	
	// Initialize instance variables.
    _request = request;
	_transform = transform;
    _completionBlock = completionBlock != nil
		? [completionBlock copy]
		: nil;
	_result = AFImageCacheResultUnknown;
	_useDiskCache = useDiskCache;
	_refresh = refresh;
	_cache = cache;

	return self;
}


#pragma mark - Public Methods

- (NSString *)cacheKey
{
	NSString *cacheKey = [AFImageCache cacheKeyForURL: _request.URL
		transform: _transform];
	
	return cacheKey;
}


#pragma mark - Overridden Methods

+ (UIImage *)imageWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform
{
	UIImage *image = nil;
	
	// Get the cache key.
	NSString *cacheKey = [AFImageCache cacheKeyForURL: url
		transform: transform];
	
	if ([[cache objectForKey: cacheKey] beginContentAccess] == YES)
	{
		// Set the image data from the cache.
		NSData *data = [cache objectForKey: cacheKey];
		
		// Cached data is pre-transformed.
		image = [UIImage imageWithData: data];
		
		// End the content access of the data.
		[[cache objectForKey: cacheKey] endContentAccess];
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
		
		// Track whether the purgeable data has been accessed.
		BOOL didBeginContentAccess = NO;
		
		@try
        {
			// If image data exists in the cache, use it.
			if (_refresh == NO
				&& (didBeginContentAccess = [[_cache objectForKey: self.cacheKey] beginContentAccess]) == YES)
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
				
				// Attempt to load the image from disk, if a disk cache is specified.
				if (_useDiskCache == YES)
				{
					// Use the disk cache, if available.
					if (_result == AFImageCacheResultFailed
						|| (_imageData != nil
						&& [_imageData length] == 0))
					{
						// Returns nil if the cache data doesn't exist.
						_imageData = [AFImageCache diskCacheDataForURL: _request.URL
							transform: _transform];
						
						// Check the data.
						if (_imageData != nil
							&& [_imageData length] == 0)
						{
							// Successfully read the file from disk.
							_result = AFImageCacheResultSuccessFromDiskCache;
						}
					}
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
				
					// Cache the data in memory, if it was just loaded.
					if (_result == AFImageCacheResultSuccessFromDiskCache
						|| _result == AFImageCacheResultSuccessFromURL)
					{
						[_cache setObject: _imageData
							forKey: self.cacheKey];
					}
					
					// Write the data to the disk cache, if it doesn't exist and the disk cache is being used.
					if (_useDiskCache)
					{
						// Only overwrite local on-disk data on success from a URL.
						[AFImageCache writeDataToDiskCache: _imageData
							url: _request.URL
							overwrite: _result == AFImageCacheResultSuccessFromURL
							transform: _transform];
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
			
			// End content access, if it was begun earlier.
			if (didBeginContentAccess == YES)
			{
				[_imageData endContentAccess];
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