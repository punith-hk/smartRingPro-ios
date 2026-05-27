import BackgroundTasks

/// Manages BGAppRefreshTask for syncing health data while the app is minimized.
///
/// Flow:
///   App minimizes → scheduleNextSync() queues a BGAppRefreshTask
///   iOS wakes app in background at ~scheduled time
///   handleAppRefresh: check BLE connected + stale → sync → reschedule
///
/// Timing: fires at (healthInterval + 1 min) after last sync, then repeats.
/// Example (15 min): last sync 11:30 → fires ~11:46, ~12:01, ~12:16 …
final class BackgroundSyncTaskManager {

    static let shared = BackgroundSyncTaskManager()
    private init() {}

    static let taskIdentifier = "com.mannaheal.MannaHealPro.bgsync"

    // MARK: - Registration (call once in AppDelegate.didFinishLaunching)

    func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: refreshTask)
        }
        print("📱 BGTask: registered \(Self.taskIdentifier)")
    }

    // MARK: - Scheduling

    /// Schedule the next background sync.
    /// firstFireDelay: how many seconds from now the task should fire.
    /// Pass nil to auto-calculate from last sync + interval + 1 min buffer.
    func scheduleNextSync(firstFireDelay: TimeInterval? = nil) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)

        let intervalSecs = AppSettingsManager.shared.getHealthInterval().minuteValue * 60
        let bufferSecs: TimeInterval = 60

        let delay: TimeInterval
        if let custom = firstFireDelay {
            delay = custom
        } else {
            let lastSyncTs = UserDefaults.standard.double(forKey: "last_sync_timestamp")
            if lastSyncTs > 0 {
                let elapsed = Date().timeIntervalSince1970 - lastSyncTs
                let remaining = (intervalSecs + bufferSecs) - elapsed
                delay = max(bufferSecs, remaining)
            } else {
                delay = bufferSecs
            }
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: delay)

        do {
            try BGTaskScheduler.shared.submit(request)
            let mins = Int(delay / 60)
            let secs = Int(delay.truncatingRemainder(dividingBy: 60))
            print("📱 BGTask: next background sync in \(mins)m \(secs)s")
        } catch {
            print("❌ BGTask: failed to schedule — \(error.localizedDescription)")
        }
    }

    // MARK: - Task Handler

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Always reschedule the NEXT task first — so we don't miss if this run is cut short
        let intervalSecs = AppSettingsManager.shared.getHealthInterval().minuteValue * 60
        scheduleNextSync(firstFireDelay: intervalSecs + 60)

        // Expiration: iOS gives ~30 sec; mark done and let sync clean up
        task.expirationHandler = {
            print("⚠️ BGTask: expired — marking complete")
            task.setTaskCompleted(success: false)
        }

        // Guard: must be BLE connected (ring in range + paired)
        guard BLEStateManager.shared.isConnected else {
            print("📱 BGTask: BLE not connected — skipping")
            task.setTaskCompleted(success: true)
            return
        }

        // Guard: must be stale
        let intervalSeconds = AppSettingsManager.shared.getHealthInterval().minuteValue * 60
        let lastSyncTs = UserDefaults.standard.double(forKey: "last_sync_timestamp")
        let elapsed = lastSyncTs > 0 ? Date().timeIntervalSince1970 - lastSyncTs : Double.infinity
        guard elapsed >= intervalSeconds else {
            print("📱 BGTask: data is fresh (\(Int(elapsed / 60))m elapsed) — skipping")
            task.setTaskCompleted(success: true)
            return
        }

        // Guard: don't double-run if a foreground sync is already in progress
        guard !BackgroundSyncManager.shared.isSyncing else {
            print("📱 BGTask: sync already running — skipping")
            task.setTaskCompleted(success: true)
            return
        }

        print("📱 BGTask: starting background sync (elapsed \(Int(elapsed / 60))m)")
        BackgroundSyncManager.shared.startFullSync { success in
            if success {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sync_timestamp")
                print("📱 BGTask: sync completed ✅")
            } else {
                print("📱 BGTask: sync failed ❌")
            }
            task.setTaskCompleted(success: success)
        }
    }
}
