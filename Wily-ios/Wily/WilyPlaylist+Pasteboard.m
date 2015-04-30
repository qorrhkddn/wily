#import "WilyPlaylist+Pasteboard.h"
#import "WilyYouTubeURL.h"
#import "WilyPlaylist+MusicSystem.h"
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

- (void)playSongFromCopiedYouTubeLink {
  NSString *URLString = [UIPasteboard generalPasteboard].string;
  NSDictionary *song = WilyYouTubeSongFromURLString(URLString);
  NSLog(@"Parsed pasteboard string [song = %@]", song);

  if ([self.delegate respondsToSelector:@selector(playlist:shouldPlaySong:)]) {
    [self.delegate playlist:self shouldPlaySong:song];
  }
}

@end
