#import "DurationFormatter.h"

@implementation DurationFormatter

+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval {
  if (isnan(interval)) {
    return @"-:-";
  }
  NSUInteger minutes = floor(interval/60);
  NSUInteger seconds = round(interval - minutes * 60);
  return [NSString stringWithFormat:@"%@:%@", @(minutes), @(seconds)];
}

@end
