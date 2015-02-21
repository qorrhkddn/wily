@import UIKit;

typedef enum : NSUInteger {
  InvisibleYouTubeVideoPlayerPlaybackStateDeckEmpty,
  InvisibleYouTubeVideoPlayerPlaybackStateLoading,
  InvisibleYouTubeVideoPlayerPlaybackStatePlaying,
  InvisibleYouTubeVideoPlayerPlaybackStatePaused
} InvisibleYouTubeVideoPlayerPlaybackState;

@protocol InvisibleYouTubeVideoPlayerDelegate;

@interface InvisibleYouTubeVideoPlayer : NSObject

/**
 Initialize a player that can invisibly play videos. However, this object
 internally has UI bindings, and needs reference to a valid UIView object,
 which the client is expected to provide as the @p containerView. The
 receiver weakly retains the @p containerView, and it is up to the caller to
 ensure that it stays in the view hierarchy for the duration of the receiver.

 @see @p invalidate.
 */
- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

/**
 Because of internal API constrains, @p invalidate must be called before
 letting go of the last reference to the receiver to avoid a memory leak.
 */
- (void)invalidate;

@property (nonatomic, weak) id<InvisibleYouTubeVideoPlayerDelegate> delegate;

/**
 Load video with @p videoIdentifier in an invisible view added
 to the receiver's container view.

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
@property(nonatomic, readonly) InvisibleYouTubeVideoPlayerPlaybackState playbackState;

@end

@protocol InvisibleYouTubeVideoPlayerDelegate <NSObject>

@optional

- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
                 didFetchVideoTitle:(NSString *)title;

/**
 @p progress is between [0, 1].
 */
- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
             didChangeVideoProgress:(float)progress;

@end
