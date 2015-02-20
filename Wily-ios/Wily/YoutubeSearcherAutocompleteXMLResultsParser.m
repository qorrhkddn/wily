#import "YoutubeSearcherAutocompleteXMLResultsParser.h"

@interface YoutubeSearcherAutocompleteXMLResultsParser () <NSXMLParserDelegate>
@property (nonatomic, readonly) NSXMLParser *xmlParser;
@property (nonatomic, readonly) void (^completionBlock)(NSArray *suggestions);
@property (nonatomic) NSMutableArray *result;
@end

@implementation YoutubeSearcherAutocompleteXMLResultsParser

- (instancetype)initWithResponseXMLParser:(NSXMLParser *)xmlParser
                          completionBlock:(void (^)(NSArray *suggestions))completionBlock {
  self = [super init];
  if (self) {
    _xmlParser = xmlParser;
    _completionBlock = completionBlock;
  }
  return self;
}

- (void)start {
  self.xmlParser.delegate = self;
  [self.xmlParser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
  self.result = [NSMutableArray array];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
  if ([elementName isEqualToString:@"suggestion"]) {
    [self.result addObject:attributeDict[@"data"]];
  }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
  self.completionBlock(self.result);
}

@end
