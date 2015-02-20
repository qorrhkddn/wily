#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"

static NSString * const VideoIdentifier = @"vrfAQI-TIVM";

@interface ViewController ()
@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view];

  [self changeWallPaper];
}

- (IBAction)play:(id)sender {
  [self playVideo];
}

- (void)playVideo {
  [self.player playVideoWithIdentifier:VideoIdentifier];
}

- (void)changeWallPaper {
  NSUInteger wallPaperNumber = arc4random() % 37;
  NSString *wallPaperImageName = [NSString stringWithFormat:@"%@", @(wallPaperNumber)];
  self.wallPaperImageView.image = [UIImage imageNamed:wallPaperImageName];
}

@end
