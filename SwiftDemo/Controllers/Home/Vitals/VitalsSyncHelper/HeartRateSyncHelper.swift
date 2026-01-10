import UIKit
import YCProductSDK

class HeartRateSyncHelper {
    
    protocol HeartRateSyncListener: AnyObject {
        func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate])
        func onSyncFailed(error: String)
    }
    
    private weak var listener: HeartRateSyncListener?
    private let TAG = "HeartRateSyncHelper"
    
    init(listener: HeartRateSyncListener) {
        self.listener = listener
    }
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            print("[\(TAG)] ❌ No BLE device connected, skipping heart rate sync")
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        
        print("[\(TAG)] 🟢 Starting heart rate sync from BLE device")
        fetchHeartRateFromRing()
    }
    
    private func fetchHeartRateFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.heartRate) { [weak self] state, datas in
            guard let self = self else { 
                print("[HeartRateSyncHelper] ⚠️ Self is nil in completion handler")
                return 
            }
            
            print("[\(self.TAG)] 🔵 Completion handler called")
            print("[\(self.TAG)] 📦 State received: \(state)")
            print("[\(self.TAG)] 📦 Data type: \(type(of: datas))")
            print("[\(self.TAG)] 📦 Data: \(String(describing: datas))")
            
            switch state {
            case .succeed:
                print("[\(self.TAG)] ✅ State is .succeed")
                if let heartRateDatas = datas as? [YCHealthDataHeartRate] {
                    print("[\(self.TAG)] ✅ Successfully cast to [YCHealthDataHeartRate], count: \(heartRateDatas.count)")
                    self.processHeartRateData(heartRateDatas)
                } else {
                    print("[\(self.TAG)] ❌ Failed to cast data to [YCHealthDataHeartRate]")
                    print("[\(self.TAG)] ❌ Actual data type: \(type(of: datas))")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No heart rate data found on device")
                self.listener?.onHeartRateDataFetched([])
            case .unavailable:
                print("[\(self.TAG)] ⚠️ Heart rate data unavailable")
                self.listener?.onSyncFailed(error: "Data unavailable")
            case .failed:
                print("[\(self.TAG)] ❌ Failed to fetch heart rate data")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                print("[\(self.TAG)] ❓ Unknown state received: \(state)")
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processHeartRateData(_ datas: [YCHealthDataHeartRate]) {
        print("[\(TAG)] 📊 Total entries fetched: \(datas.count)")
        
        // Notify listener with all data
        listener?.onHeartRateDataFetched(datas)
        
        // Print last 5 entries for debugging
        if !datas.isEmpty {
            printLast5Entries(datas)
        }
        
        // Phase 2: Later we'll compare timestamps and sync to API
        // Phase 3: Later we'll use local DB for deduplication
    }
    
    private func printLast5Entries(_ datas: [YCHealthDataHeartRate]) {
        let last5 = Array(datas.suffix(5))
        print("[\(TAG)] 🔥 Last 5 Heart Rate Entries:")
        for (index, entry) in last5.enumerated() {
            print("  \(index + 1). \(entry.toString)")
        }
    }
}
