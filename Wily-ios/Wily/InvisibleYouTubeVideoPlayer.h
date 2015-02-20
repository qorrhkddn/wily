@import UIKit;

@protocol InvisibleYouTubeVideoPlayerDelegate;

@interface InvisibleYouTubeVideoPlayer : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<InvisibleYouTubeVideoPlayerDelegate> delegate;

/**
 Load video with @p videoIdentifier in an invisible view
 added to the container view.

 If @p loadVideo has been called, @p unloadVideo must be called before
 letting go of the last reference to the receiver to avoid a memory leak.
 */
- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier;
- (void)unloadVideo;

- (void)play;
- (void)pause;

@property(nonatomic, readonly) BOOL isPlaying;
@property(nonatomic, readonly) NSTimeInterval currentPlaybackTime;
@property(nonatomic, readonly) NSTimeInterval duration;

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
