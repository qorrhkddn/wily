#import "AppDelegate.h"
#import "RemoteControlEvents.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [application beginReceivingRemoteControlEvents];
  return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
  [RemoteControlEvents consumeEvent:event];
}

@end
