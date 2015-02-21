/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.dashdash.wily.demo;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.dashdash.wily.R;
import com.dashdash.wily.demo.player.DemoPlayer;
import com.dashdash.wily.demo.player.UnsupportedDrmException;
import com.google.android.exoplayer.ExoPlayer;
import com.dashdash.wily.demo.player.DashRendererBuilder;

/**
 * An activity that plays media using {@link com.dashdash.wily.demo.player.DemoPlayer}.
 */
public class PlayerActivity extends Activity implements DemoPlayer.Listener {

    private static final String TAG = "PlayerActivity";

    private EventLogger eventLogger;
    private TextView debugTextView;
    private TextView playerStateTextView;

    private DemoPlayer player;
    private boolean playerNeedsPrepare;

    private long playerPosition;

    private Uri contentUri;
    private String contentId;

    // Activity lifecycle

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Samples.Sample sample = Samples.YOUTUBE_DASH_MP4[1];

        contentUri = Uri.parse(sample.uri);
        contentId = sample.contentId;
        setContentView(R.layout.player_activity);

        debugTextView = (TextView) findViewById(R.id.debug_text_view);
        playerStateTextView = (TextView) findViewById(R.id.player_state_view);
        TextView titleTextView = (TextView) findViewById(R.id.song_title);
        titleTextView.setText(sample.name);

        DemoUtil.setDefaultCookieManager();
    }

    @Override
    public void onResume() {
        super.onResume();
        if (player == null) {
            preparePlayer();
        } else {
            player.setBackgrounded(false);
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        player.setBackgrounded(true);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        releasePlayer();
    }

    public void playPause(View view) {

        boolean on = ((ToggleButton) view).isChecked();
        if (on) {
            player.getPlayerControl().pause();
        } else {
            player.getPlayerControl().start();
        }
    }
    // Internal methods

    private DemoPlayer.RendererBuilder getRendererBuilder() {
        String userAgent = DemoUtil.getUserAgent(this);
        return new DashRendererBuilder(userAgent, contentUri.toString(), contentId,
                new WidevineTestMediaDrmCallback(contentId), debugTextView);
    }

    private void preparePlayer() {
        if (player == null) {
            player = new DemoPlayer(getRendererBuilder());
            player.seekTo(playerPosition);
            player.addListener(this);
            playerNeedsPrepare = true;
            eventLogger = new EventLogger();
            eventLogger.startSession();
            player.addListener(eventLogger);
            player.setInfoListener(eventLogger);
            player.setInternalErrorListener(eventLogger);
        }
        if (playerNeedsPrepare) {
            player.prepare();
            playerNeedsPrepare = false;
        }
        player.setPlayWhenReady(true);
    }

    private void releasePlayer() {
        if (player != null) {
            playerPosition = player.getCurrentPosition();
            player.release();
            player = null;
            eventLogger.endSession();
            eventLogger = null;
        }
    }

    // DemoPlayer.Listener implementation

    @Override
    public void onStateChanged(boolean playWhenReady, int playbackState) {
        String text = "playWhenReady=" + playWhenReady + ", playbackState=";
        switch (playbackState) {
            case ExoPlayer.STATE_BUFFERING:
                text += "buffering";
                break;
            case ExoPlayer.STATE_ENDED:
                text += "ended";
                break;
            case ExoPlayer.STATE_IDLE:
                text += "idle";
                break;
            case ExoPlayer.STATE_PREPARING:
                text += "preparing";
                break;
            case ExoPlayer.STATE_READY:
                text += "ready";
                break;
            default:
                text += "unknown";
                break;
        }
        playerStateTextView.setText(text);
    }

    @Override
    public void onError(Exception e) {
        if (e instanceof UnsupportedDrmException) {
            // Special case DRM failures.
            UnsupportedDrmException unsupportedDrmException = (UnsupportedDrmException) e;
            int stringId = unsupportedDrmException.reason == UnsupportedDrmException.REASON_NO_DRM
                    ? R.string.drm_error_not_supported
                    : unsupportedDrmException.reason == UnsupportedDrmException.REASON_UNSUPPORTED_SCHEME
                    ? R.string.drm_error_unsupported_scheme
                    : R.string.drm_error_unknown;
            Toast.makeText(getApplicationContext(), stringId, Toast.LENGTH_LONG).show();
        }
        playerNeedsPrepare = true;
    }

    @Override
    public void onVideoSizeChanged(int width, int height, float pixelWidthHeightRatio) {
        //
    }


}
