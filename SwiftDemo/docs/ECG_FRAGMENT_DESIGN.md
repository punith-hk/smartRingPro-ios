# ECG Fragment - Design & Implementation

**HEARTO App - Electrocardiogram Measurement & Analysis**  
**Fragment:** `EcgFragment.kt`  
**Measurement Fragment:** `EcgMeasureFragment.kt`  
**History Fragment:** `EcgHistoryFragment.kt`  
**Trend Fragment:** `EcgTrendFragment.kt`  
**AI Diagnose Fragment:** `EcgAiDiagnoseFragment.kt`  
**Layout:** `fragment_ecg.xml`, `fragment_ecg_measure.xml`, `fragment_ecg_history.xml`, `fragment_ecg_trend.xml`

---

## 📋 Overview

The ECG Fragment system provides comprehensive electrocardiogram measurement, visualization, history tracking, and trend analysis capabilities. It integrates with the smart ring for real-time ECG measurements, stores data locally in Room database, syncs with backend API, and provides AI-powered diagnostics. The system consists of multiple interconnected fragments providing measurement, history viewing, trend analysis, and detailed AI reports.

**Key Features:**
- **Main ECG Screen:** Latest ECG waveform, vital signs summary, start measurement
- **ECG Measurement:** Real-time 30-second ECG recording with live visualization
- **ECG History:** Complete list of past ECG recordings with timestamps
- **Trend Tracking:** Statistical analysis with Normal/Abnormal categorization
- **AI Diagnostics:** Automated ECG analysis with health insights
- **Local Storage:** Room database for offline access
- **Cloud Sync:** Automatic synchronization with backend API
- **Cardiograph Visualization:** Custom view for ECG waveform display

---

## 🎨 Design Architecture

### Fragment Structure

```
EcgFragment (Main Screen)
├── Latest ECG Summary Card
│   ├── Heart Rate
│   ├── Blood Pressure
│   ├── HRV
│   ├── ECG Score
│   └── Last Measurement Time
├── ECG Waveform Display (Cardiograph2View)
├── Start Measurement Button
├── ECG Trend Card (Navigation)
└── ECG History Section
    ├── History Heading (Navigation)
    └── Recent Records Preview (Collapsed)

EcgMeasureFragment (Measurement Screen)
├── Real-time Cardiograph Visualization
├── Progress Indicator (0-100%)
├── Live Vital Signs Display
│   ├── Heart Rate (BPM)
│   ├── Blood Pressure (mmHg)
│   └── HRV (ms)
├── Start/Stop Controls
└── Measurement Status Indicators

EcgHistoryFragment (History List)
├── Scrollable List Container
├── History Item Cards
│   ├── Timestamp
│   ├── ECG Preview Thumbnail
│   ├── Vital Signs
│   └── Action Buttons (View, AI Analysis)
└── Empty State

EcgTrendFragment (Trend Analysis)
├── Normal/Abnormal Tabs
├── Pie Chart (Distribution)
└── Trend List Items
    ├── Date + Time
    ├── ECG Score
    ├── Heart Rate
    └── Status Indicator
```

---

