import Foundation

/// Helper class to sync unsynced ECG records to the server
final class ECGSyncHelper {
    
    static let shared = ECGSyncHelper()
    private let ecgRepository = ECGRecordRepository()
    private let TAG = "ECGSyncHelper"
    
    private init() {}
    
    /// Sync ONE unsynced ECG record to the server (uploads one at a time)
    /// - Parameter completion: Called when sync completes (success indicates if record was uploaded)
    func syncUnsyncedRecords(completion: @escaping (Bool) -> Void) {
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            print("[\(TAG)] ⚠️ No user ID found, skipping sync")
            completion(false)
            return
        }
        
        // Fetch unsynced records
        ecgRepository.fetchUnsyncedRecords { [weak self] records in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard !records.isEmpty else {
                print("[\(self.TAG)] ✅ No unsynced records to upload")
                completion(true)
                return
            }
            
            // Upload only the FIRST unsynced record
            let recordToUpload = records[0]
            print("[\(self.TAG)] 📤 Found \(records.count) unsynced record(s), uploading 1st: \(recordToUpload.timestamp)")
            
            // Upload single record (still in array format as per API spec)
            HealthService.shared.uploadECGRecords(userId: userId, records: [recordToUpload]) { result in
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Upload successful: \(response.message)")
                    if let uploaded = response.data?.uploaded {
                        print("[\(self.TAG)] 📊 Uploaded \(uploaded) record(s)")
                    }
                    
                    // Mark this record as synced
                    self.ecgRepository.markAsSynced(timestamp: recordToUpload.timestamp) { success in
                        if success {
                            print("[\(self.TAG)] 🔄 Marked \(recordToUpload.timestamp) as synced")
                        }
                        completion(success)
                    }
                    
                case .failure(let error):
                    print("[\(self.TAG)] ❌ Upload failed: \(error)")
                    completion(false)
                }
            }
        }
    }
    

    
    /// Sync a specific ECG record by timestamp
    /// - Parameters:
    ///   - timestamp: The timestamp of the record to sync
    ///   - completion: Called when sync completes
    func syncRecord(timestamp: String, completion: @escaping (Bool) -> Void) {
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            print("[\(TAG)] ⚠️ No user ID found, skipping sync")
            completion(false)
            return
        }
        
        // Fetch the specific record
        ecgRepository.fetchRecord(timestamp: timestamp) { [weak self] record in
            guard let self = self, let record = record else {
                print("[\(self?.TAG ?? "ECGSyncHelper")] ❌ Failed to fetch record")
                completion(false)
                return
            }
            
            print("[\(self.TAG)] 📤 Uploading ECG record...")
            
            HealthService.shared.uploadECGRecords(userId: userId, records: [record]) { result in
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Upload successful: \(response.message)")
                    
                    // Mark as synced
                    self.ecgRepository.markAsSynced(timestamp: timestamp) { success in
                        if success {
                            print("[\(self.TAG)] 🔄 Marked as synced")
                        }
                        completion(success)
                    }
                    
                case .failure(let error):
                    print("[\(self.TAG)] ❌ Upload failed: \(error)")
                    completion(false)
                }
            }
        }
    }
}
