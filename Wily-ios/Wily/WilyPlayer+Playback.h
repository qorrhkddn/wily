#import "WilyPlayer.h"

@interface WilyPlayer (Playback)

/**
 These methods provide access to the internal state machine.
 You can call start only once, and if you do, you must call stop.
 */
- (void)startPlayingItem;
- (void)stopPlayingItem;

@end
