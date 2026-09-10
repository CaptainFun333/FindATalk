import { WebPlugin } from '@capacitor/core';
// Web fallback: there is no widget to mirror to outside the native iOS
// app, so every method is a harmless no-op rather than a rejection —
// docs/index.html already gates every real call behind `platform ===
// 'ios'`, so this only exists so the plugin doesn't throw if that
// changes later or something calls it directly on web.
export class StreakBridgeWeb extends WebPlugin {
    async setStreak(_options) {
        // no-op on web
    }
    async setThemePreference(_options) {
        // no-op on web
    }
    async setPalettePreference(_options) {
        // no-op on web
    }
}
