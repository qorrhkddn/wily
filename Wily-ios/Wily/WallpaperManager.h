@import UIKit;

/**
 Gatekeeper for Wallpaper access.
 */
@interface WallpaperManager : NSObject

- (NSString *)randomWallpaperId;
- (UIImage *)wallpaperWithId:(NSString *)wallpaperId;

@end
