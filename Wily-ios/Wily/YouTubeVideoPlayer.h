@import UIKit;

typedef enum : NSUInteger {
  YouTubeVideoPlayerPlaybackStateDeckEmpty,
  YouTubeVideoPlayerPlaybackStateLoading,
  YouTubeVideoPlayerPlaybackStatePlaying,
  YouTubeVideoPlayerPlaybackStatePaused
} YouTubeVideoPlayerPlaybackState;

@protocol YouTubeVideoPlayerPlayerDelegate;

@interface YouTubeVideoPlayer : NSObject

/**
 Initialize a player that can play YouTube videos.

 @see @p invalidate.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 Because of internal API constrains, @p invalidate must be called before
 letting go of the last reference to the receiver to avoid a memory leak.
 */
- (void)invalidate;

@property (nonatomic, weak) id<YouTubeVideoPlayerPlayerDelegate> delegate;

/**
 Start loading video with @p videoIdentifier into the player and start
 its playback when data starts streaming in.

 The previously playing video, if any, is stopped before loading the new one.
 */
- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier;

#pragma mark MPMoviePlayerController API

/**
 NOTE: The deck must be non empty before calling these methods.
 */

- (void)play;
- (void)pause;

@property(nonatomic, readonly) NSTimeInterval currentPlaybackTime;
@property(nonatomic, readonly) NSTimeInterval duration;
@property(nonatomic, readonly) YouTubeVideoPlayerPlaybackState playbackState;

@end

@protocol YouTubeVideoPlayerPlayerDelegate <NSObject>

/**
 Note: The delegate methods will be invoked in an arbitrary execution context.
 */

@optional

- (void)youTubeVideoPlayer:(YouTubeVideoPlayer *)player
        didFetchVideoTitle:(NSString *)title;

/**
 @p progress is between [0, 1].
 */
- (void)youTubeVideoPlayer:(YouTubeVideoPlayer *)player
    didChangeVideoProgress:(float)progress;

@end
