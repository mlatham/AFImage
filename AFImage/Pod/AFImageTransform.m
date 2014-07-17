#import "AFImageTransform.h"


#pragma mark Class Definition

@implementation AFImageTransform


#pragma mark - Constructors

- (id)initWithKey: (NSString *)key
	transformDataBlock: (AFImageTransformDataBlock)transformDataBlock
	transformImageBlock: (AFImageTransformImageBlock)transformImageBlock
{
	// Abort if base initializer fails.
	if ((self = [super init]) == nil)
	{
		return nil;
	}
	
	// Initialize instance variables.
	_key = [key copy];
	_transformDataBlock = [transformDataBlock copy];
	_transformImageBlock = [transformImageBlock copy];
	
	// Return initialized instance.
	return self;
}


#pragma mark - Static Methods

+ (id)transformWithKey: (NSString *)key
	transformDataBlock: (AFImageTransformDataBlock)transformDataBlock
	transformImageBlock: (AFImageTransformImageBlock)transformImageBlock
{
	AFImageTransform *imageTransform = [[AFImageTransform alloc]
		initWithKey: key
		transformDataBlock: transformDataBlock
		transformImageBlock: transformImageBlock];
	
	// Return the transform.
	return imageTransform;
}

// Applies a blur to the image.
+ (id)transformForBlurredImageWithInputRadius: (CGFloat)inputRadius
{
	return [AFImageTransform transformWithKey: @"blurred_image"
		transformDataBlock: nil
		transformImageBlock: ^UIImage *(UIImage *image)
		{
			return [self _blurredImageFromImage: image
				inputRadius: inputRadius];
		}];
}

// Applies rounded corners to the image.
+ (id)transformForImageWithCornerRadiuses: (AFCornerRadiuses)cornerRadiuses
{
	// Set the keys.
	NSString *key = [NSString stringWithFormat: @"image_with_corner_radiuses_%f_%f_%f_%f",
		cornerRadiuses.topLeft,
		cornerRadiuses.topRight,
		cornerRadiuses.bottomRight,
		cornerRadiuses.bottomLeft];

	return [AFImageTransform transformWithKey: key
		transformDataBlock: nil
		transformImageBlock: ^UIImage *(UIImage *image)
		{
			// Transform the image.
			return [AFImageTransform _imageFromImage: image
				withCornerRadiuses: cornerRadiuses];
		}];
}

// Applies rounded corners to all corners of an image.
+ (id)transformForImageWithCornerRadius: (CGFloat)cornerRadius
{
	AFCornerRadiuses cornerRadiuses = AFCornerRadiusesMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
	
	return [AFImageTransform transformForImageWithCornerRadiuses: cornerRadiuses];
}

// Makes the image grayscale.
+ (id)transformForGrayscaleImage
{
	return [AFImageTransform transformWithKey: @"grayscale_image"
		transformDataBlock: nil
		transformImageBlock: ^UIImage *(UIImage *image)
		{
			// Transform the image.
			return [AFImageTransform _grayscaleImageFromImage: image];
		}];
}

// Makes the image a circle.
+ (id)transformForCircularImage
{
	return [AFImageTransform transformWithKey: @"circular_image"
		transformDataBlock: nil
		transformImageBlock: ^UIImage *(UIImage *image)
		{
			// Transform the image.
			return [AFImageTransform _circleImageFromImage: image];
		}];
}

// Applies no transform to the image.
+ (id)identity
{
	// Don't transform the data - just return the image.
	return [AFImageTransform transformWithKey: @"identity"
		transformDataBlock: nil
		transformImageBlock: nil];
}


#pragma mark - Instance Methods

// Applies the data transform.
- (UIImage *)transformData: (NSData *)data
{
	// Use data transform, if provided.
	if (_transformDataBlock != nil)
	{
		return _transformDataBlock(data);
	}
	
	// Otherwise, use the image transform.
	else if (_transformImageBlock != nil)
	{
		UIImage *image = [UIImage imageWithData: data];
		
		return _transformImageBlock(image);
	}
	
	// Otherwise, return the image.
	return [UIImage imageWithData: data];
}

// Applies the image transform.
- (UIImage *)transformImage: (UIImage *)image
{
	// Use the image transform, if provided.
	if (_transformImageBlock != nil)
	{
		return _transformImageBlock(image);
	}
	
	// Otherwise, use the data transform, if provided.
	else if (_transformDataBlock != nil)
	{
		CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
		
		NSData *data = (__bridge NSData *)CGDataProviderCopyData(provider);
	
		return _transformDataBlock(data);
	}
	
	// Otherwise, return the image.
	return image;
}


#pragma mark - Private Methods

+ (UIImage *)_grayscaleImageFromImage: (UIImage *)image
{
	CIImage *inputImage = [CIImage imageWithCGImage: image.CGImage];

	// TODO: Tint?
	CIFilter *monochromeFilter = [CIFilter filterWithName: @"CIColorMonochrome"
		keysAndValues: kCIInputImageKey, inputImage,
		@"inputColor", [CIColor colorWithRed: 0.25 green: 0.25 blue: 0.25],
		nil];
		
    CIImage *outputImage = monochromeFilter.outputImage;

    CIContext *context = [CIContext contextWithOptions: nil];
    CGImageRef filteredImage = [context createCGImage: outputImage
		fromRect: outputImage.extent];
    UIImage *newImage = [UIImage imageWithCGImage: filteredImage];

	// Release filtered image.
	if (filteredImage != NULL)
	{
		CGImageRelease(filteredImage);
	}
	
    return newImage;
	
}

