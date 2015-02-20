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
  [self.videoPlayerViewController.moviePlayer play];
}
- (void)pause {
  [self.videoPlayerViewController.moviePlayer pause];
}
- (void)stop {
  [self.videoPlayerViewController.moviePlayer stop];
}

@end
