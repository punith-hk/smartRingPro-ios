# Notifications Fragment - Design & Implementation

**HEARTO App - Notification Center & Alert Management**  
**Fragment:** `NotificationsFragment.kt`  
**Layout:** `fragment_notifications.xml`  
**Item Layout:** `item_notification.xml`  
**Dialog Layout:** `dialog_notification_detail.xml`  
**Repository:** `NotificationsRepository.kt`  
**Cache:** `NotificationCache.kt`

---

## 📋 Overview

The Notifications Fragment serves as the central notification center for all health alerts, system messages, and Firebase push notifications. It provides a clean, organized list view of notifications with unread indicators, vital sign summaries, timestamp information, and detailed expandable views. The fragment integrates with Firebase Cloud Messaging, maintains a local cache for performance, and syncs with the badge counter in the top navigation bar.

**Key Features:**
- RecyclerView list of all notifications
- Unread indicator (blue dot)
- Vital signs chips (Heart Rate, SpO2, BP)
- Detailed dialog view with full vitals breakdown
- Mark as read functionality
- Auto-refresh notification badge
- Firebase push notification integration
- Empty state and loading states
- Custom notification sounds (HEARTO_warning.wav)
- 5-minute cache for performance optimization

---

## 🎨 Design Architecture

### Screen Structure

```
FrameLayout (Full Height)
├── RecyclerView (Notification List)
│   └── Item Cards (Repeating)
│       ├── Unread Dot (Blue, 9dp)
│       ├── Title (Bold, Auto-generated if blank)
│       ├── Message Preview (2 lines max)
│       ├── Vitals Chips (HR, SpO2, BP)
│       └── Timestamp (Relative time)
├── Loading View (ProgressBar + Text)
└── Empty View (Icon + Message)
```

---

## 🎨 Screen Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Gray
│  Notifications    🔔 (Badge: 3)     │  Background
│                                     │  #F2F4F7
│  ┌───────────────────────────────┐ │
│  │● Heart Rate Alert             │ │  Unread
│  │  Your heart rate is 125 bpm.  │ │  (Blue dot)
│  │  ❤️ 125 bpm 🩸 98% 🫀 120/80 │ │  Vitals
│  │            23 May 2026, 02:15 │ │  Chips
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Blood Pressure Alert         │ │  Read
│  │  Your BP is higher than...    │ │  (No dot)
│  │  🫀 145/95 mmHg               │ │  White BG
│  │            22 May 2026, 08:30 │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  HRV Alert                    │ │
│  │  Your HRV is lower than...    │ │
│  │  📈 35 ms                     │ │
│  │            21 May 2026, 06:45 │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Data Flow & Architecture

### Complete Notification Flow

```
Server/Firebase
    ↓
Push Notification (FCM)
    ↓
MyFirebaseMessagingService
    ├─ Display system notification
    ├─ Play custom sound (warning.wav)
    ├─ Invalidate NotificationCache
    └─ Store in backend database
    ↓
[User Opens App]
    ↓
HomeActivity.onResume()
    ├─ Check NotificationCache.isValid
    │   ├─ Valid (< 5 min) → Use cache
    │   └─ Invalid → Fetch from API
    │
    ├─ GET /notifications/{userId}
    │   ↓
    │   API Response:
    │   {
    │     "message": "success",
    │     "data": [
    │       {
    │         "id": 123,
    │         "user_id": 456,
    │         "timestamp": 1716450900,
    │         "sent": 1,
    │         "status": 0,  // 0=unread, 1=read
    │         "title": "Heart Rate Alert",
    │         "message": "Your heart rate is 125 bpm",
    │         "vitals": "{\"heart_rate\":\"125\",\"blood_oxygen\":\"98\"}",
    │         "created_at": "2026-05-23T14:15:00.000000Z",
    │         "updated_at": "2026-05-23T14:15:00.000000Z"
    │       },
    │       ...
    │     ]
    │   }
    │
    ├─ NotificationCache.update(items)
    ├─ Update bell badge count
    └─ Notify DashboardFragment (latest alert card)
    ↓
[User Taps Bell Icon]
    ↓
Navigate to NotificationsFragment
    ↓
fetchNotifications()
    ├─ GET /notifications/{userId}
    ├─ Update NotificationCache
    ├─ Update badge count
    └─ Display in RecyclerView
    ↓
[User Taps Notification]
    ↓
onNotificationClicked(item, position)
    ├─ Show detail dialog
    ├─ Parse vitals JSON
    ├─ Display full breakdown
    └─ Mark as read if unread
        ↓
        POST /notifications/mark-as-read
        Body: {
            "id": 123,
            "user_id": 456
        }
        ↓
        Response: {
            "message": "Notification marked as read"
        }
        ↓
        ├─ Update item.status = 1
        ├─ Invalidate cache
        ├─ Refresh HomeActivity badge
        └─ Update UI (remove dot, change BG)
```

