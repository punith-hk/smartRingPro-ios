import Foundation
import YCProductSDK

/// Handles ECG data processing and algorithm integration
final class ECGDataProcessor {
    
    // MARK: - Properties
    private var ecgManager: YCECGManager!
    private var ecgDataCount: Int = 0
    private var previousData: Float = 0
    private var previousPreviousData: Float = 0
    private let ECG_CELL_SIZE: Double = 6.25
    private let ECG_HRV_LIMIT_VALUE: Int = 150
    private let FILL_DATA_COUNT: Int = 50  // Reduced from 250 to show data faster (~0.6s vs 3s delay)
    
    // Drawing animation
    private var drawLineDatas: [Int] = []
    private var drawLineIndex: Int = 0
    private var drawLineTimer: Timer?
    private let SCREEN_WIDTH = UIScreen.main.bounds.width
    
    // Electrode status tracking
    private var isReceivingECGData: Bool = false
    private var lastDataReceivedTime: Date?
    private var electrodeStatusTimer: Timer?
    
    // Device value priority flags
    private var hasReceivedDeviceHR: Bool = false
    private var hasReceivedDeviceHRV: Bool = false
    
    var onHRUpdate: ((Int) -> Void)?
    var onBPUpdate: ((Int, Int) -> Void)?  // systolic, diastolic
    var onHRVUpdate: ((Int) -> Void)?
    var onDrawECGValue: ((Int) -> Void)?  // For progressive drawing
    var onHeartbeat: (() -> Void)?
    var onElectrodeStatusChange: ((Bool) -> Void)?
    var onBloodOxygenUpdate: ((Int) -> Void)?
    var onTemperatureUpdate: ((Double) -> Void)?
    var onRRIntervalUpdate: ((Float) -> Void)?
    
    // MARK: - Data Processing
    func processRealTimeNotificationData(_ userInfo: [AnyHashable: Any]) {
        // Process blood pressure data (includes HR, BP, HRV, O2, temp)
        if let healthData = (userInfo[YCReceivedRealTimeDataType.bloodPressure.string] as? YCReceivedDeviceReportInfo)?.data as? YCReceivedRealTimeBloodPressureInfo {
            
            let hr = healthData.heartRate
            let systolic = healthData.systolicBloodPressure
            let diastolic = healthData.diastolicBloodPressure
            let hrv = healthData.hrv
            let bloodOxygen = healthData.bloodOxygen
            let temperature = healthData.temperature
            
            print("[ECG] 📡 Real-time BP data received: HR=\(hr), BP=\(systolic)/\(diastolic), HRV=\(hrv), O2=\(bloodOxygen), Temp=\(temperature)")
            
            if hr > 0 {
                hasReceivedDeviceHR = true
                print("[ECG] 🔒 Device HR priority locked - algorithm updates disabled")
                onHRUpdate?(hr)
            }
            
            if systolic > 0 && diastolic > 0 {
                onBPUpdate?(systolic, diastolic)
            }
            
            if hrv > 0 && hrv <= ECG_HRV_LIMIT_VALUE {
                hasReceivedDeviceHRV = true
                print("[ECG] 🔒 Device HRV priority locked - algorithm updates disabled")
                onHRVUpdate?(hrv)
            }
            
            if bloodOxygen > 0 {
                onBloodOxygenUpdate?(bloodOxygen)
            }
            
            if temperature > 0 {
                onTemperatureUpdate?(temperature)
            }
        } else {
            // Log when BP data is NOT present in notification
            print("[ECG] ⚠️ No BP data in notification - only ECG waveform")
        }
        
        // Process ECG waveform data
        if let ecgData = (userInfo[YCReceivedRealTimeDataType.ecg.string] as? YCReceivedDeviceReportInfo)?.data as? [Int32] {
            parseECGData(ecgData)
        }
    }
    
    private func parseECGData(_ datas: [Int32]) {
        // Mark that we're receiving data
        if !isReceivingECGData {
            isReceivingECGData = true
            onElectrodeStatusChange?(true)
            print("[ECG] Electrode connected - data flowing")
        }
        
        lastDataReceivedTime = Date()
        
        for data in datas {
            var ecgValue: Float = 0
            
            // Process through algorithm
            ecgValue = ecgManager.processECGData(Int(data))
            
            // Average every 3 samples for smoother rendering
            if (ecgDataCount % 3) == 0 {
                let tempEcgData = (ecgValue + previousData + previousPreviousData) / 3.0
                
                // Convert to drawing value: tempEcgData / 4000 * CELL_SIZE
                var drawData = Int(Double(tempEcgData) / 4000.0 * ECG_CELL_SIZE)
                let limitValue = Int(ECG_CELL_SIZE * 20)
                
                if drawData > limitValue {
                    drawData = limitValue
                } else if drawData < -limitValue {
                    drawData = -limitValue
                }
                
                // Start drawing timer when first data arrives
                if drawLineDatas.isEmpty {
                    startDrawLineTimer()
                    startElectrodeStatusMonitor()
                }
                
                // Fill initial buffer with zeros (creates starting delay)
                if drawLineDatas.count < FILL_DATA_COUNT {
                    drawLineDatas.append(0)
                } else {
                    drawLineDatas.append(drawData)
                }
            }
            
            previousPreviousData = previousData
            previousData = ecgValue
            ecgDataCount += 1
        }
    }
    
