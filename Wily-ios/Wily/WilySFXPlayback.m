#import "WilySFXPlayback.h"
#import <BRYSoundEffectPlayer/BRYSoundEffectPlayer.h>

void WilySFXPlayMeowSound() {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
  [[BRYSoundEffectPlayer sharedInstance] playSound:path];
}
