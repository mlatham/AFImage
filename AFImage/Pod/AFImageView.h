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

@property (nonatomic, assign) UIViewContentMode failedImageContentMode;

@property (nonatomic, strong) AFImageTransform *imageTransform;

@property (nonatomic, strong) UIImageView *failedImageView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIImage *failedImage;
@property (nonatomic, strong) UIImage *image;

// TODO: Progressive load.
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