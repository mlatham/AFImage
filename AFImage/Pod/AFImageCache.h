#import "AFImageCacheOperation.h"


#pragma mark Type Definitions

// Block that transforms one image into another.
typedef AFImageCacheOperation *(^AFImageCacheOperationCreateBlock)(NSURL *url, AFImageTransform *transform,
	NSCache *cache, BOOL refresh, AFImageCompletionBlock completionBlock);


#pragma mark Class Interface

@interface AFImageCache : NSObject


#pragma mark - Properties

// Allows overriding the creation of image cache operations.
@property (nonatomic, copy) AFImageCacheOperationCreateBlock imageCacheOperationCreateBlock;


#pragma mark - Static Methods

+ (instancetype)sharedInstance;


#pragma mark - Instance Methods

- (AFImageCacheOperation *)imageWithURL: (NSURL *)url
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (AFImageCacheOperation *)imageWithURL: (NSURL *)url
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (AFImageCacheOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (AFImageCacheOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock;


@end // @interface AFImageCache