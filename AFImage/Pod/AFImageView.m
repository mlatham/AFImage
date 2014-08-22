#import "AFImageView.h"


#pragma mark Class Definition

@implementation AFImageView
{
	@private __weak NSOperation *_imageOperation;
	
	@private __strong UIImageView *_placeholderImageView;
	@private __strong UIImageView *_imageView;
	@private __strong NSURL *_loadedURL;
}


#pragma mark - Properties

- (void)setContentMode: (UIViewContentMode)contentMode
{
	// Map content mode to the image view.
	_imageView.contentMode = contentMode;
	
	// Map content mode to the placeholder image view.
	_placeholderImageView.contentMode = contentMode;
	
	// Call base implementation.
	[super setContentMode: contentMode];
}

- (void)setPlaceholderImage: (UIImage *)placeholderImage
{
	_placeholderImage = placeholderImage;
	
	// Set the placeholder image.
	[self _applyPlaceholderImage];
}

- (void)setImage: (UIImage *)image
{
	// Clear the URL, if any.
	self.url = nil;

	// Show the transformed image (nil if the image is nil).
	[self _setImage: [self _transformImage: image]];
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
	[self _setImage: nil];
	
	// Set the placeholder depending on whether it shows while loading.
	if (_showsPlaceholderWhenLoading == NO)
	{
		_placeholderImageView.image = nil;
	}
	else
	{
		// Show the placeholder image.
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
					[self _setImage: image];
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
	_showsPlaceholderWhenLoading = NO; // By default don't show the placeholder while loading.
	_placeholderImageView = [[UIImageView alloc]
		initWithFrame: self.bounds];
	_placeholderImageView.backgroundColor = [UIColor clearColor];
	_placeholderImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight
		| UIViewAutoresizingFlexibleWidth;
	_placeholderImageView.contentMode = self.contentMode;
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
	if (_imageTransform != nil && image != nil)
	{
		transformedImage = [_imageTransform transformImage: image];
	}
	
	return transformedImage;
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

- (void)_applyPlaceholderImage
{
	// Set the placeholder image, applying the transformation.
	_placeholderImageView.image = [self _transformImage: _placeholderImage];
}

- (void)_setImage: (UIImage *)image
{
	// Set the image.
	_imageView.image = image;
		
	// When the image is nil'd out, hide the image view.
	if (image == nil)
	{
		// Animate to cancel any existing image set.
		[UIView animateWithDuration: 0.01f
			delay: 0
			options: UIViewAnimationOptionBeginFromCurrentState
				| UIViewAnimationOptionCurveEaseInOut
			animations: ^
			{
				_imageView.alpha = 0.f;
			}
			completion: ^(BOOL finished)
			{
				if (finished)
				{
					_imageView.hidden = YES;
				}
			}];
	}
	else
	{
		// Animate, if specified.
		if (_animate)
		{
			[UIView animateWithDuration: 0.3f
				delay: 0
				options: UIViewAnimationOptionBeginFromCurrentState
					| UIViewAnimationOptionCurveEaseInOut
				animations: ^
				{
					_imageView.alpha = 1.f;
				}
				completion: nil];
		}
		else
		{
			// Otherwise, just show it.
			_imageView.alpha = 1.f;
		}
		
		// Show the image view.
		_imageView.hidden = NO;
	}
}


@end // @implementation AFImageView