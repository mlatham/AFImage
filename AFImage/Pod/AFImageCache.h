#import "AFImageCacheOperation.h"


#pragma mark Class Interface

@interface AFImageCache : NSObject


#pragma mark - Static Methods

+ (id)sharedInstance;


#pragma mark - Instance Methods

- (NSOperation *)imageWithURL: (NSURL *)url
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (NSOperation *)imageWithURL: (NSURL *)url
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (NSOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	completionBlock: (AFImageCompletionBlock)completionBlock;

- (NSOperation *)imageWithURL: (NSURL *)url
	transform: (AFImageTransform *)transform
	refresh: (BOOL)refresh
	completionBlock: (AFImageCompletionBlock)completionBlock;


@end // @interface AFImageCache