    // MARK: - Drawing Animation
    private func startDrawLineTimer() {
        // Timer interval: 1/250 * 3 seconds (matches ECG sample rate)
        drawLineTimer = Timer.scheduledTimer(
            timeInterval: 1.0 / 250.0 * 3,
            target: self,
            selector: #selector(drawECGLine),
            userInfo: nil,
            repeats: true
        )
        drawLineIndex = 0
        print("[ECG] Draw line timer started")
    }
    
    @objc private func drawECGLine() {
        // Distance between points: 0.1 cell * CELL_SIZE * 3 samples
        let distance = ECG_CELL_SIZE * 0.1 * 3
        let datasCount = drawLineDatas.count
        
        guard drawLineIndex < datasCount else { return }
        
        let data = drawLineDatas[drawLineIndex]
        onDrawECGValue?(data)
        
        drawLineIndex += 1
    }
    
    private func stopDrawLineTimer() {
        drawLineTimer?.invalidate()
        drawLineTimer = nil
        print("[ECG] Draw line timer stopped")
    }
    
    // MARK: - Electrode Status Monitoring
    private func startElectrodeStatusMonitor() {
        // Check electrode status every 0.2 seconds for faster response
        electrodeStatusTimer = Timer.scheduledTimer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(checkElectrodeStatus),
            userInfo: nil,
            repeats: true
        )
        print("[ECG] Electrode status monitor started")
    }
    
    @objc private func checkElectrodeStatus() {
        guard let lastTime = lastDataReceivedTime else {
            if isReceivingECGData {
                isReceivingECGData = false
                onElectrodeStatusChange?(false)
                print("[ECG] Electrode disconnected - no data")
            }
            return
        }
        
        let timeSinceLastData = Date().timeIntervalSince(lastTime)
        
        // If no data received for more than 0.5 second, mark as disconnected (faster response)
        if timeSinceLastData > 0.5 {
            if isReceivingECGData {
                isReceivingECGData = false
                onElectrodeStatusChange?(false)
                print("[ECG] Electrode disconnected - timeout")
            }
        }
    }
    
    private func stopElectrodeStatusMonitor() {
        electrodeStatusTimer?.invalidate()
        electrodeStatusTimer = nil
        print("[ECG] Electrode status monitor stopped")
    }
    
    // MARK: - Algorithm Control
    func setupAlgorithm() {
        ecgManager = YCECGManager()
        
        // Setup with callbacks for RR interval and HRV
        ecgManager.setupManagerInfo { [weak self] rr, heartRate in
            guard let self = self else { return }
            
            // RR interval detected (heartbeat)
            print("[ECG] 💓 Algorithm: RR=\(rr) ms, HR=\(heartRate) bpm")
            
            // Update HR from algorithm ONLY if device value not received
            if heartRate > 0 && !self.hasReceivedDeviceHR {
                self.onHRUpdate?(heartRate)
            } else if heartRate > 0 && self.hasReceivedDeviceHR {
                print("[ECG] ⏭️  Algorithm HR ignored (device priority)")
            }
            
            // Store RR interval (always needed)
            self.onRRIntervalUpdate?(rr)
            
            // Play heartbeat sound
            self.onHeartbeat?()
            
        } hrv: { [weak self] hrv in
            guard let self = self else { return }
            
            // HRV calculated
            print("[ECG] 📊 Algorithm HRV calculated: \(hrv) ms")
            
            // Update HRV from algorithm ONLY if device value not received
            if !self.hasReceivedDeviceHRV {
                var finalHRV = hrv
                if hrv >= self.ECG_HRV_LIMIT_VALUE {
                    finalHRV = self.ECG_HRV_LIMIT_VALUE
                }
                self.onHRVUpdate?(finalHRV)
            } else {
                print("[ECG] ⏭️  Algorithm HRV ignored (device priority)")
            }
        }
        
        print("[ECG] Algorithm setup complete")
    }
    
    func resetAlgorithm() {
        ecgDataCount = 0
        previousData = 0
        previousPreviousData = 0
        drawLineDatas.removeAll()
        drawLineIndex = 0
        isReceivingECGData = false
        lastDataReceivedTime = nil
        hasReceivedDeviceHR = false
        hasReceivedDeviceHRV = false
        
        stopDrawLineTimer()
        stopElectrodeStatusMonitor()
        
        // Recreate manager for clean state
        setupAlgorithm()
        
        print("[ECG] Algorithm reset")
    }    
    // MARK: - Data Access
    func getCollectedECGData() -> [Int32] {
        // Return collected ECG data for report generation
        return []  // Will be implemented with proper storage
    }    
    // MARK: - Data Access
    var collectedDataCount: Int {
        return ecgDataCount
    }
    
    // MARK: - Cleanup
    deinit {
        stopDrawLineTimer()
        stopElectrodeStatusMonitor()
    }
}