## 🎨 Main ECG Fragment Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│          ECG                        │  Background
│                                     │  #D9EDFF
│  ┌───────────────────────────────┐ │
│  │  Latest ECG Summary            │ │  Summary
│  │                                │ │  Card
│  │  ❤️ 75 bpm   🫀 120/80 mmHg   │ │  (White)
│  │  📈 45 ms    🎯 Score: 85     │ │
│  │  🕒 2 hours ago                │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │  ECG
│  │  ~~~∧∧∧~~~∧∧∧~~~∧∧∧~~~       │ │  Waveform
│  │                               │ │  Display
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │    Start ECG Measurement      │ │  Action
│  └───────────────────────────────┘ │  Button
│                                     │
│  ┌───────────────────────────────┐ │
│  │  📊 ECG Trend Tracking     ►  │ │  Trend
│  └───────────────────────────────┘ │  Card
│                                     │
│  ┌───────────────────────────────┐ │
│  │  📜 ECG History            ►  │ │  History
│  └───────────────────────────────┘ │  Header
│                                     │
└─────────────────────────────────────┘
```

---

## 🔧 Main ECG Fragment Components

### 1. Latest ECG Summary Card

**Purpose:** Display most recent ECG measurement vitals

**Components:**
- **Heart Rate:** 
  - **ID:** `heartRateValueText`
  - **Format:** "75 bpm"
  - **Icon:** ❤️
  
- **Blood Pressure:**
  - **ID:** `bpValueText`
  - **Format:** "120/80 mmHg"
  - **Icon:** 🫀
  
- **HRV (Heart Rate Variability):**
  - **ID:** `hrvValueText`
  - **Format:** "45 ms"
  - **Icon:** 📈
  
- **ECG Score:**
  - **ID:** `ecgScoreText`
  - **Format:** "85"
  - **Range:** 0-100
  
- **ECG Report Status:**
  - **ID:** `ecgReportStatus`
  - **Values:** "Normal", "Abnormal", "Needs Review"
  
- **Last Measurement Time:**
  - **ID:** `ecgLastTime`
  - **Format:** "2 hours ago", "Today at 2:15 PM"

**Data Binding:**
```kotlin
private fun bindEcgData(entry: EcgEntry) {
    heartRateValueText.text = "${entry.heartRate} bpm"
    bpValueText.text = "${entry.sbp}/${entry.dbp} mmHg"
    hrvValueText.text = "${entry.hrv} ms"
    ecgScoreText.text = entry.tores.toString()
    ecgReportStatus.text = if (entry.tores >= 70) "Normal" else "Abnormal"
    
    // Format timestamp
    val timeAgo = getRelativeTimeString(entry.timestamp)
    ecgLastTime.text = timeAgo
}
```

---

### 2. ECG Waveform Display (Cardiograph2View)

**Custom View:** `Cardiograph2View`

**Purpose:** Display ECG waveform visualization

**Specs:**
- **ID:** `cardiograph2View`
- **Type:** Custom Canvas-based view
- **Background:** White with grid lines
- **Waveform Color:** Red (#E53935)
- **Grid:** Light gray dotted lines
- **Height:** Wrap content (dynamic based on data)

**Data Format:**
- Input: `List<Int>` (ECG raw data points)
- Range: -500 to +500 (normalized)
- Sample Rate: ~250 Hz
- Display: Last 280 points (scrolling window)

**Binding:**
```kotlin
// Load latest ECG waveform
val displayList = if (entry.ecg.size > 280) {
    entry.ecg.takeLast(entry.ecg.size - 280)
} else {
    entry.ecg
}

cardiographView.setDatas(displayList, true)
cardiographView.invalidate()
```

---

### 3. Start Measurement Button

**Specs:**
- **ID:** `tv_start_button`
- **Text:** "Start ECG Measurement"
- **Style:** `@style/AppButton` (Blue rounded)
- **Width:** Match parent
- **Margin:** 16dp horizontal

**Action:**
```kotlin
tvStartEcg.setOnClickListener {
    (activity as HomeActivity).openFragment(
        EcgMeasureFragment(), 
        "ECG Measurement", 
        true
    )
}
```

**Navigation:**
- Opens `EcgMeasureFragment`
- Adds to back stack
- Toolbar title: "ECG Measurement"

---

### 4. ECG Trend Card

**Purpose:** Navigate to trend analysis screen

**Specs:**
- **ID:** `ecgTrendCard`
- **Layout:** CardView
- **Background:** White
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Padding:** 16dp

**Content:**
- **Icon:** 📊 (Chart icon)
- **Text:** "ECG Trend Tracking"
- **Arrow:** ► (Right arrow indicator)

**Action:**
```kotlin
ecgTrendCard.setOnClickListener {
    (activity as HomeActivity).openFragment(
        EcgTrendFragment(), 
        "ECG Trend Tracking", 
        true
    )
}
```

---

### 5. ECG History Section

**Purpose:** Navigate to full history list

**Components:**

**History Heading:**
- **ID:** `ecg_history_heading`
- **Text:** "ECG History"
- **Icon:** 📜
- **Arrow:** ► (Right arrow)
- **Clickable:** Yes

**History Arrow:**
- **ID:** `iv_ecg_history_arrow`
- **Drawable:** `baseline_arrow_forward_ios_24`
- **Size:** 20dp × 20dp
- **Tint:** Gray

**Action:**
```kotlin
val openHistory = View.OnClickListener {
    (activity as HomeActivity).openFragment(
        EcgHistoryListFragment(), 
        "ECG History", 
        true
    )
}
ecgHistoryHeading.setOnClickListener(openHistory)
ivEcgHistoryArrow.setOnClickListener(openHistory)
```

**Empty State:**
- **ID:** `tv_no_history`
- **Text:** "No ECG history available"
- **Visibility:** Visible when no records exist

---

## 📊 Data Flow & Synchronization

### Complete ECG Measurement & Sync Flow

```
[User Taps "Start ECG Measurement"]
    ↓
Navigate to EcgMeasureFragment
    ↓
Check BLE Connection
    ├─ Connected → Proceed
    └─ Not Connected → Show error
    ↓
ecgMeasureStart()
    ├─ Reset UI state
    ├─ Clear previous data
    ├─ Initialize MediaPlayer (vidio.mp3)
    └─ Set UI to measuring state
    ↓
