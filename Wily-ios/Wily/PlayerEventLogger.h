//
//  Copyright (c) 2013-2014 Cédric Luthi. All rights reserved.
//

@import Foundation;

@interface PlayerEventLogger : NSObject

@property (nonatomic, assign, getter = isEnabled) BOOL enabled; // defaults to `YES`

@end
