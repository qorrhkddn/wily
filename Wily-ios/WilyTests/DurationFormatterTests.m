@import XCTest;
#import "DurationFormatter.h"

@interface DurationFormatterTests : XCTestCase

@end

@implementation DurationFormatterTests

- (void)testTimeIntervalIsConvertedToMinutesSecondsWithLeadingZeroes {
  XCTAssertEqualObjects(@"0:59", [DurationFormatter stringForTimeInterval:59]);
  XCTAssertEqualObjects(@"1:01", [DurationFormatter stringForTimeInterval:61]);
}

@end
