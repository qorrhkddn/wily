package com.dashdash.wily;

import android.app.Activity;
import android.media.MediaPlayer;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.dashdash.wily.playlist.Playlist;
import com.github.axet.vget.VGet;
import com.github.axet.vget.info.VGetParser;
import com.github.axet.vget.info.VideoInfo;
import com.github.axet.vget.vhs.VimeoInfo;
import com.github.axet.vget.vhs.YouTubeParser;
import com.github.axet.vget.vhs.YouTubeQParser;
import com.github.axet.vget.vhs.YoutubeInfo;
import com.github.axet.wget.info.DownloadInfo;

import java.io.File;
import java.net.URL;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;


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

    public void shuffle(View view) {
        final String randomUrl = "https://www.youtube.com/watch?v=S1dAlOUVSS4";
        final File mediaDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Wily");
        new Thread(new Runnable() {
            @Override
            public void run() {

                try {
                    Log.d("PlayerActivity", "downloading media");
                    download(randomUrl,mediaDir);
                    Log.d("PlayerActivity", "downloaded media");
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        }).start();
    }

    VideoInfo info;
    long last;

    public void download(String url, File path) {
        try {
            AtomicBoolean stop = new AtomicBoolean(false);
            Runnable notify = new Runnable() {
                @Override
                public void run() {
                    VideoInfo i1 = info;
                    DownloadInfo i2 = i1.getInfo();

                    // notify app or save download state
                    // you can extract information from DownloadInfo info;
                    switch (i1.getState()) {
                        case EXTRACTING:
                        case EXTRACTING_DONE:
                        case DONE:
                            if (i1 instanceof YoutubeInfo) {
                                YoutubeInfo i = (YoutubeInfo) i1;
                                System.out.println(i1.getState() + " " + i.getVideoQuality());
                            } else if (i1 instanceof VimeoInfo) {
                                VimeoInfo i = (VimeoInfo) i1;
                                System.out.println(i1.getState() + " " + i.getVideoQuality());
                            } else {
                                System.out.println("downloading unknown quality");
                            }
                            break;
                        case RETRYING:
                            System.out.println(i1.getState() + " " + i1.getDelay());
                            break;
                        case DOWNLOADING:
                            long now = System.currentTimeMillis();
                            if (now - 1000 > last) {
                                last = now;

                                String parts = "";

                                List<DownloadInfo.Part> pp = i2.getParts();
                                if (pp != null) {
                                    // multipart download
                                    for (DownloadInfo.Part p : pp) {
                                        if (p.getState().equals(DownloadInfo.Part.States.DOWNLOADING)) {
                                            parts += String.format("Part#%d(%.2f) ", p.getNumber(), p.getCount()
                                                    / (float) p.getLength());
                                        }
                                    }
                                }

                                System.out.println(String.format("%s %.2f %s", i1.getState(),
                                        i2.getCount() / (float) i2.getLength(), parts));
                            }
                            break;
                        default:
                            break;
                    }
                }
            };

            URL web = new URL(url);

            // [OPTIONAL] limit maximum quality, or do not call this function if
            // you wish maximum quality available.
            //
            // if youtube does not have video with requested quality, program
            // will raise en exception.
            VGetParser user = null;

            // create proper html parser depends on url
            user = new YouTubeQParser(YoutubeInfo.YoutubeQuality.p240);

            // download maximum video quality from youtube
            // user = new YouTubeQParser(YoutubeQuality.p480);

            // download mp4 format only, fail if non exist
            // user = new YouTubeMPGParser();

            // create proper videoinfo to keep specific video information
            info = user.info(web);

            VGet v = new VGet(info, path);

            // [OPTIONAL] call v.extract() only if you d like to get video title
            // or download url link
            // before start download. or just skip it.
            v.extract(user, stop, notify);

            System.out.println("Title: " + info.getTitle());
            System.out.println("Download URL: " + info.getInfo().getSource());

            v.download(user, stop, notify);
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
