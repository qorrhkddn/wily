@import Foundation;

@interface YoutubeSearcher : NSObject

- (NSArray *)autocompleteSuggestionsForSearchString:(NSString *)searchString;

/**
 If the the search fails, @p videoIdentifier will be @p nil.
 */
- (void)firstVideoIdentifierForSearchString:(NSString *)searchString
                            completionBlock:(void (^)(NSString *videoIdentifier))completionBlock;

@end
