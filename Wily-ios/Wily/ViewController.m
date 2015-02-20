#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
static NSString * const VideoIdentifier = @"vrfAQI-TIVM";

@interface ViewController ()

@property (nonatomic) InvisibleYouTubeVideoPlayer *player;

@property (nonatomic, getter=isPlaying) BOOL playing;

@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);
}

- (IBAction)play:(id)sender {
  UIImage *playButtonImage = self.isPlaying ? [UIImage imageNamed:@"play"] : [UIImage imageNamed:@"pause"];
  [self.playButton setImage:playButtonImage forState:UIControlStateNormal];

  if (self.isPlaying) {
    [self pauseVideo];
  } else {
    [self playVideo];
  }

  self.playing = !self.isPlaying;
}

- (void)playVideo {
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view
                                                           videoIdentifier:VideoIdentifier];
  [self.player play];
}

- (void)pauseVideo {
  [self.player pause];
}

- (void)changeWallPaper {
  NSUInteger wallPaperNumber = arc4random() % 37;
  NSString *wallPaperImageName = [NSString stringWithFormat:@"%@", @(wallPaperNumber)];
  self.wallPaperImageView.image = [UIImage imageNamed:wallPaperImageName];
}

@end
