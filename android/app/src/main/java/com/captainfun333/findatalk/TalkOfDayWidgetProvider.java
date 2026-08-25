package com.captainfun333.findatalk;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
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
 * pick as the web app (see talkOfTheDay()/hashString() in docs/index.html).
 * The algorithm here is a byte-for-byte port of that JS so the widget and
 * the app always agree on today's pick — don't let them drift apart.
 *
 * Data comes from the exact same assets/public/data.json bundled for the
 * web view, read directly off disk (no WebView/JS involved), so the widget
 * works even if the app has never been opened.
 */
public class TalkOfDayWidgetProvider extends AppWidgetProvider {

    private static final String TAG = "TalkOfDayWidget";
    private static final String CHURCH_URL_FMT =
        "https://www.churchofjesuschrist.org/study/general-conference/%s/%s/%s?lang=eng";

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

        String url() {
            return String.format(Locale.US, CHURCH_URL_FMT, year, month, urlSlug);
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

            Intent openIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(pick.url()));
            openIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);
        } else {
            // Data couldn't be read — fall back to just opening the app.
            views.setTextViewText(R.id.widget_title, context.getString(R.string.app_name));
            views.setTextViewText(R.id.widget_speaker, "");
            Intent launchIntent = new Intent(context, MainActivity.class);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);
        }

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

    /** Port of talkOfTheDay()/hashString() from docs/index.html — keep in sync. */
    private Talk talkOfTheDay(ArrayList<Talk> talks) {
        if (talks.isEmpty()) return null;

        ArrayList<Talk> sorted = new ArrayList<>(talks);
        Collections.sort(sorted, new Comparator<Talk>() {
            @Override
            public int compare(Talk a, Talk b) {
                return a.key().compareTo(b.key());
            }
        });

        Calendar cal = Calendar.getInstance();
        String dateSeed = String.format(
            Locale.US,
            "%04d-%02d-%02d",
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH)
        );

        long hash = hashString(dateSeed);
        int index = (int) (hash % sorted.size());
        return sorted.get(index);
    }

    /** DJB2 variant, bit-for-bit match of the JS hashString() (32-bit wraparound). */
    private long hashString(String s) {
        int h = 5381;
        for (int i = 0; i < s.length(); i++) {
            h = (h * 33) ^ s.charAt(i);
        }
        return Integer.toUnsignedLong(h);
    }
}
