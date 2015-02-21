#import "AppDelegate.h"
#import "NowPlayingInterface.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
  if (event.type == UIEventTypeRemoteControl) {
    switch (event.subtype) {
      case UIEventSubtypeRemoteControlPause:
      case UIEventSubtypeRemoteControlPlay:
      case UIEventSubtypeRemoteControlTogglePlayPause:
        [[NSNotificationCenter defaultCenter] postNotificationName:NowPlayingInterfaceUIEventSubtypeRemoteControlTogglePlayPause object:nil];
        break;
      default:
        break;
    }
  }
}

@end
