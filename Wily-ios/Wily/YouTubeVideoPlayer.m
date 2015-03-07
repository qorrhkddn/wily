#import "YouTubeVideoPlayer.h"
@import AVFoundation;
@import AVKit;
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "NowPlayingInterface.h"
#import "XCDYouTubeVideo+PreferredStreamURLExtraction.h"

@interface YouTubeVideoPlayer ()

@property (nonatomic, readonly) NowPlayingInterface *nowPlayingInterface;

@property (nonatomic, readwrite) YouTubeVideoPlayerPlaybackState playbackState;
@property (nonatomic) XCDYouTubeVideoOperation *videoOperation;

// The following properties are valid only during playback.
@property (nonatomic) NSString *videoIdentifier;
@property (nonatomic) id playerTimeObserver;
@property (nonatomic) AVPlayer *player;

@end

@implementation YouTubeVideoPlayer

- (instancetype)init {
  self = [super init];
  if (self) {
    _nowPlayingInterface = [[NowPlayingInterface alloc] init];

    [self startObservingNotifications];
    [self enableAVAudioSessionCategoryPlayback];
  }
  return self;
}

- (void)startObservingNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePlayPause:) name:NowPlayingInterfaceUIEventSubtypeRemoteControlTogglePlayPause object:nil];
}

- (void)enableAVAudioSessionCategoryPlayback {
  NSError *error = nil;
  BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                        error:&error];
  if (!success) {
    NSLog(@"Audio Session Category error: %@", error);
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier {
  [self.nowPlayingInterface clear];

  if (self.playbackState != YouTubeVideoPlayerPlaybackStateDeckEmpty) {
    [self clearDeck];
  }

  NSLog(@"State transition: Loading [Video Identifier = %@]", videoIdentifier);
  self.playbackState = YouTubeVideoPlayerPlaybackStateLoading;
  self.videoIdentifier = videoIdentifier;

  [self.videoOperation cancel];
  self.videoOperation = [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    self.videoOperation = nil;
    if (video) {
      [self playVideo:video];
    } else {
      [self cancelLoadWithError:error];
    }
  }];
}

- (void)cancelLoadWithError:(NSError *)error {
  NSLog(@"State transition: Clearing Deck [error = %@]", error);
  self.playbackState = YouTubeVideoPlayerPlaybackStateDeckEmpty;
  self.videoIdentifier = nil;
}

- (void)playVideo:(XCDYouTubeVideo *)video {
  NSURL *streamURL = [video lowestQualityStreamURL];
  if (streamURL == nil) {
    [self cancelLoadWithError:[self noStreamError]];
    return;
  }

  [self willPlayVideo:video];
  self.player = [AVPlayer playerWithURL:streamURL];

  [self notifyDelegateOfProgress:0];
  [self observePlayer];

  [self play];
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

  [self unobservePlayer];
  [self pause];
  [self notifyDelegateOfProgress:0];

  self.player = nil;

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
                   context:NULL];
}

- (void)unobservePlaybackOfPlayer {
  [self.player removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(rate))]) {
    [self playerRateDidChange];
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

- (void)notifyDelegateOfProgress:(float)progress {
  if ([self.delegate respondsToSelector:@selector(youTubeVideoPlayer:didChangeVideoProgress:)]) {
    [self.delegate youTubeVideoPlayer:self didChangeVideoProgress:progress];
  }
}

- (void)willPlayVideo:(XCDYouTubeVideo *)video {
  NSString *title = video.title;
  NSURL *thumbnailURL = video.mediumThumbnailURL;

  if ([self.delegate respondsToSelector:@selector(youTubeVideoPlayer:didFetchVideoTitle:)]) {
    [self.delegate youTubeVideoPlayer:self didFetchVideoTitle:title];
  }

  [self.nowPlayingInterface setTitle:title];
  [self.nowPlayingInterface asynchronouslySetImageFromThumbnailURL:thumbnailURL];
}

- (void)togglePlayPause:(NSNotification *)notification {
  if (self.playbackState == YouTubeVideoPlayerPlaybackStatePaused) {
    [self play];
  } else if (self.playbackState == YouTubeVideoPlayerPlaybackStatePlaying) {
    [self pause];
  }
}

@end
