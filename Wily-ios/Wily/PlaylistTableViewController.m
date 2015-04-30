#import "PlaylistTableViewController.h"
#import "WilyPlaylist.h"
#import "WilyPlaylist+Pasteboard.h"

@implementation PlaylistTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(showAlert:)];
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.playlist.songs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistTableViewCellReuseIdentifier" forIndexPath:indexPath];
  NSDictionary *song = self.playlist.songs[indexPath.row];

  cell.textLabel.text = song[@"title"];

  return cell;
}

- (IBAction)swipeLeft:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [self.playlist deleteSongAtIndex:indexPath.row];
    [tableView reloadData];
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  [self.playlist moveSongAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.playlist setCurrentlyPlayingIndex:indexPath.row];
}

- (void)showAlert:(id)sender {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  [alert addAction:
   [UIAlertAction actionWithTitle:[self repeatAutoplayActionSheetTitle]
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                            [self.playlist toggleAutoplay];
                          }]];
  [alert addAction:
   [UIAlertAction actionWithTitle:@"Copy YouTube Link"
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                            [self.playlist copyYouTubeLinkOfCurrentlyPlayingSong];
                          }]];
  [alert addAction:
   [UIAlertAction actionWithTitle:@"Add Copied YouTube Link"
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                            [self.playlist playSongFromCopiedYouTubeLink];
                          }]];

  [alert addAction:
   [UIAlertAction actionWithTitle:@"Cancel"
                            style:UIAlertActionStyleCancel
                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)repeatAutoplayActionSheetTitle {
  return self.playlist.shouldAutoplay ? @"Repeat Song Mode" : @"Playlist Mode";
}

@end
