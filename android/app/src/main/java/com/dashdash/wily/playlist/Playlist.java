package com.dashdash.wily.playlist;

import android.content.Context;
import android.net.Uri;

import com.dashdash.wily.R;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by isneeshmarwah on 2/20/15.
 */
public class Playlist {

    public static class Entry {

        public final String name;
        public final Uri uri;

        public Entry(String name, Uri uri) {
            this.name = name;
            this.uri = uri;
        }

    }

    private static Playlist _instance;
    private static List<Entry> _entries;
    private static int currentPlayingIndex = -1;

    private Playlist(Context context) {
        _entries = new ArrayList<>();

        Entry sampleSong = new Entry("Counting Stars",
                Uri.parse("android.resource://" + context.getPackageName() + "/" + R.raw.counting_stars));
        _entries.add(sampleSong);

        Entry sampleSong2 = new Entry("Walking with elephants",
                Uri.parse("android.resource://" + context.getPackageName() + "/" + R.raw.walking));
        _entries.add(sampleSong2);

    }

    public synchronized static Playlist getInstance(Context context) {
        if (_instance == null) {
            _instance = new Playlist(context);
        }
        return _instance;
    }

    public Entry getNext() {
        currentPlayingIndex++;

        if (currentPlayingIndex > _entries.size() - 1) {
            currentPlayingIndex = 0;
        }
        return _entries.get(currentPlayingIndex);
    }
}
