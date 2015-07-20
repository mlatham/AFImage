#import "AFImageView.h"
#import "AFImageCache.h"


#pragma mark Class Definition

@implementation AFImageView
{
	// These are unset if removed from this view.
	@private __weak NSLayoutConstraint *_emptyHeightConstraint;
	@private __weak NSLayoutConstraint *_emptyWidthConstraint;
	@private __weak NSLayoutConstraint *_emptyLeftConstraint;
	@private __weak NSLayoutConstraint *_emptyTopConstraint;

	// These are unset if removed from this view.
	@private __weak NSLayoutConstraint *_failedHeightConstraint;
	@private __weak NSLayoutConstraint *_failedWidthConstraint;
	@private __weak NSLayoutConstraint *_failedLeftConstraint;
	@private __weak NSLayoutConstraint *_failedTopConstraint;
	
	// These are unset if removed from this view.
	@private __weak NSLayoutConstraint *_imageHeightConstraint;
	@private __weak NSLayoutConstraint *_imageWidthConstraint;
	@private __weak NSLayoutConstraint *_imageLeftConstraint;
	@private __weak NSLayoutConstraint *_imageTopConstraint;

	@private __weak NSOperation *_imageOperation;
	
	@private __strong NSURL *_loadedURL;
}


#pragma mark - Properties

- (void)setContentMode: (UIViewContentMode)contentMode
{
	// Map content mode to the image view, as well.
	_imageView.contentMode = contentMode;
	
	// Call base implementation.
	[super setContentMode: contentMode];
}

- (void)setImage: (UIImage *)image
{
	// Set the image - don't animate.
	[self setImage: image
		animated: NO];
}

- (void)setImage: (UIImage *)image
	animated: (BOOL)animated
{
	// Clear the URL, if any.
	self.url = nil;

	// Transform the image.
	image = [self _transformImage: image];

	// Show the transformed image (nil if the image is nil).
	_imageView.image = image;
	
	// If the image is non-nil, set the state.
	[self setState: image != nil
		? AFImageViewStateImageLoaded
		: AFImageViewStateImageFailed
		animated: animated];
}

- (void)setURL: (NSURL *)url
	refresh: (BOOL)refresh
	animated: (BOOL)animated
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
	
	// Clear the image.
	_imageView.image = nil;
	
	// Set the url.
	_url = url;
	
	if (url != nil && [[NSNull null] isEqual: url] == NO)
	{
		AFImageCache *imageCache = [AFImageCache sharedInstance];
		
		// Set the image state to loading.
		[self setState: AFImageViewStateEmpty
			animated: NO];
		
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
					
					// Only animate the transition if coming from a web request, and animation is requested.
					[self setState: AFImageViewStateImageLoaded
						animated: animated
							&& result == AFImageCacheResultSuccessFromURL];
				}
				else if (result == AFImageCacheResultFailed)
				{
					// Show the placeholder image.
					[self setState: AFImageViewStateImageFailed
						animated: NO];
				}
			}];
	}
	else
	{
		// Set the image state to loading.
		[self setState: AFImageViewStateEmpty
			animated: NO];
	}
}

- (void)setUrl: (NSURL *)url
{
	// By default use
	[self setURL: url
		refresh: NO
		animated: YES];
}

- (void)setState: (AFImageViewState)state
	animated: (BOOL)animated
{
	CGFloat failedViewAlpha = state == AFImageViewStateImageFailed
		? 1.f
		: 0.f;
	CGFloat imageViewAlpha = state == AFImageViewStateImageLoaded
		? 1.f
		: 0.f;
	
	if (animated)
	{
		// Animate the state change.
		[UIView animateWithDuration: 0.2
			delay: 0
			options: UIViewAnimationOptionAllowUserInteraction
				| UIViewAnimationOptionCurveEaseOut
			animations: ^
			{
				_failedView.alpha = failedViewAlpha;
				_imageView.alpha = imageViewAlpha;
			}
			completion: nil];
	}
	else
	{
		// Apply the state change directly.
		_failedView.alpha = failedViewAlpha;
		_imageView.alpha = imageViewAlpha;
	}
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


#pragma mark - Overridden Methods

- (void)updateConstraints
{
	// Empty constraints.
	if (_emptyTopConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _emptyView
			attribute: NSLayoutAttributeTop
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeTop
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_emptyTopConstraint = constraint;
	}
	
	if (_emptyLeftConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _emptyView
			attribute: NSLayoutAttributeLeft
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeLeft
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_emptyLeftConstraint = constraint;
	}
	
	if (_emptyWidthConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _emptyView
			attribute: NSLayoutAttributeWidth
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeWidth
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_emptyWidthConstraint = constraint;
	}
	
	if (_emptyHeightConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _emptyView
			attribute: NSLayoutAttributeHeight
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeHeight
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_emptyHeightConstraint = constraint;
	}

	// Failed constraints.
	if (_failedTopConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _failedView
			attribute: NSLayoutAttributeTop
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeTop
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_failedTopConstraint = constraint;
	}
	
	if (_failedLeftConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _failedView
			attribute: NSLayoutAttributeLeft
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeLeft
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_failedLeftConstraint = constraint;
	}
	
	if (_failedWidthConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _failedView
			attribute: NSLayoutAttributeWidth
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeWidth
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_failedWidthConstraint = constraint;
	}
	
	if (_failedHeightConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _failedView
			attribute: NSLayoutAttributeHeight
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeHeight
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_failedHeightConstraint = constraint;
	}
	
	// Image constraints.
	if (_imageTopConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeTop
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeTop
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_imageTopConstraint = constraint;
	}
	
	if (_imageLeftConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeLeft
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeLeft
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_imageLeftConstraint = constraint;
	}
	
	if (_imageWidthConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeWidth
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeWidth
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_imageWidthConstraint = constraint;
	}
	
	if (_imageHeightConstraint == nil)
	{
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: _imageView
			attribute: NSLayoutAttributeHeight
			relatedBy: NSLayoutRelationEqual
			toItem: self
			attribute: NSLayoutAttributeHeight
			multiplier: 1.0
			constant: 0.f];
		[self addConstraint: constraint];
		_imageHeightConstraint = constraint;
	}
	
	[super updateConstraints];
}


#pragma mark - Private Methods

- (void)_initializeImageView
{
	// Set the default content mode.
	self.contentMode = UIViewContentModeScaleAspectFill;
	
	// Initialize the empty view.
	_emptyView = UIView.new;
	_emptyView.translatesAutoresizingMaskIntoConstraints = NO;
	_emptyView.backgroundColor = [UIColor clearColor];
	[self addSubview: _emptyView];
	
	// Initialize the failed view.
	_failedView = UIView.new;
	_failedView.translatesAutoresizingMaskIntoConstraints = NO;
	_failedView.backgroundColor = [UIColor clearColor];
	[self addSubview: _failedView];
	
	// Initialize the image view.
	_imageView = UIImageView.new;
	_imageView.translatesAutoresizingMaskIntoConstraints = NO;
	_imageView.backgroundColor = [UIColor clearColor];
	_imageView.contentMode = self.contentMode;
	[self addSubview: _imageView];
	
	// Set that the constraints need an update.
	[self setNeedsUpdateConstraints];
	
	// Initially set the empty state.
	[self setState: AFImageViewStateEmpty
		animated: NO];
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


@end // @implementation AFImageView