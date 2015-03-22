#import "WilyPlaylist.h"
#import "WilyPlaylist+MusicSystem.h"

@interface WilyPlaylist ()
@property (nonatomic) NSUserDefaults *store;
@property (nonatomic) NSMutableArray *mutableSongs;
@property (nonatomic) NSUInteger currentlyPlayingIndex;
@property (nonatomic, weak) id<WilyPlaylistDelegate> delegate;
@end

@implementation WilyPlaylist

- (instancetype)initWithStore:(NSUserDefaults *)store {
  self = [super init];
  if (self) {
    _store = store;
    _mutableSongs = [self loadSongsFromStore:store];
    _currentlyPlayingIndex = self.invalidIndex;
  }
  return self;
}

- (NSArray *)songs {
  return self.mutableSongs;
}

- (NSMutableArray *)loadSongsFromStore:(NSUserDefaults *)store {
  NSMutableArray *result = [@[] mutableCopy];
  for (NSString *songId in [store arrayForKey:@"playlist"]) {
    [result addObject:[store dictionaryForKey:songId]];
  }
  return result;
}

- (NSArray *)playlist {
  NSMutableArray *playlist = [@[] mutableCopy];
  for (NSDictionary *song in self.songs) {
    [playlist addObject:song[@"id"]];
  }
  return playlist;
}

- (void)savePlaylistToStore {
  [self.store setObject:self.playlist forKey:@"playlist"];
}

- (NSUInteger)invalidIndex {
  return (NSUInteger)NSNotFound;
}

- (NSUInteger)previousSongIndex {
  if (self.currentlyPlayingIndex == self.invalidIndex) {
    return NSNotFound;
  }
  if (self.songs.count == 0) {
    return 0;
  }

  if (self.currentlyPlayingIndex == 0) {
    return self.songs.count - 1;
  } else {
    return self.currentlyPlayingIndex - 1;
  }
}

- (NSUInteger)nextSongIndex {
  if (self.currentlyPlayingIndex == self.invalidIndex) {
    return NSNotFound;
  }
  if (self.songs.count == 0) {
    return 0;
  }

  if (self.currentlyPlayingIndex == (self.songs.count - 1)) {
    return 0;
  } else {
    return self.currentlyPlayingIndex + 1;
  }
}

- (NSUInteger)existingIndexForSong:(NSDictionary *)song {
  NSUInteger result = [self.songs indexOfObjectPassingTest:^BOOL(NSDictionary *s, NSUInteger idx, BOOL *stop) {
    return ([s[@"id"] isEqualToString:song[@"id"]]);
  }];
  return (result == NSNotFound) ? self.invalidIndex : result;
}

- (void)moveSongAtIndex:(NSUInteger)index toIndex:(NSUInteger)toIndex {
  [self.mutableSongs exchangeObjectAtIndex:index withObjectAtIndex:toIndex];
  if (index == self.currentlyPlayingIndex) {
    self.currentlyPlayingIndex = toIndex;
  }
  [self savePlaylistToStore];
}

- (void)deleteSongAtIndex:(NSUInteger)index {
  [self.mutableSongs removeObjectAtIndex:index];
  if (index == self.currentlyPlayingIndex) {
    self.currentlyPlayingIndex = self.invalidIndex;
    if ([self.delegate respondsToSelector:@selector(playlistDidDeleteCurrentlyPlayingSong:)]) {
      [self.delegate playlistDidDeleteCurrentlyPlayingSong:self];
    }
  } else if (self.currentlyPlayingIndex > index) {
    self.currentlyPlayingIndex -= 1;
  }
  [self savePlaylistToStore];
}

- (void)setCurrentlyPlayingIndexNoNotify:(NSUInteger)index {
  _currentlyPlayingIndex = index;
  [self savePlaylistToStore];
}

- (void)setCurrentlyPlayingIndex:(NSUInteger)index {
  [self setCurrentlyPlayingIndexNoNotify:index];
  if ([self.delegate respondsToSelector:@selector(playlist:didChangeCurrentlyPlayingIndex:)]) {
    [self.delegate playlist:self didChangeCurrentlyPlayingIndex:index];
  }
}

- (void)appendSong:(NSDictionary *)song {
  [self.store setObject:song forKey:song[@"id"]];
  [self.mutableSongs addObject:song];
  [self savePlaylistToStore];
}

@end
