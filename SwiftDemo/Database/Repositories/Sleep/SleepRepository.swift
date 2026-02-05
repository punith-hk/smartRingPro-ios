import Foundation
import CoreData

class SleepRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save New Batch (with duplicate prevention)
    func saveNewBatch(sessions: [(statisticTime: Int64, startTime: Int64, endTime: Int64, totalTimes: Int32, deepSleepTimes: Int32, lightSleepTimes: Int32, remSleepTimes: Int32, wakeupTimes: Int32, details: [(startTime: Int64, endTime: Int64, duration: Int32, sleepType: Int16)])], completion: @escaping (Bool, Int) -> Void) {
        
        context.perform { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false, 0)
                }
                return
            }
            
            var savedCount = 0
            let batchTime = Int64(Date().timeIntervalSince1970 * 1000)
            let now = Date()
            
            // Load existing statisticTime values for duplicate prevention
            let existingTimes = self.getExistingStatisticTimes()
            
            for sessionData in sessions {
                // Skip if already exists
                if existingTimes.contains(sessionData.statisticTime) {
                    print("↩️ [SleepRepository] Session already exists: \(sessionData.statisticTime) - skipping")
                    continue
                }
                
                // Create session entity
                let sessionEntity = SleepSessionEntity(context: self.context)
                sessionEntity.id = UUID()
                sessionEntity.statisticTime = sessionData.statisticTime
                sessionEntity.startTime = sessionData.startTime
                sessionEntity.endTime = sessionData.endTime
                sessionEntity.totalTimes = sessionData.totalTimes
                sessionEntity.deepSleepTimes = sessionData.deepSleepTimes
                sessionEntity.lightSleepTimes = sessionData.lightSleepTimes
                sessionEntity.remSleepTimes = sessionData.remSleepTimes
                sessionEntity.wakeupTimes = sessionData.wakeupTimes
                sessionEntity.batchTime = batchTime
                sessionEntity.createdAt = now
                sessionEntity.updatedAt = now
                
                // Create detail entities
                for detailData in sessionData.details {
                    let detailEntity = SleepDetailEntity(context: self.context)
                    detailEntity.id = UUID()
                    detailEntity.startTime = detailData.startTime
                    detailEntity.endTime = detailData.endTime
                    detailEntity.duration = detailData.duration
                    detailEntity.sleepType = detailData.sleepType
                    detailEntity.session = sessionEntity
                }
                
                savedCount += 1
            }
            
            // Save context
            do {
                if self.context.hasChanges {
                    try self.context.save()
                    print("✅ [SleepRepository] Saved \(savedCount) new sleep sessions")
                    DispatchQueue.main.async {
                        completion(true, savedCount)
                    }
                } else {
                    print("ℹ️ [SleepRepository] No new sessions to save")
                    DispatchQueue.main.async {
                        completion(true, 0)
                    }
                }
            } catch {
                print("❌ [SleepRepository] Failed to save: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }
    }
    
    // MARK: - Get Existing StatisticTime Values
    private func getExistingStatisticTimes() -> Set<Int64> {
        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.propertiesToFetch = ["statisticTime"]
        
        do {
            let sessions = try context.fetch(fetchRequest)
            return Set(sessions.map { $0.statisticTime })
        } catch {
            print("❌ [SleepRepository] Failed to fetch existing statisticTimes: \(error.localizedDescription)")
            return Set()
        }
    }
    
    // MARK: - Get Sessions by Date Range
    func getByDateRange(startDate: Date, endDate: Date) -> [SleepSessionEntity] {
        let calendar = Calendar.current
        let startTimestamp = Int64(startDate.timeIntervalSince1970)
        let endTimestamp = Int64(endDate.timeIntervalSince1970)
        let maxGapBetweenSessions: Int64 = 12 * 60 * 60 // 12 hours
        
        // Fetch ALL sessions to analyze sleep groups
        let allSessionsRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        allSessionsRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        do {
            let allSessions = try context.fetch(allSessionsRequest)
            
            // Group sessions into sleep periods (sessions within 2 hours of each other)
            var sleepGroups: [[SleepSessionEntity]] = []
            var currentGroup: [SleepSessionEntity] = []
            
            for session in allSessions {
                if currentGroup.isEmpty {
                    currentGroup = [session]
                } else if let lastSession = currentGroup.last {
                    let gap = session.startTime - lastSession.endTime
                    if gap <= maxGapBetweenSessions {
                        currentGroup.append(session)
                    } else {
                        sleepGroups.append(currentGroup)
                        currentGroup = [session]
                    }
                }
            }
            if !currentGroup.isEmpty {
                sleepGroups.append(currentGroup)
            }
            
            // Find which group belongs to this day
            // A sleep group belongs to the day its LAST session ends on
            for group in sleepGroups {
                guard let lastSession = group.last else { continue }
                
                let endDate = Date(timeIntervalSince1970: TimeInterval(lastSession.endTime))
                if calendar.isDate(endDate, inSameDayAs: startDate) {
                    print("📊 [SleepRepository] Found sleep group with \(group.count) sessions ending on selected day")
                    return group
                }
            }
            
            print("📊 [SleepRepository] No sleep group ends on selected day")
            return []
        } catch {
            print("❌ [SleepRepository] Failed to fetch sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Get Sessions for Selected Date (Android pattern)
    func getSleepBySelectedDate(prevDateStart: Date, currDateEnd: Date) -> [SleepSessionEntity] {
        // This matches Android's getSleepBySelectedDate query
        // which checks if statisticTime falls between previous day start and current day end
        return getByDateRange(startDate: prevDateStart, endDate: currDateEnd)
    }
    
    // MARK: - Get All Sessions
    func getAllSessions() -> [SleepSessionEntity] {
        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "statisticTime", ascending: false)]
        
        do {
            let sessions = try context.fetch(fetchRequest)
            print("📊 [SleepRepository] Fetched \(sessions.count) total sessions")
            return sessions
        } catch {
            print("❌ [SleepRepository] Failed to fetch all sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Get Details for Session IDs
    func getDetailsBySessionIDs(sessionIDs: [UUID]) -> [SleepDetailEntity] {
        guard !sessionIDs.isEmpty else { return [] }
        
        let fetchRequest: NSFetchRequest<SleepDetailEntity> = SleepDetailEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session.id IN %@", sessionIDs)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        do {
            let details = try context.fetch(fetchRequest)
            print("📊 [SleepRepository] Fetched \(details.count) details for \(sessionIDs.count) sessions")
            return details
        } catch {
            print("❌ [SleepRepository] Failed to fetch details: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Delete All Sessions (and cascade delete details)
    func deleteAll(completion: @escaping (Bool) -> Void) {
        context.perform { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SleepSessionEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try self.context.execute(deleteRequest)
                try self.context.save()
                print("✅ [SleepRepository] Deleted all sleep sessions")
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("❌ [SleepRepository] Failed to delete all: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete Details for Session
    func deleteDetailsForSession(sessionID: UUID, completion: @escaping (Bool) -> Void) {
        context.perform { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SleepDetailEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "session.id == %@", sessionID as CVarArg)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try self.context.execute(deleteRequest)
                try self.context.save()
                print("✅ [SleepRepository] Deleted details for session: \(sessionID)")
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("❌ [SleepRepository] Failed to delete details: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Get Session Count
    func getSessionCount() -> Int {
        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("❌ [SleepRepository] Failed to get session count: \(error.localizedDescription)")
            return 0
        }
    }
}
