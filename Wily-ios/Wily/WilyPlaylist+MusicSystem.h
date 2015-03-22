#import "WilyPlaylist.h"

@protocol WilyPlaylistDelegate;

@interface WilyPlaylist (MusicSystem)

- (instancetype)initWithSongs:(NSArray *)songs;

@property (nonatomic) id<WilyPlaylistDelegate> delegate;

@end

@protocol WilyPlaylistDelegate <NSObject>

@optional

- (void)playlist:(WilyPlaylist *)playlist didUpdateSongs:(NSArray *)songs;

@end
