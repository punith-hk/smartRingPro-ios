# Steps Fragment - Design & Implementation

**HEARTO App - Steps Counter & Activity Tracker**  
**Fragment:** `StepsFragment.kt`  
**Layout:** `fragment_steps.xml`  
**Helper:** `AutoSyncStepsHelper.kt`

---

## 📋 Overview

The Steps Fragment provides comprehensive step tracking and activity monitoring with visual progress indicators, distance calculation, and goal tracking. It features interactive bar charts with three time-range views (Day/Week/Month), real-time synchronization from the smart ring, and historical trend analysis. Steps data is the foundation for calories burned calculation and overall activity assessment.

**Key Features:**
- Three view modes: Day, Week, Month
- Progress bar with customizable daily goal
- Real-time ring data synchronization  
- Distance calculation (steps → kilometers)
- Interactive bar charts with touch selection
- Historical data from local database and API
- Zoomable and scrollable daily charts
- Range summary with distance for week/month
- Goal achievement tracking

---

## 🎨 Design Architecture

### Screen Structure

```
ScrollView (Full Height)
└── RelativeLayout
    ├── Title: "Steps"
    ├── Tab Container (Day | Week | Month)
    ├── Chart Card
    │   ├── Date Navigation (◄ Date ►)
    │   ├── Selected Point Display (Time + Value)
    │   └── Bar Chart (Dynamic: Daily/Weekly/Monthly)
    ├── Range Summary Card (Week/Month only)
    │   ├── Total Steps
    │   ├── Distance Covered
    │   └── Walking Icon
    └── Today's Steps Card
        ├── Label + Value + Target
        ├── Progress Bar (Goal %)
        ├── Distance Covered
        └── Running Emoji Icon
```

---

## 🎨 Screen Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│          Steps                      │  Background
│                                     │  #D9EDFF
│  ┌─────────────────────────────┐   │
│  │  Day  │ Week │ Month         │   │  Tab
│  └─────────────────────────────┘   │  Container
│                                     │
│  ┌───────────────────────────────┐ │
│  │  ◄  2025.01.03  ►             │ │  White
│  │       12:30                   │ │  Chart
│  │       450 steps               │ │  Card
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  Bar
│  │  │ ▂▃▅▇█▇▅▃▂▃▄▅▆▅▄▃▂      │ │ │  Chart
│  │  └─────────────────────────┘ │ │  (Green)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │  Range
│  │ 03-09 Mar Steps               │ │  Card
│  │ 68,500 steps          👣     │ │  (Week/
│  │ ─────────────────────         │ │  Month)
│  │ Distance Covered              │ │
│  │ 51.38 KM                      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Today's Steps                 │ │  Summary
│  │ 8,450 / 10000 target    🏃   │ │  Card
│  │ ████████████████░░░░░░        │ │  with
│  │ ─────────────────────         │ │  Progress
│  │ Distance Covered              │ │  & 
│  │ 6.34 KM                       │ │  Distance
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Data Flow & Synchronization

### Data Sources

#### 1. Smart Ring (Real-time)
```kotlin
YCBTClient.collectData { sportData ->
    // Receives steps data from ring
    // Stored in local DB (Sport Entity)
    // Synced to API
}
```

**Ring Data:**
- Steps counted per measurement session
- Timestamp of measurement
- Accumulated throughout the day

#### 2. Local Database
```kotlin
DatabaseProvider.provideSportRepository()
    .getAllData() // Get all local steps records
```

**Local Storage:**
- Sport entity with steps data
- Serves as cache for offline access
- Updated by ring sync
- Synced to API when online

#### 3. API (Cloud Storage)
```kotlin
// Endpoint 1: Get all steps records
GET /ring_data_by_type/{userId}?type=steps&page=1&limit=1000

// Endpoint 2: Get daily aggregated data  
GET /user_health_data_by_day/{userId}/steps

// Endpoint 3: Upload steps data
POST /add_user_health_data
Body: {
    "user_id": 123,
    "type": "steps",
    "value": "450",
    "created_at": "2026-05-23T14:30:00.000000Z"
}
```

**API Data:**
- Historical records (all entries)
- Daily aggregated totals
- Shared across devices
- Persistent storage

#### 4. ConnectionPreferences (Today's Totals)
```kotlin
ConnectionPreferences.loadTodayTotals(context)
// Returns: (steps: Int, calories: Int, distance: Double)
```

**Cached Today Data:**
- Steps count
- Calories burned
- Distance covered
- Updated after each ring sync
- Used for instant display

---

### Complete Sync Flow

```
Ring Measurement (Steps Detected)
    ↓
Sport Data Collected (YCBTClient)
    ↓
Local Database Update (SportRepository)
    ├─ Insert new steps entry
    ├─ Store timestamp
    └─ Cache data
    ↓
AutoSyncStepsHelper Triggered
    ├─ fetchLocalStepsData()
    │   ├─ Query local DB
    │   ├─ Filter steps records
    │   └─ Convert to API format
    │
    ├─ startSync() [Upload to API]
    │   ├─ For each local entry
    │   ├─ POST /add_user_health_data
    │   ├─ Mark as synced
    │   └─ Update API
    │
    └─ fetchAndSyncSportDaily("steps")
        ├─ GET /user_health_data_by_day/{userId}/steps
        ├─ Receive daily aggregates
        └─ Store for week/month charts
    ↓
ConnectionPreferences Update
    ├─ Calculate today's total steps
    ├─ Calculate distance (steps × 0.00075)
    ├─ Calculate calories (from steps)
    └─ saveTodayTotals(steps, calories, distance)
    ↓
Fragment UI Update
    ├─ Daily chart (per-entry bars)
    ├─ Weekly chart (daily totals)
    ├─ Monthly chart (daily totals)
    ├─ Progress bar (% of goal)
    ├─ Today's total display
    └─ Distance calculation
    ↓
User Sees Updated Data
```

---

## 🔄 API Call Flow Details

### Flow 1: Initial Data Load

