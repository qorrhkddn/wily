#import "RemoteControlEvents.h"

static NSString * const RemoteControlEventsDidConsumeEvent = @"RemoteControlEventsDidConsumeEvent";

@implementation RemoteControlEvents

+ (void)consumeEvent:(UIEvent *)event {
  NSDictionary *userInfo = @{@"event": event};
  [[NSNotificationCenter defaultCenter] postNotificationName:RemoteControlEventsDidConsumeEvent
                                                      object:nil
                                                    userInfo:userInfo];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didConsumeEvent:)
                                                 name:RemoteControlEventsDidConsumeEvent
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didConsumeEvent:(NSNotification *)note {
  UIEvent *event = [note userInfo][@"event"];
  if (event.type == UIEventTypeRemoteControl) {
    switch (event.subtype) {
      case UIEventSubtypeRemoteControlPause:
      case UIEventSubtypeRemoteControlPlay:
      case UIEventSubtypeRemoteControlTogglePlayPause:
        [self didTogglePlayPause];
        break;
      case UIEventSubtypeRemoteControlNextTrack:
        [self didPressNext];
        break;
      case UIEventSubtypeRemoteControlPreviousTrack:
        [self didPressPrevious];
        break;
      default:
        break;
    }
  }
}

- (void)didTogglePlayPause {
  if ([self.delegate respondsToSelector:@selector(remoteControlEventsDidTogglePlayPause:)]) {
    [self.delegate remoteControlEventsDidTogglePlayPause:self];
  }
}

- (void)didPressNext {
  if ([self.delegate respondsToSelector:@selector(remoteControlEventsDidPressNext:)]) {
    [self.delegate remoteControlEventsDidPressNext:self];
  }
}

- (void)didPressPrevious {
  if ([self.delegate respondsToSelector:@selector(remoteControlEventsDidPressPrevious:)]) {
    [self.delegate remoteControlEventsDidPressPrevious:self];
  }
}

@end
