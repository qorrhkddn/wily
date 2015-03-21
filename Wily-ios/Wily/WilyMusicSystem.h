@import Foundation;

@class WilyPlayer;
@protocol WilyMusicSystemDelegate;

@interface WilyMusicSystem : NSObject

@property (nonatomic, readonly) WilyPlayer *player;

@property (nonatomic, weak) id<WilyMusicSystemDelegate> delegate;

- (void)enqueueItemForYouTubeVideoWithId:(NSString *)videoId;

- (void)updatePlaylist:(NSArray *)playlist;

@end

@protocol WilyMusicSystemDelegate <NSObject>

@optional

- (void)musicSystem:(WilyMusicSystem *)musicSystem playerDidChange:(WilyPlayer *)player;

- (void)musicSystem:(WilyMusicSystem *)musicSystem playlistDidAddItem:(NSDictionary *)playlistItem;

@end