openEcgMeasure()
    ↓
YCBTClient.appEcgTestStart(
    BleDataResponse,
    BleRealDataResponse
)
    ↓
[Real-time Data Stream - 30 seconds]
    ↓
BleRealDataResponse.onRealDataResponse()
    ├─ Receive ECG data points (List<Int>)
    ├─ Process every 3 points (normalize to -500 to +500)
    ├─ Add to drawLists
    ├─ Update cardiographView in real-time
    ├─ Update progress (0-100%)
    └─ Update live vitals (HR, BP, HRV)
    ↓
[Measurement Complete - 100%]
    ↓
Play completion sound (vidio.mp3)
    ↓
hrv_evt_handle(evt_type, params)
    ├─ evt_type == 3 → Final HRV value
    └─ Store HRV result
    ↓
Calculate ECG Score (Tores)
    ↓
saveData()
    ├─ 1. Save to Local Room Database
    │   ├─ Create EcgEntry object
    │   ├─ timestamp: System.currentTimeMillis()
    │   ├─ ecg: List<Int> (raw data)
    │   ├─ heartRate: Int
    │   ├─ sbp: Int (Systolic BP)
    │   ├─ dbp: Int (Diastolic BP)
    │   ├─ hrv: Int
    │   ├─ tores: Int (ECG score)
    │   └─ repository.insert(ecgEntry)
    │
    ├─ 2. Upload to API
    │   ├─ Convert data to JSON
    │   ├─ POST /ecg_records
    │   ├─ Body: {
    │   │     "user_id": 123,
    │   │     "timestamp": 1716450900,
    │   │     "heart_rate": 75,
    │   │     "systolic": 120,
    │   │     "diastolic": 80,
    │   │     "hrv": 45,
    │   │     "ecg_score": 85,
    │   │     "ecg_data": "[12,15,18,...,250]",
    │   │     "status": "completed",
    │   │     "measurement_duration": 30
    │   │   }
    │   └─ Response: {
    │         "response": 0,
    │         "message": "ECG record saved successfully",
    │         "data": { "id": 456, ... }
    │       }
    │
    └─ 3. Update ConnectionPreferences
        ├─ saveLastEcgData()
        ├─ Update dashboard cache
        └─ Trigger dashboard refresh
    ↓
Show Success Dialog
    ├─ "Measurement Complete"
    ├─ Display final vitals
    └─ Options: [View AI Report] [Done]
    ↓
[If "View AI Report" tapped]
    ↓
Navigate to EcgAiDiagnoseFragment
    ├─ Pass timestamp parameter
    ├─ Load ECG data from local DB
    ├─ Run AI analysis
    └─ Display diagnostic results
    ↓
[Return to ECG Fragment]
    ↓
AutoSyncEcgHelper.startSync()
    ├─ Fetch local unsynced records
    ├─ Upload to API (if any pending)
    ├─ Fetch latest from API
    └─ Update local cache
    ↓
Refresh Main ECG Screen
    ├─ Update summary card
    ├─ Update waveform display
    ├─ Update history preview
    └─ Update last measurement time
