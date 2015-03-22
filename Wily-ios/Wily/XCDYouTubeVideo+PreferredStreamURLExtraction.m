#import "XCDYouTubeVideo+PreferredStreamURLExtraction.h"

@implementation XCDYouTubeVideo (PreferredStreamURLExtraction)

- (NSURL *)streamURLForPreferredVideoQualities:(NSArray *)preferredVideoQualities {
  for (NSNumber *videoQuality in preferredVideoQualities) {
    NSURL *result = self.streamURLs[videoQuality];
    if (result) {
      return result;
    }
  }
  return nil;
}

+ (NSArray *)lowToHighVideoQualities {
  return @[@(XCDYouTubeVideoQualitySmall240),
           @(XCDYouTubeVideoQualityMedium360),
           @(XCDYouTubeVideoQualityHD720)];
}

- (NSURL *)lowestQualityStreamURL {
  return [self streamURLForPreferredVideoQualities:
          [XCDYouTubeVideo lowToHighVideoQualities]];
}

@end
