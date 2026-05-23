# Calories Fragment - Design & Implementation

**HEARTO App - Calories Burned Tracker & Analyzer**  
**Fragment:** `CaloriesFragment.kt`  
**Layout:** `fragment_calories.xml`  
**Helper:** `AutoSyncStepsHelper.kt`

---

## 📋 Overview

The Calories Fragment provides comprehensive tracking and visualization of calories burned throughout the day, week, and month. It features interactive bar charts with three time-range views, real-time data synchronization from the smart ring, and historical trend analysis. The calories data is calculated based on steps and activity detected by the ring.

**Key Features:**
- Three view modes: Day, Week, Month
- Interactive bar charts with touch selection
- Real-time ring data synchronization
- Historical data from local database and API
- Zoomable and scrollable daily charts
- Range summary cards for week/month
- Today's total calories display
- Automatic data aggregation

---

## 🎨 Design Architecture

### Screen Structure

```
ScrollView (Full Height)
└── RelativeLayout
    ├── Title: "Calories"
    ├── Tab Container (Day | Week | Month)
    ├── Chart Card
    │   ├── Date Navigation (◄ Date ►)
    │   ├── Selected Point Display (Time + Value)
    │   └── Bar Chart (Dynamic: Daily/Weekly/Monthly)
    ├── Today's Consumption Card
    │   ├── Label + Value
    │   └── Fire Icon
    └── Range Summary Card (Week/Month only)
        ├── Range Label + Total
        └── Fire Icon
```

---

## 🎨 Screen Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│          Calories                   │  Background
│                                     │  #D9EDFF
│  ┌─────────────────────────────┐   │
│  │  Day  │ Week │ Month         │   │  Tab
│  └─────────────────────────────┘   │  Container
│                                     │
│  ┌───────────────────────────────┐ │
│  │  ◄  2025.01.03  ►             │ │  White
│  │       12:30                   │ │  Chart
│  │       250 kcal                │ │  Card
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  Bar
│  │  │ ▂▃▅▇█▇▅▃▂▃▄▅▆▅▄▃▂      │ │ │  Chart
│  │  └─────────────────────────┘ │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Today's Consumption           │ │  Value
│  │ 1,850 kcal            🔥     │ │  Card
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │  Range
│  │ 03-09 Mar                     │ │  Card
│  │ Consumption                   │ │  (Week/
│  │ 12,250 kcal           🔥     │ │  Month)
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
    // Receives calories data from ring
    // Stored temporarily in local DB
    // Synced to API
}
```

**Ring Data:**
- Calories burned per activity session
- Timestamp of measurement
- Calculated from steps and activity level

#### 2. Local Database
```kotlin
DatabaseProvider.provideSportRepository()
    .getAllData() // Get all local calories records
```

**Local Storage:**
- Immediate storage for ring data
- Serves as cache for offline access
- Synced to API when online

#### 3. API (Cloud Storage)
```kotlin
// Endpoint 1: Get all calories records
GET /ring_data_by_type/{userId}?type=calories&page=1&limit=1000

// Endpoint 2: Get daily aggregated data
GET /user_health_data_by_day/{userId}/{type}
```

**API Data:**
- Historical records
- Daily aggregated totals
- Shared across devices

---

### Sync Flow

```
Ring Measurement
    ↓
Local Database (Sport Entity)
    ↓
AutoSyncStepsHelper
    ├─ Fetch local data
    ├─ Upload to API
    ├─ Fetch daily aggregates
    └─ Update UI
    ↓
Fragment Display
    ├─ Daily chart (per-entry)
    ├─ Weekly chart (daily totals)
    └─ Monthly chart (daily totals)
