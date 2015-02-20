@import Foundation;

@interface YoutubeSearcher : NSObject

/**
 If the the search fails, the @p suggestions array will be @p nil.
 On success, @p suggestions will be a non-nil array of NSStrings.
 */
- (void)autocompleteSuggestionsForSearchString:(NSString *)searchString
                               completionBlock:(void (^)(NSArray *suggestions))completionBlock;

/**
 If the the search fails, @p videoIdentifier will be @p nil.
 */
- (void)firstVideoIdentifierForSearchString:(NSString *)searchString
                            completionBlock:(void (^)(NSString *videoIdentifier))completionBlock;

@end
