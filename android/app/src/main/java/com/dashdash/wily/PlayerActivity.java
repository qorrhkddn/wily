package com.dashdash.wily;

import android.app.Activity;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.dashdash.wily.playlist.Playlist;
import com.google.android.exoplayer.ExoPlayer;
import com.google.android.exoplayer.FrameworkSampleSource;
import com.google.android.exoplayer.MediaCodecAudioTrackRenderer;
import com.google.android.exoplayer.util.PlayerControl;


public class PlayerActivity extends Activity {

    Playlist _playlist;
    private ExoPlayer player;
    private PlayerControl playerControl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_player);

        _playlist = Playlist.getInstance(this);
        setupPlayer();
    }

    private void setupPlayer() {

        final View root = findViewById(R.id.root);
        final ImageView wallpaper = (ImageView) findViewById(R.id.wallpaper);
        final TextView songTitle = (TextView) findViewById(R.id.song_title);


        Playlist.Entry songEntry = _playlist.getNext();
        songTitle.setText(songEntry.name);

        player = ExoPlayer.Factory.newInstance(1);
        FrameworkSampleSource frameworkSampleSource = new FrameworkSampleSource(this, songEntry.uri, null, 1);
        MediaCodecAudioTrackRenderer mediaCodecAudioTrackRenderer = new MediaCodecAudioTrackRenderer(frameworkSampleSource);
        player.prepare(mediaCodecAudioTrackRenderer);
        player.setPlayWhenReady(true);

        playerControl = new PlayerControl(player);

    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
    }

    public void playPause(View view) {

        boolean on = ((ToggleButton) view).isChecked();
        if (on) {
            playerControl.pause();
        } else {
            playerControl.start();
        }
    }
}
