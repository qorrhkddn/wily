#import "ViewController.h"
#import "InvisibleYouTubeVideoPlayer.h"
#import "YoutubeSearcher.h"

static NSString * const VideoIdentifier = @"vrfAQI-TIVM";
static NSString *const SearchResultCellIdentifier = @"SearchResultCell";

@interface ViewController () <InvisibleYouTubeVideoPlayerDelegate, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate>

@property (nonatomic) InvisibleYouTubeVideoPlayer *player;
@property (nonatomic) YoutubeSearcher *searcher;

@property (nonatomic, getter=isPlaying) BOOL playing;

@property (weak, nonatomic) IBOutlet UIImageView *wallPaperImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchResultsDisplayController;

@property (nonatomic, strong) NSArray *searchResults;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.player = [[InvisibleYouTubeVideoPlayer alloc] initWithContainerView:self.view];
  self.player.delegate = self;
  self.searcher = [[YoutubeSearcher alloc] init];

  [self changeWallPaper];
  self.playProgressView.transform = CGAffineTransformMakeScale(1, 3);

  UITableView *tableView = self.searchResultsDisplayController.searchResultsTableView;
  tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [tableView registerNib:[UINib nibWithNibName:@"SearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:SearchResultCellIdentifier];
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
  [self.searcher autocompleteSuggestionsForSearchString:@"hello"
                                        completionBlock:^(NSArray *suggestions) {
                                          NSLog(@"%@", suggestions);
                                        }];
  /*
  [self.searcher firstVideoIdentifierForSearchString:@"hello"
                                     completionBlock:^(NSString *videoIdentifier) {
                                       NSLog(@"%@", videoIdentifier);
                                     }];
   */
  [self.player loadVideoWithIdentifier:VideoIdentifier];
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

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
             didChangeVideoProgress:(float)progress {
  NSLog(@"progress: %@", @(progress));
}

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
                 didFetchVideoTitle:(NSString *)title {
  NSLog(@"title: %@", title);
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
    [self.player loadVideoWithIdentifier:videoIdentifier];
    [self.player play];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchResultsDisplayController setActive:NO animated:YES];
  }];
}

@end