---

## 🔔 Firebase Cloud Messaging Integration

### Push Notification Flow

```
Backend Server Triggers Alert
    ↓
Send FCM Message
    ↓
Firebase Cloud Messaging
    ↓
Device Receives Notification
    ↓
MyFirebaseMessagingService.onMessageReceived()
    ↓
Extract Data:
    - title: String
    - body: String
    - data: Map<String, String>
    ↓
Play Custom Sound:
    - File: res/raw/warning.wav (HEARTO_warning.wav)
    - Duration: ~2 seconds
    - Vibration: [0, 300, 200, 300]
    ↓
Show System Notification:
    - Title: from FCM message
    - Body: from FCM message
    - Icon: @drawable/baseline_album_24
    - Priority: HIGH
    - Auto-cancel: true
    ↓
Invalidate NotificationCache
    (Forces fresh fetch on next open)
    ↓
User Taps Notification
    ↓
Open App → Notifications Fragment
```

---

### FCM Configuration

**Notification Channel (Android 8.0+):**
```kotlin
Channel ID: "default_channel"
Name: "General Notifications"
Importance: IMPORTANCE_HIGH
Features:
  - Lights: Enabled
  - Vibration: Enabled
  - Sound: warning.wav (custom)
```

**Custom Sound Setup:**
```kotlin
// Location: app/src/main/res/raw/warning.wav
val soundUri = Uri.parse("android.resource://${packageName}/${R.raw.warning}")

NotificationChannel:
  setSound(soundUri, audioAttributes)

NotificationCompat.Builder:
  setSound(soundUri)
```

**Vibration Pattern:**
```kotlin
longArrayOf(0, 300, 200, 300)
// 0ms wait, 300ms vibrate, 200ms pause, 300ms vibrate
```

---

## 📱 Fragment UI Components

### Background
- **Color:** #F2F4F7 (Light Gray)
- **Container:** FrameLayout

---

### 1. RecyclerView (Notification List)

**Specs:**
- **ID:** `notificationsRecycler`
- **Layout Manager:** LinearLayoutManager (Vertical)
- **Adapter:** NotificationsAdapter
- **Padding:** 8dp
- **Item Spacing:** 5dp vertical, 12dp horizontal (in item layout)
- **Visibility:** Visible only when data exists

---

### 2. Loading View

```xml
┌───────────────────┐
│       ⏳          │  ProgressBar
│ Loading           │  + Text
│ notifications...  │
└───────────────────┘
```

**Container:**
- **ID:** `loadingView`
- **Layout:** Vertical LinearLayout
- **Alignment:** Center of screen
- **Visibility:** Visible during API call

**ProgressBar:**
- **Size:** 48dp × 48dp
- **Tint:** #15558D (Primary Blue)
- **Style:** Indeterminate

**Text:**
- **Text:** "Loading notifications..."
- **Size:** 14sp
- **Color:** #666666 (Gray)
- **Margin Top:** 16dp

---

### 3. Empty View

```xml
┌───────────────────┐
│       🔔          │  Bell Icon
│ No notifications  │  (Grayed out)
│ yet               │
│ You don't have    │  Message
│ any notifications │
│ at the moment     │
└───────────────────┘
```

**Container:**
- **ID:** `emptyView`
- **Layout:** Vertical LinearLayout
- **Alignment:** Center of screen
- **Padding:** 32dp
- **Visibility:** Gone (shown when no data)

**Icon:**
- **Drawable:** `baseline_notifications_24`
- **Size:** 80dp × 80dp
- **Tint:** #CCCCCC (Light Gray)
- **Margin Bottom:** 16dp

**Title:**
- **Text:** "No notifications yet"
- **Size:** 18sp
- **Color:** #666666
- **Style:** Bold
- **Margin Bottom:** 8dp

**Subtitle:**
- **Text:** "You don't have any notifications at the moment"
- **Size:** 14sp
- **Color:** #999999
- **Max Width:** 280dp
- **Alignment:** Center

---

## 🎴 Notification Item Card Design

### Card Structure

```xml
┌─────────────────────────────────────┐
│ ●  Heart Rate Alert                 │  Unread Dot + Title
│    Your heart rate is elevated at   │  Message (2 lines)
│    125 bpm. Please take rest.       │
│    ❤️ 125 bpm  🩸 98%  🫀 120/80   │  Vitals Chips
│                 23 May 2026, 02:15  │  Timestamp
└─────────────────────────────────────┘
```

