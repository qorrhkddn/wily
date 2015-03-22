@import UIKit;

@protocol RemoteControlEventsDelegate;

/**
 Remote control events can only be received by a UIResponder. This class
 acts as a bridge for classes that are interested in the remote control
 events but do not want UI bindings. It is expected that the
 `+ [RemoteControlEvents consumeEvent:]` method of this class will be
 invoked from a suitable UIResponder, which will be relayed to all the
 delegates of the instances of this class.

 For example,

   @implementation AppDelegate

   - (void)remoteControlReceivedWithEvent:(UIEvent *)event {
     [RemoteControlEvents consumeEvent:event];
   }

 */
@interface RemoteControlEvents : NSObject

+ (void)consumeEvent:(UIEvent *)event;

@property (nonatomic, weak) id<RemoteControlEventsDelegate> delegate;

@end

@protocol RemoteControlEventsDelegate <NSObject>

@optional

- (void)remoteControlEventsDidTogglePlayPause:(RemoteControlEvents *)events;
- (void)remoteControlEventsDidPressNext:(RemoteControlEvents *)events;
- (void)remoteControlEventsDidPressPrevious:(RemoteControlEvents *)events;

@end