```

---

## 🎯 View Modes

### Mode 1: Day View (Default)

**Display:**
- Bar chart with hourly data points
- X-axis: 00:00 to 24:00
- Y-axis: Calories (kcal)
- Bars: Orange (#FFA500)
- Zoomable and scrollable

**Data Source:**
- `caloriesDataList` (per-entry records)
- Filtered by selected date

**Features:**
- Zoom to see 30-minute intervals
- Pan to see full 24-hour range
- Touch bar to see exact time + value
- Auto-scroll to latest data

---

### Mode 2: Week View

**Display:**
- Bar chart with 7 bars (M, T, W, T, F, S, S)
- X-axis: Day abbreviations
- Y-axis: Total calories per day
- Bars: Orange (#FFA500)

**Data Source:**
- `caloriesDataByDayList` (daily aggregates)
- Filtered by selected week (Mon-Sun)

**Features:**
- Navigate previous/next week
- Touch bar to see full date + value
- Range summary card shows week total
- Week starts on Monday

---

### Mode 3: Month View

**Display:**
- Bar chart with daily bars (1-31)
- X-axis: Day of month
- Y-axis: Total calories per day
- Bars: Orange (#FFA500)

**Data Source:**
- `caloriesDataByDayList` (daily aggregates)
- Filtered by selected month

**Features:**
- Navigate previous/next month
- Touch bar to see date + value
- Range summary card shows month total
- Handles different month lengths (28-31 days)

---

## 📱 Fragment UI Components

### Background
- **Color:** #D9EDFF (Light Blue)
- **Container:** ScrollView with RelativeLayout

---

### 1. Title Section

```xml
Calories
```

**Specs:**
- **ID:** `caloriesTitle`
- **Text:** "Calories"
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

**Tab Design (Each):**
- **Width:** 0dp with weight=1 (equal distribution)
- **Padding:** 12dp
- **Size:** 14sp
- **Color:** Black
- **Style:** Bold
- **Alignment:** Center

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
│       250 kcal                │  Selected Value
│                               │
│  [Bar Chart]                  │  Interactive Chart
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `caloriesDataChartCard`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 24dp
- **Height:** 260dp
- **Margin:** 12dp
- **Padding:** 16dp

---

#### Date Navigation Bar

**Container:** RelativeLayout (`dateContainer`)

**Previous Icon:**
- **ID:** `previousIcon`
- **Drawable:** `baseline_arrow_back_ios_24`
- **Size:** 18dp × 18dp
- **Tint:** Black
- **Position:** Left-aligned, centered vertically
- **Action:** Navigate to previous day/week/month

**Date Text:**
- **ID:** `dateText`
- **Format:** "yyyy.MM.dd" (Day), "dd MMM – dd MMM" (Week), "MMM yyyy" (Month)
- **Size:** 14sp
- **Color:** Black
- **Style:** Bold
- **Position:** Center between arrows

**Next Icon:**
- **ID:** `nextIcon`
- **Drawable:** `baseline_arrow_forward_ios_24`
- **Size:** 18dp × 18dp
- **Tint:** Black
- **Position:** Right of date text
- **Action:** Navigate to next day/week/month

---

#### Selected Point Display

**Time Display:**
- **ID:** `selectedChartTime`
- **Text:** "12:30" (Day), "Monday, 2025-03-14" (Week/Month)
- **Size:** 14sp
- **Color:** Gray (#808080)
- **Position:** Below date, centered

**Value Container:** Horizontal LinearLayout
- **ID:** `selectedChartValueContainer`

**Value Text:**
- **ID:** `selectedChartValue`
- **Text:** "250"
- **Size:** 14sp
- **Color:** Gray (#808080)

**Unit Text:**
- **ID:** `selectedChartValueUnit`
- **Text:** "kcal"
- **Size:** 14sp
- **Color:** Gray (#808080)
- **Margin Start:** 2dp

---

#### Bar Charts (3 instances)

**Daily Chart:**
- **ID:** `caloriesDataChartDaily`
- **Visibility:** Visible (default)
- **Type:** BarChart (MPAndroidChart library)
- **Background:** White

**Weekly Chart:**
- **ID:** `caloriesDataChartWeekly`
- **Visibility:** Gone
- **Type:** BarChart
- **Background:** White

**Monthly Chart:**
- **ID:** `caloriesDataChartMonthly`
- **Visibility:** Gone
- **Type:** BarChart
- **Background:** White

**Common Specs:**
- **Width:** Match parent
- **Height:** Match parent (fills card below selected point)
- **Margin Bottom:** 4dp
- **Position:** Below `selectedChartValueContainer`

---

### 4. Today's Consumption Card

```xml
┌───────────────────────────────┐
│ Today's Consumption           │
│ 1,850 kcal            🔥     │
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `calories_value_card`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 12dp
- **Margin:** 12dp
- **Padding:** 12dp vertical, 24dp horizontal

**Label:**
- **ID:** `caloriesConsumptionLabel`
- **Text:** "Today's Consumption" or "5th Jan Consumption"
- **Size:** 18sp
- **Color:** Black
- **Position:** Top-left

**Value:**
- **ID:** `caloriesValueText`
- **Text:** "1850"
- **Size:** 24sp
- **Color:** Black
- **Style:** Bold
- **Position:** Below label

**Unit:**
- **ID:** `kcalText`
- **Text:** "kcal"
- **Size:** 18sp
- **Color:** Black
- **Position:** Baseline-aligned with value