**Card Specs:**
- **Type:** CardView
- **Corner Radius:** 12dp
- **Elevation:** 3dp
- **Margin:** 12dp horizontal, 5dp vertical
- **Padding:** 14dp
- **Background:**
  - **Unread:** #EDF6FF (Light blue tint)
  - **Read:** #FFFFFF (White)

---

### Components

#### 1. Unread Dot

**Specs:**
- **ID:** `unreadDot`
- **Shape:** Circle (circle_shape drawable)
- **Size:** 9dp × 9dp
- **Color:** #0D99FF (Primary Blue)
- **Margin:** 5dp top, 10dp end
- **Visibility:**
  - **Unread (status=0):** VISIBLE
  - **Read (status=1):** INVISIBLE (preserves layout space)

---

#### 2. Title

**Specs:**
- **ID:** `itemTitle`
- **Size:** 15sp
- **Color:** Black
- **Style:** Bold
- **Max Lines:** 1
- **Ellipsize:** End

**Auto-Generation Logic:**
```kotlin
fun resolveTitle(item: NotificationItem): String {
    if (!item.title.isNullOrBlank()) return item.title
    
    val msg = item.message.trim()
    return when {
        msg.contains("blood sugar", true)   -> "Blood Sugar Alert"
        msg.contains("hrv", true)           -> "HRV Alert"
        msg.contains("heart rate", true)    -> "Heart Rate Alert"
        msg.contains("blood pressure", true)-> "Blood Pressure Alert"
        msg.contains("blood oxygen", true)  -> "Blood Oxygen Alert"
        msg.contains("temperature", true)   -> "Temperature Alert"
        msg.contains("vitals", true)        -> "Vitals Alert"
        else                                -> "Health Alert"
    }
}
```

**Examples:**
- Empty title + "Your heart rate is 125 bpm" → "Heart Rate Alert"
- Empty title + "Blood oxygen is low at 92%" → "Blood Oxygen Alert"
- Provided title → Use as-is

---

#### 3. Message Preview

**Specs:**
- **ID:** `itemMessage`
- **Size:** 13sp
- **Color:** #555555 (Dark Gray)
- **Max Lines:** 2
- **Ellipsize:** End
- **Padding Top:** 4dp

**Content:**
- Full message from API
- Truncated to 2 lines if longer
- Ends with "..." if truncated

---

#### 4. Vitals Chips Row

**Container:**
- **ID:** `vitalsRow`
- **Layout:** Horizontal LinearLayout
- **Margin Top:** 8dp
- **Visibility:** Visible only if vitals JSON exists

**Chip 1 - Heart Rate:**
- **ID:** `chipHr`
- **Background:** `@drawable/chip_bg_red` (Light red rounded)
- **Text Color:** #E53935 (Red)
- **Size:** 11sp
- **Padding:** 8dp horizontal, 3dp vertical
- **Margin End:** 6dp
- **Format:** "❤️ 125 bpm"

**Chip 2 - Blood Oxygen (SpO2):**
- **ID:** `chipSpo2`
- **Background:** `@drawable/chip_bg_blue` (Light blue rounded)
- **Text Color:** #1565C0 (Blue)
- **Size:** 11sp
- **Padding:** 8dp horizontal, 3dp vertical
- **Margin End:** 6dp
- **Format:** "🩸 98%"

**Chip 3 - Blood Pressure:**
- **ID:** `chipBp`
- **Background:** `@drawable/chip_bg_green` (Light green rounded)
- **Text Color:** #2E7D32 (Green)
- **Size:** 11sp
- **Padding:** 8dp horizontal, 3dp vertical
- **Format:** "🫀 120/80"

**Vitals JSON Parsing:**
```kotlin
fun parseVitals(vitalsJson: String?): Map<String, String> {
    if (vitalsJson.isNullOrBlank()) return emptyMap()
    return try {
        val obj = JSONObject(vitalsJson)
        val map = mutableMapOf<String, String>()
        obj.keys().forEach { key -> map[key] = obj.getString(key) }
        map
    } catch (e: Exception) {
        emptyMap()
    }
}

// Example JSON:
{
    "heart_rate": "125",
    "blood_oxygen": "98",
    "blood_pressure": "120/80"
}
```

---

#### 5. Timestamp

**Specs:**
- **ID:** `itemTime`
- **Size:** 11sp
- **Color:** #AAAAAA (Light Gray)
- **Alignment:** Text end (right-aligned)
- **Padding Top:** 6dp
- **Format:** "dd MMM yyyy, hh:mm a"

**Examples:**
- "23 May 2026, 02:15 PM"
- "22 May 2026, 08:30 AM"
- "21 May 2026, 06:45 PM"

**Formatting:**
```kotlin
val dateFormat = SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault())
val formattedDate = dateFormat.format(Date(item.timestamp * 1000L))
```

---

