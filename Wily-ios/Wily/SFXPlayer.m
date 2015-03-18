#import "SFXPlayer.h"
#import <BRYSoundEffectPlayer/BRYSoundEffectPlayer.h>

@implementation SFXPlayer

+ (void)playMeowSound {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
  [[BRYSoundEffectPlayer sharedInstance] playSound:path];
}

@end
