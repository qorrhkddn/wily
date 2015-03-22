#import "WilyMusicSystem.h"
#import "WilyPlayer.h"
#import "WilyPlayer+Playback.h"
#import "RemoteControlEvents.h"
#import "CacheableAVPlayerItem.h"
#import <MXPersistentCache/MXPersistentCache.h>
#import "WilyYouTube.h"
#import "WilyPlaylist.h"
#import "WilyPlaylist+MusicSystem.h"

@interface WilyMusicSystem () <RemoteControlEventsDelegate, CacheableAVPlayerItemDelegate, WilyPlaylistDelegate>

@property (nonatomic, readonly) MXPersistentCache *mediaCache;
@property (nonatomic, readonly) NSUserDefaults *keyValueStore;
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
    _keyValueStore = [NSUserDefaults standardUserDefaults];
    _remoteControlEvents = [[RemoteControlEvents alloc] init];

    NSArray *songs = [self.keyValueStore arrayForKey:@"songs"];
    _playlist = [[WilyPlaylist alloc] initWithSongs:songs];
    _playlist.delegate = self;

    _remoteControlEvents.delegate = self;
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

- (void)enqueueItemForYouTubeVideoWithId:(NSString *)videoId {
  NSLog(@"Enqueuing Video [%@]", videoId);
  NSURL *fileURL = [self.mediaCache fileURLForKey:videoId];
  NSDictionary *song = [self.keyValueStore dictionaryForKey:videoId];
  if (fileURL && song) {
    NSLog(@"Found existing song and downloaded file for video [videoId = %@]", videoId);
    [self playSong:song withFileURL:fileURL];
  } else {
    NSLog(@"Video not found; will fetch metadata and stream [videoId = %@]", videoId);
    [self fetchSongWithId:videoId];
  }
}

- (void)playSong:(NSDictionary *)song withFileURL:(NSURL *)fileURL  {
  AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:fileURL];
  [self playSong:song withPlayerItem:playerItem];
}

- (void)playSong:(NSDictionary *)song withPlayerItem:(AVPlayerItem *)playerItem {
  [self changePlayer:[[WilyPlayer alloc] initWithPlayerItem:playerItem song:song]];
  [self.player startPlayingItem];
}

- (void)changePlayer:(WilyPlayer *)player {
  self.currentlyDownloadingVideoId = nil;
  [self.player stopPlayingItem];
  self.player = player;
  if ([self.delegate respondsToSelector:@selector(musicSystem:playerDidChange:)]) {
    [self.delegate musicSystem:self playerDidChange:self.player];
  }
}

- (void)fetchSongWithId:(NSString *)videoId {
  [self changePlayer:nil];
  __weak typeof(self) weakSelf = self;
  WilyYouTubeFetchVideoWithId(videoId, ^(NSError *error, NSURL *streamURL, NSDictionary *song) {
    if (error == nil) {
      [weakSelf playSong:song withStreamURL:streamURL];
    }
  });
}

- (void)playSong:(NSDictionary *)song withStreamURL:(NSURL *)streamURL {
  [self.playlist insertAsCurrentlyPlayingSong:song];

  CacheableAVPlayerItem *cacheablePlayerItem = [[CacheableAVPlayerItem alloc] initWithURL:streamURL];
  cacheablePlayerItem.delegate = self;
  [self playSong:song withPlayerItem:cacheablePlayerItem];
  self.currentlyDownloadingVideoId = song[@"id"];
}

- (void)remoteControlEventsDidTogglePlayPause:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did toggle play/pause");
  [self.player togglePlayPause];
}

- (void)remoteControlEventsDidPressNext:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press next");
}

- (void)remoteControlEventsDidPressPrevious:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press previous");
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

- (void)playlist:(WilyPlaylist *)playlist didUpdateSongs:(NSArray *)songs {
  [self.keyValueStore setObject:songs forKey:@"songs"];
}

@end