```

---

## 🩺 ECG Measurement Fragment Design

### Visual Layout (Measuring State)

```
┌─────────────────────────────────────┐
│                                     │
│  ECG Measurement                    │
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │  Real-time
│  │  ~~~∧∧∧~~~∧∧∧~~~∧∧∧~~~       │ │  ECG
│  │  [Scrolling waveform]         │ │  Waveform
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  Progress: 45%                      │  Progress
│  ████████████░░░░░░░░░░░░░         │  Bar
│                                     │
│  ┌─────────┬─────────┬─────────┐  │
│  │ ❤️ HR   │ 🫀 BP   │ 📈 HRV  │  │  Live
│  │ 75 bpm  │ 120/80  │ 45 ms   │  │  Vitals
│  └─────────┴─────────┴─────────┘  │
│                                     │
│  ⭕ Stop Measurement                │  Stop
│                                     │  Button
│                                     │
│  ⚡ Keep finger on sensor           │  Status
│                                     │  Message
└─────────────────────────────────────┘
```

---

### Measurement States

#### State 1: Idle (Before Start)

**UI Elements:**
- **Start Button:** "Start ECG Test" (visible, enabled)
- **Progress Text:** Hidden
- **Stop Button:** Hidden
- **Waveform:** Empty/static baseline
- **Vitals:** All show "---"
- **Status:** "Place finger on sensor to begin"

#### State 2: Measuring (0-100%)

**UI Elements:**
- **Start Button:** Hidden
- **Progress Text:** "45%" (visible, updating)
- **Progress Bar:** Animated (0-100%)
- **Stop Button:** Visible, clickable
- **Waveform:** Scrolling in real-time
- **Vitals:** Updating live
- **Status:** "Measuring... Keep still"

**Progress Updates:**
```kotlin
// Update every 300ms
handler.post {
    count++ // 0 to 100
    progressBar.progress = count
    tvProgressText.text = "$count%"
    
    if (count >= 100) {
        // Measurement complete
        onMeasurementComplete()
    }
}
```

#### State 3: Complete (100%)

**UI Elements:**
- **Progress Text:** "100%" (green checkmark)
- **Stop Button:** Changes to "Done"
- **Waveform:** Final complete waveform
- **Vitals:** Final calculated values
- **Status:** "Measurement complete!"
- **Sound:** Play vidio.mp3 (completion sound)

#### State 4: Error

**UI Elements:**
- **All:** Reset to idle state
- **Toast:** "Measurement error. Please try again."
- **Waveform:** Cleared
- **Vitals:** Reset to "---"

---

### Real-time Data Processing

```kotlin
private fun openEcgMeasure() {
    YCBTClient.appEcgTestStart(
        object : BleDataResponse {
            override fun onDataResponse(code: Int, ratio: Float, hashMap: HashMap<*, *>?) {
                if (code == 0) {
                    Log.d(TAG, "ECG measurement started successfully")
                }
            }
        },
        object : BleRealDataResponse {
            override fun onRealDataResponse(code: Int, hashMap: HashMap<*, *>?) {
                // code == 0x01: ECG data points
                if (code == 1) {
                    val list = hashMap?.get("real_ecg_data") as? List<Int>
                    if (!list.isNullOrEmpty()) {
                        mEcgMeasureList.addAll(list)
                        person(list) // Process and normalize
                    }
                }
                
                // code == 0x02: Heart rate
                else if (code == 2) {
                    val hr = hashMap?.get("real_heart_rate") as? Int
                    hr?.let { updateHeartRate(it) }
                }
                
                // code == 0x03: Blood pressure
                else if (code == 3) {
                    val sbp = hashMap?.get("real_sbp") as? Int
                    val dbp = hashMap?.get("real_dbp") as? Int
                    if (sbp != null && dbp != null) {
                        updateBloodPressure(sbp, dbp)
                    }
                }
                
                // code == 0x04: HRV
                else if (code == 4) {
                    val hrv = hashMap?.get("real_hrv") as? Int
                    hrv?.let { updateHRV(it) }
                }
            }
        }
    )
}
```

**Data Normalization:**
```kotlin
private fun person(datas: List<Int>) {
    mEcgMeasureList.addAll(datas)
    var index = 0
    var value = 0
    
    for (data in datas) {
        value += data
        index++
        
        // Average every 3 points
        if (index % 3 == 0) {
            value = value / 40 / 3
            
            // Clamp to range [-500, 500]
            value = when {
                value > 500 -> 500
                value < -500 -> -500
                else -> value
            }
            
            drawLists.add(value)
            value = 0 // Reset
        }
    }
}
```

**Waveform Rendering:**
```kotlin
private var measureThread: Thread? = null

