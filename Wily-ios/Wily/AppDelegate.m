#import "AppDelegate.h"
#import "RemoteControlEvents.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
  [RemoteControlEvents consumeEvent:event];
}

@end
