#import "WilyPlaylist.h"

@protocol WilyPlaylistDelegate;

@interface WilyPlaylist (MusicSystem)

- (instancetype)initWithStore:(NSUserDefaults *)store;

@property (nonatomic) id<WilyPlaylistDelegate> delegate;

@end

@protocol WilyPlaylistDelegate <NSObject>

@optional

- (void)playlistDidDeleteCurrentlyPlayingSong:(WilyPlaylist *)playlist;

@end
