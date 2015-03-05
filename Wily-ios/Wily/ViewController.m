#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
#import "YoutubeSearcher.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>

static NSString *const SearchResultCellIdentifier = @"SearchResultCell";

@interface ViewController () <InvisibleYouTubeVideoPlayerDelegate, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@property (nonatomic) YoutubeSearcher *searcher;

@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIImageView *catImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchResultsDisplayController;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlaybackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *playControlsContainerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;

@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic) SystemSoundID meowSound;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view];
  self.player.delegate = self;
  self.searcher = [[YoutubeSearcher alloc] init];

  [self loadMeowSound];
  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);

  [self.player addObserver:self forKeyPath:@"playbackState" options:NSKeyValueObservingOptionNew context:nil];

  UITableView *tableView = self.searchResultsDisplayController.searchResultsTableView;
  tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [tableView registerNib:[UINib nibWithNibName:@"SearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:SearchResultCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self showSearchDisplay];
}

- (void)updatePlayButtonImage {
  switch (self.player.playbackState) {
    case InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty:
      self.playControlsContainerView.hidden = YES;
      break;
    case InvisibleYouTubeVideoPlayerPlaybackStateLoading:
      self.playControlsContainerView.hidden = NO;
      self.playButton.hidden = YES;
      [self.loadingSpinner startAnimating];
      break;
    case InvisibleYouTubeVideoPlayerPlaybackStatePaused:
      self.playControlsContainerView.hidden = NO;
      [self.loadingSpinner stopAnimating];
      self.playButton.hidden = NO;
      [self.playButton setImage:[UIImage imageNamed:@"play"]
                       forState:UIControlStateNormal];
      break;
    case InvisibleYouTubeVideoPlayerPlaybackStatePlaying:
      self.playControlsContainerView.hidden = NO;
      [self.loadingSpinner stopAnimating];
      self.playButton.hidden = NO;
      [self.playButton setImage:[UIImage imageNamed:@"pause"]
                       forState:UIControlStateNormal];
      break;
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  [self updatePlayButtonImage];
}

- (void)dealloc {
  OSStatus status = AudioServicesDisposeSystemSoundID(self.meowSound);
  NSLog(@"Dispose meow sound, status: %@", @(status));
  [self.player removeObserver:self forKeyPath:@"playbackState"];
}

- (void)changeWallPaper {
  NSUInteger wallPaperNumber = arc4random() % 37;
  NSString *wallPaperImageName = [NSString stringWithFormat:@"%@", @(wallPaperNumber)];
  self.wallPaperImageView.image = [UIImage imageNamed:wallPaperImageName];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SearchResultCellIdentifier forIndexPath:indexPath];
  cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
  cell.textLabel.text = self.searchResults[indexPath.row];
  return cell;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  [self.searcher autocompleteSuggestionsForSearchString:searchBar.text completionBlock:^(NSArray *suggestions) {
    self.searchResults = suggestions;
    [self.searchResultsDisplayController.searchResultsTableView reloadData];
  }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.searcher firstVideoIdentifierForSearchString:self.searchResults[indexPath.row] completionBlock:^(NSString *videoIdentifier) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideSearchDisplay];
    if (videoIdentifier != nil) {
      [self playVideoWithIdentifier:videoIdentifier];
    }
  }];
}

- (void)playVideoWithIdentifier:(NSString *)videoIdentifier {
  [self changeWallPaper];
  [self.player loadVideoWithIdentifier:videoIdentifier];
}

- (IBAction)play:(id)sender {
  if (self.player.playbackState == InvisibleYouTubeVideoPlayerPlaybackStatePlaying) {
    [self.player pause];
  } else if (self.player.playbackState == InvisibleYouTubeVideoPlayerPlaybackStatePaused) {
    [self.player play];
  }
}

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
                 didFetchVideoTitle:(NSString *)title {
  NSLog(@"title: %@", title);
  self.titleLabel.text = title;
}

- (NSString *)formattedStringForTimeInterval:(NSTimeInterval)interval {
  if (isnan(interval)) {
    return @"-:-";
  }
  NSUInteger minutes = floor(interval/60);
  NSUInteger seconds = round(interval - minutes * 60);
  return [NSString stringWithFormat:@"%@:%@", @(minutes), @(seconds)];
}

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
             didChangeVideoProgress:(float)progress {
  NSLog(@"progress: %@", @(progress));
  [self.playProgressView setProgress:progress animated:YES];
  self.currentPlaybackTimeLabel.text = [self formattedStringForTimeInterval:player.currentPlaybackTime];
  self.durationLabel.text = [self formattedStringForTimeInterval:player.duration];
}

- (IBAction)swipeDownDetected:(UISwipeGestureRecognizer *)sender {
  [self showSearchDisplay];
}

- (BOOL)isInCatImageViewPoint:(CGPoint)point {
  CGRect containingRect = CGRectInset(self.catImageView.bounds, -5, -5);
  return CGRectContainsPoint(containingRect, point);
}

- (void)loadMeowSound {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  SystemSoundID soundID;
  OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileURL), &soundID);
  NSLog(@"Load meow sound, status: %@", @(status));
  self.meowSound = soundID;
}

- (IBAction)tapDetected:(UITapGestureRecognizer *)sender {
  CGPoint tappedPoint = [sender locationInView:sender.view];
  CGPoint tappedPointInImageView = [self.catImageView convertPoint:tappedPoint fromView:sender.view];
  if ([self isInCatImageViewPoint:tappedPointInImageView]) {
    AudioServicesPlaySystemSound(self.meowSound);
  }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  [self hideSearchDisplay];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
  [self hideSearchDisplay];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
  [self hideSearchDisplay];
}

- (void)showSearchDisplay {
  self.searchBarHeightConstraint.constant = 44;
  [self.searchResultsDisplayController setActive:YES animated:YES];
  [self.searchResultsDisplayController.searchBar becomeFirstResponder];
}

- (void)hideSearchDisplay {
  self.searchBarHeightConstraint.constant = 0;
  [self.searchResultsDisplayController setActive:NO animated:YES];
}

@end
