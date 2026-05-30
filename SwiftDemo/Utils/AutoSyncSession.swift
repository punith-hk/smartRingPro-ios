import Foundation

/// Tracks whether an automatic BLE sync has already been triggered in this
/// app session (since last kill/relaunch).
///
/// The flag lives purely in memory — it is never persisted to disk — so it
/// resets to `false` every time the app is freshly launched.
///
/// Rules:
///   - `hasTriggered = false` on every fresh launch
///   - Set to `true` the moment auto-sync fires (regardless of result)
///   - Stays `true` for the lifetime of the process; tab switches / background
///     / foreground cycles do NOT reset it
///   - Set `hasTriggered = false` back ONLY when the app is terminated
enum AutoSyncSession {
    /// Whether auto-sync has already fired once in this session.
    static var hasTriggered = false
}
