#import "InvisibleYouTubeVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "MPMoviePlayerController+BackgroundPlayback.h"
#import "PlayerEventLogger.h"
#import "NowPlayingInfoCenterProvider.h"

@interface InvisibleYouTubeVideoPlayer ()

@property (nonatomic, weak, readonly) UIView *containerView;
@property (nonatomic, readonly) PlayerEventLogger *playerEventLogger;
@property (nonatomic, readonly) NowPlayingInfoCenterProvider *nowPlayingInfoCenterProvider;

// The following properties are valid only during playback.
@property (nonatomic) UIView *videoContainerView;
@property (nonatomic) XCDYouTubeVideoPlayerViewController *videoPlayerViewController;
@property (nonatomic) NSString *videoIdentifier;
@property (nonatomic) NSTimer *playerProgressTimer;

@end

@implementation InvisibleYouTubeVideoPlayer

- (instancetype)initWithContainerView:(UIView *)containerView {
  self = [super init];
  if (self) {
    _containerView = containerView;
    _playerEventLogger = [[PlayerEventLogger alloc] init];
    _nowPlayingInfoCenterProvider = [[NowPlayingInfoCenterProvider alloc] init];

    [self startObservingVideoNotifications];
    [self enableAVAudioSessionCategoryPlayback];
  }
  return self;
}

- (void)startObservingVideoNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerViewControllerDidReceiveVideo:) name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:nil];
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
  NSAssert(self.playerProgressTimer == nil, @"`unloadVideo' must be called before calling `loadVideo' again");

  self.videoIdentifier = videoIdentifier;
  self.videoContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
  self.videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:self.videoIdentifier];
  [self.containerView addSubview:self.videoContainerView];
  self.videoContainerView.hidden = YES;

  NSLog(@"Changing video [Video Identifier = %@]", self.videoIdentifier);
  [self.videoPlayerViewController presentInView:self.videoContainerView];

  self.moviePlayer.backgroundPlaybackEnabled = YES;
  [self.moviePlayer play];
  [self notifyDelegateOfProgress:0];
  [self startPollingMediaPlayerForProgress];
}

- (void)unloadVideo {
  NSAssert(self.playerProgressTimer != nil, @"`loadVideo' must be called before calling `unloadVideo' again");

  [self.moviePlayer stop];
  [self notifyDelegateOfProgress:0];
  [self stopPollingMediaPlayerForProgress];

  self.videoPlayerViewController = nil;
  self.videoContainerView = nil;
  self.videoIdentifier = nil;
}

- (MPMoviePlayerController *)moviePlayer {
  return self.videoPlayerViewController.moviePlayer;
}

- (BOOL)isPlaying {
  if (self.videoIdentifier == nil) {
    return NO;
  }
  return (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying);
}

- (void)play {
  NSAssert(!self.isPlaying, @"Attempting to play when already playing");
  [self.moviePlayer play];
}

- (void)pause {
  NSAssert(self.isPlaying, @"Attempting to pause when not playing");
  [self.moviePlayer pause];
}

- (NSTimeInterval)currentPlaybackTime {
  return [self.moviePlayer currentPlaybackTime];
}

- (NSTimeInterval)duration {
  return [self.moviePlayer duration];
}

- (void)startPollingMediaPlayerForProgress {
  self.playerProgressTimer =
  [NSTimer scheduledTimerWithTimeInterval:5
                                   target:self
                                 selector:@selector(progressTimerTick:)
                                 userInfo:nil
                                  repeats:YES];
}

- (void)progressTimerTick:(NSObject *)sender {
  if (!self.isPlaying) {
    return;
  }

  float progress = 0;
  if (self.duration != 0) {
    progress = self.currentPlaybackTime / self.duration;
  }
  [self notifyDelegateOfProgress:progress];
}

- (void)stopPollingMediaPlayerForProgress {
  [self.playerProgressTimer invalidate];
  self.playerProgressTimer = nil;
}

- (void)notifyDelegateOfProgress:(float)progress {
  if ([self.delegate respondsToSelector:@selector(invisibleYouTubeVideoPlayer:didChangeVideoProgress:)]) {
    [self.delegate invisibleYouTubeVideoPlayer:self didChangeVideoProgress:progress];
  }
}

- (void)videoPlayerViewControllerDidReceiveVideo:(NSNotification *)notification {
  if ([self.delegate respondsToSelector:@selector(invisibleYouTubeVideoPlayer:didFetchVideoTitle:)]) {
    NSString *title = [notification.userInfo[XCDYouTubeVideoUserInfoKey] title];
    [self.delegate invisibleYouTubeVideoPlayer:self didFetchVideoTitle:title];
  }
}

@end
