package com.captainfun333.findatalk;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

import androidx.activity.EdgeToEdge;

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
        registerPlugin(IAPBridgePlugin.class);
        super.onCreate(savedInstanceState);
        // Android 15+ forces edge-to-edge anyway, so this changes no layout
        // there; it's here because Play Console flags targetSdk 35+ apps
        // that never call it. Deliberately not called on older versions:
        // SystemBars only passes insets through on WebView 140+, and
        // Android 8/9 can't update past WebView 138, so enabling it there
        // would put content under the bars (see ENGINEERING_NOTES.md).
        // Must run after super.onCreate(): BridgeActivity sets the
        // NoActionBar theme there, and calling this first builds the window
        // with the launch theme and shows an action bar.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            EdgeToEdge.enable(this);
        }
        // Edge-to-edge (forced at targetSdk 35+) is handled by Capacitor's
        // built-in SystemBars plugin, which feeds the real system-bar insets
        // to the page's env(safe-area-inset-*) CSS. Don't attach an insets
        // listener to the WebView here: Android ignores padding on a WebView,
        // and intercepting the insets hides them from the CSS (see
        // ENGINEERING_NOTES.md).
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
