#import "PlayerViewController.h"
#import "WilyMusicSystem.h"
#import "WilyPlayer.h"
#import "YouTubeSearcher.h"
#import "SFXPlayer.h"
#import "DurationFormatter.h"
#import "WallpaperManager.h"

static NSString *const SearchResultCellIdentifier = @"SearchResultCell";

@interface PlayerViewController () <WilyMusicSystemDelegate, WilyPlayerDelegate, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic) WilyMusicSystem *musicSystem;
@property (nonatomic) YouTubeSearcher *searcher;
@property (nonatomic) WallpaperManager *wallpaperManager;

@property (weak, nonatomic) IBOutlet UIImageView *wallpaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchResultsDisplayController;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlaybackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *playControlsContainerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;

@property (nonatomic) NSString *wallpaperId;
@property (nonatomic, strong) NSArray *searchResults;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.musicSystem = [[WilyMusicSystem alloc] init];
  self.musicSystem.delegate = self;
  self.searcher = [[YouTubeSearcher alloc] init];
  self.wallpaperManager = [[WallpaperManager alloc] init];

  [self changeWallpaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);
  self.playControlsContainerView.hidden = YES;

  UITableView *tableView = self.searchResultsDisplayController.searchResultsTableView;
  tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [tableView registerNib:[UINib nibWithNibName:@"SearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:SearchResultCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self showSearchDisplay];
}

- (void)changeWallpaper {
  self.wallpaperId = [self.wallpaperManager randomWallpaperId];
  self.wallpaperImageView.image = [self.wallpaperManager wallpaperWithId:self.wallpaperId];
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

- (IBAction)swipeDownDetected:(UISwipeGestureRecognizer *)sender {
  [self showSearchDisplay];
}

- (IBAction)wilyIconTapped:(id)sender {
  [SFXPlayer playMeowSound];
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

- (void)playVideoWithIdentifier:(NSString *)videoIdentifier {
  [self changeWallpaper];
  [self.musicSystem enqueueItemForYouTubeVideoWithId:videoIdentifier];
}

- (void)musicSystem:(WilyMusicSystem *)musicSystem playerDidChange:(WilyPlayer *)player {
  if (player) {
    player.delegate = self;
    self.titleLabel.text = player.song[@"title"];
  } else {
    self.playControlsContainerView.hidden = YES;
  }
}

- (void)player:(WilyPlayer *)player didChangePlaybackState:(WilyPlayerPlaybackState)playbackState {
  switch (playbackState) {
    case WilyPlayerPlaybackStateLoading:
      self.playControlsContainerView.hidden = NO;
      self.playButton.hidden = YES;
      [self.loadingSpinner startAnimating];
      break;
    case WilyPlayerPlaybackStatePaused:
      self.playControlsContainerView.hidden = NO;
      [self.loadingSpinner stopAnimating];
      self.playButton.hidden = NO;
      [self.playButton setImage:[UIImage imageNamed:@"play"]
                       forState:UIControlStateNormal];
      break;
    case WilyPlayerPlaybackStatePlaying:
      self.playControlsContainerView.hidden = NO;
      [self.loadingSpinner stopAnimating];
      self.playButton.hidden = NO;
      [self.playButton setImage:[UIImage imageNamed:@"pause"]
                       forState:UIControlStateNormal];
      break;
  }
}

- (void)player:(WilyPlayer *)player didChangeProgress:(float)progress {
  [self.playProgressView setProgress:progress animated:YES];
  self.currentPlaybackTimeLabel.text = [DurationFormatter stringForTimeInterval:player.currentPlaybackTime];
  self.durationLabel.text = [DurationFormatter stringForTimeInterval:player.duration];
}

- (IBAction)play:(id)sender {
  [self.musicSystem.player togglePlayPause];
}

@end