## 📋 Notification Detail Dialog

### Dialog Structure

```
┌─────────────────────────────────────┐
│  Heart Rate Alert                   │  Title
│  ─────────────────────────────────  │
│                                     │
│  Your heart rate is elevated at     │  Full Message
│  125 bpm. Please take rest and      │  (No truncation)
│  monitor your vitals.               │
│                                     │
│  23 May 2026, 02:15 PM              │  Full Timestamp
│                                     │
│  ─── Vital Signs ───                │  Section Header
│                                     │
│  ❤️  Heart Rate:        125 bpm    │  Vital 1
│  🩸 Blood Oxygen:       98 %       │  Vital 2
│  🫀 Blood Pressure:     120/80 mmHg│  Vital 3
│  🌡️  Temperature:       36.5 °C    │  Vital 4 (if exists)
│  📈 HRV:                45 ms      │  Vital 5 (if exists)
│  🍬 Blood Sugar:        95 mg/dL   │  Vital 6 (if exists)
│                                     │
│  ┌───────────────────────────────┐ │
│  │            OK                 │ │  Close Button
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Dialog Specs:**
- **Layout:** `dialog_notification_detail.xml`
- **Style:** Custom with transparent window background
- **Corner Radius:** Rounded (via dialog_confirm drawable)
- **Padding:** 24dp
- **Max Width:** 90% of screen width

---

### Dialog Components

#### Title
- **ID:** `dialogTitle`
- **Text:** Resolved title (auto-generated if needed)
- **Size:** 20sp
- **Color:** Black
- **Style:** Bold

#### Message
- **ID:** `dialogMessage`
- **Text:** Full message (no truncation)
- **Size:** 15sp
- **Color:** #555555
- **Max Lines:** None (full display)

#### Timestamp
- **ID:** `dialogTime`
- **Format:** "dd MMM yyyy, hh:mm a"
- **Size:** 13sp
- **Color:** #999999

#### Vitals Container
- **ID:** `dialogVitalsContainer`
- **Layout:** Vertical LinearLayout
- **Visibility:** Visible only if vitals exist

**Vital Row Template (item_vital_row.xml):**
```xml
┌─────────────────────────────────┐
│  ❤️  Heart Rate:     125 bpm   │
└─────────────────────────────────┘
```

**Components:**
- **Label:** Icon + Name (e.g., "❤️ Heart Rate:")
  - **ID:** `vitalLabel`
  - **Size:** 14sp
  - **Color:** Black
  - **Style:** Normal

- **Value:** Value + Unit (e.g., "125 bpm")
  - **ID:** `vitalValue`
  - **Size:** 14sp
  - **Color:** Black
  - **Style:** Bold

**Vital Mappings:**
```kotlin
val vitalLabels = mapOf(
    "heart_rate"      to "❤️  Heart Rate",
    "blood_oxygen"    to "🩸 Blood Oxygen",
    "blood_pressure"  to "🫀 Blood Pressure",
    "blood_sugar"     to "🍬 Blood Sugar",
    "temperature"     to "🌡️  Temperature",
    "hrv"             to "📈 HRV"
)

val vitalUnits = mapOf(
    "heart_rate"      to "bpm",
    "blood_oxygen"    to "%",
    "blood_pressure"  to "mmHg",
    "blood_sugar"     to "mg/dL",
    "temperature"     to "°C",
    "hrv"             to "ms"
)
```

---

#### OK Button
- **ID:** `btnOk`
- **Style:** `@style/AppButton`
- **Text:** "OK"
- **Width:** Match parent
- **Action:** Dismiss dialog

---

## 🔧 Core Functionality

### 1. Fragment Initialization

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)
    
    // Setup RecyclerView
    binding.notificationsRecycler.layoutManager = LinearLayoutManager(requireContext())
    binding.notificationsRecycler.adapter = adapter
    
    // Load user ID
    val prefs = requireContext().getSharedPreferences("AppPreferences", Context.MODE_PRIVATE)
    userId = prefs.getInt("id", prefs.getInt("user_id", -1))
    
    // Fetch notifications
    fetchNotifications()
}
```

---

### 2. Fetch Notifications from API

