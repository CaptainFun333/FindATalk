package com.captainfun333.findatalk;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.util.Log;
import android.widget.RemoteViews;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Locale;

/**
 * Home-screen widget that shows the same deterministic "Talk of the Day"
 * pick as the web app (see talkOfTheDay()/localDayNumber()/splitmix32()
 * in docs/index.html). The algorithm here is a byte-for-byte port of that
 * JS so the widget and the app always agree on today's pick — don't let
 * them drift apart.
 *
 * Data comes from the exact same assets/public/data.json bundled for the
 * web view, read directly off disk (no WebView/JS involved), so the widget
 * works even if the app has never been opened.
 *
 * Tapping the widget opens the app rather than the talk's URL directly —
 * see updateWidget() below for why.
 */
public class TalkOfDayWidgetProvider extends AppWidgetProvider {

    private static final String TAG = "TalkOfDayWidget";

    private static class Talk {
        final String title;
        final String speaker;
        final String year;
        final String month;
        final String urlSlug;

        Talk(String title, String speaker, String year, String month, String urlSlug) {
            this.title = title;
            this.speaker = speaker;
            this.year = year;
            this.month = month;
            this.urlSlug = urlSlug;
        }

        String key() {
            return year + "|" + month + "|" + urlSlug;
        }
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        String action = intent.getAction();
        // Force a refresh right at midnight (and after reboot / manual
        // clock changes) instead of waiting on the ~daily periodic update,
        // which the system is free to delay or batch.
        if (Intent.ACTION_DATE_CHANGED.equals(action)
                || Intent.ACTION_TIME_CHANGED.equals(action)
                || Intent.ACTION_TIMEZONE_CHANGED.equals(action)
                || Intent.ACTION_BOOT_COMPLETED.equals(action)) {
            AppWidgetManager manager = AppWidgetManager.getInstance(context);
            ComponentName provider = new ComponentName(context, TalkOfDayWidgetProvider.class);
            int[] ids = manager.getAppWidgetIds(provider);
            for (int id : ids) {
                updateWidget(context, manager, id);
            }
        }
    }

