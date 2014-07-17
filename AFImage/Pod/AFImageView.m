#import "AFImageView.h"


#pragma mark Class Definition

@implementation AFImageView
{
	@private __weak NSOperation *_imageOperation;
	@private __strong UIImageView *_imageView;
	@private __strong NSURL *_loadedURL;
}


#pragma mark - Properties

- (void)setContentMode: (UIViewContentMode)contentMode
{
	// Map content mode to the image view.
	_imageView.contentMode = contentMode;
	
	// Call base implementation.
	[super setContentMode: contentMode];
}

- (void)setPlaceholderImage: (UIImage *)placeholderImage
{
	_placeholderImage = placeholderImage;
	
	// If the url is not set - apply the placeholder image.
	if (self.url != nil && [[NSNull null] isEqual: self.url] == NO)
	{
		[self _applyPlaceholderImage];
	}
}

- (void)setImage: (UIImage *)image
{
	// Clear the URL, if any.
	self.url = nil;

	// Show the placeholder image, if the image is unset.
	if (image == nil)
	{
		[self _applyPlaceholderImage];
	}
	// Otherwise, show the transformed image.
	else
	{
		UIImage *transformedImage = [self _transformImage: image];
		
		// Set the image.
		_imageView.image = transformedImage;
	}
}

- (void)setURL: (NSURL *)url
	refresh: (BOOL)refresh
{
	// Don't reload the same URL.
	if (refresh == NO
		&& ([url isEqual: _loadedURL] == YES
		|| [url isEqual: _url] == YES))
	{
		return;
	}
	
	// Cancel the operation.
	[self _cancelOperationIfNecessary];
	
	// Clear any last loaded URL.
	_loadedURL = nil;
	
	AFImageCache *imageCache = [AFImageCache sharedInstance];
	
	// Clear the image.
	if (_showsPlaceholderWhenLoading == NO)
	{
		_imageView.image = nil;
	}
	else
	{
		[self _applyPlaceholderImage];
	}
	
	// Set the url.
	_url = url;
	
	if (url != nil && [[NSNull null] isEqual: url] == NO)
	{
		// Load the image.
		_imageOperation = [imageCache imageWithURL: url
			transform: _imageTransform
			refresh: refresh
			completionBlock: ^(AFImageCacheResult result, UIImage *image)
			{
				if (result == AFImageCacheResultSuccessFromMemoryCache
					|| result == AFImageCacheResultSuccessFromDiskCache
					|| result == AFImageCacheResultSuccessFromURL)
				{
					// Got the image.
					_loadedURL = url;
					
					// Set the loaded image.
					_imageView.image = image;
				}
				else if (result == AFImageCacheResultFailed)
				{
					// Show the placeholder image.
					[self _applyPlaceholderImage];
				}
			}];
	}
	else
	{
		// Show the placeholder image.
		[self _applyPlaceholderImage];
	}
}

- (void)setUrl: (NSURL *)url
{
	[self setURL: url
		refresh: NO];
}


#pragma mark - Constructors

- (id)initWithFrame: (CGRect)frame
{
	// Abort if base initializer fails.
	if ((self = [super initWithFrame: frame]) == nil)
	{
		return nil;
	}
	
	// Initialize view.
	[self _initializeImageView];
	
	// Return initialized instance.
	return self;
}

- (id)initWithCoder: (NSCoder *)coder
{
	// Abort if base initializer fails.
	if ((self = [super initWithCoder: coder]) == nil)
	{
		return nil;
	}
	
	// Initialize view.
	[self _initializeImageView];
	
	// Return initialized instance.
	return self;
}


#pragma mark - Private Methods

- (void)_initializeImageView
{
	// Set the default content mode.
	self.contentMode = UIViewContentModeScaleAspectFill;
	
	// Initialize the image view.
	_showsPlaceholderWhenLoading = YES; // By default show the placeholder while loading.
	_imageView = [[UIImageView alloc]
		initWithFrame: self.bounds];
	_imageView.backgroundColor = [UIColor clearColor];
	_imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight
		| UIViewAutoresizingFlexibleWidth;
	_imageView.contentMode = self.contentMode;
	[self addSubview: _imageView];
}

- (UIImage *)_transformImage: (UIImage *)image
{
	UIImage *transformedImage = image;
	
	// Apply transform, if provided.
	if (_imageTransform != nil)
	{
		transformedImage = [_imageTransform transformImage: image];
	}
	
	return transformedImage;
}

- (void)_applyPlaceholderImage
{
	_imageView.image = [self _transformImage: _placeholderImage];
}

- (void)_cancelOperationIfNecessary
{
	// Cancel any existing operation.
	if (_imageOperation != nil)
	{
		[_imageOperation cancel];
		_imageOperation = nil;
	}
}


@end // @implementation AFImageView