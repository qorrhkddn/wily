@import Foundation;

/**
 This notification needs to be thrown from the Application Delegate's
 implementation of `remoteControlReceivedWithEvent` for the play/pause to work.
 */
extern NSString * const NowPlayingInterfaceUIEventSubtypeRemoteControlTogglePlayPause;

@interface NowPlayingInterface : NSObject

- (void)clear;

- (void)setTitle:(NSString *)title;
- (void)asynchronouslySetImageFromThumbnailURL:(NSURL *)thumbnailURL;
- (void)setDuration:(float)duration;
- (void)setCurrentPlaybackTime:(float)playbackTime;

@end
