@import UIKit;

@interface InvisibleYouTubeVideoPlayer : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

/**
 Load video with @p videoIdentifier in an invisible view
 added to the container view.
 */
- (void)loadVideoWithIdentifier:(NSString *)videoIdentifier;

- (void)play;
- (void)pause;
- (void)stop;

@end
