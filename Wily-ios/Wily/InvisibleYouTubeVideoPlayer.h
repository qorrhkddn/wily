@import UIKit;

@protocol InvisibleYouTubeVideoPlayerDelegate;

@interface InvisibleYouTubeVideoPlayer : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<InvisibleYouTubeVideoPlayerDelegate> delegate;

/**
 Load video with @p videoIdentifier in an invisible view
 added to the container view.
 */
- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier;

/**
 If @p play has been called, @p stop must be called before called before
 letting go of the last reference to the receiver to avoid a memory leak.
 */
- (void)play;
- (void)pause;
- (void)stop;

@property(nonatomic, readonly) NSTimeInterval currentPlaybackTime;
@property(nonatomic, readonly) NSTimeInterval duration;

@end

@protocol InvisibleYouTubeVideoPlayerDelegate <NSObject>

@optional

/**
 @p progress is between [0, 1].
 */
- (void)invisibleYouTubeVideoPlayer:(InvisibleYouTubeVideoPlayer *)player
             didChangeVideoProgress:(float)progress;

@end
