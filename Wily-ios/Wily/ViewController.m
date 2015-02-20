#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
static NSString * const VideoIdentifier = @"vrfAQI-TIVM";

@interface ViewController ()

@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);
}

- (IBAction)play:(id)sender {
  [self playVideo];
}

- (void)playVideo {
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view
                                                           videoIdentifier:VideoIdentifier];
  [self.player play];
}

- (void)changeWallPaper {
  NSUInteger wallPaperNumber = arc4random() % 37;
  NSString *wallPaperImageName = [NSString stringWithFormat:@"%@", @(wallPaperNumber)];
  self.wallPaperImageView.image = [UIImage imageNamed:wallPaperImageName];
}

@end