private fun makeStart() {
    measureThread = Thread {
        while (isStart) {
            try {
                Thread.sleep(12) // 12ms refresh rate (~83 FPS)
                
                if (index < drawLists.size) {
                    val currentData = drawLists[index]
                    
                    handler.post {
                        cardiographView?.addData(currentData)
                    }
                    
                    index++
                }
            } catch (e: Exception) {
                Log.e(TAG, "Rendering error: ${e.message}")
            }
        }
    }
    measureThread?.start()
}
```

---

### Save to Local Database

```kotlin
private fun saveData() {
    val timestamp = System.currentTimeMillis()
    
    // Create ECG entry
    val ecgEntry = EcgEntry(
        timestamp = timestamp,
        ecg = mEcgMeasureList, // Full raw data
        heartRate = currentHeartRate,
        sbp = currentSbp,
        dbp = currentDbp,
        hrv = currentHrv,
        tores = calculateEcgScore() // ECG quality score
    )
    
    // Save to Room database
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val repository = DatabaseProvider.provideEcgRepository(requireContext())
            repository.insert(ecgEntry)
            
            Log.i(TAG, "✅ ECG saved to local DB: timestamp=$timestamp")
            
            // Update UI on main thread
            withContext(Dispatchers.Main) {
                showSuccessDialog()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save ECG: ${e.message}")
        }
    }
}
```

**EcgEntry Data Model:**
```kotlin
@Entity(tableName = "ecg_records")
data class EcgEntry(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,
    
    val timestamp: Long,          // Measurement time (milliseconds)
    val ecg: List<Int>,           // Raw ECG data points
    val heartRate: Int,           // Heart rate (bpm)
    val sbp: Int,                 // Systolic blood pressure (mmHg)
    val dbp: Int,                 // Diastolic blood pressure (mmHg)
    val hrv: Int,                 // Heart rate variability (ms)
    val tores: Int,               // ECG score (0-100)
    val uploaded: Boolean = false // Sync status
)
```

---

### Upload to API

```kotlin
private fun uploadEcgToApi(ecgEntry: EcgEntry, onSuccess: (() -> Unit)? = null) {
    val repository = UserHealthDataRepository()
    
    // Convert ECG data to JSON string
    val ecgDataJson = Gson().toJson(ecgEntry.ecg)
    
    // Prepare API payload
    val requestBody = mapOf(
        "user_id" to userId,
        "timestamp" to ecgEntry.timestamp,
        "heart_rate" to ecgEntry.heartRate,
        "systolic" to ecgEntry.sbp,
        "diastolic" to ecgEntry.dbp,
        "hrv" to ecgEntry.hrv,
        "ecg_score" to ecgEntry.tores,
        "ecg_data" to ecgDataJson,
        "status" to "completed",
        "measurement_duration" to 30
    )
    
    // POST to API
    repository.uploadEcgRecord(requestBody)
        .enqueue(object : Callback<EcgRecordsPostResponse> {
            override fun onResponse(call, response) {
                if (response.isSuccessful) {
                    Log.i(TAG, "✅ ECG uploaded successfully")
                    
                    // Mark as uploaded in local DB
                    CoroutineScope(Dispatchers.IO).launch {
                        val dbRepository = DatabaseProvider.provideEcgRepository(requireContext())
                        dbRepository.markAsUploaded(ecgEntry.timestamp)
                    }
                    
                    onSuccess?.invoke()
                } else {
                    Log.e(TAG, "❌ ECG upload failed: ${response.errorBody()?.string()}")
                }
            }
            
            override fun onFailure(call, t) {
                Log.e(TAG, "❌ ECG upload error: ${t.message}")
            }
        })
}
```

**API Endpoint:**
```
POST https://hearto.in/api/ecg_records

Headers:
  Content-Type: application/json
  Authorization: Bearer <token>

Body:
{
    "user_id": 123,
    "timestamp": 1716450900,
    "heart_rate": 75,
    "systolic": 120,
    "diastolic": 80,
    "hrv": 45,
    "ecg_score": 85,
    "ecg_data": "[12,15,18,21,24,...,250]",
    "status": "completed",
    "measurement_duration": 30
}

Response (Success):
{
    "response": 0,
    "message": "ECG record saved successfully",
    "data": {
        "id": 456,
        "user_id": 123,
        "timestamp": 1716450900,
        "created_at": "2026-05-23T14:15:00.000000Z"
    }
}

