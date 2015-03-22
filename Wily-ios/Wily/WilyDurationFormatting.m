#import "WilyDurationFormatting.h"

NSString *WilyDurationStringForTimeInterval(NSTimeInterval interval) {
  if (isnan(interval)) {
    return @"-:--";
  }
  NSUInteger minutes = floor(interval/60);
  unsigned seconds = round(interval - minutes * 60);
  return [NSString stringWithFormat:@"%@:%02u", @(minutes), seconds];
}
