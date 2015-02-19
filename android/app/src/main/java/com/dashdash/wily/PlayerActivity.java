package com.dashdash.wily;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;


public class PlayerActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_player);

        final View controlsView = findViewById(R.id.player_controls);
        final View contentView = findViewById(R.id.wallpaper);
    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
    }
}
