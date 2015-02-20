#import "YoutubeSearcher.h"
#import <iOS-GTLYouTube/GTLYouTube.h>

static NSString * const GoogleAPIKey = @"AIzaSyD2Otqd_OlhLfZekoXGMSuibDgGcagp-3Y";

@interface YoutubeSearcher ()
@property (nonatomic, readonly) GTLServiceYouTube *service;
@end

@implementation YoutubeSearcher

- (instancetype)init {
  self = [super init];
  if (self) {
    _service = [[GTLServiceYouTube alloc] init];
    _service.APIKey = GoogleAPIKey;
  }
  return self;
}

- (NSArray *)autocompleteSuggestionsForSearchString:(NSString *)searchString {
  return @[];
}

- (void)firstVideoIdentifierForSearchString:(NSString *)searchString
                            completionBlock:(void (^)(NSString *videoIdentifier))completionBlock {
  GTLQueryYouTube *query = [GTLQueryYouTube queryForSearchListWithPart:@"snippet"];
  query.q = searchString;
  [self.service executeQuery:query
           completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeSearchListResponse *searchListResponse, NSError *error) {
             if (error != nil) {
               NSLog(@"Youtube search failed: %@", [error localizedDescription]);
               completionBlock(nil);
             } else {
               NSLog(@"Youtube search completed: %@", searchListResponse);
               GTLYouTubeSearchResult *searchResult = [[searchListResponse items] firstObject];
               NSString *videoId = [[searchResult identifier] JSONValueForKey:@"videoId"];
               completionBlock(videoId);
             }
           }];
}

@end
