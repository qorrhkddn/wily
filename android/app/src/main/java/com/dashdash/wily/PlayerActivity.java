package com.dashdash.wily;

import android.app.Activity;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.dashdash.wily.playlist.Playlist;


public class PlayerActivity extends Activity {

    Playlist _playlist;
    private MediaPlayer mediaPlayer;

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
        final Button btnPlayPause = (Button) findViewById(R.id.btn_play);


        Playlist.Entry songEntry = _playlist.getNext();
        songTitle.setText(songEntry.name);

        mediaPlayer = MediaPlayer.create(this, songEntry.uri);
        mediaPlayer.start();
    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
    }

    public void playPause(View view) {

        boolean on = ((ToggleButton) view).isChecked();
        if (on) {
            mediaPlayer.pause();
        } else {
            mediaPlayer.start();
        }
    }
}