**Icon:**
- **ID:** `caloriesIcon`
- **Drawable:** `baseline_local_fire_department_24` (Fire/Flame)
- **Size:** 50dp × 50dp
- **Background:** Circle shape, Red (#EB3223)
- **Icon Tint:** White
- **Position:** Right-center, 20dp from end

---

### 5. Range Summary Card (Week/Month Only)

```xml
┌───────────────────────────────┐
│ 03-09 Mar                     │
│ Consumption                   │
│ 12,250 kcal           🔥     │
└───────────────────────────────┘
```

**Card Specs:**
- **ID:** `calories_range_card`
- **Background:** White
- **Corner Radius:** 24dp
- **Elevation:** 12dp
- **Margin:** 12dp
- **Padding:** 12dp vertical, 24dp horizontal
- **Visibility:** Gone (visible only in Week/Month tabs)

**Label:**
- **ID:** `caloriesRangeLabel`
- **Text:** "03-09 Mar\nConsumption" (Week) or "Mar 2025 Consumption" (Month)
- **Size:** 15sp
- **Color:** Black
- **Max Lines:** 2
- **Position:** Top-left

**Value:**
- **ID:** `caloriesRangeValueText`
- **Text:** "12250"
- **Size:** 24sp
- **Color:** Black
- **Style:** Bold
- **Position:** Below label

**Unit:**
- **ID:** `caloriesRangeKcalText`
- **Text:** "kcal"
- **Size:** 18sp
- **Color:** Black
- **Position:** Baseline-aligned with value

**Icon:**
- **ID:** `caloriesRangeIcon`
- **Drawable:** `baseline_local_fire_department_24`
- **Size:** 50dp × 50dp
- **Background:** Circle shape, Orange (#FF8C00)
- **Icon Tint:** White
- **Position:** Right-center, 20dp from end

---

## 🔧 Core Functionality

### 1. Fragment Initialization

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    // Set background
    view.setBackgroundColor(Color.parseColor("#D9EDFF"))
    
    // Fetch data
    fetchCaloriesHistoryFromHelper()
    fetchCaloriesDataByDate()
    
    // Initialize views
    bindViews(view)
    
    // Setup charts
    setupChart()          // Daily
    setupWeeklyChart()    // Weekly
    setupMonthlyChart()   // Monthly
    
    // Set initial state
    selectTab(tabDay, tabs)
    isDayMode = true
    updateDate()
    
    // Setup listeners
    setupTabListeners()
    setupNavigationListeners()
}
```

---

### 2. Data Fetching with AutoSyncStepsHelper

```kotlin
@RequiresApi(Build.VERSION_CODES.O)
private fun fetchCaloriesHistoryFromHelper() {
    val helper = AutoSyncStepsHelper(requireContext(), object : AutoSyncStepsListener {
        // 1. Local data loaded
        override fun onLocalCaloriesDataFetched(data: List<GetHealthData>) {
            Log.i(TAG, "📲 Loaded ${data.size} calories records from local DB")
            caloriesDataList = data.toMutableList()
            showSportSummaryFromSavedData()
            selectedDateHealthDataList()  // Update daily chart
        }
        
        // 2. Data uploaded to API
        override fun onNewStepsUploaded() {
            Log.i(TAG, "✅ Calories synced successfully")
        }
        
        // 3. Daily aggregates fetched
        override fun onSportDailyFetched(type: String, data: List<GetHealthData>) {
            if (type != "calories") return
            
            caloriesDataByDayList = data.toMutableList()
            
            // Clean invalid data (values > 10 million)
            caloriesDataByDayList.forEach { entry ->
                if (entry.value > 10_000_000) entry.value = 0.0
            }
            
            selectedWeekCaloriesDataList()   // Update weekly chart
            selectedMonthCaloriesDataList()  // Update monthly chart
        }
    })
    
    // Trigger sync
    helper.fetchLocalCaloriesData()
    helper.startSync()
    helper.fetchAndSyncSportDaily("calories")
}
```

**Data Cleaning:**
- Invalid values (> 10 million) set to 0
- Prevents chart display issues
- Likely from corrupted ring data or timestamp errors

---

### 3. Day View - Data Filtering & Display

```kotlin
private fun selectedDateHealthDataList() {
    if (caloriesDataList.isEmpty()) return
    
    // Filter by selected date
    val filteredData = caloriesDataList.filter { data ->
        try {
            // Parse timestamp or created_at
            val inputFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'")
                .withZone(ZoneId.of("UTC"))
            
            var createdDate = if (data.timestamp != null) {
                val instant = Instant.ofEpochSecond(data.timestamp.toLong())
                LocalDateTime.ofInstant(instant, ZoneId.of("UTC")).format(inputFormatter)
            } else {
                data.created_at
            }
            
            val createdAtInstant = Instant.from(inputFormatter.parse(createdDate))
            val createdAtDate = createdAtInstant.atZone(ZoneId.of("Asia/Kolkata")).toLocalDate()
            
            // Match selected date AND value < 5000 (filter outliers)
            createdAtDate.isEqual(selectedDate) && data.value.toInt() < 5000
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing date: ${data.created_at}", e)
            false
        }
    }
    
    // Update label
    val todayDate = LocalDate.now(ZoneId.of("Asia/Kolkata"))
    if (selectedDate.isEqual(todayDate)) {
        caloriesConsumptionLabel.text = "Today's Consumption"
    } else {
        val day = selectedDate.dayOfMonth
        val suffix = getOrdinalSuffix(day)  // "st", "nd", "rd", "th"
        val month = DateTimeFormatter.ofPattern("MMM").format(selectedDate)
        val fullText = "${day}${suffix} ${month} Consumption"
        
        // Apply superscript to suffix
        val spannable = SpannableString(fullText)
        val suffixStart = day.toString().length
        val suffixEnd = suffixStart + suffix.length
        spannable.setSpan(SuperscriptSpan(), suffixStart, suffixEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        spannable.setSpan(RelativeSizeSpan(0.6f), suffixStart, suffixEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        
        caloriesConsumptionLabel.text = spannable
    }
    
    // Calculate total
    val totalCaloriesToday = filteredData.sumOf { it.value.toInt() }
    caloriesValueText.text = totalCaloriesToday.toString()
    
    // Update chart
    populateChart(filteredData)
    getInitialData(filteredData)
}
```

**Ordinal Suffix Logic:**
```kotlin
private fun getOrdinalSuffix(day: Int): String {
    return when {
        day in 11..13 -> "th"
        day % 10 == 1 -> "st"
        day % 10 == 2 -> "nd"
        day % 10 == 3 -> "rd"
        else -> "th"
    }
}
```

**Examples:**
- 1st, 2nd, 3rd, 4th, 5th
- 11th, 12th, 13th (special case)
- 21st, 22nd, 23rd, 31st

---

### 4. Week View - Data Filtering & Display

```kotlin
private fun selectedWeekCaloriesDataList() {
    if (caloriesDataByDayList.isEmpty()) return
    
    val weeklyDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    
    // Filter by week range
    val filteredData = caloriesDataByDayList.filter { data ->
        try {
            data.vDate?.let { dateStr ->
                val itemDate = LocalDate.parse(dateStr, weeklyDateFormatter)
                itemDate in weekStartDate..weekEndDate
            } ?: false
        } catch (e: DateTimeParseException) {
            Log.e(TAG, "Invalid date format: ${data.vDate}", e)
            false
        }
    }.toMutableList()
    
    // Populate chart
    populateWeeklyCaloriesChart(filteredData)
    getInitialWeeklyData(filteredData)
    
    // Update range summary card
    val totalRangeCalories = filteredData.sumOf { it.value.toLong() }
    val displayFormatter = DateTimeFormatter.ofPattern("dd MMM")
    caloriesRangeLabel.text = "${weekStartDate.format(displayFormatter)} – ${weekEndDate.format(displayFormatter)}\nConsumption"
    caloriesRangeValueText.text = totalRangeCalories.toString()
}
```

**Week Navigation:**
```kotlin
private fun goToPreviousWeek() {
    weekStartDate = weekStartDate.minusWeeks(1)
    weekEndDate = weekEndDate.minusWeeks(1)
    updateWeekDates()
    selectedWeekCaloriesDataList()
}

private fun goToNextWeek() {
    weekStartDate = weekStartDate.plusWeeks(1)
    weekEndDate = weekEndDate.plusWeeks(1)
    updateWeekDates()
    selectedWeekCaloriesDataList()
}
```

**Week Starts Monday:**
```kotlin
private var weekStartDate: LocalDate = LocalDate.now().with(DayOfWeek.MONDAY)
private var weekEndDate: LocalDate = LocalDate.now().with(DayOfWeek.SUNDAY)
```

---

### 5. Month View - Data Filtering & Display

```kotlin
private fun selectedMonthCaloriesDataList() {
    if (caloriesDataByDayList.isEmpty()) return
    
    val monthlyDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    
    // Filter by month range
    val filteredData = caloriesDataByDayList.filter { data ->
        try {
            data.vDate?.let { dateStr ->
                val itemDate = LocalDate.parse(dateStr, monthlyDateFormatter)
                itemDate in monthStartDate..monthEndDate
            } ?: false
        } catch (e: DateTimeParseException) {
            Log.e(TAG, "Invalid date format: ${data.vDate}", e)
            false
        }
    }.toMutableList()
    
    // Populate chart
    populateMonthlyCaloriesChart(filteredData)
    getInitialWeeklyData(filteredData)
    
    // Update range summary card
    val totalRangeCalories = filteredData.sumOf { it.value.toLong() }
    val displayFormatter = DateTimeFormatter.ofPattern("MMM yyyy")
    caloriesRangeLabel.text = "${monthStartDate.format(displayFormatter)} Consumption"
    caloriesRangeValueText.text = totalRangeCalories.toString()
}
```

**Month Navigation:**
```kotlin
private fun goToPreviousMonth() {
    selectedDate = selectedDate.minusMonths(1)
    monthStartDate = selectedDate.withDayOfMonth(1)
    monthEndDate = selectedDate.withDayOfMonth(selectedDate.lengthOfMonth())
    updateMonthDates()
    selectedMonthCaloriesDataList()
}

private fun goToNextMonth() {
    selectedDate = selectedDate.plusMonths(1)
    monthStartDate = selectedDate.withDayOfMonth(1)
    monthEndDate = selectedDate.withDayOfMonth(selectedDate.lengthOfMonth())
    updateMonthDates()
    selectedMonthCaloriesDataList()
}
```

**Handles Variable Month Lengths:**
- February: 28/29 days
- April, June, September, November: 30 days
- January, March, May, July, August, October, December: 31 days

---

### 6. Chart Setup - Daily (Zoomable)

```kotlin
private fun setupChart() {
    // Basic configuration
    caloriesDataChart.description.isEnabled = false
    caloriesDataChart.setTouchEnabled(true)
    caloriesDataChart.isDragEnabled = true
    caloriesDataChart.setScaleEnabled(true)
    caloriesDataChart.setPinchZoom(true)
    caloriesDataChart.isScaleXEnabled = true
    caloriesDataChart.isScaleYEnabled = false
    
    // Grid lines
    caloriesDataChart.axisLeft.setDrawGridLines(true)
    caloriesDataChart.axisLeft.gridColor = Color.LTGRAY
    caloriesDataChart.axisLeft.gridLineWidth = 0.5f
    caloriesDataChart.axisRight.setDrawGridLines(false)
    caloriesDataChart.xAxis.setDrawGridLines(false)
    
    // Smooth scrolling
    caloriesDataChart.isDragDecelerationEnabled = true
    caloriesDataChart.dragDecelerationFrictionCoef = 0.9f
    
    // X-axis configuration
    val xAxis = caloriesDataChart.xAxis
    xAxis.position = XAxis.XAxisPosition.BOTTOM
    xAxis.granularity = 1f
    xAxis.labelCount = 6
    xAxis.axisMinimum = 0f
    xAxis.axisMaximum = 24f
    
    // Dynamic label formatting
    xAxis.valueFormatter = object : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            val visibleRange = caloriesDataChart.viewPortHandler.scaleX * 
                              (xAxis.axisMaximum - xAxis.axisMinimum)
            
            return if (visibleRange <= 5f) {
                // Zoomed in: show 30-min intervals
                val hour = value.toInt()
                val minute = ((value - hour) * 60).toInt()
                String.format("%02d:%02d", hour, minute)
            } else {
                // Zoomed out: show hours
                val hour = value.toInt()
                String.format("%02d:00", hour)
            }
        }
    }
    
    // Visible range
    caloriesDataChart.setVisibleXRangeMaximum(5f)
    
    // Touch listener for value selection
    caloriesDataChart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
        override fun onValueSelected(e: Entry?, h: Highlight?) {
            if (e != null) {
                val hour = e.x.toInt()
                val minute = ((e.x - hour) * 60).toInt()
                val timeFormatted = String.format("%02d:%02d", hour, minute)
                val caloriesValue = e.y.toInt()
                
                selectedChartTime.text = timeFormatted
                selectedChartValue.text = caloriesValue.toString()
            }
        }
        
        override fun onNothingSelected() {}
    })
    
    // Zoom listener for dynamic labels
    caloriesDataChart.setOnChartGestureListener(object : OnChartGestureListener {
        override fun onChartScale(me: MotionEvent?, scaleX: Float, scaleY: Float) {
            updateXAxisLabels()
        }
        // ... other gesture methods
    })
}
```

**Dynamic Label Update:**
```kotlin
private fun updateXAxisLabels() {
    val xAxis = caloriesDataChart.xAxis
    val visibleRange = caloriesDataChart.highestVisibleX - caloriesDataChart.lowestVisibleX
    
    if (visibleRange > 6) {
        // Show only full hours
        xAxis.valueFormatter = object : ValueFormatter() {
            override fun getFormattedValue(value: Float): String {
                return String.format("%02d:00", value.toInt())
            }
        }
        xAxis.granularity = 1f
    } else {
        // Show 30-minute intervals
        xAxis.valueFormatter = object : ValueFormatter() {
            override fun getFormattedValue(value: Float): String {
                val hour = value.toInt()
                val minutes = if (value - hour >= 0.5) 30 else 0
                return String.format("%02d:%02d", hour, minutes)
            }
        }
        xAxis.granularity = 0.5f
    }
    
    caloriesDataChart.invalidate()
}
```

---

### 7. Populate Daily Chart

```kotlin
private fun populateChart(healthDataList: List<GetHealthData>) {
    val caloriesEntries = mutableListOf<BarEntry>()
    
    healthDataList.forEach { healthData ->
        try {
            // Parse timestamp
            val inputFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'")
                .withZone(ZoneId.of("UTC"))
            
            val createdAt = if (healthData.timestamp != null) {
                val instant = Instant.ofEpochSecond(healthData.timestamp.toLong())
                LocalDateTime.ofInstant(instant, ZoneId.of("UTC")).format(inputFormatter)
            } else {
                healthData.created_at
            }
            
            val createdAtInstant = Instant.from(inputFormatter.parse(createdAt))
            val localTime = createdAtInstant.atZone(ZoneId.systemDefault()).toLocalTime()
            
            // Convert to hour fraction (e.g., 14:30 = 14.5)
            val hourFraction = localTime.hour + localTime.minute / 60f
            
            val value = healthData.value.toFloatOrNull() ?: 0f
            caloriesEntries.add(BarEntry(hourFraction, value))
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing date for chart: ${healthData.created_at}", e)
        }
    }
    
    // Sort by time
    val sortedEntries = caloriesEntries.sortedBy { it.x }
    
    // Set Y-axis range
    val maxYValue = healthDataList.maxOfOrNull { it.value.toFloatOrNull() ?: 0f } ?: 0f
    val leftAxis = caloriesDataChart.axisLeft
    leftAxis.axisMinimum = 0f
    leftAxis.axisMaximum = maxYValue + 2f
    caloriesDataChart.axisRight.isEnabled = false
    
    if (sortedEntries.isNotEmpty()) {
        // Create bar dataset
        val barDataSet = BarDataSet(sortedEntries, "Calories Data")
        barDataSet.color = Color.parseColor("#FFA500")  // Orange
        barDataSet.setDrawValues(false)
        
        val barData = BarData(barDataSet)
        barData.barWidth = 0.07f
        
        caloriesDataChart.legend.isEnabled = false
        caloriesDataChart.data = barData
        
        // Auto-scroll to latest data
        caloriesDataChart.post {
            val lastEntryX = sortedEntries.lastOrNull()?.x ?: 0f
            caloriesDataChart.moveViewToX(lastEntryX)
        }
        
        // Extend X-axis slightly
        caloriesDataChart.xAxis.axisMaximum = (sortedEntries.lastOrNull()?.x ?: 0f) + 1
        
        caloriesDataChart.invalidate()
    } else {
        caloriesDataChart.data = null
        caloriesDataChart.invalidate()
    }
}
```

---

### 8. Setup Weekly Chart

```kotlin
private fun setupWeeklyChart() {
    caloriesWeeklyDataChart.description.isEnabled = false
    caloriesWeeklyDataChart.setTouchEnabled(true)
    caloriesWeeklyDataChart.isDragEnabled = true
    caloriesWeeklyDataChart.setScaleEnabled(true)
    caloriesWeeklyDataChart.setPinchZoom(true)
    caloriesWeeklyDataChart.isScaleXEnabled = true
    caloriesWeeklyDataChart.isScaleYEnabled = false
    
    // Grid lines
    caloriesWeeklyDataChart.axisLeft.setDrawGridLines(true)
    caloriesWeeklyDataChart.axisLeft.gridColor = Color.LTGRAY
    caloriesWeeklyDataChart.axisLeft.gridLineWidth = 0.5f
    
    // X-axis for weekdays
    val xAxis = caloriesWeeklyDataChart.xAxis
    xAxis.position = XAxis.XAxisPosition.BOTTOM
    xAxis.setDrawGridLines(false)
    xAxis.granularity = 1f
    xAxis.labelCount = 7
    
    // Fixed labels: M, T, W, T, F, S, S
    xAxis.valueFormatter = object : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            return when (value.toInt()) {
                0 -> "M"   // Monday
                1 -> "T"   // Tuesday
                2 -> "W"   // Wednesday
                3 -> "T"   // Thursday
                4 -> "F"   // Friday
                5 -> "S"   // Saturday
                6 -> "S"   // Sunday
                else -> ""
            }
        }
    }
    
    xAxis.axisMinimum = 0f
    xAxis.axisMaximum = 6f
    caloriesWeeklyDataChart.setVisibleXRangeMaximum(7f)
    
    // Touch listener
    caloriesWeeklyDataChart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
        override fun onValueSelected(e: Entry?, h: Highlight?) {
            if (e != null && e is DateBarEntry) {
                val dayIndex = e.x.toInt()
                val dayLabel = when (dayIndex) {
                    0 -> "Monday"
                    1 -> "Tuesday"
                    2 -> "Wednesday"
                    3 -> "Thursday"
                    4 -> "Friday"
                    5 -> "Saturday"
                    6 -> "Sunday"
                    else -> ""
                }
                val value = e.y.toInt()
                val date = e.date  // Custom property in DateBarEntry
                
                selectedChartTime.text = "$dayLabel, $date"
                selectedChartValue.text = value.toString()
            }
        }
        
        override fun onNothingSelected() {}
    })
}
```

**Custom DateBarEntry Class:**
```kotlin
class DateBarEntry(
    x: Float,       // X-axis value (0-6 for days)
    y: Float,       // Y-axis value (calories)
    val date: String // Date in "yyyy-MM-dd" format
) : BarEntry(x, y)
```

---

### 9. Tab Switching Logic

```kotlin
private fun setupTabListeners() {
    val tabs = listOf(tabDay, tabWeek, tabMonth)
    
    tabDay.setOnClickListener {
        // Show daily chart only
        caloriesDataChart.visibility = View.VISIBLE
        caloriesWeeklyDataChart.visibility = View.GONE
        caloriesMonthlyDataChart.visibility = View.GONE
        
        // Hide range card (not needed for day view)
        caloriesRangeCard.visibility = View.GONE
        
        // Set mode flags
        isDayMode = true
        isWeekMode = false
        isMonthMode = false
        
        // Update tab visuals
        selectTab(tabDay, tabs)
        
        // Update date display
        updateDate()
    }
    
    tabWeek.setOnClickListener {
        // Show weekly chart only
        caloriesDataChart.visibility = View.GONE
        caloriesWeeklyDataChart.visibility = View.VISIBLE
        caloriesMonthlyDataChart.visibility = View.GONE
        
        // Show range card
        caloriesRangeCard.visibility = View.VISIBLE
        
        // Set mode flags
        isDayMode = false
        isWeekMode = true
        isMonthMode = false
        
        // Update tab visuals
        selectTab(tabWeek, tabs)
        
        // Update date display
        updateWeekDates()
    }
    
    tabMonth.setOnClickListener {
        // Show monthly chart only
        caloriesDataChart.visibility = View.GONE
        caloriesWeeklyDataChart.visibility = View.GONE
        caloriesMonthlyDataChart.visibility = View.VISIBLE
        
        // Show range card
        caloriesRangeCard.visibility = View.VISIBLE
        
        // Set mode flags
        isDayMode = false
        isWeekMode = false
        isMonthMode = true
        
        // Update tab visuals
        selectTab(tabMonth, tabs)
        
        // Update date display
        updateMonthDates()
    }
}

