#import <Foundation/Foundation.h>

@interface WilyPlaylist : NSObject

- (NSArray *)songs;
- (NSString *)currentlyPlayingSongId;

/**
 If @p previousSongId is @p nil, then song is moved to the top of the list.
 */
- (void)moveSongWithId:(NSString *)songId afterSongWithId:(NSString *)previousSongId;

- (void)deleteSongWithId:(NSString *)songId;

- (void)insertAsCurrentlyPlayingSong:(NSDictionary *)song;

@end
