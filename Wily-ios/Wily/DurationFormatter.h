@import Foundation;

@interface DurationFormatter : NSObject

/**
 Convert a time interval into a string suitable for display in
 a music player like interface.
 */
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval;

@end
