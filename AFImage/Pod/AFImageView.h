#import "AFImageCache.h"


#pragma mark Class Interface

@interface AFImageView : UIView


#pragma mark - Properties

@property (nonatomic, assign) UIViewContentMode placeholderContentMode;

@property (nonatomic, assign) BOOL showsPlaceholderWhenLoading;

@property (nonatomic, strong) AFImageTransform *imageTransform;

@property (nonatomic, copy) NSURL *url;

- (void)setURL: (NSURL *)url
	refresh: (BOOL)refresh;

@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *image;


@end // @interface AFImageView