```
Fragment onViewCreated()
    ↓
fetchStepsHistoryFromHelper()
    ↓
AutoSyncStepsHelper created with listener
    ↓
helper.fetchLocalStepsData()
    ↓
    [Background Coroutine]
    DatabaseProvider.provideSportRepository(context)
    ↓
    repository.getAllData()
    ↓
    Filter: sport.steps > 0
    ↓
    Convert timestamps to ISO 8601 format
    ↓
    Map to GetUserHealthData objects
    ↓
    [Main Thread]
    onLocalStepsDataFetched(data)
    ↓
    stepsDataList = data
    ↓
    showSportSummaryFromSavedData()
        ├─ ConnectionPreferences.loadTodayTotals()
        ├─ Update stepsValueText
        ├─ Update distanceValueText
        ├─ Update progress bar
        └─ Display current values
    ↓
    selectedDateStepsDataList()
        ├─ Filter by selected date
        ├─ Update chart
        └─ Update selected point display
```

---

### Flow 2: Ring Sync & Upload

```
helper.startSync()
    ↓
[Background Coroutine]
    ↓
For each unsynced local entry:
    ↓
    Prepare API payload:
    {
        "user_id": 123,
        "type": "steps",
        "value": "450",
        "created_at": "2026-05-23T14:30:00.000000Z"
    }
    ↓
    POST /add_user_health_data
    ↓
    [API Response]
    {
        "response": 0,
        "message": "Health data added successfully",
        "data": { ... }
    }
    ↓
    If successful (response == 0):
        ├─ Mark entry as synced in local DB
        └─ Continue to next entry
    ↓
    If failed:
        ├─ Log error
        ├─ Keep entry as unsynced
        └─ Retry on next sync
    ↓
All entries processed
    ↓
[Main Thread]
onNewStepsUploaded() callback
    ↓
Log: "✅ Steps synced successfully"
```

---

### Flow 3: Fetch Daily Aggregates

```
helper.fetchAndSyncSportDaily("steps")
    ↓
[Background Coroutine]
    ↓
GET /user_health_data_by_day/{userId}/steps
    ↓
[API Response]
{
    "response": 0,
    "data": [
        {
            "v_date": "2026-05-20",
            "value": 12450.0
        },
        {
            "v_date": "2026-05-21", 
            "value": 10890.0
        },
        ...
    ]
}
    ↓
Parse response
    ↓
Filter: Remove invalid data (value > 100,000)
    ↓
Store in stepsDataByDayList
    ↓
[Main Thread]
onSportDailyFetched(type, data)
    ↓
If type == "steps":
    ├─ stepsDataByDayList = data
    ├─ Clean invalid values (> 100k → 0)
    ├─ selectedWeekStepsDataList()
    │   ├─ Filter by week range
    │   └─ Update weekly chart
    └─ selectedMonthStepsDataList()
        ├─ Filter by month range
        └─ Update monthly chart
```

---

### Flow 4: Background Worker Integration

```
PeriodicWorkManager (Every 15 minutes)
    ↓
RingDataSyncWorker.doWork()
    ↓
Check BLE connection
    ↓
If connected:
    ↓
    Fetch latest ring data
    ↓
    Store in local DB
    ↓
    AutoSyncStepsHelper.startSync()
        ↓
        Upload to API
        ↓
        Update ConnectionPreferences
        ↓
        EventBus.post(StepsUpdatedEvent)
    ↓
Fragment receives event (if open)
    ↓
Refresh UI with latest data
```

---

## 🎯 View Modes

### Mode 1: Day View (Default)