```kotlin
private fun fetchNotifications() {
    if (userId == -1) return
    
    // Show loading state
    binding.loadingView.visibility = View.VISIBLE
    binding.emptyView.visibility = View.GONE
    binding.notificationsRecycler.visibility = View.GONE
    
    // API Call
    repository.getNotifications(userId, forceRefresh = true)
        .enqueue(object : Callback<NotificationsResponse> {
            override fun onResponse(call, response) {
                if (_binding == null) return
                
                binding.loadingView.visibility = View.GONE
                
                if (response.isSuccessful && response.body() != null) {
                    val notifications = response.body()!!.data
                    
                    // Update shared cache
                    NotificationCache.update(notifications)
                    
                    // Update badge in HomeActivity
                    (activity as? HomeActivity)
                        ?.updateNotificationBadge(NotificationCache.unreadCount)
                    
                    // Display data or empty state
                    if (notifications.isEmpty()) {
                        binding.emptyView.visibility = View.VISIBLE
                    } else {
                        binding.notificationsRecycler.visibility = View.VISIBLE
                        adapter.setItems(notifications.toMutableList())
                    }
                } else {
                    Log.e(TAG, "Failed: ${response.code()}")
                    binding.emptyView.visibility = View.VISIBLE
                }
            }
            
            override fun onFailure(call, t) {
                if (_binding == null) return
                Log.e(TAG, "Failure: ${t.message}")
                binding.loadingView.visibility = View.GONE
                binding.emptyView.visibility = View.VISIBLE
            }
        })
}
```

**API Endpoint:**
```
GET https://hearto.in/api/notifications/{userId}

Response:
{
    "message": "success",
    "data": [
        {
            "id": 123,
            "user_id": 456,
            "timestamp": 1716450900,
            "sent": 1,
            "status": 0,
            "title": "Heart Rate Alert",
            "message": "Your heart rate is elevated at 125 bpm",
            "vitals": "{\"heart_rate\":\"125\",\"blood_oxygen\":\"98\"}",
            "created_at": "2026-05-23T14:15:00.000000Z",
            "updated_at": "2026-05-23T14:15:00.000000Z"
        }
    ]
}
```

---

### 3. Notification Click Handler

```kotlin
private fun onNotificationClicked(item: NotificationItem, position: Int) {
    // 1. Resolve title
    val title = resolveTitle(item)
    
    // 2. Parse vitals JSON
    val vitalsMap = parseVitals(item.vitals)
    
    // 3. Inflate dialog view
    val dialogView = LayoutInflater.from(requireContext())
        .inflate(R.layout.dialog_notification_detail, null)
    
    // 4. Set basic info
    dialogView.findViewById<TextView>(R.id.dialogTitle).text = title
    dialogView.findViewById<TextView>(R.id.dialogMessage).text = item.message
    dialogView.findViewById<TextView>(R.id.dialogTime).text =
        SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault())
            .format(Date(item.timestamp * 1000L))
    
    // 5. Build vitals rows
    val vitalsContainer = dialogView.findViewById<LinearLayout>(R.id.dialogVitalsContainer)
    if (vitalsMap.isNotEmpty()) {
        vitalsContainer.visibility = View.VISIBLE
        
        val vitalLabels = mapOf(
            "heart_rate"      to "❤️  Heart Rate",
            "blood_oxygen"    to "🩸 Blood Oxygen",
            "blood_pressure"  to "🫀 Blood Pressure",
            "blood_sugar"     to "🍬 Blood Sugar",
            "temperature"     to "🌡️  Temperature",
            "hrv"             to "📈 HRV"
        )
        
        val vitalUnits = mapOf(
            "heart_rate"      to "bpm",
            "blood_oxygen"    to "%",
            "blood_pressure"  to "mmHg",
            "blood_sugar"     to "mg/dL",
            "temperature"     to "°C",
            "hrv"             to "ms"
        )
        
        val inflater = LayoutInflater.from(requireContext())
        vitalLabels.forEach { (key, label) ->
            val value = vitalsMap[key] ?: return@forEach
            val row = inflater.inflate(R.layout.item_vital_row, vitalsContainer, false)
            row.findViewById<TextView>(R.id.vitalLabel).text = label
            row.findViewById<TextView>(R.id.vitalValue).text = "$value ${vitalUnits[key] ?: ""}"
            vitalsContainer.addView(row)
        }
    } else {
        vitalsContainer.visibility = View.GONE
    }
    
    // 6. Show dialog
    val alertDialog = AlertDialog.Builder(requireContext())
        .setView(dialogView)
        .create()
    alertDialog.window?.setBackgroundDrawableResource(android.R.color.transparent)
    
    dialogView.findViewById<Button>(R.id.btnOk).setOnClickListener {
        alertDialog.dismiss()
    }
    
    alertDialog.show()
    
    // 7. Mark as read (if unread)
    if (item.status == 0 && userId != -1) {
        markNotificationAsRead(item, position)
    }
}
```

---

### 4. Mark as Read