Response (Error):
{
    "response": 1,
    "message": "Failed to save ECG record",
    "error": "Database error"
}
```

---

## 📜 ECG History Fragment Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │
│  ECG History                        │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 Today, 2:15 PM             │ │  History
│  │ ~~~∧∧∧~~~ (Preview)           │ │  Item 1
│  │ ❤️ 75 bpm  🫀 120/80  📈 45   │ │
│  │ 🎯 Score: 85  ✅ Normal        │ │
│  │ [View] [AI Analysis]          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 Yesterday, 10:30 AM        │ │  History
│  │ ~~~∧∧∧~~~ (Preview)           │ │  Item 2
│  │ ❤️ 78 bpm  🫀 125/82  📈 42   │ │
│  │ 🎯 Score: 82  ✅ Normal        │ │
│  │ [View] [AI Analysis]          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📅 May 21, 6:45 PM            │ │  History
│  │ ~~~∧∧∧~~~ (Preview)           │ │  Item 3
│  │ ❤️ 92 bpm  🫀 135/88  📈 35   │ │
│  │ 🎯 Score: 65  ⚠️ Abnormal     │ │
│  │ [View] [AI Analysis]          │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### History Item Card Components

**Container:**
- **Type:** CardView
- **Background:** White
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Margin:** 12dp horizontal, 8dp vertical
- **Padding:** 16dp

**Timestamp:**
- **Format:** "Today, 2:15 PM" or "May 21, 2026, 6:45 PM"
- **Size:** 14sp
- **Color:** #555555
- **Icon:** 📅

**ECG Preview:**
- **Type:** Miniature Cardiograph2View
- **Height:** 60dp
- **Width:** Match parent
- **Shows:** Last 100 points of ECG waveform

**Vitals Row:**
- **Heart Rate:** "❤️ 75 bpm"
- **Blood Pressure:** "🫀 120/80"
- **HRV:** "📈 45 ms"
- **Size:** 12sp
- **Layout:** Horizontal chips

**Score & Status:**
- **Score:** "🎯 Score: 85"
- **Status:** "✅ Normal" or "⚠️ Abnormal"
- **Color:** Green (#4CAF50) for Normal, Orange (#FF9800) for Abnormal

**Action Buttons:**

**View Button:**
- **Text:** "View"
- **Action:** Load full ECG waveform on main ECG screen
- **Icon:** 👁️

**AI Analysis Button:**
- **Text:** "AI Analysis"
- **Action:** Navigate to EcgAiDiagnoseFragment
- **Icon:** 🧠

---

### History Data Loading

```kotlin
private fun loadHistory() {
    viewLifecycleOwner.lifecycleScope.launch(Dispatchers.IO) {
        val repository = DatabaseProvider.provideEcgRepository(requireContext())
        val entries = repository.getAllWithIntList()
            .sortedByDescending { it.timestamp }
        
        withContext(Dispatchers.Main) {
            listContainer.removeAllViews()
            
            if (entries.isEmpty()) {
                tvEmpty.visibility = View.VISIBLE
                listContainer.visibility = View.GONE
            } else {
                tvEmpty.visibility = View.GONE
                listContainer.visibility = View.VISIBLE
                
                entries.forEach { entry ->
                    val itemView = createHistoryItemView(entry)
                    listContainer.addView(itemView)
                }
            }
        }
    }
}
```

**Empty State:**
- **Text:** "No ECG history available"
- **Icon:** 📊 (grayed out)
- **Message:** "Start your first ECG measurement to see history"

---

## 📊 ECG Trend Fragment Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │
│  ECG Trend Tracking                 │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Normal  │ Abnormal          │   │  Tab
│  └─────────────────────────────┘   │  Selector
│                                     │
│  ┌───────────────────────────────┐ │
│  │        Pie Chart              │ │  Distribution
│  │     ╱‾‾‾╲                     │ │  Chart
│  │    │ 85% │                    │ │  (Normal vs
│  │     ╲___╱                     │ │  Abnormal)
│  │  🟢 Normal: 85%               │ │
│  │  🟠 Abnormal: 15%             │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ May 23, 2:15 PM               │ │  Trend
│  │ 🎯 Score: 85  ❤️ 75 bpm      │ │  Item 1
│  │ ✅ Normal                     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ May 22, 10:30 AM              │ │  Trend
│  │ 🎯 Score: 82  ❤️ 78 bpm      │ │  Item 2
│  │ ✅ Normal                     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ May 21, 6:45 PM               │ │  Trend
│  │ 🎯 Score: 65  ❤️ 92 bpm      │ │  Item 3
│  │ ⚠️ Abnormal                   │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Trend Components

#### 1. Tab Selector

**Normal Tab:**
- **ID:** `tabNormal`
- **Text:** "Normal"
- **Selected:** White background
- **Unselected:** Transparent

**Abnormal Tab:**
- **ID:** `tabAbnormal`
- **Text:** "Abnormal"
- **Selected:** White background
- **Unselected:** Transparent

**Behavior:**
- Switch between Normal and Abnormal filtered lists
- Update pie chart on switch

---

#### 2. Pie Chart

**Library:** MPAndroidChart

**Specs:**
- **ID:** `pieChart`
- **Type:** PieChart
- **Colors:**
  - Normal: Green (#4CAF50)
  - Abnormal: Orange (#FF9800)

**Data:**
```kotlin
private fun setupPieChart(normalCount: Int, abnormalCount: Int) {
    val total = normalCount + abnormalCount
    if (total == 0) {
        pieChart.visibility = View.GONE
        return
    }
    
    val normalPercent = (normalCount.toFloat() / total * 100).toInt()
    val abnormalPercent = (abnormalCount.toFloat() / total * 100).toInt()
    
    val entries = listOf(
        PieEntry(normalPercent.toFloat(), "Normal"),
        PieEntry(abnormalPercent.toFloat(), "Abnormal")
    )
    
    val dataSet = PieDataSet(entries, "").apply {
        colors = listOf(
            Color.parseColor("#4CAF50"), // Green
            Color.parseColor("#FF9800")  // Orange
        )
        valueTextSize = 14f
        valueTextColor = Color.WHITE
    }
    
    pieChart.data = PieData(dataSet)
    pieChart.description.isEnabled = false
    pieChart.legend.isEnabled = true
    pieChart.invalidate()
}
```

---

#### 3. Trend List Items

**Container:**
- **ID:** `trendListContainer`
- **Layout:** Vertical LinearLayout

**Item Card:**
- **Background:** White
- **Corner Radius:** 12dp
- **Elevation:** 2dp
- **Margin:** 8dp vertical
- **Padding:** 12dp

**Components:**
- **Date/Time:** "May 23, 2026, 2:15 PM"
- **Score:** "🎯 Score: 85"
- **Heart Rate:** "❤️ 75 bpm"
- **Status:** "✅ Normal" or "⚠️ Abnormal"

**Data Loading:**
```kotlin
private fun loadEcgData() {
    viewLifecycleOwner.lifecycleScope.launch(Dispatchers.IO) {
        val allEntries = repository.getAllWithIntList()
        
        // Categorize by score threshold (70)
        normalList = allEntries.filter { it.tores >= 70 }
            .sortedByDescending { it.timestamp }
        
        abnormalList = allEntries.filter { it.tores < 70 }
            .sortedByDescending { it.timestamp }
        
        withContext(Dispatchers.Main) {
            setupPieChart(normalList.size, abnormalList.size)
            
            // Show normal list by default
            displayTrendList(normalList)
        }
    }
}
```

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background (light blue) |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Text | `#000000` | Titles, values |
| Secondary Text | `#555555` | Timestamps, descriptions |
| Tertiary Text | `#888888` | Hints, placeholders |
| ECG Waveform | `#E53935` | Red waveform line |
| Progress Bar Filled | `#4CAF50` | Green progress |
| Progress Bar Unfilled | `#E0E0E0` | Gray background |
| Normal Status | `#4CAF50` | Green (Normal ECG) |
| Abnormal Status | `#FF9800` | Orange (Abnormal ECG) |
| Button Primary | `#15558D` | Blue action buttons |
| Grid Lines | `#E0E0E0` | Chart grid |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Screen Title | 22sp | Bold | Black |
| Card Title | 18sp | Bold | Black |
| Vital Value | 24sp | Bold | Black |
| Vital Label | 14sp | Normal | #555555 |
| ECG Score | 28sp | Bold | Black |
| Timestamp | 14sp | Normal | #555555 |
| Status Text | 16sp | Bold | Green/Orange |
| Progress Text | 18sp | Bold | Black |
| Button Text | 16sp | Bold | White |
| History Date | 14sp | Normal | #555555 |
| Trend Item Text | 14sp | Normal | Black |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 16dp |
| Card Margin | 12dp |
| Card Padding | 16dp |
| Card Corner Radius | 16dp |
| Card Elevation | 4dp |
| Button Margin | 16dp horizontal |
| Waveform Height | 180dp |
| Progress Bar Height | 8dp |
| History Item Margin | 8dp vertical |
| Trend Item Margin | 8dp vertical |
| Icon Size | 20dp × 20dp |

