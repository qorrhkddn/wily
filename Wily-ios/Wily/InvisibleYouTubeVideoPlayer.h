@import UIKit;

@interface InvisibleYouTubeVideoPlayer : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView
                      videoIdentifier:(NSString *)videoIdentifier NS_DESIGNATED_INITIALIZER;

/**
 @note Multiple calls to this method are ignored.
 */
- (void)play;

- (void)pause;

@end
