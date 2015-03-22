#import "PlaylistTableViewController.h"
#import "WilyPlaylist.h"

@implementation PlaylistTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
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

@end
