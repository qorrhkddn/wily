#import "WallpaperManager.h"

static const NSUInteger NumberOfWallpapers = 37;

@implementation WallpaperManager

- (NSString *)randomWallpaperId {
  return [@(arc4random() % NumberOfWallpapers) stringValue];
}

- (UIImage *)wallpaperWithId:(NSString *)wallpaperId {
  return [UIImage imageNamed:wallpaperId];
}

@end
