@import XCTest;
#import "WilyDurationFormatting.h"

@interface WilyDurationFormattingTests : XCTestCase

@end

@implementation WilyDurationFormattingTests

- (void)testTimeIntervalIsConvertedToMinutesSecondsWithLeadingZeroes {
  XCTAssertEqualObjects(@"0:59", WilyDurationStringForTimeInterval(59));
  XCTAssertEqualObjects(@"1:01", WilyDurationStringForTimeInterval(61));
}

@end
