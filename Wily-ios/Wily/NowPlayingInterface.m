#import "NowPlayingInterface.h"
#import <XCDYouTubeKit/XCDYouTubeKit.h>

NSString * const NowPlayingInterfaceUIEventSubtypeRemoteControlTogglePlayPause = @"NowPlayingInterfaceUIEventSubtypeRemoteControlTogglePlayPause";

@implementation NSDictionary (NowPlayingInterfaceExtensions)

- (NSDictionary *)tdt_dictionaryByMergingDictionary:(NSDictionary *)dict {
  NSMutableDictionary *result = [self mutableCopy];
  [result addEntriesFromDictionary:dict];
  return result;
}

@end

@implementation NowPlayingInterface

- (void)clear {
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{}];
}

- (void)updateNowPlayingInfoDictionaryWithDictionary:(NSDictionary *)dict {
  NSDictionary *result = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo];
  result = [result tdt_dictionaryByMergingDictionary:dict];
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:result];
}

- (void)setTitle:(NSString *)title {
  [self updateNowPlayingInfoDictionaryWithDictionary:@{ MPMediaItemPropertyTitle: title }];
}

- (void)asynchronouslySetImageFromThumbnailURL:(NSURL *)thumbnailURL {
  [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:thumbnailURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
   {
     if (data) {
       UIImage *image = [UIImage imageWithData:data];
       MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
       if (artwork) {
         [self updateNowPlayingInfoDictionaryWithDictionary:
          @{ MPMediaItemPropertyArtwork: artwork }];
       }
     }
   }];
}

- (void)setDuration:(float)duration {
  [self updateNowPlayingInfoDictionaryWithDictionary:
   @{ MPMediaItemPropertyPlaybackDuration: @(duration) }];
}

- (void)setCurrentPlaybackTime:(float)playbackTime {
  [self updateNowPlayingInfoDictionaryWithDictionary:
   @{ MPNowPlayingInfoPropertyElapsedPlaybackTime: @(playbackTime) }];
}

@end
