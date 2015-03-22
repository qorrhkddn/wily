@import Foundation;

@class WilyPlayer;
@class WilyPlaylist;
@protocol WilyMusicSystemDelegate;

@interface WilyMusicSystem : NSObject

@property (nonatomic, readonly) WilyPlayer *player;
@property (nonatomic, readonly) WilyPlaylist *playlist;

@property (nonatomic, weak) id<WilyMusicSystemDelegate> delegate;

- (void)playSong:(NSDictionary *)song;

@end

@protocol WilyMusicSystemDelegate <NSObject>

@optional

- (void)musicSystem:(WilyMusicSystem *)musicSystem playerDidChange:(WilyPlayer *)player;

@end
