@import Foundation;
@import AVFoundation;

typedef enum : NSUInteger {
  WilyPlayerPlaybackStateLoading,
  WilyPlayerPlaybackStatePlaying,
  WilyPlayerPlaybackStatePaused
} WilyPlayerPlaybackState;

@protocol WilyPlayerDelegate;

/**
 Adapter over AVPlayer. Will automatically start playback.
 */
@interface WilyPlayer : NSObject

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem
                              song:(NSDictionary *)song;

@property (nonatomic, readonly) NSDictionary *song;

@property (nonatomic, weak) id<WilyPlayerDelegate> delegate;

- (void)togglePlayPause;
- (void)repeat;

@property(nonatomic, readonly) WilyPlayerPlaybackState playbackState;
@property (nonatomic, readonly) NSTimeInterval currentPlaybackTime;
@property (nonatomic, readonly) NSTimeInterval duration;

@end

@protocol WilyPlayerDelegate <NSObject>

/**
 Note: The delegate methods will be invoked in an arbitrary execution context.
 */

@optional

- (void)player:(WilyPlayer *)player didChangePlaybackState:(WilyPlayerPlaybackState)playbackState;

/**
 @p progress is between [0, 1].
 */
- (void)player:(WilyPlayer *)player didChangeProgress:(float)progress;

@end
