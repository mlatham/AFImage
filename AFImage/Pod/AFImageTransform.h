#import "AFCornerRadiuses.h"


#pragma mark Type Definitions

// Block that transforms one image into another.
typedef UIImage *(^AFImageTransformImageBlock)(UIImage *image);

// Block that transforms image data into an image.
typedef UIImage *(^AFImageTransformDataBlock)(NSData *data);


#pragma mark Class Interface
#import "AFCornerRadiuses.h"


@interface AFImageTransform : NSObject


#pragma mark - Properties

// A unique key identifying this transform - suitable to cache it.
@property (nonatomic, copy) NSString *key;

// Transform block to apply the transform to raw data.
@property (nonatomic, copy) AFImageTransformDataBlock transformDataBlock;

// Transform block to apply the transform to an image.
@property (nonatomic, copy) AFImageTransformImageBlock transformImageBlock;


#pragma mark - Constructors

- (id)initWithKey: (NSString *)key
	transformDataBlock: (AFImageTransformDataBlock)transformDataBlock
	transformImageBlock: (AFImageTransformImageBlock)transformImageBlock;


#pragma mark - Static Methods

// Creates a general transform.
+ (id)transformWithKey: (NSString *)key
	transformDataBlock: (AFImageTransformDataBlock)transformDataBlock
	transformImageBlock: (AFImageTransformImageBlock)transformImageBlock;

// Applies a blur to the image.
+ (id)transformForBlurredImageWithInputRadius: (CGFloat)inputRadius;

// Applies rounded corners to the image.
+ (id)transformForImageWithCornerRadiuses: (AFCornerRadiuses)cornerRadiuses;

// Applies rounded corners to all corners of an image.
+ (id)transformForImageWithCornerRadius: (CGFloat)cornerRadius;

// Makes the image grayscale.
+ (id)transformForGrayscaleImage;

// Makes the image a circle.
+ (id)transformForCircularImage;

// Applies no transform to the image.
+ (id)identity;


#pragma mark - Instance Methods

// Applies the data transform.
- (UIImage *)transformData: (NSData *)data;

// Applies the image transform.
- (UIImage *)transformImage: (UIImage *)image;


@end // @interface AFImageTransform