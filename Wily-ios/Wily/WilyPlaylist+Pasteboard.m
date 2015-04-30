#import "WilyPlaylist+Pasteboard.h"
#import "WilyYouTubeURL.h"
@import UIKit;

@implementation WilyPlaylist (Pasteboard)

- (void)copyYouTubeLinkToCurrentlyPlayingSong {
  NSUInteger idx = [self currentlyPlayingIndex];
  if (idx == [self invalidIndex]) {
    return;
  }

  NSDictionary *song = [self songs][idx];
  if (song == nil) {
    return;
  }

  NSString *URLString = WilyYouTubeURLStringFromSong(song);
  NSLog(@"Setting pasteboard string = %@", URLString);
  [UIPasteboard generalPasteboard].string = URLString;
}

@end
