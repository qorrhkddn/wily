@import UIKit;

@interface InvisibleYouTubeVideoPlayer : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

/**
 Start playing video with @p videoIdentifier in an invisible view
 added to the container view.

 @note Multiple calls to this method are undefined.
 */
- (void)playVideoWithIdentifier:(NSString *)videoIdentifier;

- (void)pause;

@end
