#import "PlayerViewController.h"
#import "WilyMusicSystem.h"
#import "WilyPlayer.h"
#import "YouTubeSearcher.h"
#import "WilySFXPlayback.h"
#import "WilyDurationFormatting.h"
#import "PlaylistTableViewController.h"
#import "WallpaperManager.h"

static NSString *const SearchResultCellIdentifier = @"SearchResultCell";

@interface PlayerViewController () <WilyMusicSystemDelegate, WilyPlayerDelegate, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic) WilyMusicSystem *musicSystem;
@property (nonatomic) YouTubeSearcher *searcher;

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
@property (weak, nonatomic) IBOutlet UIView *coachmark;

@property (nonatomic, strong) NSArray *searchResults;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.musicSystem = [[WilyMusicSystem alloc] init];
  self.musicSystem.delegate = self;
  self.searcher = [[YouTubeSearcher alloc] init];

  [self setRandomWallpaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);

  UITableView *tableView = self.searchResultsDisplayController.searchResultsTableView;
  tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [tableView registerNib:[UINib nibWithNibName:@"SearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:SearchResultCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)hideCoachmark {
  self.coachmark.hidden = YES;
}

- (IBAction)coachmarkTapped:(id)sender {
  [self hideCoachmark];
}

- (NSString *)setRandomWallpaper {
  NSString *wallpaperId = [self.musicSystem.wallpaperManager randomWallpaperId];
  [self setWallpaperWithId:wallpaperId];
  return wallpaperId;
}

- (void)setWallpaperWithId:(NSString *)wallpaperId {
  self.wallpaperImageView.image = [self.musicSystem.wallpaperManager wallpaperWithId:wallpaperId];
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
  NSString *searchSuggestion = self.searchResults[indexPath.row];
  [self.searcher firstVideoIdentifierForSearchString:searchSuggestion completionBlock:^(NSString *videoId) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideSearchDisplay];
    if (videoId != nil) {
      [self playVideoWithId:videoId forSearchSuggestion:searchSuggestion];
    }
  }];
}

- (IBAction)swipeDownDetected:(UISwipeGestureRecognizer *)sender {
  [self hideCoachmark];
  [self showSearchDisplay];
}

- (IBAction)wilyIconTapped:(id)sender {
  WilySFXPlayMeowSound();
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

- (void)playVideoWithId:(NSString *)videoId forSearchSuggestion:(NSString *)searchSuggestion {
  NSDictionary *song = @{@"id": videoId, @"title": searchSuggestion};
  [self.musicSystem playSong:song];
}

- (void)musicSystem:(WilyMusicSystem *)musicSystem playerDidChange:(WilyPlayer *)player {
  if (player) {
    player.delegate = self;
    self.titleLabel.text = player.song[@"title"] ?: @"--";
    [self setWallpaperWithId:player.song[@"wallpaperId"]];
  } else {
    self.titleLabel.text = @"";
    [self hideControls];
  }
}

- (void)player:(WilyPlayer *)player didChangePlaybackState:(WilyPlayerPlaybackState)playbackState {
  switch (playbackState) {
    case WilyPlayerPlaybackStateLoading:
      [self showControlsForLoadingState];
      break;
    case WilyPlayerPlaybackStatePaused:
      [self showControlsForPlaybackStateWithIsPlaying:NO];
      break;
    case WilyPlayerPlaybackStatePlaying:
      [self showControlsForPlaybackStateWithIsPlaying:YES];
      break;
  }
}

- (void)hideControls {
  self.playControlsContainerView.hidden = YES;
}

- (void)showControlsForLoadingState {
  self.playControlsContainerView.hidden = NO;
  self.playButton.hidden = YES;
  [self.loadingSpinner startAnimating];
}

- (void)showControlsForPlaybackStateWithIsPlaying:(BOOL)isPlaying {
  self.playControlsContainerView.hidden = NO;
  [self.loadingSpinner stopAnimating];
  self.playButton.hidden = NO;
  NSString *imageName = isPlaying ? @"pause" : @"play";
  [self.playButton setImage:[UIImage imageNamed:imageName]
                   forState:UIControlStateNormal];
}

- (void)player:(WilyPlayer *)player didChangeProgress:(float)progress {
  [self.playProgressView setProgress:progress animated:YES];
  self.currentPlaybackTimeLabel.text = WilyDurationStringForTimeInterval(player.currentPlaybackTime);
  self.durationLabel.text = WilyDurationStringForTimeInterval(player.duration);
}

- (IBAction)play:(id)sender {
  [self.musicSystem.player togglePlayPause];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  UIViewController *destinationViewController = [segue destinationViewController];
  if ([destinationViewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController *)destinationViewController;
    destinationViewController = [navigationController topViewController];
    if ([destinationViewController isKindOfClass:[PlaylistTableViewController class]]) {
      PlaylistTableViewController *playlistTableViewController = (PlaylistTableViewController *)destinationViewController;
      playlistTableViewController.playlist = self.musicSystem.playlist;
      [self hideCoachmark];
    }
  }
}

@end