private fun selectTab(selectedTab: TextView, allTabs: List<TextView>) {
    allTabs.forEach {
        it.isSelected = false
        it.setBackgroundResource(android.R.color.transparent)
    }
    selectedTab.isSelected = true
    selectedTab.setBackgroundResource(R.drawable.tab_selected_bg)
}
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
| Tab Unselected BG | Light Gray | Tab container background |
| Tab Selected BG | White | Selected tab highlight |
| Bar Color | `#FFA500` | Chart bars (Orange) |
| Fire Icon BG (Today) | `#EB3223` | Red circle |
| Fire Icon BG (Range) | `#FF8C00` | Dark orange circle |
| Fire Icon | `#FFFFFF` | White flame |
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
| Calories Value | 24sp | Bold | Black |
| Unit Text | 18sp | Normal | Black |
| Range Label | 15sp | Normal | Black |
| Range Value | 24sp | Bold | Black |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 16dp horizontal |
| Card Margin | 12dp |
| Card Padding | 16dp (chart), 12dp/24dp (value cards) |
| Tab Container Margin | 16dp horizontal, 8dp top |
| Tab Padding | 12dp |
| Chart Card Height | 260dp |
| Icon Size | 50dp × 50dp |
| Arrow Icon Size | 18dp × 18dp |
| Corner Radius | 24dp |
| Elevation | 12-24dp |

