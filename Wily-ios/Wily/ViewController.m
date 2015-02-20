#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
static NSString * const VideoIdentifier = @"vrfAQI-TIVM";

@interface ViewController ()
@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self performSelector:@selector(playVideo) withObject:nil afterDelay:1];
}

- (void)playVideo {
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view
                                                           videoIdentifier:VideoIdentifier];
  [self.player play];
}

@end
