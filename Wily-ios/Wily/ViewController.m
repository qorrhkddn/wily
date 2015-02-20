#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);
}

- (void)changeWallPaper {
  NSUInteger wallPaperNumber = arc4random() % 37;
  NSString *wallPaperImageName = [NSString stringWithFormat:@"%@", @(wallPaperNumber)];
  self.wallPaperImageView.image = [UIImage imageNamed:wallPaperImageName];
}

@end
