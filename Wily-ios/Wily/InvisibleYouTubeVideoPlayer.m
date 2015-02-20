#import "InvisibleYouTubeVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "MPMoviePlayerController+BackgroundPlayback.h"

@interface InvisibleYouTubeVideoPlayer ()
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic) UIView *videoContainerView;
@property (nonatomic) XCDYouTubeVideoPlayerViewController *videoPlayerViewController;
@property (getter = isPlaying) BOOL playing;
@end

@implementation InvisibleYouTubeVideoPlayer

- (instancetype)initWithContainerView:(UIView *)containerView
                      videoIdentifier:(NSString *)videoIdentifier {
  self = [super init];
  if (self) {
    _containerView = containerView;
    _videoContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    _videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoIdentifier];
  }
  return self;
}

- (void)play {
  if (!self.isPlaying) {
    _playing = YES;
    [self reallyPlay];
  }
}

- (void)reallyPlay {
  [self.containerView addSubview:self.videoContainerView];
  self.videoContainerView.hidden = YES;

  [self.videoPlayerViewController presentInView:self.videoContainerView];

  MPMoviePlayerController *moviePlayer = self.videoPlayerViewController.moviePlayer;
  [moviePlayer prepareToPlay];
  [[self class] enableAVAudioSessionCategoryPlayback];
  moviePlayer.backgroundPlaybackEnabled = YES;
  moviePlayer.shouldAutoplay = YES;
  [moviePlayer play];
}

+ (void)enableAVAudioSessionCategoryPlayback {
  NSError *error = nil;
  BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                        error:&error];
  if (!success) {
    NSLog(@"Audio Session Category error: %@", error);
  }
}

@end
