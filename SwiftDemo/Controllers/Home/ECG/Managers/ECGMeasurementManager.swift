import Foundation
import AVFoundation
import YCProductSDK

/// Manages ECG measurement state and timing
final class ECGMeasurementManager {
    
    // MARK: - Constants
    private let ECG_MEASURE_TIME: Int = 60  // 60 seconds
    private let ECG_MEASURE_DATA_LIMIT_COUNT: Int = 2800
    private let ECG_HRV_LIMIT_VALUE: Double = 150.0
    
    // MARK: - Properties
    private(set) var isMeasuring = false
    private(set) var elapsedTime: Int = 0
    private var measurementTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    var onTimeUpdate: ((Int, Double) -> Void)?  // (seconds, progress)
    var onMeasurementComplete: (() -> Void)?
    
    // MARK: - Measurement Control
    func startMeasurement() {
        guard !isMeasuring else { return }
        
        isMeasuring = true
        elapsedTime = 0
        
        // Start SDK measurement
        YCProduct.startECGMeasurement { [weak self] state, response in
            if state == .succeed {
                print("[ECG] SDK measurement started successfully")
            } else {
                print("[ECG] SDK measurement start failed: \(String(describing: response))")
            }
        }
        
        // Start timer
        measurementTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        
        print("[ECG] Measurement started")
    }
    
    func stopMeasurement() {
        guard isMeasuring else { return }
        
        isMeasuring = false
        measurementTimer?.invalidate()
        measurementTimer = nil
        
        YCProduct.stopECGMeasurement { state, response in
            if state == .succeed {
                print("[ECG] SDK measurement stopped successfully")
            } else {
                print("[ECG] SDK measurement stop failed: \(String(describing: response))")
            }
        }
        
        print("[ECG] Measurement stopped")
    }
    
    private func handleTimerTick() {
        elapsedTime += 1
        let progress = Double(elapsedTime) / Double(ECG_MEASURE_TIME)
        
        onTimeUpdate?(elapsedTime, progress)
        
        // Auto-complete after 60 seconds
        if elapsedTime >= ECG_MEASURE_TIME {
            stopMeasurement()
            onMeasurementComplete?()
        }
    }
    
    // MARK: - Audio
    func playHeartbeatSound() {
        guard let soundPath = Bundle.main.path(forResource: "ecg_tip", ofType: "m4a") else {
            print("[ECG] Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundPath))
            audioPlayer?.play()
        } catch {
            print("[ECG] Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Results
    func getMeasurementResult(deviceHR: Int?, deviceHRV: Int?, completion: @escaping (YCECGMeasurementResult) -> Void) {
        let ecgManager = YCECGManager()
        ecgManager.getECGMeasurementResult(deviceHeartRate: deviceHR, deviceHRV: deviceHRV) { result in
            print("[ECG] Result: HR=\(result.hearRate), HRV=\(result.hrv), Type=\(result.ecgMeasurementType.rawValue)")
            completion(result)
        }
    }
    
    // MARK: - Cleanup
    deinit {
        stopMeasurement()
    }
}
