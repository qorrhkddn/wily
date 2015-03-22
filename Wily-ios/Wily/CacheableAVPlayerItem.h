@import AVFoundation;

@protocol CacheableAVPlayerItemDelegate;

/**
 A player item subclass that can simultaneously play and download HTTP streams.

 Based on http://vombat.tumblr.com/post/86294492874/caching-audio-streamed-using-avplayer
 */
@interface CacheableAVPlayerItem : AVPlayerItem

- (instancetype)initWithURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<CacheableAVPlayerItemDelegate> delegate;

@end

@protocol CacheableAVPlayerItemDelegate <NSObject>

/**
 Called when the entire item referenced by @p URL has been downloaded.
 */
- (void)cacheableAVPlayerItem:(CacheableAVPlayerItem *)playerItem
       didDownloadURLContents:(NSData *)data;

@end
