#import "InvisibleYouTubeVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "MPMoviePlayerController+BackgroundPlayback.h"
#import "PlayerEventLogger.h"
#import "NowPlayingInterface.h"

@interface InvisibleYouTubeVideoPlayer ()

@property (nonatomic, weak, readonly) UIView *containerView;
@property (nonatomic, readonly) PlayerEventLogger *playerEventLogger;
@property (nonatomic, readonly) NowPlayingInterface *nowPlayingInterface;

@property(nonatomic, readwrite) InvisibleYouTubeVideoPlayerPlaybackState playbackState;

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
    _nowPlayingInterface = [[NowPlayingInterface alloc] init];

    [self startObservingNotifications];
    [self enableAVAudioSessionCategoryPlayback];
  }
  return self;
}

- (void)startObservingNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerViewControllerDidReceiveVideo:) name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
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

  if (self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty) {
    [self clearDeck];
  }

  NSLog(@"State transition: Loading [Video Identifier = %@]", videoIdentifier);
  self.playbackState = InvisibleYouTubeVideoPlayerPlaybackStateLoading;

  self.videoIdentifier = videoIdentifier;
  self.videoContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
  self.videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:self.videoIdentifier];
  [self.containerView addSubview:self.videoContainerView];
  self.videoContainerView.hidden = YES;

  [self.videoPlayerViewController presentInView:self.videoContainerView];

  self.moviePlayer.backgroundPlaybackEnabled = YES;
  [self.moviePlayer play];
  [self notifyDelegateOfProgress:0];
  [self startPollingMediaPlayerForProgress];
}

- (void)invalidate {
  if (self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty) {
    [self clearDeck];
  }
}

- (void)clearDeck {
  NSAssert(self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempt to unload video when the deck is empty");

  NSLog(@"State transition: Clearing Deck");
  self.playbackState = InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty;

  [self stopPollingMediaPlayerForProgress];
  [self.moviePlayer stop];
  [self notifyDelegateOfProgress:0];

  self.videoPlayerViewController = nil;
  self.videoContainerView = nil;
  self.videoIdentifier = nil;

  [self.nowPlayingInterface clear];
}

- (MPMoviePlayerController *)moviePlayer {
  return self.videoPlayerViewController.moviePlayer;
}

- (void)play {
  NSAssert(self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempting to play empty deck");
  [self.moviePlayer play];
}

- (void)pause {
  NSAssert(self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty,
           @"Attempting to pause an empty deck");
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
  [NSTimer scheduledTimerWithTimeInterval:1
                                   target:self
                                 selector:@selector(progressTimerTick:)
                                 userInfo:nil
                                  repeats:YES];
}

- (void)progressTimerTick:(NSObject *)sender {
  if (self.playbackState != InvisibleYouTubeVideoPlayerPlaybackStatePlaying) {
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
  XCDYouTubeVideo *video = notification.userInfo[XCDYouTubeVideoUserInfoKey];
  NSString *title = video.title;
  NSURL *thumbnailURL = video.mediumThumbnailURL;

  if ([self.delegate respondsToSelector:@selector(invisibleYouTubeVideoPlayer:didFetchVideoTitle:)]) {
    [self.delegate invisibleYouTubeVideoPlayer:self didFetchVideoTitle:title];
  }

  [self.nowPlayingInterface setTitle:title];
  [self.nowPlayingInterface asynchronouslySetImageFromThumbnailURL:thumbnailURL];
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
  MPMoviePlayerController *moviePlayerController = notification.object;
  switch (moviePlayerController.playbackState)   {
    case MPMoviePlaybackStateStopped:
    case MPMoviePlaybackStatePaused:
      NSLog(@"State transition: Pausing");
      self.playbackState = InvisibleYouTubeVideoPlayerPlaybackStatePaused;
      break;
    case MPMoviePlaybackStatePlaying:
      NSLog(@"State transition: Playing");
      self.playbackState = InvisibleYouTubeVideoPlayerPlaybackStatePlaying;
      break;
    default:
      NSLog(@"Ignoring unexpected movie player controller transition");
      break;
  }
}

@end
