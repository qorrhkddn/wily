#import "XCDYouTubeVideo.h"

@interface XCDYouTubeVideo (PreferredStreamURLExtraction)

/**
 @return the stream URL that matches one of @p preferredVideoQualities,
 tried in order.
 */
- (NSURL *)streamURLForPreferredVideoQualities:(NSArray *)preferredVideoQualities;

- (NSURL *)lowestQualityStreamURL;

@end
