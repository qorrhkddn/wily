@import XCTest;
#import "WilyYouTubeURL.h"

@interface WilyYouTubeURLTests : XCTestCase

@end

@implementation WilyYouTubeURLTests

- (void)testExtraction {
  XCTAssertEqualObjects(@"123", WilyYouTubeSongFromURLString(@"http://youtu.be/123")[@"id"]);
  XCTAssertEqualObjects(@"123", WilyYouTubeSongFromURLString(@"http://youtube.com/v/123")[@"id"]);
  XCTAssertNil(WilyYouTubeSongFromURLString(@"http://youtube.com/z/123"));
}

@end
