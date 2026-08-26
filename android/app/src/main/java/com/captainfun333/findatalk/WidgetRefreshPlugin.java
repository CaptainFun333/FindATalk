package com.captainfun333.findatalk;

import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * Tiny custom plugin whose only job is telling the home-screen widget to
 * redraw itself right now. TalkOfDayWidgetProvider already reads the
 * streak straight out of SharedPreferences (see streakText() there), so
 * the value on disk is always current the moment @capacitor/preferences
 * writes it — the missing piece is that nothing repaints the widget's
 * RemoteViews until AppWidgetManager is told to, which otherwise only
 * happens on the ~daily periodic update or a midnight/reboot broadcast
 * (see TalkOfDayWidgetProvider.onReceive()). Without this, a streak
 * advance made mid-day just sits unseen on the widget for up to a day.
 *
 * Called from mirrorStreakToNative() in docs/index.html right after
 * Preferences.set() on the 'android' branch. iOS solves the same problem
 * with WidgetCenter.reloadTimelines() inside StreakBridgePlugin.setStreak
 * — see ios/App/App/StreakBridgePlugin.swift.
 */
@CapacitorPlugin(name = "WidgetRefresh")
public class WidgetRefreshPlugin extends Plugin {
    @PluginMethod
    public void refresh(PluginCall call) {
        Context context = getContext();
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        ComponentName provider = new ComponentName(context, TalkOfDayWidgetProvider.class);
        int[] ids = manager.getAppWidgetIds(provider);

        if (ids.length > 0) {
            Intent intent = new Intent(context, TalkOfDayWidgetProvider.class);
            intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
            context.sendBroadcast(intent);
        }

        call.resolve();
    }
}
