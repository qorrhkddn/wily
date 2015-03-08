@import AVFoundation;

/**
 A player item subclass that can simultaneously play and download HTTP streams.

 Based on http://vombat.tumblr.com/post/86294492874/caching-audio-streamed-using-avplayer
 */
@interface CachingAVPlayerItem : AVPlayerItem

- (instancetype)initWithURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

@end
