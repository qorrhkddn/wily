#import "YouTubeVideoPlayer.h"
@import AVFoundation;
@import AVKit;
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "NowPlayingInterface.h"
#import "RemoteControlEvents.h"
#import "XCDYouTubeVideo+PreferredStreamURLExtraction.h"
#import "CacheableAVPlayerItem.h"
#import <MXPersistentCache/MXPersistentCache.h>

@interface YouTubeVideoPlayer () <RemoteControlEventsDelegate, CacheableAVPlayerItemDelegate>

@property (nonatomic, readonly) MXPersistentCache *mediaCache;
@property (nonatomic, readonly) NSUserDefaults *keyValueStore;
@property (nonatomic, readonly) RemoteControlEvents *remoteControlEvents;
@property (nonatomic, readonly) NowPlayingInterface *nowPlayingInterface;

@property (nonatomic, readwrite) YouTubeVideoPlayerPlaybackState playbackState;
@property (nonatomic) XCDYouTubeVideoOperation *videoOperation;

// The following properties are valid only during playback.
@property (nonatomic) NSString *videoIdentifier;
@property (nonatomic) id playerTimeObserver;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) NSDictionary *unsavedMetadata;

@end

@implementation YouTubeVideoPlayer

- (instancetype)init {
  self = [super init];
  if (self) {
    _mediaCache = [[MXPersistentCache alloc] initWithPrefix:@"media-v0" extension:@"mp4"];
    _keyValueStore = [NSUserDefaults standardUserDefaults];
    _remoteControlEvents = [[RemoteControlEvents alloc] init];
    _nowPlayingInterface = [[NowPlayingInterface alloc] init];

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

- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier {
  [self.nowPlayingInterface clear];

  if (self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty) {
    [self clearDeck];
  }

  NSLog(@"State transition: Loading [Video Identifier = %@]", videoIdentifier);
  self.playbackState = YouTubeVideoPlayerPlaybackStateLoading;
  self.videoIdentifier = videoIdentifier;

  NSURL *fileURL = [self.mediaCache fileURLForKey:videoIdentifier];
  NSDictionary *metadata = [self.keyValueStore dictionaryForKey:videoIdentifier];
  if (fileURL && metadata) {
    NSLog(@"Found existing metadata and downloaded file for video [videoId = %@]", videoIdentifier);
    [self playDownloadedFileURL:fileURL withMetadata:metadata];
  } else {
    NSLog(@"Video not found; will fetch metadata and stream [videoId = %@]", videoIdentifier);
    [self fetchMetadataForIdentifier:videoIdentifier];
  }
}

- (void)fetchMetadataForIdentifier:(NSString *)videoIdentifier {
  self.videoOperation = [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    self.videoOperation = nil;
    if (video) {
      [self streamVideo:video];
    } else {
      [self cancelPlaybackWithError:error];
    }
  }];
}

- (void)cancelPlaybackWithError:(NSError *)error {
  NSLog(@"State transition: Clearing Deck [error = %@]", error);
  self.playbackState = YouTubeVideoPlayerPlaybackStateDeckEmpty;
  self.videoIdentifier = nil;
}

- (void)streamVideo:(XCDYouTubeVideo *)video {
  NSURL *streamURL = [video lowestQualityStreamURL];
  if (streamURL == nil) {
    [self cancelPlaybackWithError:[self noStreamError]];
    return;
  }

  NSDictionary *metadata = [YouTubeVideoPlayer metadataFromVideo:video];
  self.unsavedMetadata = metadata;
  [self willPlayVideoWithMetadata:metadata];

  CacheableAVPlayerItem *cacheablePlayerItem = [[CacheableAVPlayerItem alloc] initWithURL:streamURL];
  cacheablePlayerItem.delegate = self;
  [self beginPlayingItem:cacheablePlayerItem];
}

- (void)beginPlayingItem:(AVPlayerItem *)playerItem {
  self.playerItem  = playerItem;
  [self observePlayerItem];
  self.player = [AVPlayer playerWithPlayerItem:self.playerItem];

  [self notifyDelegateOfProgress:0];
  [self observePlayer];

  [self play];
}

+ (NSDictionary *)metadataFromVideo:(XCDYouTubeVideo *)video {
  NSString *title = video.title;
  NSURL *thumbnailURL = video.mediumThumbnailURL;

  return @{@"title": title, @"thumbnailURL": [thumbnailURL absoluteString]};
}

- (void)playDownloadedFileURL:(NSURL *)fileURL withMetadata:(NSDictionary *)metadata {
  NSParameterAssert(fileURL);
  NSParameterAssert(metadata);

  [self willPlayVideoWithMetadata:metadata];

  AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:fileURL];
  [self beginPlayingItem:playerItem];
}

- (NSError *)noStreamError {
  return [NSError errorWithDomain:XCDYouTubeVideoErrorDomain
                             code:XCDYouTubeErrorNoStreamAvailable
                         userInfo:nil];
}

- (void)invalidate {
  if (self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty) {
    [self clearDeck];
  }
}