---

## 📱 User Experience Flows

### Flow 1: View Today's Calories

```
Open Calories Fragment
    ↓
Day tab selected (default)
    ↓
Fetch local calories data
    ↓
Filter by today's date
    ↓
Display on bar chart
    ↓
Show total: "1,850 kcal"
    ↓
Auto-scroll to latest time
    ↓
Touch any bar to see exact time + value
```

---

### Flow 2: Navigate to Previous Day

```
Day tab selected
    ↓
Tap left arrow (◄)
    ↓
selectedDate -= 1 day
    ↓
Date display updates: "2025.01.02"
    ↓
Filter data by new date
    ↓
Chart updates with historical data
    ↓
Total updates to that day's value
    ↓
Label changes: "2nd Jan Consumption"
```

---

### Flow 3: Switch to Week View

```
Tap "Week" tab
    ↓
Tab background changes
    ↓
Daily chart hidden
    ↓
Weekly chart shown
    ↓
Range card appears
    ↓
Date shows: "03-09 Mar"
    ↓
7 bars displayed (M, T, W, T, F, S, S)
    ↓
Touch bar to see full date + value
    ↓
Range card shows total: "12,250 kcal"
```

---

### Flow 4: Navigate Weeks

```
Week tab selected
    ↓
Showing current week (Mon-Sun)
    ↓
Tap left arrow (◄)
    ↓
weekStartDate -= 7 days
    ↓
weekEndDate -= 7 days
    ↓
Date range updates: "26 Feb-04 Mar"
    ↓
Filter data by new week
    ↓
Chart updates with 7 bars
    ↓
Range total updates
```