```kotlin
private fun markNotificationAsRead(item: NotificationItem, position: Int) {
    repository.markAsRead(item.id, userId)
        .enqueue(object : Callback<SimpleResponse> {
            override fun onResponse(call, response) {
                if (response.isSuccessful) {
                    // Update local item
                    item.status = 1
                    
                    // Refresh adapter (removes dot, changes BG)
                    adapter.notifyItemChanged(position)
                    
                    // Invalidate cache + force refresh
                    NotificationCache.invalidate()
                    (activity as? HomeActivity)?.refreshNotifications(forceRefresh = true)
                }
            }
            
            override fun onFailure(call, t) {
                Log.e(TAG, "Mark as read error: ${t.message}")
            }
        })
}
```

**API Endpoint:**
```
POST https://hearto.in/api/notifications/mark-as-read

Body:
{
    "id": 123,
    "user_id": 456
}

Response:
{
    "message": "Notification marked as read"
}
```

**Effects:**
1. Update item status: 0 → 1
2. Adapter refreshes item view
3. Unread dot disappears
4. Card background: #EDF6FF → #FFFFFF
5. Cache invalidated
6. Badge count decreases
7. Dashboard alert card updates

---

## 🔄 Notification Cache System

### NotificationCache.kt

**Purpose:**
- In-memory singleton cache
- Prevents API spam on onResume()
- Shared between HomeActivity badge + DashboardFragment alert card
- 5-minute TTL (Time To Live)

**Structure:**
```kotlin
object NotificationCache {
    private const val TTL_MS = 5 * 60 * 1000L  // 5 minutes
    
    private var cachedNotifications: List<NotificationItem> = emptyList()
    private var lastFetchedAt: Long = 0L
    
    // Properties
    val isValid: Boolean
        get() = cachedNotifications.isNotEmpty() &&
                (System.currentTimeMillis() - lastFetchedAt) < TTL_MS
    
    val unreadCount: Int
        get() = cachedNotifications.count { it.status == 0 }
    
    val latest: NotificationItem?
        get() = cachedNotifications.firstOrNull()
    
    val all: List<NotificationItem>
        get() = cachedNotifications
    
    // Methods
    fun update(notifications: List<NotificationItem>) {
        cachedNotifications = notifications
        lastFetchedAt = System.currentTimeMillis()
    }
    
    fun invalidate() {
        lastFetchedAt = 0L
    }
}
```

**Usage Flow:**
```
HomeActivity.onResume()
    ↓
Check NotificationCache.isValid
    ├─ Valid (< 5 min)
    │   ├─ Use cache
    │   ├─ Update badge from cache
    │   └─ Update Dashboard from cache
    │
    └─ Invalid (> 5 min or empty)
        ├─ Fetch from API
        ├─ Update cache
        ├─ Update badge
        └─ Update Dashboard

Invalidate Triggers:
- FCM notification received
- Notification marked as read
- Manual refresh
```

---

## 📊 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#F2F4F7` | Screen background (light gray) |
| Card Unread BG | `#EDF6FF` | Unread notification card (light blue tint) |
| Card Read BG | `#FFFFFF` | Read notification card (white) |
| Unread Dot | `#0D99FF` | Blue dot indicator |
| Title Text | `#000000` | Black |
| Message Text | `#555555` | Dark gray |
| Timestamp Text | `#AAAAAA` | Light gray |
| Chip Red BG | Light Red | Heart rate chip background |
| Chip Red Text | `#E53935` | Heart rate chip text |
| Chip Blue BG | Light Blue | SpO2 chip background |
| Chip Blue Text | `#1565C0` | SpO2 chip text |
| Chip Green BG | Light Green | BP chip background |
| Chip Green Text | `#2E7D32` | BP chip text |
| Loading Text | `#666666` | Loading message |
| Empty Icon | `#CCCCCC` | Empty state icon tint |
| Empty Title | `#666666` | Empty state title |
| Empty Subtitle | `#999999` | Empty state subtitle |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Card Title | 15sp | Bold | Black |
| Card Message | 13sp | Normal | #555555 |
| Card Timestamp | 11sp | Normal | #AAAAAA |
| Vitals Chip | 11sp | Normal | Varies (Red/Blue/Green) |
| Dialog Title | 20sp | Bold | Black |
| Dialog Message | 15sp | Normal | #555555 |
| Dialog Time | 13sp | Normal | #999999 |
| Vital Label | 14sp | Normal | Black |
| Vital Value | 14sp | Bold | Black |
| Loading Text | 14sp | Normal | #666666 |
| Empty Title | 18sp | Bold | #666666 |
| Empty Subtitle | 14sp | Normal | #999999 |

### Spacing