    private void updateWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_talk_of_day);
        Talk pick = null;
        try {
            pick = talkOfTheDay(loadTalks(context));
        } catch (Exception e) {
            Log.e(TAG, "Failed to compute Talk of the Day", e);
        }

        String streakText = streakText(context);
        if (streakText != null) {
            views.setTextViewText(R.id.widget_streak, streakText);
            views.setViewVisibility(R.id.widget_streak, android.view.View.VISIBLE);
        } else {
            views.setViewVisibility(R.id.widget_streak, android.view.View.GONE);
        }

        if (pick != null) {
            views.setTextViewText(R.id.widget_title, pick.title);
            views.setTextViewText(R.id.widget_speaker, pick.speaker);
        } else {
            views.setTextViewText(R.id.widget_title, context.getString(R.string.app_name));
            views.setTextViewText(R.id.widget_speaker, "");
        }

        applyAppearanceOverride(context, views);

        // Tapping opens the app (not the talk directly in a browser) so
        // the person taps "Open This Talk" from inside it — that's the
        // one place recordOpened()/touchStreak() actually run, so this is
        // what makes the streak advance at all. Going straight to the
        // browser bypassed the app entirely and the streak just never
        // moved.
        Intent launchIntent = new Intent(context, MainActivity.class);
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        // Tells MainActivity to reset the WebView back to Home instead of
        // resuming wherever it was left — see maybeGoHome() there.
        launchIntent.putExtra(MainActivity.EXTRA_OPEN_HOME, true);
        PendingIntent pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

        appWidgetManager.updateAppWidget(appWidgetId, views);
    }

    // Written by mirrorStreakToNative() in docs/index.html via
    // @capacitor/preferences, whose Android implementation always uses a
    // SharedPreferences file named "CapacitorStorage" (its hardcoded
    // default) regardless of anything in capacitor.config.json — keep
    // both names in sync if that ever changes.
    private static final String STREAK_PREFS_NAME = "CapacitorStorage";
    private static final String STREAK_KEY = "findATalkStreak";

    /** Read-only mirror of renderStreak()'s text in docs/index.html —
        this only displays whatever the app last wrote, it never advances
        the streak itself (that only happens when the app is actually
        opened). Returns null if there's no streak yet, so the caller can
        hide the row entirely rather than show a "0-day" default. */
    private String streakText(Context context) {
        try {
            SharedPreferences prefs = context.getSharedPreferences(STREAK_PREFS_NAME, Context.MODE_PRIVATE);
            String raw = prefs.getString(STREAK_KEY, null);
            if (raw == null) return null;

            JSONObject obj = new JSONObject(raw);
            int count = obj.optInt("count", 0);
            if (count <= 0) return null;
            if (count == 1) return "🔥 Day 1 — come back tomorrow to start a streak";

            JSONArray activeDaysJson = obj.optJSONArray("activeDays");
            int activeDays = activeDaysJson != null ? activeDaysJson.length() : 0;
            return String.format(Locale.US, "🔥 %d of the last 365 — %d-day streak", activeDays, count);
        } catch (Exception e) {
            Log.e(TAG, "Failed to read streak", e);
            return null;
        }
    }

    // Written by mirrorThemeToNative() in docs/index.html, same
    // SharedPreferences file as the streak — see the comment above
    // STREAK_PREFS_NAME. Value is "light"/"dark" if the person made an
    // explicit choice with the in-app toggle, or absent if they haven't
    // (still following the system setting).
    private static final String THEME_KEY = "findATalkTheme";

    // Literal hex values (not @color/widget_* resource references) for
    // both palettes — must match values/colors.xml (light) and
    // values-night/colors.xml (dark). A resource reference re-resolves
    // against whatever the device's CURRENT night mode is at render time,
    // which is exactly the auto-follow-system behavior an explicit
    // override needs to bypass; RemoteViews.setTextColor()/
    // setBackgroundResource() below only accept literal values/resource
    // ids anyway, not something that could re-resolve later.
    private static final int LIGHT_INK = Color.parseColor("#1C2C42");
    private static final int LIGHT_INK_SOFT = Color.parseColor("#3D4D64");
    private static final int LIGHT_BRASS = Color.parseColor("#A9822F");
    private static final int LIGHT_BURGUNDY = Color.parseColor("#6E2B34");
    private static final int DARK_INK = Color.parseColor("#FFFFFF");
    private static final int DARK_INK_SOFT = Color.parseColor("#B7BDCF");
    private static final int DARK_BRASS = Color.parseColor("#CAA550");
    private static final int DARK_BURGUNDY = Color.parseColor("#D98A93");

    // Written by mirrorPaletteToNative() in docs/index.html, same
    // SharedPreferences file as theme/streak. Value is 'rose'/'slate'/
    // 'sage' if the person picked a Color Palette in Settings, or absent
    // if they haven't (still Brass, the default — the LIGHT_*/DARK_*
    // constants above and their two drawables cover that case already).
    private static final String PALETTE_KEY = "findATalkPalette";

    // One more literal color set per non-Brass palette, same reasoning as
    // LIGHT_*/DARK_* above — must match docs/index.html's
    // :root[data-palette="X"] / :root[data-theme="dark"][data-palette="X"]
    // --ink/--ink-soft/--brass/--burgundy.
    private static final int LIGHT_ROSE_INK = Color.parseColor("#3C2530");
    private static final int LIGHT_ROSE_INK_SOFT = Color.parseColor("#6B4C58");
    private static final int LIGHT_ROSE_ACCENT = Color.parseColor("#A45A72");
    private static final int LIGHT_ROSE_ACCENT2 = Color.parseColor("#A3792F");
    private static final int DARK_ROSE_INK = Color.parseColor("#FFFFFF");
    private static final int DARK_ROSE_INK_SOFT = Color.parseColor("#C9B3BA");
    private static final int DARK_ROSE_ACCENT = Color.parseColor("#D491A8");
    private static final int DARK_ROSE_ACCENT2 = Color.parseColor("#C9A35E");

    private static final int LIGHT_SLATE_INK = Color.parseColor("#202B3A");
    private static final int LIGHT_SLATE_INK_SOFT = Color.parseColor("#4C5A6C");
    private static final int LIGHT_SLATE_ACCENT = Color.parseColor("#4A6F92");
    private static final int LIGHT_SLATE_ACCENT2 = Color.parseColor("#6A3B5C");
    private static final int DARK_SLATE_INK = Color.parseColor("#FFFFFF");
    private static final int DARK_SLATE_INK_SOFT = Color.parseColor("#B3BDC9");
    private static final int DARK_SLATE_ACCENT = Color.parseColor("#7FA9C9");
    private static final int DARK_SLATE_ACCENT2 = Color.parseColor("#C98BB0");

    private static final int LIGHT_SAGE_INK = Color.parseColor("#28322A");
    private static final int LIGHT_SAGE_INK_SOFT = Color.parseColor("#5C645D");
    private static final int LIGHT_SAGE_ACCENT = Color.parseColor("#6F7C3F");
    private static final int LIGHT_SAGE_ACCENT2 = Color.parseColor("#8C4A2F");
    private static final int DARK_SAGE_INK = Color.parseColor("#FFFFFF");
    private static final int DARK_SAGE_INK_SOFT = Color.parseColor("#B9C2B5");
    private static final int DARK_SAGE_ACCENT = Color.parseColor("#9DB06A");
    private static final int DARK_SAGE_ACCENT2 = Color.parseColor("#D98A63");

    /** True if the system is currently in night mode — used as the
        fallback when a palette is set but no explicit Light/Dark choice
        has been made, since a non-Brass palette can't rely on the
        layout's @color/widget_* (values/values-night) resources, which
        only know about Brass. */
    private boolean isSystemDark(Context context) {
        int mode = context.getResources().getConfiguration().uiMode
            & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        return mode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
    }

    /** No-op only in the one case that needs nothing extra: Brass (the
        default palette) with no explicit theme choice either — the
        layout's own @color/widget_* references (auto light/dark via
        values/values-night) already handle "follow the system setting"
        correctly with zero extra code, exactly as before palettes
        existed. Every other combination (an explicit theme choice, a
        non-Brass palette, or both) picks a literal color set instead,
        since @color/widget_* only ever resolves to Brass. */
    private void applyAppearanceOverride(Context context, RemoteViews views) {
        SharedPreferences prefs = context.getSharedPreferences(STREAK_PREFS_NAME, Context.MODE_PRIVATE);
        String theme = prefs.getString(THEME_KEY, null);
        String palette = prefs.getString(PALETTE_KEY, "brass");
        if ("brass".equals(palette) && theme == null) return;

        boolean dark = "dark".equals(theme) || (theme == null && isSystemDark(context));

        int backgroundRes;
        int ink, inkSoft, accent, accent2;
        switch (palette) {
            case "rose":
                backgroundRes = dark ? R.drawable.widget_background_rose_dark : R.drawable.widget_background_rose_light;
                ink = dark ? DARK_ROSE_INK : LIGHT_ROSE_INK;
                inkSoft = dark ? DARK_ROSE_INK_SOFT : LIGHT_ROSE_INK_SOFT;
                accent = dark ? DARK_ROSE_ACCENT : LIGHT_ROSE_ACCENT;
                accent2 = dark ? DARK_ROSE_ACCENT2 : LIGHT_ROSE_ACCENT2;
                break;
            case "slate":
                backgroundRes = dark ? R.drawable.widget_background_slate_dark : R.drawable.widget_background_slate_light;
                ink = dark ? DARK_SLATE_INK : LIGHT_SLATE_INK;
                inkSoft = dark ? DARK_SLATE_INK_SOFT : LIGHT_SLATE_INK_SOFT;
                accent = dark ? DARK_SLATE_ACCENT : LIGHT_SLATE_ACCENT;
                accent2 = dark ? DARK_SLATE_ACCENT2 : LIGHT_SLATE_ACCENT2;
                break;
            case "sage":
                backgroundRes = dark ? R.drawable.widget_background_sage_dark : R.drawable.widget_background_sage_light;
                ink = dark ? DARK_SAGE_INK : LIGHT_SAGE_INK;
                inkSoft = dark ? DARK_SAGE_INK_SOFT : LIGHT_SAGE_INK_SOFT;
                accent = dark ? DARK_SAGE_ACCENT : LIGHT_SAGE_ACCENT;
                accent2 = dark ? DARK_SAGE_ACCENT2 : LIGHT_SAGE_ACCENT2;
                break;
            default:
                backgroundRes = dark ? R.drawable.widget_background_dark : R.drawable.widget_background_light;
                ink = dark ? DARK_INK : LIGHT_INK;
                inkSoft = dark ? DARK_INK_SOFT : LIGHT_INK_SOFT;
                accent = dark ? DARK_BRASS : LIGHT_BRASS;
                accent2 = dark ? DARK_BURGUNDY : LIGHT_BURGUNDY;
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", backgroundRes);
        views.setTextColor(R.id.widget_eyebrow, accent);
        views.setTextColor(R.id.widget_title, ink);
        views.setTextColor(R.id.widget_speaker, inkSoft);
        views.setTextColor(R.id.widget_streak, accent2);
    }

    private ArrayList<Talk> loadTalks(Context context) throws Exception {
        ArrayList<Talk> talks = new ArrayList<>();
        try (InputStream is = context.getAssets().open("public/data.json");
             BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            char[] buf = new char[8192];
            int n;
            while ((n = reader.read(buf)) != -1) sb.append(buf, 0, n);

            JSONObject root = new JSONObject(sb.toString());
            JSONArray talksJson = root.getJSONArray("talks");
            for (int i = 0; i < talksJson.length(); i++) {
                JSONArray t = talksJson.getJSONArray(i);
                // [title, speaker, year, month, urlSlug]
                talks.add(new Talk(
                    t.getString(0),
                    t.getString(1),
                    String.valueOf(t.get(2)),
                    t.getString(3),
                    t.getString(4)
                ));
            }
        }
        return talks;
    }

    /** Port of talkOfTheDay()/localDayNumber()/splitmix32() from docs/index.html — keep in sync. */
    private Talk talkOfTheDay(ArrayList<Talk> talks) {
        if (talks.isEmpty()) return null;

        ArrayList<Talk> sorted = new ArrayList<>(talks);
        Collections.sort(sorted, new Comparator<Talk>() {
            @Override
            public int compare(Talk a, Talk b) {
                return a.key().compareTo(b.key());
            }
        });

        int seed = localDayNumber(Calendar.getInstance());
        int hash = splitmix32(seed);
        int index = (int) (Integer.toUnsignedLong(hash) % sorted.size());
        return sorted.get(index);
    }

    /** Days since epoch on the device's local calendar (not UTC) — a
        straight port of localDayNumber() in docs/index.html. Must use the
        same "local midnight, floor(ms/86400000)" arithmetic as the JS
        version, not a timezone-independent day count, so it lines up
        exactly with what the web app computes on the same device. */
    private int localDayNumber(Calendar cal) {
        Calendar midnight = (Calendar) cal.clone();
        midnight.set(Calendar.HOUR_OF_DAY, 0);
        midnight.set(Calendar.MINUTE, 0);
        midnight.set(Calendar.SECOND, 0);
        midnight.set(Calendar.MILLISECOND, 0);
        long ms = midnight.getTimeInMillis();
        return (int) Math.floorDiv(ms, 86400000L);
    }

    /** Integer mixing hash (splitmix32), bit-for-bit match of the JS
        splitmix32() in docs/index.html — replaced a prior DJB2-on-string
        version that didn't avalanche for adjacent dates. Java's `int`
        arithmetic already wraps mod 2^32 on overflow, matching JS's
        `>>> 0` coercions and Math.imul, as long as `>>>` (unsigned shift)
        is used everywhere the JS does. */
    private int splitmix32(int seed) {
        int h = seed + 0x9e3779b9;
        int z = h;
        z = (z ^ (z >>> 16)) * 0x21f0aaad;
        z = (z ^ (z >>> 15)) * 0x735a2d97;
        z = z ^ (z >>> 15);
        return z;
    }
}
