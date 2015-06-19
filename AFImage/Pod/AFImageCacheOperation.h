#import "AFImageTransform.h"


#pragma mark Enumerations

typedef enum
{
	AFImageCacheResultUnknown,
	AFImageCacheResultSuccessFromMemoryCache,
	AFImageCacheResultSuccessFromDiskCache,
	AFImageCacheResultSuccessFromURL,
	AFImageCacheResultFailed,
	AFImageCacheResultCancelled

} AFImageCacheResult;


#pragma mark - Type Definitions

typedef void (^AFImageCompletionBlock)(AFImageCacheResult result, UIImage *image);
typedef void (^AFImageCacheURLCompletion)(AFImageCacheResult result, NSURL *imageCacheURL);


#pragma mark - Class Interface

@interface AFImageCacheOperation : NSOperation


#pragma mark - Properties

@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, readonly) NSHTTPURLResponse *response;

@property (nonatomic, readonly) NSMutableURLRequest *request;


#pragma mark - Constructors

- (id)initWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	useDiskCache: (BOOL)useDiskCache
    completionBlock: (AFImageCompletionBlock)completionBlock;

+ (UIImage *)imageWithURL: (NSURL *)url
	cache: (NSCache *)cache
	transform: (AFImageTransform *)transform;


@end // @interface AFImageCacheOperation