| Element | Value |
|---------|-------|
| RecyclerView Padding | 8dp |
| Card Margin Horizontal | 12dp |
| Card Margin Vertical | 5dp |
| Card Corner Radius | 12dp |
| Card Elevation | 3dp |
| Card Padding | 14dp |
| Unread Dot Size | 9dp × 9dp |
| Unread Dot Margin | 5dp top, 10dp end |
| Message Padding Top | 4dp |
| Vitals Row Margin Top | 8dp |
| Chip Padding Horizontal | 8dp |
| Chip Padding Vertical | 3dp |
| Chip Margin End | 6dp |
| Timestamp Padding Top | 6dp |
| Empty View Padding | 32dp |
| Empty Icon Size | 80dp × 80dp |
| Empty Icon Margin Bottom | 16dp |
| Loading Text Margin Top | 16dp |

---

## 📱 User Experience Flows

### Flow 1: Receive Push Notification

```
Server Triggers Alert
    ↓
FCM Message Sent
    ↓
Device Receives Notification
    ↓
MyFirebaseMessagingService.onMessageReceived()
    ↓
Play Sound: warning.wav (2 seconds)
    ↓
Vibrate: [0, 300, 200, 300]
    ↓
Show System Notification:
    - Title: "Heart Rate Alert"
    - Body: "Your heart rate is 125 bpm"
    - Icon: Bell icon
    - Priority: HIGH
    ↓
Invalidate NotificationCache
    ↓
User Taps Notification
    ↓
App Opens → HomeActivity
    ↓
Navigate to NotificationsFragment
    ↓
List refreshes with new notification at top
    ↓
New notification has blue dot (unread)
```

---

### Flow 2: View Notification Details

```
Open NotificationsFragment
    ↓
Scroll through list
    ↓
See notification with blue dot
    ↓
Tap notification card
    ↓
Detail dialog appears
    ↓
Display:
    - Full title
    - Complete message (no truncation)
    - Full timestamp
    - All vital signs breakdown
    ↓
Read vitals:
    ❤️  Heart Rate: 125 bpm
    🩸 Blood Oxygen: 98%
    🫀 Blood Pressure: 120/80 mmHg
    🌡️  Temperature: 36.5°C
    ↓
Tap "OK" button
    ↓
Dialog closes
    ↓
[In Background]
    - API call to mark as read
    - Item status: 0 → 1
    - Adapter refreshes
    - Blue dot disappears
    - Card background: blue tint → white
    - Badge count: 3 → 2
    - Cache invalidated
```

---

### Flow 3: Empty State

```
Open NotificationsFragment
    ↓
API returns empty array
    ↓
LoadingView hides
    ↓
EmptyView displays:
    - Bell icon (grayed)
    - "No notifications yet"
    - "You don't have any notifications at the moment"
    ↓
User sees empty state
    ↓
Navigate away
```

---

### Flow 4: Badge Update Flow

```
[Scenario: 3 unread notifications]
    ↓
HomeActivity shows badge: "3"
    ↓
User taps bell icon
    ↓
NotificationsFragment opens
    ↓
List displays 3 unread (blue dots)
    ↓
User taps first notification
    ↓
Dialog opens → Mark as read
    ↓
Badge updates: "3" → "2"
    ↓
User taps second notification
    ↓
Badge updates: "2" → "1"
    ↓
User taps third notification
    ↓
Badge updates: "1" → Badge hidden
    ↓
All notifications marked as read
```

---

### Flow 5: Cache Refresh Logic

