package com.captainfun333.findatalk;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

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
        // targetSdk 35+ makes the OS draw edge-to-edge unconditionally (no
        // opt-out) — without this, the WebView draws under the status/nav
        // bars and the app's own UI (buttons, header) can be obscured on
        // gesture-nav devices. Pad the WebView itself by the system bar
        // insets instead of the CSS safe-area-inset-* vars docs/index.html
        // already uses for iOS notches, since Android's WebView doesn't
        // reliably report those without this listener.
        View webView = getBridge() != null ? getBridge().getWebView() : null;
        if (webView != null) {
            ViewCompat.setOnApplyWindowInsetsListener(webView, (v, insets) -> {
                Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
                return insets;
            });
        }
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