+ (UIImage *)_blurredImageFromImage: (UIImage *)image
	inputRadius: (CGFloat)inputRadius
{
	CIImage *inputImage = [CIImage imageWithCGImage: image.CGImage];
	CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"];
	[filter setValue: inputImage
		forKey: kCIInputImageKey];
	[filter setValue: [NSNumber numberWithFloat: inputRadius]
		forKey: @"inputRadius"];
	CIImage *outputImage = [filter outputImage];
	
	CIContext *context = [CIContext contextWithOptions: nil];
	CGImageRef filteredImage =  [context createCGImage: outputImage
		fromRect: [inputImage extent]];
	UIImage *blurredImage = [UIImage imageWithCGImage: filteredImage];
	
	// Release filtered image.
	if (filteredImage != NULL)
	{
		CFRelease(filteredImage);
	}
	
	return blurredImage;
}

+ (UIImage *)_circleImageFromImage: (UIImage *)image
{
	CGFloat imageWidth = image.size.width;
	CGFloat imageHeight = image.size.height;
	CGRect clippingRect = CGRectMake(
		0.f,
		0.f,
		imageWidth,
		imageHeight);
	if (imageWidth > imageHeight)
	{
		clippingRect.origin.x = (imageWidth - imageHeight) / 2.f;
		clippingRect.size.width = imageHeight;
	}
	if (imageHeight > imageWidth)
	{
		clippingRect.origin.y = (imageHeight - imageWidth) / 2.f;
		clippingRect.size.height = imageWidth;
	}
		
	// Create the bitmap context.
	CGContextRef context = AFCreateBitmapContext(image, imageWidth, imageHeight);

	if (context == NULL)
	{
		return image;
	}
		
	// Create the path.
	CGPathRef path = CGPathCreateWithEllipseInRect(clippingRect, NULL);
	
	// Clip the image.
	UIImage *resultImage = [self _imageFromImage: image
		width: imageWidth
		height: imageHeight
		clippedToPath: path
		context: context];
		
	// Release context and path.
	CGContextRelease(context);
	CGPathRelease(path);
	
	// Return the clipped image.
	return resultImage;
}

+ (UIImage *)_imageFromImage: (UIImage *)image
	withCornerRadiuses: (AFCornerRadiuses)cornerRadiuses
{
	CGFloat width = image.size.width;
	CGFloat height = image.size.height;

	// Create the bitmap context.
	CGContextRef context = AFCreateBitmapContext(image, width, height);

	if (context == NULL)
	{
		return image;
	}

	// Get the extremities of the result image.
	CGFloat minX = 0.f;
	CGFloat midX = width / 2.f;
	CGFloat maxX = width;
    CGFloat minY = 0.f;
	CGFloat midY = height / 2.f;
	CGFloat maxY = height;

	// Create the clipping path.
	CGMutablePathRef path = CGPathCreateMutable();
	CGContextMoveToPoint(context, minX, midY);
    CGContextAddArcToPoint(context, minX, minY, midX, minY, cornerRadiuses.bottomLeft);
    CGContextAddArcToPoint(context, maxX, minY, maxX, midY, cornerRadiuses.bottomRight);
    CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, cornerRadiuses.topRight);
    CGContextAddArcToPoint(context, minX, maxY, minX, midY, cornerRadiuses.topLeft);
    CGContextClosePath(context);

	// Clip the image.
	UIImage *resultImage = [self _imageFromImage: image
		width: width
		height: height
		clippedToPath: path
		context: context];
	
	// Release context and path.
	CGContextRelease(context);
	CGPathRelease(path);
	
	// Return the clipped image.
	return resultImage;
}

+ (UIImage *)_imageFromImage: (UIImage *)image
	width: (CGFloat)width
	height: (CGFloat)height
	clippedToPath: (CGPathRef)path
	context: (CGContextRef)context
{
	// Apply the clipping path.
	CGContextAddPath(context, path);
	CGContextClip(context);

	// Draw the image.
	CGContextDrawImage(context,
		CGRectMake(0.f, 0.f, width, height),
		[image CGImage]);

	// Create the result image.
	CGImageRef resultImageRef = CGBitmapContextCreateImage(context);
	UIImage *resultImage = [UIImage imageWithCGImage: resultImageRef];
	
	// Free the image.
	CGImageRelease(resultImageRef);

	// Return the image.
	return resultImage;
}

static CGContextRef AFCreateBitmapContext(UIImage *image, CGFloat width, CGFloat height)
{
	const size_t BytesPerComponent = 8;
	const size_t BytesPerRow = 0;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	// Create a bitmap context the same size as the image.
	CGContextRef context = CGBitmapContextCreate(NULL,
		width,
		height,
		BytesPerComponent,
		BytesPerRow,
		colorSpace,
		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

	// Free the RGB color space.
	CGColorSpaceRelease(colorSpace);
	
	// Return the context.
	return context;
}


@end // @implementation AFImageTransform