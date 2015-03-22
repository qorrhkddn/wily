#import "WilyYouTube.h"
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "XCDYouTubeVideo+PreferredStreamURLExtraction.h"
#import "NSDictionary+WilyExtensions.h"

@implementation XCDYouTubeVideo (WilyYouTubeExtension)

- (NSDictionary *)wily_song {
  return @{@"title": self.title,
           @"thumbnailURL": [self.mediumThumbnailURL absoluteString]};
}

@end

@implementation NSError (WilyYouTubeExtension)

+ (NSError *)wily_noStreamError {
  return [NSError errorWithDomain:XCDYouTubeVideoErrorDomain
                             code:XCDYouTubeErrorNoStreamAvailable
                         userInfo:nil];
}

@end

void WilyYouTubeFetchSong(NSDictionary *song, void (^completionBlock)(NSError *error, NSURL *streamURL, NSDictionary *song)) {
  NSString *videoId = song[@"id"];
  NSLog(@"Fetching [videoId = %@]", videoId);
  [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    NSURL *streamURL;

    if (error == nil) {
      streamURL = [video lowestQualityStreamURL];
      if (streamURL == nil) {
        error = [NSError wily_noStreamError];
      }
    }

    if (error) {
      NSLog(@"Fetch Failed [videoId = %@, error = %@]", videoId, [error localizedDescription]);
      completionBlock(error, nil, nil);
    } else {
      NSLog(@"Fetch Completed [videoId = %@, streamURL = %@]", videoId, streamURL);
      completionBlock(nil, streamURL, [song wily_dictionaryByMergingDictionary:[video wily_song]]);
    }
  }];
}