```
[Time: 10:00 AM - First open]
    ↓
NotificationCache.isValid = false
    ↓
Fetch from API
    ↓
Cache updated with 5 notifications
    ↓
lastFetchedAt = 10:00 AM
    ↓
[Time: 10:03 AM - User opens again]
    ↓
NotificationCache.isValid = true (< 5 min)
    ↓
Use cached data (no API call)
    ↓
Badge: 5 unread
    ↓
[Time: 10:04 AM - FCM notification received]
    ↓
NotificationCache.invalidate()
    ↓
[Time: 10:05 AM - User opens again]
    ↓
NotificationCache.isValid = false (invalidated)
    ↓
Fetch from API
    ↓
Cache updated with 6 notifications
    ↓
lastFetchedAt = 10:05 AM
    ↓
Badge: 6 unread
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### Data Loading
- [ ] API fetch successful
- [ ] Loading state displays
- [ ] Empty state displays when no data
- [ ] RecyclerView populates correctly
- [ ] Cache updates after fetch
- [ ] Badge count updates

#### Notification Display
- [ ] Unread dot shows for status=0
- [ ] Unread dot hidden for status=1
- [ ] Card background tinted for unread
- [ ] Card background white for read
- [ ] Title auto-generates when blank
- [ ] Message truncates to 2 lines
- [ ] Timestamp formats correctly
- [ ] Vitals chips show when data exists
- [ ] Vitals chips hidden when no data

#### Click Behavior
- [ ] Tap opens detail dialog
- [ ] Dialog shows full message
- [ ] Dialog shows all vitals
- [ ] Vitals parse correctly from JSON
- [ ] OK button closes dialog
- [ ] Mark as read API called
- [ ] Item updates after mark as read
- [ ] Badge count decreases
- [ ] Cache invalidates

#### Firebase Integration
- [ ] FCM message received
- [ ] System notification displays
- [ ] Custom sound plays (warning.wav)
- [ ] Vibration pattern works
- [ ] Cache invalidates on FCM
- [ ] Badge updates after FCM

#### Cache System
- [ ] Cache valid for 5 minutes
- [ ] Cache invalid after 5 minutes
- [ ] Cache invalidates on mark as read
- [ ] Cache invalidates on FCM
- [ ] Unread count correct
- [ ] Latest notification correct

---

### UI/UX Tests

#### Visual Design
- [ ] Background color correct (#F2F4F7)
- [ ] Card elevation visible
- [ ] Card corner radius correct
- [ ] Unread dot blue (#0D99FF)
- [ ] Chip colors correct (Red/Blue/Green)
- [ ] Text sizes correct
- [ ] Text colors correct
- [ ] Icon displays properly

#### States
- [ ] Loading spinner centered
- [ ] Loading text displays
- [ ] Empty icon centered
- [ ] Empty text displays
- [ ] RecyclerView scrolls smoothly
- [ ] Cards stack properly

#### Responsive Layout
- [ ] Works in portrait mode
- [ ] Works in landscape mode
- [ ] Dialog fits on screen
- [ ] Text doesn't overflow
- [ ] Chips wrap if needed

#### Edge Cases
- [ ] Very long message
- [ ] Very long title
- [ ] Missing vitals JSON
- [ ] Invalid vitals JSON
- [ ] Missing timestamp
- [ ] API timeout
- [ ] Network error
- [ ] Fragment destroyed during load

---

## 🚀 Future Enhancements

### 1. Swipe to Delete

```xml
Swipe left on notification card
    ↓
Show delete button
    ↓
Confirm deletion
    ↓
Remove from list + API
```

### 2. Filter by Category

```xml
┌─────────────────────────────┐
│ [All] [Vitals] [System]     │  Filter Chips
└─────────────────────────────┘
```

### 3. Search Notifications

```xml
┌─────────────────────────────┐
│ 🔍 Search notifications...  │  Search Bar
└─────────────────────────────┘
```

### 4. Mark All as Read

```xml
┌─────────────────────────────┐
│ [Mark All as Read]          │  Bulk Action
└─────────────────────────────┘
```

### 5. Notification Preferences

```xml
┌─────────────────────────────┐
│ ☑ Heart Rate Alerts         │
│ ☑ Blood Pressure Alerts     │
│ ☑ Blood Oxygen Alerts       │
│ ☐ System Notifications      │
└─────────────────────────────┘
```

### 6. Push Notification Settings

```xml
┌─────────────────────────────┐
│ Sound: warning.wav          │
│ Vibration: ☑ Enabled        │
│ Priority: High              │
└─────────────────────────────┘
```

### 7. Notification History Archive

```xml
Archive old notifications
    (> 30 days)
    ↓
Separate "Archive" tab
```

### 8. Rich Notification Actions

```xml
System Notification:
┌─────────────────────────────┐
│ Heart Rate Alert            │
│ Your HR is 125 bpm          │
│ [View Details] [Dismiss]    │  Quick Actions
└─────────────────────────────┘
```

### 9. Notification Grouping

```xml
Group by:
- Today
- Yesterday
- This Week
- Older
```

### 10. Export Notifications

```xml
┌─────────────────────────────┐
│ [Export to PDF]             │
│ [Share via Email]           │
└─────────────────────────────┘
```

---

## 📊 Analytics & Tracking

### Key Metrics

**User Engagement:**
- Notifications screen views
- Average time on screen
- Notification open rate
- Mark as read rate
- Click-through rate

**Notification Stats:**
- Total notifications sent
- Delivered count
- Read count
- Unread count
- Most common alert types

**Performance:**
- API response time
- Cache hit rate
- FCM delivery rate
- Sound playback success rate

### Implementation

```kotlin
// Track screen view
Analytics.logEvent("notifications_screen_viewed", mapOf(
    "unread_count" to unreadCount,
    "total_count" to totalCount
))

// Track notification opened
Analytics.logEvent("notification_opened", mapOf(
    "notification_id" to id,
    "notification_type" to type,
    "status" to status
))

// Track mark as read
Analytics.logEvent("notification_marked_read", mapOf(
    "notification_id" to id,
    "time_to_read" to timeToRead
))

// Track FCM received
Analytics.logEvent("fcm_notification_received", mapOf(
    "title" to title,
    "has_vitals" to hasVitals
))
```

---

**Document Version:** 1.0  
**Last Updated:** May 23, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

