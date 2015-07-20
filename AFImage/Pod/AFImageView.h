#import "AFImageTransform.h"


#pragma mark Enumerations

typedef enum
{
	AFImageViewStateEmpty,
	AFImageViewStateImageFailed,
	AFImageViewStateImageLoaded

} AFImageViewState;


#pragma mark Class Interface

@interface AFImageView : UIView


#pragma mark - Properties

// View that will be shown when the remote image fails to load. Add custom failure views to this view.
@property (nonatomic, strong, readonly) UIView *failedView;

// View that will be shown when this image view has no content (or is loading). Add custom loading views to this view.
@property (nonatomic, strong, readonly) UIView *emptyView;

// Image view that shows the loaded image.
@property (nonatomic, strong, readonly) UIImageView *imageView;

@property (nonatomic, strong) AFImageTransform *imageTransform;
@property (nonatomic, strong) UIImage *image;

// TODO: Progressive load?
@property (nonatomic, copy) NSURL *url;


#pragma mark - Public Methods

// Sets a URL, optionally refreshing or animating in the change.
- (void)setURL: (NSURL *)url
	refresh: (BOOL)refresh
	animated: (BOOL)animated;

// Sets an image, optionally animating in the change.
- (void)setImage: (UIImage *)image
	animated: (BOOL)animated;

// Sets the state, optionally animating. Override this method to customize the on load animation.
- (void)setState: (AFImageViewState)state
	animated: (BOOL)animated;


@end // @interface AFImageView