**Display:**
- Bar chart with hourly data points
- X-axis: 00:00 to 24:00
- Y-axis: Steps count
- Bars: Green (#4CAF50)
- Zoomable and scrollable

**Data Source:**
- `stepsDataList` (per-entry records from local DB)
- Filtered by selected date
- Each bar = steps at specific time

**Features:**
- Zoom to see 30-minute intervals
- Pan to see full 24-hour range
- Touch bar to see exact time + steps
- Auto-scroll to latest data
- Progress bar shows % of daily goal

**Data Processing:**
```kotlin
val filteredData = stepsDataList.filter { data ->
    val createdAtDate = parseDate(data.created_at)
    createdAtDate.isEqual(selectedDate)
}

val totalSteps = filteredData.sumOf { it.value.toIntOrNull() ?: 0 }
val progress = ((totalSteps.toFloat() / stepTarget) * 100).toInt()
```

---

### Mode 2: Week View

**Display:**
- Bar chart with 7 bars (M, T, W, T, F, S, S)
- X-axis: Day abbreviations
- Y-axis: Total steps per day
- Bars: Green (#4CAF50)

**Data Source:**
- `stepsDataByDayList` (daily aggregates from API)
- Filtered by selected week (Mon-Sun)
- Each bar = total steps for that day

**Features:**
- Navigate previous/next week
- Touch bar to see full date + steps
- Range summary card shows:
  - Week total steps
  - Total distance covered
- Week starts on Monday

**Data Processing:**
```kotlin
val filteredData = stepsDataByDayList.filter { data ->
    val itemDate = LocalDate.parse(data.vDate)
    itemDate in weekStartDate..weekEndDate
}

val totalSteps = filteredData.sumOf { it.value.toLong() }
val totalDistance = totalSteps * 0.00075 // km
```

---

### Mode 3: Month View

**Display:**
- Bar chart with daily bars (1-31)
- X-axis: Day of month
- Y-axis: Total steps per day
- Bars: Green (#4CAF50)

**Data Source:**
- `stepsDataByDayList` (daily aggregates from API)
- Filtered by selected month

**Features:**
- Navigate previous/next month
- Touch bar to see date + steps
- Range summary card shows:
  - Month total steps
  - Total distance covered
- Handles different month lengths (28-31 days)

**Data Processing:**
```kotlin
val filteredData = stepsDataByDayList.filter { data ->
    val itemDate = LocalDate.parse(data.vDate)
    itemDate in monthStartDate..monthEndDate
}

val totalSteps = filteredData.sumOf { it.value.toLong() }
val totalDistance = totalSteps * 0.00075 // km
```

---

## 📱 Fragment UI Components

### Background
- **Color:** #D9EDFF (Light Blue)
- **Container:** ScrollView with RelativeLayout

---

### 1. Title Section

```xml
Steps
```

**Specs:**
- **ID:** `stepsTitle`
- **Text:** "Steps"
- **Size:** 22sp
- **Color:** Black
- **Style:** Bold
- **Alignment:** Center
- **Margin:** 16dp horizontal, 8dp top

---

### 2. Tab Container

```xml
┌─────────────────────────────┐
│  Day  │ Week │ Month        │
└─────────────────────────────┘
```

**Container Specs:**
- **ID:** `tabContainer`
- **Layout:** Horizontal LinearLayout
- **Background:** `@drawable/tab_unselected_bg` (light gray rounded)
- **Margin:** 16dp horizontal, 8dp top, 4dp bottom

**Tab Design:**
- **Width:** 0dp with weight=1 (equal distribution)
- **Padding:** 12dp
- **Size:** 14sp
- **Color:** Black
- **Style:** Bold

**Tab States:**
- **Selected:** `@drawable/tab_selected_bg` (white rounded)
- **Unselected:** Transparent background

**Tab IDs:**
- `tabDay` (default selected)
- `tabWeek`
- `tabMonth`

---

### 3. Chart Card

```xml
┌───────────────────────────────┐
│  ◄  2025.01.03  ►             │  Date Navigation
│       12:30                   │  Selected Time
│       450 steps               │  Selected Value
│                               │
│  [Bar Chart - Green Bars]     │  Interactive Chart
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `stepsDataChartCard`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 24dp
- **Height:** 260dp
- **Margin:** 12dp
- **Padding:** 16dp

#### Date Navigation Bar

**Previous Icon:**
- **ID:** `previousIcon`
- **Drawable:** `baseline_arrow_back_ios_24`
- **Size:** 18dp × 18dp
- **Tint:** Black
- **Action:** Navigate to previous day/week/month

**Date Text:**
- **ID:** `dateText`
- **Format:** "yyyy.MM.dd" (Day), "dd MMM – dd MMM" (Week), "MMM yyyy" (Month)
- **Size:** 14sp
- **Color:** Black
- **Style:** Bold

**Next Icon:**
- **ID:** `nextIcon`
- **Drawable:** `baseline_arrow_forward_ios_24`
- **Size:** 18dp × 18dp
- **Tint:** Black
- **Action:** Navigate to next day/week/month

#### Selected Point Display

**Time Display:**
- **ID:** `selectedChartTime`
- **Text:** "12:30" (Day), "Monday, 2025-03-14" (Week/Month)
- **Size:** 14sp
- **Color:** Gray (#808080)

**Value Container:** Horizontal LinearLayout

**Value Text:**
- **ID:** `selectedChartValue`
- **Text:** "450"
- **Size:** 14sp
- **Color:** Gray (#808080)

**Unit Text:**
- **ID:** `selectedChartValueUnit`
- **Text:** "steps"
- **Size:** 14sp
- **Color:** Gray (#808080)
- **Margin Start:** 2dp

#### Bar Charts (3 instances)

**Daily Chart:**
- **ID:** `stepsDataChartDaily`
- **Visibility:** Visible (default)
- **Bar Color:** Green (#4CAF50)

**Weekly Chart:**
- **ID:** `stepsDataChartWeekly`
- **Visibility:** Gone
- **Bar Color:** Green (#4CAF50)

**Monthly Chart:**
- **ID:** `stepsDataChartMonthly`
- **Visibility:** Gone
- **Bar Color:** Green (#4CAF50)

**Common Specs:**
- **Type:** BarChart (MPAndroidChart)
- **Background:** White
- **Bar Width:** 0.07f

---

### 4. Range Summary Card (Week/Month Only)

```xml
┌───────────────────────────────┐
│ 03-09 Mar Steps               │
│ 68,500 steps          👣     │
│ ─────────────────────         │
│ Distance Covered              │
│ 51.38 KM                      │
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `steps_range_card`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 12dp
- **Margin:** 12dp
- **Padding:** 12dp vertical, 24dp horizontal
- **Visibility:** Gone (visible only in Week/Month tabs)

**Label:**
- **ID:** `stepsRangeLabel`
- **Text:** "03-09 Mar\nSteps" (Week) or "Mar 2026 Steps" (Month)
- **Size:** 15sp
- **Color:** Black
- **Max Lines:** 2

**Steps Value:**
- **ID:** `stepsRangeValueText`
- **Text:** "68500"
- **Size:** 24sp
- **Color:** Black
- **Style:** Bold

**Unit:**
- **ID:** `stepsRangeUnit`
- **Text:** "steps"
- **Size:** 18sp
- **Color:** Black

**Divider:**
- **Height:** 1dp
- **Background:** #E0E0E0
- **Margin:** 10dp top, 8dp bottom

**Distance Label:**
- **ID:** `stepsRangeDistanceLabel`
- **Text:** "Distance Covered"
- **Size:** 13sp
- **Color:** Gray (#888888)

**Distance Value:**
- **ID:** `stepsRangeDistanceValueText`
- **Text:** "51.38"
- **Size:** 20sp
- **Color:** Black
- **Style:** Bold

**Distance Unit:**
- **Text:** "KM"
- **Size:** 14sp
- **Color:** Gray (#888888)

**Icon:**
- **ID:** `stepsRangeIcon`
- **Drawable:** `baseline_directions_walk_24` (Walking person)
- **Size:** 50dp × 50dp
- **Background:** Circle shape, Green (#4CAF50)
- **Icon Tint:** White
- **Position:** Right-center

---

### 5. Today's Steps Card

```xml
┌───────────────────────────────┐
│ Today's Steps                 │
│ 8,450 / 10000 target    🏃   │
│ ████████████████░░░░░░        │  (84% Progress)
│ ─────────────────────         │
│ Distance Covered              │
│ 6.34 KM                       │
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `steps_value_card`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 12dp
- **Margin:** 12dp
- **Padding:** 16dp vertical, 24dp horizontal

**Layout:** Vertical LinearLayout

#### Section 1: Label

**Label:**
- **ID:** `stepsConsumptionLabel`
- **Text:** "Today's Steps" or "5th Jan Steps"
- **Size:** 18sp
- **Color:** Black
- **Margin Bottom:** 8dp

#### Section 2: Steps Value Row

**Container:** RelativeLayout

**Left Side (LinearLayout - Horizontal):**

**Steps Value:**
- **ID:** `stepsValueText`
- **Text:** "8450"
- **Size:** 28sp
- **Color:** Black
- **Style:** Bold

**Target Text:**
- **ID:** `stepsTargetText`
- **Text:** "/ 10000 target"
- **Size:** 14sp
- **Color:** Gray (#888888)
- **Margin Start:** 6dp
- **Alignment:** Bottom

**Right Side:**

**Emoji Icon:**
- **ID:** `stepsIcon`
- **Text:** "🏃" (Running emoji)
- **Size:** 44sp
- **Position:** Right-aligned, centered vertically

#### Section 3: Progress Bar

**Progress Bar:**
- **ID:** `stepsProgressBar`
- **Style:** Horizontal
- **Height:** 10dp
- **Max:** 100
- **Progress:** Calculated (steps / target × 100)
- **Drawable:** `@drawable/steps_progress_bg` (Custom gradient)
- **Margin Bottom:** 12dp

**Progress Colors:**
- Filled: Green gradient (#4CAF50 → #66BB6A)
- Unfilled: Light gray (#E0E0E0)

**Calculation:**
```kotlin
val progress = ((totalSteps.toFloat() / stepTarget) * 100).toInt().coerceAtMost(100)
stepsProgressBar.progress = progress
```

#### Section 4: Divider

**Divider:**
- **Height:** 1dp
- **Background:** #E0E0E0
- **Margin Bottom:** 12dp

#### Section 5: Distance Section

**Distance Label:**
- **ID:** `distanceLabel`
- **Text:** "Distance Covered"
- **Size:** 13sp
- **Color:** Gray (#888888)
- **Margin Bottom:** 4dp

**Distance Value Container (Horizontal):**

**Distance Value:**
- **ID:** `distanceValueText`
- **Text:** "6.34"
- **Size:** 22sp
- **Color:** Black
- **Style:** Bold

**Distance Unit:**
- **Text:** "KM"
- **Size:** 14sp
- **Color:** Gray (#888888)
- **Margin Start:** 4dp
- **Alignment:** Bottom

---

## 🔧 Core Functionality

### 1. Fragment Initialization

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    // Set background
    view.setBackgroundColor(Color.parseColor("#D9EDFF"))
    
    // Fetch data with AutoSyncStepsHelper
    fetchStepsHistoryFromHelper()
    
    // Bind all views
    bindViews(view)
    
    // Read step target from UserPreferences
    stepTarget = ApplicationPreferences.getInt(
        requireContext(), "steps_target", 10000, "UserPreferences"
    )
    stepsTargetText.text = "/ $stepTarget target"
    
    // Setup charts
    setupChart()          // Daily
    setupWeeklyChart()    // Weekly  
    setupMonthlyChart()   // Monthly
    
    // Set initial state
    updateDate()
    selectTab(tabDay, tabs)
    isDayMode = true
    
    // Setup listeners
    setupTabListeners()
    setupNavigationListeners()
}
```

---

### 2. Data Fetching with AutoSyncStepsHelper

```kotlin
@RequiresApi(Build.VERSION_CODES.O)
private fun fetchStepsHistoryFromHelper() {
    val helper = AutoSyncStepsHelper(requireContext(), object : AutoSyncStepsListener {
        // 1. Local steps data loaded
        override fun onLocalStepsDataFetched(data: List<GetHealthData>) {
            Log.i("StepsFragment", "📲 Loaded ${data.size} steps records from local DB")
            stepsDataList = data.toMutableList()
            
            // Load today's cached totals
            showSportSummaryFromSavedData()
            
            // Update daily chart
            selectedDateStepsDataList()
        }
        
        // 2. Data uploaded to API
        override fun onNewStepsUploaded() {
            Log.i("StepsFragment", "✅ Steps synced successfully")
        }
        
        // 3. Daily aggregates fetched
        override fun onSportDailyFetched(type: String, data: List<GetHealthData>) {
            if (type != "steps") return
            
            stepsDataByDayList = data.toMutableList()
            
            // Clean invalid data (values > 100k)
            stepsDataByDayList.forEach { entry ->
                if (entry.value > 100_000) entry.value = 0.0
            }
            
            // Update weekly and monthly charts
            selectedWeekStepsDataList()
            selectedMonthStepsDataList()
        }
    })
    
    // Trigger all data fetching operations
    helper.fetchLocalStepsData()
    helper.startSync()
    helper.fetchAndSyncSportDaily("steps")
}
```

**AutoSyncStepsHelper Operations:**
1. **fetchLocalStepsData():** Query local DB → Callback with data
2. **startSync():** Upload unsynced entries to API
3. **fetchAndSyncSportDaily("steps"):** Get daily aggregates from API

---

### 3. Load Today's Cached Totals

```kotlin
private fun showSportSummaryFromSavedData() {
    if (!isAdded || context == null) return
    
    // Load from ConnectionPreferences
    val (steps, _, distance) = ConnectionPreferences.loadTodayTotals(requireContext())
    
    Log.i("StepsFragment", "🔥 Today → Steps: $steps | Distance: ${String.format("%.2f", distance)} km")
    
    // Update UI
    stepsValueText.text = "$steps"
    distanceValueText.text = "%.2f".format(distance)
    stepsTargetText.text = "/ $stepTarget target"
    
    // Update progress bar
    val progress = ((steps.toFloat() / stepTarget.toFloat()) * 100).toInt().coerceAtMost(100)
    stepsProgressBar.progress = progress
}
```

**ConnectionPreferences Structure:**
```kotlin
// Stored keys:
"steps_today" → Int (total steps)
"calories_today" → Int (total calories)
"distance_today" → Double (total km)
"last_update_date" → String (yyyy-MM-dd)

// Updated by:
- AutoSyncStepsHelper after ring sync
- Calculated from local DB totals
- Reset daily at midnight
```

---

### 4. Day View - Data Filtering & Display

```kotlin
private fun selectedDateStepsDataList() {
    if (stepsDataList.isEmpty()) {
        Log.i("StepsFragment", "No steps data available to filter.")
        return
    }
    
    // Filter by selected date
    val filteredData = stepsDataList.filter { data ->
        try {
            val inputFormatter = DateTimeFormatter
                .ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'")
                .withZone(ZoneId.of("UTC"))
            
            // Handle timestamp or created_at
            val createdDate = if (data.timestamp != null) {
                val instant = Instant.ofEpochSecond(data.timestamp.toLong())
                LocalDateTime.ofInstant(instant, ZoneId.of("UTC")).format(inputFormatter)
            } else {
                data.created_at
            }
            
            val createdAtInstant = Instant.from(inputFormatter.parse(createdDate))
            val createdAtDate = createdAtInstant.atZone(ZoneId.of("Asia/Kolkata")).toLocalDate()
            
            // Match selected date
            createdAtDate.isEqual(selectedDate)
        } catch (e: Exception) {
            Log.e("StepsFragment", "Error parsing date", e)
            false
        }
    }
    
    // Update label with ordinal suffix
    val todayDate = LocalDate.now(ZoneId.of("Asia/Kolkata"))
    if (selectedDate.isEqual(todayDate)) {
        stepsConsumptionLabel.text = "Today's Steps"
    } else {
        val day = selectedDate.dayOfMonth
        val suffix = getOrdinalSuffix(day)
        val month = DateTimeFormatter.ofPattern("MMM").format(selectedDate)
        val fullText = "${day}${suffix} ${month} Steps"
        
        // Apply superscript to suffix
        val spannable = SpannableString(fullText)
        val suffixStart = day.toString().length
        val suffixEnd = suffixStart + suffix.length
        spannable.setSpan(SuperscriptSpan(), suffixStart, suffixEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        spannable.setSpan(RelativeSizeSpan(0.6f), suffixStart, suffixEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        
        stepsConsumptionLabel.text = spannable
    }
    
    // Calculate total
    val totalSteps = filteredData.sumOf { it.value.toIntOrNull() ?: 0 }
    stepsValueText.text = totalSteps.toString()
    
    // Update progress
    stepsTargetText.text = "/ $stepTarget target"
    val progress = ((totalSteps.toFloat() / stepTarget) * 100).toInt().coerceAtMost(100)
    stepsProgressBar.progress = progress
    
    // Calculate distance
    val todayCheck = LocalDate.now(ZoneId.of("Asia/Kolkata"))
    if (selectedDate.isEqual(todayCheck)) {
        // Use cached value for today
        val (_, _, dist) = ConnectionPreferences.loadTodayTotals(requireContext())
        distanceValueText.text = "%.2f".format(dist)
    } else {
        // Estimate: 0.75m per step → km
        val estimatedKm = totalSteps * 0.00075
        distanceValueText.text = "%.2f".format(estimatedKm)
    }
    
    // Update chart
    populateChart(filteredData)
    getInitialData(filteredData)
}
```

**Distance Calculation:**
```
Average stride length: 0.75 meters
Steps × 0.75 = meters
Meters / 1000 = kilometers

Example:
10,000 steps × 0.75m = 7,500m = 7.5 km
```

**Ordinal Suffix Logic:**
```kotlin
private fun getOrdinalSuffix(day: Int): String {
    return when {
        day in 11..13 -> "th"  // Special case
        day % 10 == 1 -> "st"
        day % 10 == 2 -> "nd"
        day % 10 == 3 -> "rd"
        else -> "th"
    }
}
```

---

### 5. Week View - Data Filtering & Display

```kotlin
private fun selectedWeekStepsDataList() {
    if (stepsDataByDayList.isEmpty()) {
        Log.i("StepsFragment", "No steps data available for week.")
        return
    }
    
    val weeklyDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    
    // Filter by week range
    val filteredData = stepsDataByDayList.filter { data ->
        try {
            data.vDate?.let { dateStr ->
                val itemDate = LocalDate.parse(dateStr, weeklyDateFormatter)
                itemDate in weekStartDate..weekEndDate
            } ?: false
        } catch (e: DateTimeParseException) {
            Log.e("StepsFragment", "Invalid date format: ${data.vDate}", e)
            false
        }
    }.toMutableList()
    
    // Populate chart
    populateWeeklyStepsChart(filteredData)
    getInitialWeeklyData(filteredData)
    
    // Calculate totals
    val totalSteps = filteredData.sumOf { it.value.toLong() }
    val totalDistance = totalSteps * 0.00075 // km
    
    // Update range summary card
    val displayFormatter = DateTimeFormatter.ofPattern("dd MMM")
    stepsRangeLabel.text = "${weekStartDate.format(displayFormatter)} – ${weekEndDate.format(displayFormatter)}\nSteps"
    stepsRangeValueText.text = totalSteps.toString()
    stepsRangeDistanceValueText.text = "%.2f".format(totalDistance)
}
```

**Week Navigation:**
```kotlin
private fun goToPreviousWeek() {
    weekStartDate = weekStartDate.minusWeeks(1)
    weekEndDate = weekEndDate.minusWeeks(1)
    updateWeekDates()
    selectedWeekStepsDataList()
}

private fun goToNextWeek() {
    weekStartDate = weekStartDate.plusWeeks(1)
    weekEndDate = weekEndDate.plusWeeks(1)
    updateWeekDates()
    selectedWeekStepsDataList()
}
```

---

### 6. Month View - Data Filtering & Display

```kotlin
private fun selectedMonthStepsDataList() {
    if (stepsDataByDayList.isEmpty()) {
        Log.i("StepsFragment", "No steps data available for month.")
        return
    }
    
    val monthlyDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    
    // Filter by month range
    val filteredData = stepsDataByDayList.filter { data ->
        try {
            data.vDate?.let { dateStr ->
                val itemDate = LocalDate.parse(dateStr, monthlyDateFormatter)
                itemDate in monthStartDate..monthEndDate
            } ?: false
        } catch (e: DateTimeParseException) {
            Log.e("StepsFragment", "Invalid date format: ${data.vDate}", e)
            false
        }
    }.toMutableList()
    
    // Populate chart
    populateMonthlyStepsChart(filteredData)
    getInitialWeeklyData(filteredData)
    
    // Calculate totals
    val totalSteps = filteredData.sumOf { it.value.toLong() }
    val totalDistance = totalSteps * 0.00075 // km
    
    // Update range summary card
    val displayFormatter = DateTimeFormatter.ofPattern("MMM yyyy")
    stepsRangeLabel.text = "${monthStartDate.format(displayFormatter)} Steps"
    stepsRangeValueText.text = totalSteps.toString()
    stepsRangeDistanceValueText.text = "%.2f".format(totalDistance)
}
```

---

### 7. Chart Setup - Daily (Zoomable)

```kotlin
private fun setupChart() {
    // Basic configuration
    stepsDataChart.description.isEnabled = false
    stepsDataChart.setTouchEnabled(true)
    stepsDataChart.isDragEnabled = true
    stepsDataChart.setScaleEnabled(true)
    stepsDataChart.setPinchZoom(true)
    stepsDataChart.isScaleXEnabled = true
    stepsDataChart.isScaleYEnabled = false
    
    // Grid lines
    stepsDataChart.axisLeft.setDrawGridLines(true)
    stepsDataChart.axisLeft.gridColor = Color.LTGRAY
    stepsDataChart.axisLeft.gridLineWidth = 0.5f
    stepsDataChart.axisRight.setDrawGridLines(false)
    stepsDataChart.xAxis.setDrawGridLines(false)
    stepsDataChart.axisLeft.setDrawAxisLine(false)
    
    // Smooth scrolling
    stepsDataChart.isDragDecelerationEnabled = true
    stepsDataChart.dragDecelerationFrictionCoef = 0.9f
    
    // Touch selection
    stepsDataChart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
        override fun onValueSelected(e: Entry?, h: Highlight?) {
            if (e != null) {
                val hour = e.x.toInt()
                val minute = ((e.x - hour) * 60).toInt()
                selectedChartTime.text = String.format("%02d:%02d", hour, minute)
                selectedChartValue.text = e.y.toInt().toString()
            }
        }
        
        override fun onNothingSelected() {}
    })
    
    // X-axis configuration
    val xAxis = stepsDataChart.xAxis
    xAxis.position = XAxis.XAxisPosition.BOTTOM
    xAxis.setDrawGridLines(false)
    xAxis.granularity = 1f
    xAxis.labelCount = 6
    xAxis.axisMinimum = 0f
    xAxis.axisMaximum = 24f
    xAxis.valueFormatter = object : ValueFormatter() {
        override fun getFormattedValue(value: Float) = String.format("%02d:00", value.toInt())
    }
    
    // Visible range
    stepsDataChart.setVisibleXRangeMaximum(5f)
    
    // Zoom listener for dynamic labels
    stepsDataChart.setOnChartGestureListener(object : OnChartGestureListener {
        override fun onChartScale(me: MotionEvent?, scaleX: Float, scaleY: Float) {
            updateXAxisLabels()
        }
        // ... other gesture methods
    })
}
```

---

### 8. Populate Daily Chart

```kotlin
private fun populateChart(healthDataList: List<GetHealthData>) {
    val entries = mutableListOf<BarEntry>()
    
    healthDataList.forEach { healthData ->
        try {
            val inputFormatter = DateTimeFormatter
                .ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'")
                .withZone(ZoneId.of("UTC"))
            
            // Parse timestamp
            val createdAt = if (healthData.timestamp != null) {
                val instant = Instant.ofEpochSecond(healthData.timestamp.toLong())
                LocalDateTime.ofInstant(instant, ZoneId.of("UTC")).format(inputFormatter)
            } else {
                healthData.created_at
            }
            
            val createdAtInstant = Instant.from(inputFormatter.parse(createdAt))
            val localTime = createdAtInstant.atZone(ZoneId.systemDefault()).toLocalTime()
            
            // Convert to hour fraction
            val hourFraction = localTime.hour + localTime.minute / 60f
            
            val value = healthData.value.toFloatOrNull() ?: 0f
            entries.add(BarEntry(hourFraction, value))
        } catch (e: Exception) {
            Log.e("StepsFragment", "Error parsing chart data", e)
        }
    }
    
    // Sort by time
    val sortedEntries = entries.sortedBy { it.x }
    
    // Set Y-axis range
    val maxYValue = sortedEntries.maxOfOrNull { it.y } ?: 0f
    val leftAxis = stepsDataChart.axisLeft
    leftAxis.axisMinimum = 0f
    leftAxis.axisMaximum = maxYValue + 500f
    stepsDataChart.axisRight.isEnabled = false
    
    if (sortedEntries.isNotEmpty()) {
        // Create bar dataset
        val dataSet = BarDataSet(sortedEntries, "Steps Data")
        dataSet.color = Color.parseColor("#4CAF50")  // Green
        dataSet.setDrawValues(false)
        
        val barData = BarData(dataSet)
        barData.barWidth = 0.07f
        
        stepsDataChart.legend.isEnabled = false
        stepsDataChart.data = barData
        
        // Auto-scroll to latest
        stepsDataChart.post {
            stepsDataChart.moveViewToX(sortedEntries.lastOrNull()?.x ?: 0f)
        }
        
        // Extend X-axis
        stepsDataChart.xAxis.axisMaximum = (sortedEntries.lastOrNull()?.x ?: 0f) + 1
        
        stepsDataChart.invalidate()
    } else {
        stepsDataChart.data = null
        stepsDataChart.invalidate()
    }
}
```

---

### 9. Setup Weekly Chart

```kotlin
private fun setupWeeklyChart() {
    stepsWeeklyDataChart.description.isEnabled = false
    stepsWeeklyDataChart.setTouchEnabled(true)
    stepsWeeklyDataChart.isDragEnabled = true
    stepsWeeklyDataChart.setScaleEnabled(true)
    stepsWeeklyDataChart.setPinchZoom(true)
    stepsWeeklyDataChart.isScaleXEnabled = true
    stepsWeeklyDataChart.isScaleYEnabled = false
    
    // Grid lines
    stepsWeeklyDataChart.axisLeft.setDrawGridLines(true)
    stepsWeeklyDataChart.axisLeft.gridColor = Color.LTGRAY
    stepsWeeklyDataChart.axisLeft.gridLineWidth = 0.5f
    
    // X-axis for weekdays
    val xAxis = stepsWeeklyDataChart.xAxis
    xAxis.position = XAxis.XAxisPosition.BOTTOM
    xAxis.setDrawGridLines(false)
    xAxis.granularity = 1f
    xAxis.labelCount = 7
    
    // Fixed labels: M, T, W, T, F, S, S
    xAxis.valueFormatter = object : ValueFormatter() {
        override fun getFormattedValue(value: Float) = when (value.toInt()) {
            0 -> "M"; 1 -> "T"; 2 -> "W"; 3 -> "T"
            4 -> "F"; 5 -> "S"; 6 -> "S"; else -> ""
        }
    }
    
    xAxis.axisMinimum = 0f
    xAxis.axisMaximum = 6f
    stepsWeeklyDataChart.setVisibleXRangeMaximum(7f)
    
    // Touch listener
    stepsWeeklyDataChart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
        override fun onValueSelected(e: Entry?, h: Highlight?) {
            if (e != null && e is DateBarEntry) {
                val dayLabel = when (e.x.toInt()) {
                    0 -> "Monday"; 1 -> "Tuesday"; 2 -> "Wednesday"
                    3 -> "Thursday"; 4 -> "Friday"; 5 -> "Saturday"
                    6 -> "Sunday"; else -> ""
                }
                selectedChartTime.text = "$dayLabel, ${e.date}"
                selectedChartValue.text = e.y.toInt().toString()
            }
        }
        
        override fun onNothingSelected() {}
    })
}
```

---

### 10. Populate Weekly Chart

```kotlin
private fun populateWeeklyStepsChart(healthDataList: List<GetHealthData>) {
    val entries = mutableListOf<DateBarEntry>()
    
    healthDataList.forEach { healthData ->
        try {
            val df = DateTimeFormatter.ofPattern("yyyy-MM-dd")
            val localDate = LocalDate.parse(healthData.vDate, df)
            
            // Map day of week to X value (0-6)
            val xValue = when (localDate.dayOfWeek) {
                DayOfWeek.MONDAY -> 0f
                DayOfWeek.TUESDAY -> 1f
                DayOfWeek.WEDNESDAY -> 2f
                DayOfWeek.THURSDAY -> 3f
                DayOfWeek.FRIDAY -> 4f
                DayOfWeek.SATURDAY -> 5f
                DayOfWeek.SUNDAY -> 6f
                else -> -1f
            }
            
            if (xValue != -1f) {
                entries.add(DateBarEntry(xValue, healthData.value.toFloat(), healthData.vDate))
            }
        } catch (e: Exception) {
            Log.e("StepsFragment", "Error parsing weekly chart date", e)
        }
    }
    
    val sortedEntries = entries.sortedBy { it.x }
    
    // Set Y-axis range
    val maxYValue = sortedEntries.maxOfOrNull { it.y } ?: 1000f
    stepsWeeklyDataChart.axisLeft.axisMinimum = 0f
    stepsWeeklyDataChart.axisLeft.axisMaximum = maxYValue + 500f
    stepsWeeklyDataChart.axisRight.isEnabled = false
    
    if (sortedEntries.isNotEmpty()) {
        val dataSet = BarDataSet(sortedEntries, "Weekly Steps")
        dataSet.color = Color.parseColor("#4CAF50")
        dataSet.setDrawValues(false)
        
        val barData = BarData(dataSet)
        barData.barWidth = 0.5f
        
        stepsWeeklyDataChart.legend.isEnabled = false
        stepsWeeklyDataChart.data = barData
        stepsWeeklyDataChart.invalidate()
    } else {
        stepsWeeklyDataChart.data = null
        stepsWeeklyDataChart.invalidate()
    }
}
```

**Custom DateBarEntry:**
```kotlin
class DateBarEntry(
    x: Float,       // X-axis value (0-6 for days)
    y: Float,       // Y-axis value (steps count)
    val date: String // Date in "yyyy-MM-dd" format
) : BarEntry(x, y)
```

---

## 📊 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Text | `#000000` | Titles, values, labels |
| Secondary Text | `#808080` | Selected point time/value |
| Tertiary Text | `#888888` | Distance label, unit text |
| Bar Color | `#4CAF50` | Chart bars (Green) |
| Progress Filled | `#4CAF50` → `#66BB6A` | Progress bar gradient |
| Progress Unfilled | `#E0E0E0` | Progress bar background |
| Divider | `#E0E0E0` | Horizontal dividers |
| Walking Icon BG | `#4CAF50` | Green circle |
| Icon Tint | `#FFFFFF` | White icons |
| Grid Lines | `#D3D3D3` | Light gray |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Screen Title | 22sp | Bold | Black |
| Tab Text | 14sp | Bold | Black |
| Date Text | 14sp | Bold | Black |
| Selected Time | 14sp | Normal | Gray (#808080) |
| Selected Value | 14sp | Normal | Gray (#808080) |
| Consumption Label | 18sp | Normal | Black |
| Steps Value | 28sp | Bold | Black |
| Target Text | 14sp | Normal | Gray (#888888) |
| Range Label | 15sp | Normal | Black |
| Range Value | 24sp | Bold | Black |
| Range Unit | 18sp | Normal | Black |
| Distance Label | 13sp | Normal | Gray (#888888) |
| Distance Value | 22sp (Day), 20sp (Range) | Bold | Black |
| Distance Unit | 14sp | Normal | Gray (#888888) |
| Running Emoji | 44sp | - | - |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 16dp horizontal |
| Card Margin | 12dp |
| Card Padding (Chart) | 16dp |
| Card Padding (Steps) | 16-24dp |
| Tab Padding | 12dp |
| Progress Bar Height | 10dp |
| Progress Margin Bottom | 12dp |
| Divider Height | 1dp |
| Icon Size | 50dp × 50dp |
| Arrow Icon Size | 18dp × 18dp |
| Corner Radius | 24dp |
| Elevation | 12-24dp |

---

## 📱 User Experience Flows

### Flow 1: View Today's Steps

```
Open Steps Fragment
    ↓
Day tab selected (default)
    ↓
Load cached totals from ConnectionPreferences
    ↓
Display: Steps, Progress %, Distance
    ↓
Fetch local steps data
    ↓
Filter by today's date
    ↓
Display on bar chart (green bars)
    ↓
Auto-scroll to latest time
    ↓
Touch any bar → See exact time + steps
```

---

### Flow 2: Check Weekly Progress

```
Tap "Week" tab
    ↓
Weekly chart shown
    ↓
Range card appears
    ↓
Date shows: "03-09 Mar"
    ↓
7 bars displayed (M-S)
    ↓
Range card shows:
    - Total: 68,500 steps
    - Distance: 51.38 KM
    ↓
Touch Monday bar
    ↓
Display: "Monday, 2026-05-03"
    ↓
Value: "9,850 steps"
```

---

### Flow 3: Ring Sync & Update

```
Ring detects steps during walk
    ↓
Data stored locally (Sport DB)
    ↓
AutoSyncStepsHelper triggered
    ↓
[Background Process]
    ├─ Upload to API
    ├─ Update ConnectionPreferences
    └─ Calculate new distance
    ↓
Fragment receives update (if open)
    ↓
UI refreshes:
    ├─ Steps value updated
    ├─ Progress bar moves
    ├─ Distance recalculated
    ├─ Chart adds new bar
    └─ Auto-scroll to latest
```

---

### Flow 4: Achieve Daily Goal

```
User reaches 10,000 steps
    ↓
Progress bar fills to 100%
    ↓
Visual completion indicator
    ↓
(Optional: Notification sent)
    ↓
Dashboard alert updated:
    "Daily Step Goal Achieved!"
```

---

### Flow 5: Navigate Historical Data

```
Day view showing today
    ↓
Tap left arrow (◄)
    ↓
selectedDate -= 1 day
    ↓
Date updates: "2026.05.22"
    ↓
Filter local data by new date
    ↓
Chart updates with that day's steps
    ↓
Label changes: "22nd May Steps"
    ↓
Total and distance update
    ↓
Progress bar shows that day's %
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### Data Loading
- [ ] Local database data fetched
- [ ] API data fetched successfully
- [ ] Daily aggregates retrieved
- [ ] ConnectionPreferences loaded
- [ ] Invalid data cleaned (> 100k)
- [ ] Ring sync triggers properly
- [ ] Fragment handles no data gracefully

#### Day View
- [ ] Filter by selected date works
- [ ] Today's label correct
- [ ] Past dates show ordinal suffix
- [ ] Total steps calculated correctly
- [ ] Progress bar percentage accurate
- [ ] Distance calculated (steps × 0.00075)
- [ ] Today uses cached distance
- [ ] Past days estimate distance
- [ ] Chart displays bars at correct times
- [ ] Auto-scroll to latest data
- [ ] Touch bar shows time + steps
- [ ] Navigation works (prev/next)

#### Week View
- [ ] Filter by week range works
- [ ] 7 bars displayed (Mon-Sun)
- [ ] X-axis labels correct (M,T,W,T,F,S,S)
- [ ] Touch shows full date + steps
- [ ] Range card shows total steps
- [ ] Range card shows total distance
- [ ] Week navigation works
- [ ] Week starts on Monday

#### Month View
- [ ] Filter by month range works
- [ ] Correct number of bars (28-31)
- [ ] Touch shows date + steps
- [ ] Range card shows totals
- [ ] Month navigation works
- [ ] Handles Feb correctly (28/29)

#### Progress Tracking
- [ ] Progress calculates correctly
- [ ] Max capped at 100%
- [ ] Progress bar visual updates
- [ ] Target loaded from UserPreferences
- [ ] Target display correct

---

### UI/UX Tests
- [ ] Background color correct
- [ ] Green bars render properly
- [ ] Progress bar gradient visible
- [ ] Running emoji displays
- [ ] Walking icon renders
- [ ] Cards stack vertically
- [ ] Tab switching smooth
- [ ] Range card visibility correct
- [ ] Text doesn't overflow
- [ ] Distance formats to 2 decimals

---

## 🚀 Future Enhancements

### 1. Hourly Step Goals

```xml
┌───────────────────────────────────┐
│  Hourly Goal: 400 steps/hour      │
│  This Hour: 325 steps (81%)       │
│  ████████████████░░░░              │
└───────────────────────────────────┘
```

### 2. Step Streaks

```xml
┌───────────────────────────────────┐
│  Current Streak: 15 days 🔥       │
│  Hit your goal 15 days in a row!  │
└───────────────────────────────────┘
```

### 3. Leaderboard

```xml
┌───────────────────────────────────┐
│  This Week's Ranking              │
│  🥇 You: 85,420 steps             │
│  🥈 Sarah: 82,100 steps           │
│  🥉 Mike: 79,850 steps            │
└───────────────────────────────────┘
```

### 4. Activity Map

```xml
┌───────────────────────────────────┐
│  Today's Walking Route            │
│  [Interactive Map]                │
│  Duration: 2h 15m                 │
│  Avg Speed: 5.2 km/h              │
└───────────────────────────────────┘
```

### 5. Smart Reminders

```
"You've been sitting for 1 hour. 
Take a 5-minute walk to hit your 
hourly goal!"
```

### 6. Step Challenges

```xml
┌───────────────────────────────────┐
│  Active Challenge                 │
│  📍 Walk 100,000 steps this week  │
│  Progress: 68,500 / 100,000 (68%) │
│  Reward: Achievement Badge        │
└───────────────────────────────────┘
```

### 7. Cadence Analysis

```xml
┌───────────────────────────────────┐
│  Walking Cadence                  │
│  Average: 105 steps/min           │
│  Peak: 128 steps/min              │
│  Status: Moderate pace            │
└───────────────────────────────────┘
```

### 8. Calorie Comparison

```xml
┌───────────────────────────────────┐
│  Steps & Calories                 │
│  8,450 steps → 285 kcal burned    │
│  Efficiency: 0.034 kcal/step      │
└───────────────────────────────────┘
```

### 9. Weather Integration

```xml
┌───────────────────────────────────┐
│  Walking Conditions               │
│  ☀️ Sunny, 22°C                   │
│  Perfect day for a walk!          │
│  Suggested: 30 min outdoor walk   │
└───────────────────────────────────┘
```

### 10. Social Sharing

```xml
┌───────────────────────────────────┐
│  [Share] [Challenge Friend]       │
│  Share your daily steps progress  │
│  or challenge friends to beat it! │
└───────────────────────────────────┘
```

---

## 📊 Analytics & Tracking

### Key Metrics
- Steps fragment views
- Tab switches (Day/Week/Month)
- Average daily steps
- Goal achievement rate
- Most active days
- Distance covered trends
- Chart interactions
- Navigation clicks

### Implementation
```kotlin
Analytics.logEvent("steps_screen_viewed")
Analytics.logEvent("steps_tab_switched", mapOf("to_tab" to toTab))
Analytics.logEvent("steps_goal_achieved", mapOf("steps" to steps, "goal" to goal))
Analytics.logEvent("steps_bar_selected", mapOf("time" to time, "steps" to steps))
```

---

**Document Version:** 1.0  
**Last Updated:** May 23, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