---

## 📱 User Experience Flows

### Flow 1: Complete ECG Measurement

```
User opens ECG Fragment
    ↓
Tap "Start ECG Measurement"
    ↓
Navigate to EcgMeasureFragment
    ↓
Check BLE connection
    ├─ Connected → Proceed
    └─ Not connected → Show error
    ↓
Display idle state
    ↓
User places finger on ring sensor
    ↓
Tap "Start ECG Test" button
    ↓
ecgMeasureStart() called
    ├─ Clear previous data
    ├─ Initialize audio
    ├─ Set UI to measuring state
    └─ Start progress timer
    ↓
openEcgMeasure() triggers BLE command
    ↓
[Real-time measurement - 30 seconds]
    ├─ ECG waveform updates (12ms refresh)
    ├─ Progress bar increases (0-100%)
    ├─ Live vitals update (HR, BP, HRV)
    └─ Status: "Measuring... Keep still"
    ↓
Progress reaches 100%
    ↓
Play completion sound (vidio.mp3)
    ↓
Calculate final ECG score (Tores)
    ↓
saveData() called
    ├─ 1. Save to Room database
    │   └─ Insert EcgEntry with full data
    │
    ├─ 2. Upload to API
    │   ├─ Convert to JSON
    │   ├─ POST /ecg_records
    │   └─ Mark as uploaded
    │
    └─ 3. Update cache
        └─ ConnectionPreferences.saveLastEcgData()
    ↓
Show success dialog
    ├─ Display final vitals
    └─ Options: [View AI Report] [Done]
    ↓
[If "View AI Report"]
    ↓
    Navigate to EcgAiDiagnoseFragment
    ├─ Load ECG from local DB
    ├─ Run AI analysis
    └─ Show diagnostic report
    ↓
[If "Done"]
    ↓
    Return to ECG Fragment
    ↓
UI refreshes
    ├─ Latest ECG summary updated
    ├─ Waveform displays new data
    └─ Last measurement time updated
```

---

### Flow 2: View ECG History