---

### Flow 5: Switch to Month View

```
Tap "Month" tab
    ↓
Tab background changes
    ↓
Weekly chart hidden
    ↓
Monthly chart shown
    ↓
Date shows: "Mar 2025"
    ↓
Up to 31 bars displayed (1-31)
    ↓
Touch bar to see date + value
    ↓
Range card shows month total
```

---

### Flow 6: Zoom Daily Chart

```
Day tab selected
    ↓
Chart shows 5 hours visible
    ↓
X-axis labels: "08:00", "09:00", etc.
    ↓
Pinch to zoom in
    ↓
Visible range < 5 hours
    ↓
X-axis updates: "08:00", "08:30", "09:00", "09:30"
    ↓
Shows 30-minute intervals
    ↓
Pan left/right to scroll through 24 hours
```

---

### Flow 7: Ring Data Sync

```
Ring measures calories during activity
    ↓
Data stored locally in Sport DB
    ↓
AutoSyncStepsHelper triggers
    ↓
Fetch local data
    ↓
Upload to API (POST /add_user_health_data)
    ↓
Fetch daily aggregates (GET /user_health_data_by_day)
    ↓
Update all charts
    ↓
Update today's total
    ↓
User sees latest calories immediately
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### Data Loading
- [ ] Local database data fetched correctly
- [ ] API data fetched successfully
- [ ] Daily aggregates retrieved
- [ ] Data cleaned (values > 10M set to 0)
- [ ] Ring sync triggers properly
- [ ] ConnectionPreferences today totals loaded
- [ ] Fragment handles no data gracefully

#### Day View
- [ ] Filter by selected date works
- [ ] Today's label shows "Today's Consumption"
- [ ] Past dates show ordinal (1st, 2nd, 3rd, etc.)
- [ ] Total calories calculated correctly
- [ ] Chart displays bars at correct times
- [ ] Bars sorted by time (oldest to newest)
- [ ] Auto-scroll to latest data
- [ ] Touch bar shows time + value
- [ ] Previous/Next navigation works
- [ ] Date format correct (yyyy.MM.dd)

#### Week View
- [ ] Filter by week range works
- [ ] 7 bars displayed (Mon-Sun)
- [ ] X-axis labels correct (M, T, W, T, F, S, S)
- [ ] Touch bar shows full date + value
- [ ] Range card shows week total
- [ ] Range label format correct (dd MMM – dd MMM)
- [ ] Previous/Next week navigation works
- [ ] Week starts on Monday

#### Month View
- [ ] Filter by month range works
- [ ] Correct number of bars (28-31)
- [ ] Touch bar shows date + value
- [ ] Range card shows month total
- [ ] Range label format correct (MMM yyyy)
- [ ] Previous/Next month navigation works
- [ ] Handles February correctly (28/29 days)

#### Chart Interactions
- [ ] Zoom in/out works
- [ ] Pan/scroll works
- [ ] Labels update when zoomed
- [ ] Hour labels when zoomed out
- [ ] 30-min labels when zoomed in
- [ ] Touch selection highlights bar
- [ ] Selected values update display
- [ ] Chart rendering smooth

#### Tab Switching
- [ ] Day tab shows daily chart only
- [ ] Week tab shows weekly chart only
- [ ] Month tab shows monthly chart only
- [ ] Range card hidden in Day view
- [ ] Range card shown in Week/Month views
- [ ] Tab visuals update correctly
- [ ] Date format changes per tab

---

### UI/UX Tests

#### Visual Design
- [ ] Background color correct (#D9EDFF)
- [ ] Cards white with rounded corners
- [ ] Elevation shadows visible
- [ ] Text sizes correct
- [ ] Colors match specification
- [ ] Icons render properly
- [ ] Fire icon circles visible
- [ ] Tab backgrounds animate smoothly

#### Responsive Layout
- [ ] Scroll view works properly
- [ ] Chart fills card correctly
- [ ] Cards stack vertically
- [ ] Text doesn't overflow
- [ ] Charts adapt to screen width
- [ ] Portrait mode works
- [ ] Landscape mode works

#### Edge Cases
- [ ] No data for selected date
- [ ] Very high calorie values
- [ ] Very low calorie values
- [ ] Missing timestamps handled
- [ ] Corrupted data filtered out
- [ ] API timeout handled
- [ ] Network error handled
- [ ] Fragment destroyed during load

---

## 🚀 Future Enhancements

### 1. Calorie Goals

```xml
┌───────────────────────────────────┐
│  Daily Calorie Goal               │
│  1,850 / 2,000 kcal    (92%)     │
│  ████████████████████░░           │
└───────────────────────────────────┘
```

**Features:**
- Set daily calorie burn goal
- Progress bar visualization
- Percentage display
- Goal achievement notifications

---

### 2. Activity Breakdown

```xml
┌───────────────────────────────────┐
│  Calories by Activity             │
│                                   │
│  🚶 Walking: 450 kcal (30%)      │
│  🏃 Running: 600 kcal (40%)      │
│  🚴 Cycling: 450 kcal (30%)      │
└───────────────────────────────────┘
```

**Features:**
- Break down by activity type
- Pie chart visualization
- Most active period
- Activity recommendations

---

### 3. Calorie vs. Intake Comparison

```xml
┌───────────────────────────────────┐
│  Calories Balance                 │
│                                   │
│  Burned: 1,850 kcal   🔥         │
│  Consumed: 2,100 kcal 🍽️         │
│  Balance: +250 kcal (Surplus)     │
└───────────────────────────────────┘
```

**Features:**
- Track food calories (manual or API)
- Calculate net balance
- Surplus/deficit indicator
- Weight management insights

---

### 4. Weekly/Monthly Averages

```xml
┌───────────────────────────────────┐
│  Weekly Average                   │
│                                   │
│  This Week: 1,850 kcal/day       │
│  Last Week: 1,750 kcal/day       │
│  Change: +100 kcal (+5.7%)       │
└───────────────────────────────────┘
```

**Features:**
- Average calories per day
- Week-over-week comparison
- Month-over-month comparison
- Trend arrows (↑ ↓ →)

---

### 5. Export Data

```xml
┌───────────────────────────────────┐
│  [Export CSV] [Export PDF]        │
│                                   │
│  Share your calorie data          │
│  with your doctor or trainer      │
└───────────────────────────────────┘
```

**Features:**
- Export to CSV
- Export to PDF with charts
- Email to self/trainer
- Share via apps

---

### 6. Rest Days Tracker

```xml
┌───────────────────────────────────┐
│  Rest Days This Month: 4          │
│                                   │
│  M  T  W  T  F  S  S             │
│  ✓  ✓  ○  ✓  ✓  ✓  ○            │
└───────────────────────────────────┘
```

**Features:**
- Mark rest days
- Calendar view
- Optimal rest day suggestions
- Recovery indicators

---

### 7. Calorie Streaks

```xml
┌───────────────────────────────────┐
│  Current Streak: 12 days 🔥      │
│  Longest Streak: 45 days         │
│                                   │
│  You've hit your goal 12 days    │
│  in a row. Keep it up!           │
└───────────────────────────────────┘
```

**Features:**
- Track consecutive days hitting goal
- Longest streak record
- Achievement badges
- Motivational messages

---

### 8. Personalized Insights

```xml
┌───────────────────────────────────┐
│  Insights                         │
│                                   │
│  💡 You burn most calories on     │
│     weekends (avg 2,100 kcal)     │
│                                   │
│  💡 Your most active time is      │
│     6-8 PM (avg 300 kcal/hour)    │
└───────────────────────────────────┘
```

**Features:**
- AI-powered insights
- Pattern detection
- Personalized recommendations
- Actionable tips

---

### 9. Metabolic Rate Estimation

```xml
┌───────────────────────────────────┐
│  Estimated BMR: 1,650 kcal/day   │
│  Active Burn: +850 kcal          │
│  Total: 2,500 kcal/day           │
│                                   │
│  Your metabolism is healthy!      │
└───────────────────────────────────┘
```

**Features:**
- Calculate Basal Metabolic Rate
- Factor in activity level
- Total Daily Energy Expenditure
- Metabolism health assessment

---

### 10. Integration with Fitness Apps

```xml
┌───────────────────────────────────┐
│  Connected Apps                   │
│                                   │
│  ● Google Fit                     │
│  ● MyFitnessPal                   │
│  ○ Strava (Not connected)         │
└───────────────────────────────────┘
```

**Features:**
- Sync with Google Fit
- Import from MyFitnessPal
- Export to Strava
- Two-way data sync

---

## 📊 Analytics & Tracking

### Key Metrics

**User Engagement:**
- Calories fragment views
- Tab switches (Day/Week/Month)
- Chart interactions (zoom, pan, touch)
- Navigation button clicks
- Average time on screen

**Data Patterns:**
- Average daily calories
- Peak calorie burn times
- Most active days
- Weekly patterns
- Monthly trends

**Feature Usage:**
- Chart zoom frequency
- Historical data views
- Range card interactions
- Sync trigger counts

### Implementation

```kotlin
// Track fragment view
Analytics.logEvent("calories_screen_viewed")

// Track tab switches
Analytics.logEvent("calories_tab_switched", mapOf(
    "from_tab" to fromTab,  // "day", "week", "month"
    "to_tab" to toTab
))

// Track navigation
Analytics.logEvent("calories_date_navigated", mapOf(
    "direction" to direction,  // "previous", "next"
    "mode" to mode,           // "day", "week", "month"
    "date" to selectedDate
))

// Track chart interactions
Analytics.logEvent("calories_chart_zoomed", mapOf(
    "zoom_level" to zoomLevel,
    "mode" to "day"
))

Analytics.logEvent("calories_bar_selected", mapOf(
    "time" to time,
    "value" to value,
    "mode" to mode
))
```

---

**Document Version:** 1.0  
**Last Updated:** May 23, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

