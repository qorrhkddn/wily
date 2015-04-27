#import "WilyYouTubeURL.h"

NSDictionary *WilyYouTubeSongFromURLString(NSString *string) {
  NSString *regexString = @"((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)";
  NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];

  NSArray *array = [regExp matchesInString:string options:0 range:NSMakeRange(0, string.length)];
  if (array.count > 0) {
    NSTextCheckingResult *result = array.firstObject;
    return @{@"id": [string substringWithRange:result.range]};
  }
  return nil;
}

NSString *WilyYouTubeURLStringFromSong(NSDictionary *song) {
  return [@"http://youtu.be/" stringByAppendingString:song[@"id"]];
}
