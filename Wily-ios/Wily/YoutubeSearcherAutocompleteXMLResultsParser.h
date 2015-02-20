@import Foundation;

@interface YoutubeSearcherAutocompleteXMLResultsParser : NSObject

- (instancetype)initWithResponseXMLParser:(NSXMLParser *)xmlParser
                          completionBlock:(void (^)(NSArray *suggestions))completionBlock;

- (void)start;

@end
