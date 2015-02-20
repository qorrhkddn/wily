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
  self.videoIdentifier = videoIdentifier;
  self.videoContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
  self.videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:self.videoIdentifier];
  [self.containerView addSubview:self.videoContainerView];
  self.videoContainerView.hidden = YES;

  NSLog(@"Changing video [Video Identifier = %@]", self.videoIdentifier);
  [self.videoPlayerViewController presentInView:self.videoContainerView];

  self.videoPlayerViewController.moviePlayer.backgroundPlaybackEnabled = YES;
}

- (void)play {
  NSAssert(self.playerProgressTimer == nil, @"`stop' must be called before calling `play' again");

  [self.videoPlayerViewController.moviePlayer play];
  [self notifyDelegateOfProgress:0];
  [self startPollingMediaPlayerForProgress];
}

- (void)pause {
  [self.videoPlayerViewController.moviePlayer pause];
}

- (void)stop {
  NSAssert(self.playerProgressTimer != nil, @"`play' must be called before calling `stop' again");

  [self.videoPlayerViewController.moviePlayer stop];
  [self notifyDelegateOfProgress:0];
  [self stopPollingMediaPlayerForProgress];
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
  MPMoviePlayerController *moviePlayer = self.videoPlayerViewController.moviePlayer;
  if (moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
    float progress = 0;
    if (moviePlayer.duration != 0) {
      progress = moviePlayer.currentPlaybackTime / moviePlayer.duration;
    }
    [self notifyDelegateOfProgress:progress];
  }
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

@end
