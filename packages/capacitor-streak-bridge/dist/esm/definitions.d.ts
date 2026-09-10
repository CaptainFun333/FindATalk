export interface StreakBridgePlugin {
  /**
   * Mirrors the current streak JSON into the App Group UserDefaults the
   * TalkOfDayWidget extension reads from, and asks WidgetKit to reload it.
   * No-op on platforms other than iOS (there's no widget to mirror to).
   */
  setStreak(options: { json: string }): Promise<void>;
  /** Mirrors an explicit light/dark theme choice the same way. */
  setThemePreference(options: { theme: string }): Promise<void>;
  /** Mirrors a Color Palette choice the same way. */
  setPalettePreference(options: { palette: string }): Promise<void>;
}
