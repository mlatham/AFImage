#import "AFImageView.h"


#pragma mark Class Definition

@implementation AFImageView
{
	@private __weak NSOperation *_imageOperation;
	
	@private __strong NSURL *_loadedURL;
}


#pragma mark - Properties

- (void)setPlaceholderContentMode: (UIViewContentMode)placeholderContentMode
{
	// Set the placeholder image view.
	_placeholderImageView.contentMode = placeholderContentMode;
}

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
	self.placeholderContentMode = UIViewContentModeScaleAspectFill;
	
	_showsPlaceholderWhenLoading = NO; // By default don't show the placeholder while loading.
	
	// Initialize the placeholder image view.
	_placeholderImageView = UIImageView.new;
	_placeholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
	_placeholderImageView.backgroundColor = [UIColor clearColor];
	_placeholderImageView.contentMode = self.contentMode;
	[self addSubview: _placeholderImageView];
	
	// Initialize the image view.
	_imageView = UIImageView.new;
	_imageView.translatesAutoresizingMaskIntoConstraints = NO;
	_imageView.backgroundColor = [UIColor clearColor];
	_imageView.contentMode = self.contentMode;
	[self addSubview: _imageView];
	
	// Add constraints.
	[self addConstraints:
	@[
		// Placeholder image view.
		[NSLayoutConstraint constraintWithItem: _placeholderImageView
			attribute: NSLayoutAttributeTop
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeTop
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _placeholderImageView
			attribute: NSLayoutAttributeLeft
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeLeft
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _placeholderImageView
			attribute: NSLayoutAttributeWidth
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeWidth
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _placeholderImageView
			attribute: NSLayoutAttributeHeight
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeHeight
			multiplier: 1.0
			constant: 0.f],
		
		// Image view constraints.
		[NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeTop
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeTop
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeLeft
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeLeft
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeWidth
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeWidth
			multiplier: 1.0
			constant: 0.f],
		
		[NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeHeight
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeHeight
			multiplier: 1.0
			constant: 0.f]
	]];
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
	_placeholderImageView.image = _placeholderImage;
}

- (void)_setImage: (UIImage *)image
{
	// Set the image.
	_imageView.image = image;
}


@end // @implementation AFImageView