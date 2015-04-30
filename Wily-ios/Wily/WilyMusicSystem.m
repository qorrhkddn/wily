#import "WilyMusicSystem.h"
#import "WilyPlayer.h"
#import "WilyPlayer+Playback.h"
#import "RemoteControlEvents.h"
#import "CacheableAVPlayerItem.h"
#import <MXPersistentCache/MXPersistentCache.h>
#import "WilyYouTube.h"
#import "WilyPlaylist.h"
#import "WilyPlaylist+MusicSystem.h"
#import "WallpaperManager.h"
#import "NSDictionary+WilyExtensions.h"

@interface WilyMusicSystem () <RemoteControlEventsDelegate, CacheableAVPlayerItemDelegate, WilyPlaylistDelegate, WilyPlayerPlaybackDelegate>

@property (nonatomic, readonly) MXPersistentCache *mediaCache;
@property (nonatomic, readonly) NSUserDefaults *store;
@property (nonatomic, readonly) RemoteControlEvents *remoteControlEvents;
@property (nonatomic) WilyPlaylist *playlist;

@property (nonatomic) WilyPlayer *player;
@property (nonatomic) NSString *currentlyDownloadingVideoId;

@end

@implementation WilyMusicSystem

- (instancetype)init {
  self = [super init];
  if (self) {
    _mediaCache = [[MXPersistentCache alloc] initWithPrefix:@"media" extension:@"mp4"];
    _store = [NSUserDefaults standardUserDefaults];
    _remoteControlEvents = [[RemoteControlEvents alloc] init];
    _remoteControlEvents.delegate = self;
    _wallpaperManager = [[WallpaperManager alloc] init];

    _playlist = [[WilyPlaylist alloc] initWithStore:_store];
    _playlist.delegate = self;

    [self enableAVAudioSessionCategoryPlayback];
  }
  return self;
}

- (void)enableAVAudioSessionCategoryPlayback {
  NSError *error = nil;
  BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                        error:&error];
  if (!success) {
    NSLog(@"Audio Session Category error: %@", error);
  }
}

- (void)playSong:(NSDictionary *)song {
  song = [self songByAttachingWallpaper:song];
  NSUInteger index = [self.playlist existingIndexForSong:song];
  if (index == self.playlist.invalidIndex) {
    [self fetchStreamURLForSong:song];
  } else {
    [self playSongAtIndex:index];
  }
}

- (NSDictionary *)songByAttachingWallpaper:(NSDictionary *)song {
  if (song[@"wallpaperId"]) {
    return song;
  }
  NSDictionary *wallpaperDict = @{@"wallpaperId": [self.wallpaperManager randomWallpaperId]};
  return [song wily_dictionaryByMergingDictionary:wallpaperDict];
}

- (void)playSongAtIndex:(NSUInteger)index {
  if (index == self.playlist.invalidIndex) {
    return;
  }

  NSDictionary *song = self.playlist.songs[index];
  NSURL *fileURL = [self.mediaCache fileURLForKey:song[@"id"]];
  if (fileURL == nil) {
    [self fetchStreamURLForSong:song];
  } else {
    [self.playlist setCurrentlyPlayingIndexNoNotify:index];
    [self playSong:song withFileURL:fileURL];
  }
}

- (void)playSong:(NSDictionary *)song withFileURL:(NSURL *)fileURL  {
  AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:fileURL];
  [self changePlayer:[[WilyPlayer alloc] initWithPlayerItem:playerItem song:song]];
}

- (void)changePlayer:(WilyPlayer *)player {
  self.currentlyDownloadingVideoId = nil;
  [self.player stopPlayingItem];
  self.player = player;
  self.player.playbackDelegate = self;
  [self.player startPlayingItem];

  if ([self.delegate respondsToSelector:@selector(musicSystem:playerDidChange:)]) {
    [self.delegate musicSystem:self playerDidChange:self.player];
  }
}

- (void)fetchStreamURLForSong:(NSDictionary *)song {
  WilyPlayer *dummyPlayerForFetchingState = [[WilyPlayer alloc] initWithPlayerItem:nil song:song];
  [self changePlayer:dummyPlayerForFetchingState];

  __weak typeof(self) weakSelf = self;
  WilyYouTubeFetchSong(song, ^(NSError *error, NSURL *streamURL, NSDictionary *updatedSong) {
    if (error == nil) {
      [weakSelf playSong:updatedSong withStreamURL:streamURL];
    }
  });
}

- (void)playSong:(NSDictionary *)song withStreamURL:(NSURL *)streamURL {
  NSUInteger index = [self.playlist existingIndexForSong:song];
  if (index == self.playlist.invalidIndex) {
    [self.playlist appendSong:song];
    [self.playlist setCurrentlyPlayingIndexNoNotify:(self.playlist.songs.count - 1)];
  }

  CacheableAVPlayerItem *cacheablePlayerItem = [[CacheableAVPlayerItem alloc] initWithURL:streamURL];
  cacheablePlayerItem.delegate = self;
  [self changePlayer:[[WilyPlayer alloc] initWithPlayerItem:cacheablePlayerItem song:song]];

  self.currentlyDownloadingVideoId = song[@"id"];
}

- (void)remoteControlEventsDidTogglePlayPause:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did toggle play/pause");
  [self.player togglePlayPause];
}

- (void)remoteControlEventsDidPressNext:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press next");
  [self playNext];
}

- (void)playNext {
  [self playSongAtIndex:[self.playlist nextSongIndex]];
}

- (void)remoteControlEventsDidPressPrevious:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press previous");
  [self playSongAtIndex:[self.playlist previousSongIndex]];
}

- (void)cacheableAVPlayerItem:(CacheableAVPlayerItem *)playerItem
       didDownloadURLContents:(NSData *)data {
  NSLog(@"Download completed [Size = %@ bytes, videoId = %@]", @([data length]), self.currentlyDownloadingVideoId);
  if (self.currentlyDownloadingVideoId == nil) {
    NSLog(@"Unexpected state: Have downloaded data without corresponding videoId; will ignore");
    return;
  }

  [self.mediaCache persistFileForKey:self.currentlyDownloadingVideoId withData:data];
  self.currentlyDownloadingVideoId = nil;
}

- (void)playlistDidDeleteCurrentlyPlayingSong:(WilyPlaylist *)playlist {
  [self changePlayer:nil];
}

- (void)playlist:(WilyPlaylist *)playlist didChangeCurrentlyPlayingIndex:(NSUInteger)index {
  [self playSongAtIndex:index];
}

- (void)playerDidEndPlayingSong:(WilyPlayer *)player {
  if ([self.playlist shouldAutoplay]) {
    [self playNext];
  } else {
    [self.player repeat];
  }
}

- (void)playlist:(WilyPlaylist *)playlist shouldPlaySong:(NSDictionary *)song {
  [self playSong:song];
}

@end
