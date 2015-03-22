#import "NSDictionary+WilyExtensions.h"

@implementation NSDictionary (WilyExtensions)

- (NSDictionary *)wily_dictionaryByMergingDictionary:(NSDictionary *)dictionary {
  NSMutableDictionary *result = [self mutableCopy];
  [result addEntriesFromDictionary:dictionary];
  return result;
}

@end
