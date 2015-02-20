#import "YoutubeSearcher.h"
#import <iOS-GTLYouTube/GTLYouTube.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
#import "YoutubeSearcherAutocompleteXMLResultsParser.h"

static NSString * const GoogleAPIKey = @"AIzaSyD2Otqd_OlhLfZekoXGMSuibDgGcagp-3Y";

@interface YoutubeSearcher ()
@property (nonatomic, readonly) GTLServiceYouTube *service;
@end

@implementation YoutubeSearcher

- (instancetype)init {
  self = [super init];
  if (self) {
    [[AFNetworkActivityLogger sharedLogger] startLogging];

    _service = [[GTLServiceYouTube alloc] init];
    _service.APIKey = GoogleAPIKey;
  }
  return self;
}

- (void)autocompleteSuggestionsForSearchString:(NSString *)searchString
                               completionBlock:(void (^)(NSArray *suggestions))completionBlock {
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  NSString *baseURL = @"http://suggestqueries.google.com/complete/search?client=toolbar&ds=yt&q=";
  NSString *encodedSearchString = [searchString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
  encodedSearchString = [encodedSearchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *queryURL = [baseURL stringByAppendingString:encodedSearchString];
  [manager setResponseSerializer:[AFXMLParserResponseSerializer serializer]];
  [manager GET:queryURL parameters:nil success:^(AFHTTPRequestOperation *operation, NSXMLParser *responseParser) {
    __block YoutubeSearcherAutocompleteXMLResultsParser *parser = [[YoutubeSearcherAutocompleteXMLResultsParser alloc] initWithResponseXMLParser:responseParser completionBlock:^(NSArray *suggestions) {
      parser = nil; // To ensure that we hold on to the parser until it completes.
      completionBlock(suggestions);
    }];
    [parser start];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Autocomplete query failed [searchString = %@, error = %@]", searchString, error);
  }];
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
