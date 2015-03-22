#import "WilyPlaylist.h"
#import "WilyPlaylist+MusicSystem.h"

@interface WilyPlaylist ()
@property (nonatomic) NSArray *songs;
@property (nonatomic) NSString *currentlyPlayingSongId;
@property (nonatomic) id<WilyPlaylistDelegate> delegate;
@end

@implementation WilyPlaylist

- (instancetype)initWithSongs:(NSArray *)songs {
  self = [super init];
  if (self) {
    _songs = songs;
  }
  return self;
}

- (void)moveSongWithId:(NSString *)songId afterSongWithId:(NSString *)previousSongId {

}

- (void)deleteSongWithId:(NSString *)songId {

}

- (void)insertAsCurrentlyPlayingSong:(NSDictionary *)song {
  self.songs = [self.songs arrayByAddingObject:song];
  [self notifyDelegateOfSongsUpdate];
}

- (void)notifyDelegateOfSongsUpdate {
  if ([self.delegate respondsToSelector:@selector(playlist:didUpdateSongs:)]) {
    [self.delegate playlist:self didUpdateSongs:self.songs];
  }
}

@end
