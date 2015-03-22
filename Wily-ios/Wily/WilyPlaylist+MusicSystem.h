#import "WilyPlaylist.h"

@protocol WilyPlaylistDelegate;

@interface WilyPlaylist (MusicSystem)

- (instancetype)initWithStore:(NSUserDefaults *)store;

@property (nonatomic) id<WilyPlaylistDelegate> delegate;

- (void)setCurrentlyPlayingIndexNoNotify:(NSUInteger)index;

@end

@protocol WilyPlaylistDelegate <NSObject>

@optional

- (void)playlist:(WilyPlaylist *)playlist didChangeCurrentlyPlayingIndex:(NSUInteger)index;

- (void)playlistDidDeleteCurrentlyPlayingSong:(WilyPlaylist *)playlist;

@end
