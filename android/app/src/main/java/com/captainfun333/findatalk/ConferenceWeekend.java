package com.captainfun333.findatalk;

import java.util.Calendar;

/**
 * Port of isConferenceDay() in docs/index.html — keep in sync (and with
 * TalkStore.isConferenceDay in TalkModel.swift and functions/totd.js).
 *
 * General Conference is the first Sunday of April and of October plus the
 * Saturday before it, which can land on the last day of March or
 * September. On those days there is no Talk of the Day: the app shows an
 * "Are you participating in General Conference today?" card instead
 * (idea 87), and the home-screen widget follows suit.
 *
 * Plain java.util only, no Android classes, so the rule can be compiled
 * and checked on its own.
 */
final class ConferenceWeekend {

    private ConferenceWeekend() {}

    static boolean isConferenceDay(Calendar cal) {
        int dayOfWeek = cal.get(Calendar.DAY_OF_WEEK);
        Calendar sunday = (Calendar) cal.clone();
        if (dayOfWeek == Calendar.SATURDAY) {
            sunday.add(Calendar.DAY_OF_MONTH, 1);
        } else if (dayOfWeek != Calendar.SUNDAY) {
            return false;
        }
        int month = sunday.get(Calendar.MONTH);
        return (month == Calendar.APRIL || month == Calendar.OCTOBER)
            && sunday.get(Calendar.DAY_OF_MONTH) <= 7;
    }
}
