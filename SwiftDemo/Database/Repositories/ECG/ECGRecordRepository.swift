import Foundation
import CoreData

/// ECG Record Repository
/// Handles all database operations for ECG records
class ECGRecordRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "ECGRecordRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save new ECG record
    func saveRecord(
        timestamp: String,
        heartRate: Int,
        sbp: Int,
        dbp: Int,
        hrv: Int,
        ecgList: [Int],
        diagnoseType: Int,
        isAfib: Bool,
        hrvIndex: Double,
        loadIndex: Double,
        pressureIndex: Double,
        bodyIndex: Double,
        bloodOxygen: Int,
        temperature: Double,
        tores: Int = 0,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("[\(TAG)] 💾 Saving ECG record: \(timestamp)")
        
        // Validate diagnoseType (should never be 0)
        guard diagnoseType != 0 else {
            print("[\(TAG)] ❌ Cannot save failed measurement (Type 0)")
            completion(false, "Failed measurement cannot be saved")
            return
        }
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            // Check if record already exists
            let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
            
            do {
                let existing = try backgroundContext.fetch(fetchRequest)
                if !existing.isEmpty {
                    print("[\(self.TAG)] ⚠️ Record already exists: \(timestamp)")
                    DispatchQueue.main.async {
                        completion(false, "Record already exists")
                    }
                    return
                }
                
                // Create new record
                _ = ECGRecordEntity.create(
                    timestamp: timestamp,
                    heartRate: heartRate,
                    sbp: sbp,
                    dbp: dbp,
                    hrv: hrv,
                    ecgList: ecgList,
                    diagnoseType: diagnoseType,
                    isAfib: isAfib,
                    hrvIndex: hrvIndex,
                    loadIndex: loadIndex,
                    pressureIndex: pressureIndex,
                    bodyIndex: bodyIndex,
                    bloodOxygen: bloodOxygen,
                    temperature: temperature,
                    tores: tores,
                    in: backgroundContext
                )
                
                // Save
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ ECG record saved successfully")
                
                DispatchQueue.main.async {
                    completion(true, nil)
                }
                
            } catch {
                print("[\(self.TAG)] ❌ Save failed: \(error)")
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all ECG records, sorted by timestamp (newest first)
    func fetchAllRecords(completion: @escaping ([ECGRecord]) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            let records = entities.map { ECGRecord(from: $0) }
            print("[\(TAG)] 📚 Fetched \(records.count) ECG records")
            completion(records)
        } catch {
            print("[\(TAG)] ❌ Fetch failed: \(error)")
            completion([])
        }
    }
    
    /// Fetch record by timestamp
    func fetchRecord(timestamp: String, completion: @escaping (ECGRecord?) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                completion(ECGRecord(from: entity))
            } else {
                completion(nil)
            }
        } catch {
            print("[\(TAG)] ❌ Fetch failed: \(error)")
            completion(nil)
        }
    }
    
    /// Fetch unsynced records (for API upload)
    func fetchUnsyncedRecords(completion: @escaping ([ECGRecord]) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSynced == false")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            let records = entities.map { ECGRecord(from: $0) }
            print("[\(TAG)] 🔄 Found \(records.count) unsynced records")
            completion(records)
        } catch {
            print("[\(TAG)] ❌ Fetch unsynced failed: \(error)")
            completion([])
        }
    }
    
    // MARK: - Update Operations
    
    /// Mark record as synced
    func markAsSynced(timestamp: String, completion: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                entity.isSynced = true
                try context.save()
                print("[\(TAG)] ✅ Marked as synced: \(timestamp)")
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("[\(TAG)] ❌ Mark synced failed: \(error)")
            completion(false)
        }
    }
    
    /// Mark record as unsynced
    func markAsUnsynced(timestamp: String, completion: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                entity.isSynced = false
                try context.save()
                print("[\(TAG)] ⚠️ Marked as unsynced: \(timestamp)")
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("[\(TAG)] ❌ Mark unsynced failed: \(error)")
            completion(false)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete record by timestamp
    func deleteRecord(timestamp: String, completion: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            print("[\(TAG)] 🗑️ Deleted record: \(timestamp)")
            completion(true)
        } catch {
            print("[\(TAG)] ❌ Delete failed: \(error)")
            completion(false)
        }
    }
    
    /// Delete all records (for testing)
    func deleteAllRecords(completion: @escaping (Bool) -> Void) {
        CoreDataManager.shared.deleteAllData(for: "ECGRecordEntity")
        completion(true)
    }
    
    /// Update the tores score for a record identified by timestamp
    func updateTores(timestamp: String, tores: Int, completion: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<ECGRecordEntity> = ECGRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", timestamp)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                entity.tores = Int16(tores)
                try context.save()
                print("[\(TAG)] ✅ Updated tores=\(tores) for \(timestamp)")
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("[\(TAG)] ❌ updateTores failed: \(error)")
            completion(false)
        }
    }
}
