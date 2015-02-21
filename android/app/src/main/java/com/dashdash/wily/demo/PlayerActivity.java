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
import android.text.Editable;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.dashdash.wily.R;
import com.dashdash.wily.demo.player.DemoPlayer;
import com.dashdash.wily.demo.player.UnsupportedDrmException;
import com.google.android.exoplayer.ExoPlayer;
import com.dashdash.wily.demo.player.DashRendererBuilder;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestInitializer;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.services.youtube.YouTube;
import com.google.api.services.youtube.model.ResourceId;
import com.google.api.services.youtube.model.SearchListResponse;
import com.google.api.services.youtube.model.SearchResult;
import com.google.api.services.youtube.model.Thumbnail;

import java.io.IOException;
import java.util.Iterator;
import java.util.List;
import java.util.Stack;

/**
 * An activity that plays media using {@link com.dashdash.wily.demo.player.DemoPlayer}.
 */
public class PlayerActivity extends Activity implements DemoPlayer.Listener {

    private static final String TAG = "PlayerActivity";
    private static final String YOUTUBE_API_KEY = "AIzaSyD2Otqd_OlhLfZekoXGMSuibDgGcagp-3Y";

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
        final EditText searchBox= (EditText) findViewById(R.id.searchbox);
        searchBox.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if(actionId == EditorInfo.IME_ACTION_SEARCH) {
                    searchYoutube(searchBox.getText().toString());
                    return true;
                }
                else
                {
                    return false;
                }
            }
        });
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


    private void searchYoutube(final String query)
    {
        new Thread(new Runnable() {
            @Override
            public void run() {

                try {
                    // This object is used to make YouTube Data API requests. The last
                    // argument is required, but since we don't need anything
                    // initialized when the HttpRequest is initialized, we override
                    // the interface and provide a no-op function.
                    YouTube youtube = new YouTube.Builder(new NetHttpTransport(), new JacksonFactory(), new HttpRequestInitializer() {
                        public void initialize(HttpRequest request) throws IOException {
                        }
                    }).setApplicationName("youtube-cmdline-search-sample").build();

                    // Define the API request for retrieving search results.
                    YouTube.Search.List search = youtube.search().list("id,snippet");

                    // Set your developer key from the Google Developers Console for
                    // non-authenticated requests. See:
                    // https://console.developers.google.com/
                    String apiKey = YOUTUBE_API_KEY;
                    search.setKey(apiKey);
                    search.setQ(query);

                    // Restrict the search results to only include videos. See:
                    // https://developers.google.com/youtube/v3/docs/search/list#type
                    search.setType("video");

                    // To increase efficiency, only retrieve the fields that the
                    // application uses.
                    search.setFields("items(id/kind,id/videoId,snippet/title,snippet/thumbnails/default/url)");
                    search.setMaxResults(Long.valueOf(1));

                    // Call the API and print results.
                    SearchListResponse searchResponse = search.execute();
                    List<SearchResult> searchResultList = searchResponse.getItems();
                    if (searchResultList != null) {
                        prettyPrint(searchResultList.iterator(), query);
                    }
                } catch (GoogleJsonResponseException e) {
                    System.err.println("There was a service error: " + e.getDetails().getCode() + " : "
                            + e.getDetails().getMessage());
                } catch (IOException e) {
                    System.err.println("There was an IO error: " + e.getCause() + " : " + e.getMessage());
                } catch (Throwable t) {
                    t.printStackTrace();
                }
            }
        }).start();
    }
    private static void prettyPrint(Iterator<SearchResult> iteratorSearchResults, String query) {

        System.out.println("\n=============================================================");
        System.out.println(
                "   First video for search on \"" + query + "\".");
        System.out.println("=============================================================\n");

        if (!iteratorSearchResults.hasNext()) {
            System.out.println(" There aren't any results for your query.");
        }

        while (iteratorSearchResults.hasNext()) {

            SearchResult singleVideo = iteratorSearchResults.next();
            ResourceId rId = singleVideo.getId();

            // Confirm that the result represents a video. Otherwise, the
            // item will not contain a video ID.
            if (rId.getKind().equals("youtube#video")) {
                Thumbnail thumbnail = singleVideo.getSnippet().getThumbnails().getDefault();

                System.out.println(" Video Id" + rId.getVideoId());
                System.out.println(" Title: " + singleVideo.getSnippet().getTitle());
                System.out.println(" Thumbnail: " + thumbnail.getUrl());
                System.out.println("\n-------------------------------------------------------------\n");
            }
        }
    }
}
