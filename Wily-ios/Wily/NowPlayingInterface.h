@import Foundation;

@interface NowPlayingInterface : NSObject

- (void)clear;

- (void)setTitle:(NSString *)title;
- (void)asynchronouslySetImageFromThumbnailURL:(NSURL *)thumbnailURL;
- (void)setDuration:(float)duration;
- (void)setCurrentPlaybackTime:(float)playbackTime;

@end