- (void)clearDeck {
  NSAssert(self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempt to unload video when the deck is empty");

  self.unsavedMetadata = nil;
  [self.videoOperation cancel];

  [self unobservePlayerItem];
  [self unobservePlayer];
  [self pause];
  [self notifyDelegateOfProgress:0];

  self.player = nil;
  self.playerItem = nil;

  [self.nowPlayingInterface clear];

  NSLog(@"State transition: Clearing Deck");
  self.playbackState = YouTubeVideoPlayerPlaybackStateDeckEmpty;
  self.videoIdentifier = nil;
}

- (void)play {
  NSAssert(self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempting to play empty deck");
  NSLog(@"YouTubeVideoPlayer: play [videoId = %@]", self.videoIdentifier);
  [self.player play];
}

- (void)pause {
  NSAssert(self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempting to pause an empty deck");
  NSLog(@"YouTubeVideoPlayer: pause");
  [self.player pause];
}

- (NSTimeInterval)currentPlaybackTime {
  return CMTimeGetSeconds(self.player.currentTime);
}

- (NSTimeInterval)duration {
  return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (void)observePlayer {
  [self addTimeObserverToPlayer];
  [self observePlaybackOfPlayer];
}

- (void)unobservePlayer {
  [self unobservePlaybackOfPlayer];
  [self removeTimeObserverFromPlayer];
}

- (void)addTimeObserverToPlayer {
  CMTime oneSecond = CMTimeMakeWithSeconds(1, 1);
  __weak typeof(self) weakSelf = self;
  self.playerTimeObserver =
  [self.player addPeriodicTimeObserverForInterval:oneSecond queue:NULL usingBlock:^(CMTime time) {
    [weakSelf progressTimerTick];
  }];
}

- (void)progressTimerTick {
  if (self.playbackState != YouTubeVideoPlayerPlaybackStatePlaying) {
    return;
  }

  float progress = 0;
  if (self.duration != 0) {
    progress = self.currentPlaybackTime / self.duration;
  }
  [self notifyDelegateOfProgress:progress];

  [self.nowPlayingInterface setCurrentPlaybackTime:self.currentPlaybackTime];
  [self.nowPlayingInterface setDuration:self.duration];
}

- (void)removeTimeObserverFromPlayer {
  [self.player removeTimeObserver:self.playerTimeObserver];
  self.playerTimeObserver = nil;
}

- (void)observePlaybackOfPlayer {
  [self.player addObserver:self
                forKeyPath:NSStringFromSelector(@selector(rate))
                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                   context:(__bridge void *)self];
}

- (void)unobservePlaybackOfPlayer {
  [self.player removeObserver:self
                   forKeyPath:NSStringFromSelector(@selector(rate))
                      context:(__bridge void *)self];
}

- (void)observePlayerItem {
  [self.playerItem addObserver:self
                    forKeyPath:NSStringFromSelector(@selector(status))
                       options:0
                       context:(__bridge void *)self];
}

- (void)unobservePlayerItem {
  [self.playerItem removeObserver:self
                       forKeyPath:NSStringFromSelector(@selector(status))
                          context:(__bridge void *)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context != ((__bridge void *)self)) {
    return;
  }
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(rate))]) {
    [self playerRateDidChange];
  }
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
    [self playerItemStatusDidChange];
  }
}

- (void)playerRateDidChange {
  float rate = self.player.rate;
  if (rate != 0) {
    NSLog(@"State transition: Playing [rate = %@]", @(rate));
    self.playbackState = YouTubeVideoPlayerPlaybackStatePlaying;
  } else {
    NSLog(@"State transition: Pausing");
    self.playbackState = YouTubeVideoPlayerPlaybackStatePaused;
  }
}

- (void)playerItemStatusDidChange {
  switch (self.playerItem.status) {
    case AVPlayerStatusUnknown:
      NSLog(@"Unexpected transition of player item to unknown");
      break;
    case AVPlayerStatusReadyToPlay:
      NSLog(@"Player item ready to play");
      // XXX invoke play from here?
      break;
    case AVPlayerItemStatusFailed:
      NSLog(@"Player item failed to load [error = %@]",
            [self.playerItem.error localizedDescription]);
      break;
  }
}

- (void)notifyDelegateOfProgress:(float)progress {
  if ([self.delegate respondsToSelector:@selector(youTubeVideoPlayer:didChangeVideoProgress:)]) {
    [self.delegate youTubeVideoPlayer:self didChangeVideoProgress:progress];
  }
}

- (void)willPlayVideoWithMetadata:(NSDictionary *)metadata {
  NSString *title = metadata[@"title"];
  NSURL *thumbnailURL = [NSURL URLWithString:metadata[@"thumbnailURL"]];

  if ([self.delegate respondsToSelector:@selector(youTubeVideoPlayer:didFetchVideoTitle:)]) {
    [self.delegate youTubeVideoPlayer:self didFetchVideoTitle:title];
  }

  [self.nowPlayingInterface setTitle:title];
  [self.nowPlayingInterface asynchronouslySetImageFromThumbnailURL:thumbnailURL];
}

- (void)remoteControlEventsDidTogglePlayPause:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did toggle play/pause");
  if (self.playbackState == YouTubeVideoPlayerPlaybackStatePaused) {
    [self play];
  } else if (self.playbackState == YouTubeVideoPlayerPlaybackStatePlaying) {
    [self pause];
  }
}

- (void)remoteControlEventsDidPressNext:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press next");
}

- (void)remoteControlEventsDidPressPrevious:(RemoteControlEvents *)events {
  NSLog(@"Remote control: did press previous");
}

- (void)cacheableAVPlayerItem:(CacheableAVPlayerItem *)playerItem
       didDownloadURLContents:(NSData *)data {
  NSLog(@"Download completed [Size = %@ bytes, videoId = %@]", @([data length]), self.videoIdentifier);
  if (self.unsavedMetadata == nil) {
    NSLog(@"Unexpected state: Have downloaded data without corresponding metadata; will ignore");
    return;
  }

  [self.mediaCache persistFileForKey:self.videoIdentifier withData:data];
  [self.keyValueStore setObject:self.unsavedMetadata forKey:self.videoIdentifier];
  self.unsavedMetadata = nil;
}

@end
