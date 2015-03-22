#import "WilyPlayer.h"
@import AVKit;
#import "NowPlayingInterface.h"

@interface WilyPlayer ()

@property (nonatomic, readonly) AVPlayerItem *playerItem;
@property (nonatomic, readonly) NowPlayingInterface *nowPlayingInterface;

@property (nonatomic) AVPlayer *player;
@property(nonatomic, readwrite) WilyPlayerPlaybackState playbackState;
@property (nonatomic) id playerTimeObserver;

@end

@implementation WilyPlayer

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem
                              song:(NSDictionary *)song {
  self = [super init];
  if (self) {
    _playerItem = playerItem;
    _song = song;

    _nowPlayingInterface = [[NowPlayingInterface alloc] init];
  }
  return self;
}

- (void)startPlayingItem {
  [self updateNowPlayingInterface];

  [self observePlayerItem];
  self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
  self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

  [self notifyDelegateOfProgress:0];
  [self observePlayer];
}

- (void)stopPlayingItem {
  [self unobservePlayerItem];
  [self unobservePlayer];
  [self.player pause];
  [self notifyDelegateOfProgress:0];

  self.player = nil;

  [self.nowPlayingInterface clear];

  NSLog(@"State transition: Clearing Deck");
}

- (void)togglePlayPause {
  if (self.playbackState == WilyPlayerPlaybackStatePaused) {
    [self.player play];
  } else if (self.playbackState == WilyPlayerPlaybackStatePlaying) {
    [self.player pause];
  }
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
  if (self.playbackState != WilyPlayerPlaybackStatePlaying) {
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

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerItemDidReachEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.playerItem];
}

- (void)unobservePlayerItem {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.playbackState = WilyPlayerPlaybackStatePlaying;
  } else {
    NSLog(@"State transition: Pausing");
    self.playbackState = WilyPlayerPlaybackStatePaused;
  }
  [self notifyDelegateOfPlaybackState];
}

- (void)playerItemStatusDidChange {
  switch (self.playerItem.status) {
    case AVPlayerStatusUnknown:
      NSLog(@"Unexpected transition of player item to unknown");
      break;
    case AVPlayerStatusReadyToPlay:
      NSLog(@"Player item ready to play");
      [self.player play];
      break;
    case AVPlayerItemStatusFailed:
      NSLog(@"Player item failed to load [error = %@]",
            [self.playerItem.error localizedDescription]);
      break;
  }
}

- (void)notifyDelegateOfPlaybackState {
  if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackState:)]) {
    [self.delegate player:self didChangePlaybackState:self.playbackState];
  }
}

- (void)notifyDelegateOfProgress:(float)progress {
  if ([self.delegate respondsToSelector:@selector(player:didChangeProgress:)]) {
    [self.delegate player:self didChangeProgress:progress];
  }
}

- (void)updateNowPlayingInterface {
  NSURL *thumbnailURL = [NSURL URLWithString:self.song[@"thumbnailURL"]];
  [self.nowPlayingInterface setTitle:self.song[@"title"]];
  [self.nowPlayingInterface asynchronouslySetImageFromThumbnailURL:thumbnailURL];
}

- (void)playerItemDidReachEnd:(NSNotification *)note {
  if (self.shouldRepeat) {
    [self.playerItem seekToTime:kCMTimeZero];
  }
}

@end