```
User on ECG Fragment
    ↓
Tap "ECG History" heading
    ↓
Navigate to EcgHistoryFragment
    ↓
loadHistory() called
    ├─ Query Room database
    ├─ Sort by timestamp (descending)
    └─ Load all ECG entries
    ↓
Display history list
    ├─ Each item shows:
    │   ├─ Timestamp
    │   ├─ ECG preview thumbnail
    │   ├─ Vital signs
    │   └─ Action buttons
    └─ Or empty state if no history
    ↓
[User taps "View" button]
    ↓
Load selected ECG entry
    ↓
Navigate back to ECG Fragment
    ↓
Display selected ECG
    ├─ Waveform updates
    ├─ Vitals update
    └─ Summary card updates
```

---

### Flow 3: AI Analysis

```
User on ECG History
    ↓
Tap "AI Analysis" button on any entry
    ↓
Navigate to EcgAiDiagnoseFragment
    ├─ Pass timestamp parameter
    └─ Show loading indicator
    ↓
Load ECG data from local DB
    ↓
Run AI analysis (via YCBTClient.AITools)
    ├─ Analyze waveform pattern
    ├─ Detect abnormalities
    ├─ Calculate health scores
    └─ Generate insights
    ↓
Display AI report
    ├─ Overall health status
    ├─ Detected conditions (if any)
    ├─ Risk assessment
    ├─ Recommendations
    └─ Detailed breakdown
    ↓
User reviews report
    ↓
[Optional] Share or export report
```

---

### Flow 4: Track Trends

```
User on ECG Fragment
    ↓
Tap "ECG Trend Tracking" card
    ↓
Navigate to EcgTrendFragment
    ↓
loadEcgData() called
    ├─ Load all ECG entries
    ├─ Categorize: Normal (≥70) / Abnormal (<70)
    └─ Calculate percentages
    ↓
Display trend screen
    ├─ Pie chart showing distribution
    ├─ Normal tab selected by default
    └─ List of normal ECG records
    ↓
[User taps "Abnormal" tab]
    ↓
Filter list to abnormal entries
    ↓
Display abnormal records
    ├─ Each shows timestamp + score + status
    └─ Tap to view details
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### Main ECG Fragment
- [ ] Latest ECG summary loads correctly
- [ ] Waveform displays properly
- [ ] Start measurement button works
- [ ] Trend card navigation works
- [ ] History heading navigation works
- [ ] Empty state displays when no history

#### ECG Measurement
- [ ] BLE connection check works
- [ ] Idle state displays correctly
- [ ] Start button initiates measurement
- [ ] Real-time waveform updates (12ms)
- [ ] Progress bar animates (0-100%)
- [ ] Live vitals update correctly
- [ ] Stop button halts measurement
- [ ] Completion sound plays
- [ ] Final vitals calculated correctly
- [ ] Local DB save successful
- [ ] API upload successful
- [ ] Success dialog displays
- [ ] AI report navigation works

#### ECG History
- [ ] History list loads from DB
- [ ] Items sorted by date (newest first)
- [ ] ECG preview thumbnails display
- [ ] Vital signs show correctly
- [ ] View button loads ECG
- [ ] AI Analysis button navigates
- [ ] Empty state displays when no data

#### ECG Trend
- [ ] Pie chart calculates correctly
- [ ] Normal/Abnormal tabs switch
- [ ] List filters by category
- [ ] Percentages display correctly
- [ ] Trend items show all data

---

### UI/UX Tests

#### Visual Design
- [ ] Background color correct (#D9EDFF)
- [ ] Cards have white background
- [ ] Waveform displays in red
- [ ] Progress bar green when complete
- [ ] Normal status shows green
- [ ] Abnormal status shows orange
- [ ] All icons visible
- [ ] Text sizes correct

#### States
- [ ] Idle state correct
- [ ] Measuring state correct
- [ ] Complete state correct
- [ ] Error state correct
- [ ] Loading states display
- [ ] Empty states display

#### Edge Cases
- [ ] BLE disconnection during measurement
- [ ] API failure (saves locally)
- [ ] Very long ECG waveform
- [ ] No history data
- [ ] Fragment destroyed during measurement
- [ ] Low battery during measurement

---

## 🚀 Future Enhancements

### 1. Multi-lead ECG
- Support for 12-lead ECG
- Enhanced diagnostic accuracy

### 2. Export ECG Data
- Export as PDF with waveform
- Share via email/apps

### 3. Comparison View
- Compare two ECG measurements
- Track improvement/decline

### 4. Alerts & Notifications
- Abnormal ECG detected
- Reminder for regular measurements

### 5. Integration with Doctors
- Share ECG with healthcare provider
- Telehealth consultation

---

**Document Version:** 1.0  
**Last Updated:** May 23, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

