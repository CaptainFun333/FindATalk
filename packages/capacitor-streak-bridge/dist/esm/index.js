import { registerPlugin } from '@capacitor/core';
const StreakBridge = registerPlugin('StreakBridge', {
    web: () => import('./web').then((m) => new m.StreakBridgeWeb()),
});
export * from './definitions';
export { StreakBridge };
