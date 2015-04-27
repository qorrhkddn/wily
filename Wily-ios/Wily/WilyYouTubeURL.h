@import Foundation;

/// @return nil if @p string is not a valid Youtube Video URL.
NSDictionary *WilyYouTubeSongFromURLString(NSString *string);

NSString *WilyYouTubeURLStringFromSong(NSDictionary *song);
