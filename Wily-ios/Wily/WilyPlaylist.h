#import <Foundation/Foundation.h>

@interface WilyPlaylist : NSObject

- (NSArray *)songs;

- (NSUInteger)invalidIndex;
- (NSUInteger)currentlyPlayingIndex;
- (NSUInteger)previousSongIndex;
- (NSUInteger)nextSongIndex;
- (NSUInteger)existingIndexForSong:(NSDictionary *)song;

- (BOOL)shouldAutoplay;
- (void)toggleAutoplay;

- (void)moveSongAtIndex:(NSUInteger)index toIndex:(NSUInteger)toIndex;
- (void)deleteSongAtIndex:(NSUInteger)index;

- (void)setCurrentlyPlayingIndex:(NSUInteger)index;
- (void)appendSong:(NSDictionary *)song;

@end
