[XCDYouTubeKit][] seems to provide a pre-packaged solution for the
first requirement (playback of a known video id). The second
requirement (saving streams for offline access) seems non-trivial from
a cursory glance, although there does seem to be API support in the
form of [MTAudioProcessingTap][].

An alternative would be try and use the iOS ready mobile version of
[VLC][Mobile VLC] and augment it with YouTube stream playback.

[XCDYouTubeKit]: https://github.com/0xced/XCDYouTubeKit
[MTAudioProcessingTap]: https://chritto.wordpress.com/2013/01/07/processing-avplayers-audio-with-mtaudioprocessingtap/
[Mobile VLC]: http://www.videolan.org/vlc/download-ios.html
