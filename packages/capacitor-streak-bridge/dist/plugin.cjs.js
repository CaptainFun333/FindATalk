'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
const core = require('@capacitor/core');
class StreakBridgeWeb extends core.WebPlugin {
    async setStreak(_options) {
        // no-op on web — see dist/esm/web.js for the full explanation
    }
    async setThemePreference(_options) {
        // no-op on web
    }
    async setPalettePreference(_options) {
        // no-op on web
    }
}
const StreakBridge = core.registerPlugin('StreakBridge', {
    web: () => new StreakBridgeWeb(),
});
exports.StreakBridge = StreakBridge;
exports.StreakBridgeWeb = StreakBridgeWeb;
