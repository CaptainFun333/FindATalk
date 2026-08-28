package com.captainfun333.findatalk;

import android.content.Intent;
import android.os.Bundle;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    // Set by the "Talk of the Day" widget's PendingIntent (see
    // TalkOfDayWidgetProvider.java) — nothing else in this app sets it, so
    // its presence always means "opened from the widget, go to Home" (see
    // goToHomeScreen() in docs/index.html). Ordinary foregrounding (app
    // switcher, Home button) doesn't go through this at all — this is the
    // one path that should force the WebView back to Home instead of
    // resuming wherever it was left.
    static final String EXTRA_OPEN_HOME = "com.captainfun333.findatalk.OPEN_HOME";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(WidgetRefreshPlugin.class);
        super.onCreate(savedInstanceState);
        // Cold start already opens fresh on Home with no stale state to
        // reset, so this is a harmless no-op here — kept for symmetry with
        // onNewIntent() below, which is where this actually matters (the
        // app already running, its WebView state stale).
        maybeGoHome(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        maybeGoHome(intent);
    }

    private void maybeGoHome(Intent intent) {
        if (intent == null || !intent.getBooleanExtra(EXTRA_OPEN_HOME, false)) return;
        if (getBridge() == null || getBridge().getWebView() == null) return;
        getBridge().getWebView().evaluateJavascript(
            "window.goToHomeScreen && window.goToHomeScreen();", null);
    }
}
