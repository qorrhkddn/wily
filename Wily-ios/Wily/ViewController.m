#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
#import "YoutubeSearcher.h"

static NSString *const SearchResultCellIdentifier = @"SearchResultCell";

@interface ViewController () <InvisibleYouTubeVideoPlayerDelegate, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate>

@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@property (nonatomic) YoutubeSearcher *searcher;

@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchResultsDisplayController;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlaybackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (nonatomic, strong) NSArray *searchResults;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view];
  self.player.delegate = self;
  self.searcher = [[YoutubeSearcher alloc] init];

  [self disableControls];

  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);

  UITableView *tableView = self.searchResultsDisplayController.searchResultsTableView;
  tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [tableView registerNib:[UINib nibWithNibName:@"SearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:SearchResultCellIdentifier];
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
    [self.searchResultsDisplayController setActive:NO animated:YES];
    if (videoIdentifier != nil) {
      [self playVideoWithIdentifier:videoIdentifier];
    }
  }];
}

- (void)disableControls {
  self.playButton.hidden = YES;
  self.currentPlaybackTimeLabel.text = @"-:-";
  self.durationLabel.text = @"-:-";
}

- (void)enableControls {
  self.playButton.hidden = NO;
}

- (void)playVideoWithIdentifier:(NSString *)videoIdentifier {
  if (self.player.isPlaying) {
    [self.player unloadVideo];
  }
  [self.player loadVideoWithIdentifier:videoIdentifier];
  [self enableControls];
  [self updatePlayButtonImage];
}

- (void)updatePlayButtonImage {
  UIImage *image = self.player.isPlaying ? [UIImage imageNamed:@"play"] : [UIImage imageNamed:@"pause"];
  [self.playButton setImage:image forState:UIControlStateNormal];
}

- (IBAction)play:(id)sender {
  if (self.player.isPlaying) {
    [self pauseVideo];
  } else {
    [self playVideo];
  }
}

- (void)playVideo {
  [self.player play];
  [self updatePlayButtonImage];
}

- (void)pauseVideo {
  [self.player pause];
  [self updatePlayButtonImage];
}

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
                 didFetchVideoTitle:(NSString *)title {
  NSLog(@"title: %@", title);
  self.titleLabel.text = title;
}

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
             didChangeVideoProgress:(float)progress {
  NSLog(@"progress: %@", @(progress));
  [self.playProgressView setProgress:progress animated:YES];
  self.currentPlaybackTimeLabel.text = [NSString stringWithFormat:@"%@", @(player.currentPlaybackTime / 60)];
  self.durationLabel.text = [NSString stringWithFormat:@"%@", @(player.duration / 60)];
}

@end
