import Foundation
import CoreData

/// Singleton Core Data manager (equivalent to Android's DatabaseProvider)
/// Manages the persistent container and provides database access
final class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private init() {
        print("🗄️ CoreDataManager initialized")
    }
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MannaHealData")

        // Enable lightweight migration so adding new attributes (e.g. tores) doesn't crash
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data failed to load: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Core Data store loaded: \(storeDescription.url?.lastPathComponent ?? "unknown")")
        }
        
        // Merge policy: Prefer in-memory changes over store
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving Support
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                let nserror = error as NSError
                print("❌ Core Data save error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveContextAsync(completion: ((Bool) -> Void)? = nil) {
        let context = persistentContainer.viewContext
        context.perform {
            if context.hasChanges {
                do {
                    try context.save()
                    print("✅ Core Data async save successful")
                    completion?(true)
                } catch {
                    print("❌ Core Data async save failed: \(error)")
                    completion?(false)
                }
            } else {
                print("ℹ️ No changes to save")
                completion?(true)
            }
        }
    }
    
    // MARK: - Background Context
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Delete All Data (for testing)
    
    func deleteAllData(for entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ All \(entityName) data deleted")
        } catch {
            print("❌ Failed to delete \(entityName) data: \(error)")
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Print database file location (for manual inspection)
    func printDatabaseLocation() {
        if let storeURL = persistentContainer.persistentStoreDescriptions.first?.url {
            print("📂 Database location: \(storeURL.path)")
            print("💡 Copy this path and open in DB Browser for SQLite")
            print("💡 Or use: sqlite3 '\(storeURL.path)'")
        }
    }
    
    /// Get count of records in an entity
    func getRecordCount(for entityName: String) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        do {
            let count = try context.count(for: fetchRequest)
            print("📊 \(entityName): \(count) records")
            return count
        } catch {
            print("❌ Failed to count \(entityName): \(error)")
            return 0
        }
    }
}
