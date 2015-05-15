#import "WilyPlaylist+Pasteboard.h"
#import "WilyYouTubeURL.h"
#import "WilyPlaylist+MusicSystem.h"
@import UIKit;

@implementation WilyPlaylist (Pasteboard)

- (void)copyYouTubeLinkOfCurrentlyPlayingSong {
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
  [UIPasteboard generalPasteboard].URL = [NSURL URLWithString:URLString];
}

- (void)playSongFromCopiedYouTubeLink {
  NSString *URLString = nil;

  NSURL *URL = [UIPasteboard generalPasteboard].URL;
  if (URL) {
    URLString = [URL absoluteString];
  } else {
    URLString = [UIPasteboard generalPasteboard].string;
  }

  if (URLString == nil) {
    return;
  }

  NSDictionary *song = WilyYouTubeSongFromURLString(URLString);
  NSLog(@"Parsed pasteboard URL [string = %@, song = %@]", URLString, song);

  if ([self.delegate respondsToSelector:@selector(playlist:shouldPlaySong:)]) {
    [self.delegate playlist:self shouldPlaySong:song];
  }
}

@end
