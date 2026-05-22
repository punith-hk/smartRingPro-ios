# Device Screen - Design & Implementation

**HEARTO App - Device Management Screen**  
**Fragment:** `DeviceFragment.kt`  
**Sub-Fragments:** `HealthSettingsFragment.kt`, `DeviceSettingsFragment.kt`  
**Layouts:** `fragment_device.xml`, `fragment_health_settings.xml`, `fragment_device_settings.xml`

---

## 📋 Overview

The Device screen is the central hub for managing the HEARTO smart ring connection, configuring health monitoring settings, and performing device maintenance. It provides:

1. **Device Status Display** - Ring connection status, battery level, firmware version
2. **Health Settings** - Monitor intervals, daily targets, measurement units
3. **Device Settings** - Factory reset, firmware updates, device management

The screen automatically detects connection state and adapts the UI accordingly, enabling features only when the ring is connected.

---

## 🎨 Design Architecture

### Three-Level Structure

```
DeviceFragment (Main Screen)
├── Device Status Card (Ring info, battery, firmware)
├── Health Settings Card → HealthSettingsFragment
│   ├── Temperature Unit
│   ├── Health Monitor Interval (15/30/45/60 min)
│   ├── Daily Steps Target
│   └── Daily Sleep Target
├── Device Settings Card → DeviceSettingsFragment
│   ├── Reset Ring (Factory Reset)
│   └── Update Firmware
└── Bind Device Button (if not connected)
```

---

## 🎯 Context 1: Device Fragment (Main Screen)

### Screen States

#### State 1: Device Not Connected
```
┌─────────────────────────────────────┐
│                                     │
│  ┌───────────────────────────────┐ │
│  │   Bind the Device             │ │  (Blue button)
│  │   Connect your ring to        │ │
│  │   start monitoring            │ │
│  └───────────────────────────────┘ │
│                                     │
│  App Version: 1.2.0                 │
└─────────────────────────────────────┘
```

**Visibility:**
- ✅ Bind Device Card
- ✅ App Version
- ❌ Device Status Card
- ❌ Health Settings Card
- ❌ Device Settings Card
- ❌ Firmware Details
- ❌ Disconnect Button

**Behavior:**
- Tap "Bind the Device" → Opens DeviceActivity (pairing screen)
- Retrieves saved MAC address and device name from ConnectionPreferences
- If no saved device, shows bind button

---

#### State 2: Device Connected
```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────┐   │
│  │ [Ring Image]  HEARTO Ring   │   │ Device
│  │               🔵 Connected   │   │ Status
│  │               A1:B2:C3:D4    │   │ Card
│  │               🔋 85%         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ⚙️ Health Settings          →│   │ Navigate
│  │   Monitor interval, targets  │   │ to
│  └─────────────────────────────┘   │ Settings
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔧 Device Settings          →│   │ Navigate
│  │   Reset ring & firmware      │   │ to
│  └─────────────────────────────┘   │ Settings
│                                     │
│  💾 FirmWare 1.0.5                  │
│                                     │
│  [Disconnect Button]                │
│                                     │
│  App Version: 1.2.0                 │
└─────────────────────────────────────┘
```

**Visibility:**
- ✅ Device Status Card
- ✅ Health Settings Card
- ✅ Device Settings Card
- ✅ Firmware Details
- ✅ Disconnect Button
- ✅ App Version
- ❌ Bind Device Card

---

### Device Status Card Design

```xml
┌───────────────────────────────────────┐
│                                       │
│  [Ring Image]     HEARTO Ring         │
│   100×100dp       [Ring Name]         │
│                                       │
│                   🔵 Connected        │
│                   [Connection Status] │
│                                       │
│                   A1:B2:C3:D4:E5:F6   │
│                   [MAC Address]       │
│                                       │
│                   🔋 85%              │
│                   [Battery %]         │
│                                       │
└───────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 16dp
- **Elevation:** 20dp
- **Margin:** 30dp horizontal, 30dp top
- **Layout:** Horizontal (Image + Info Column)

#### Ring Image
- **Drawable:** `@drawable/hearto_ring`
- **Size:** 100dp × 100dp
- **Margin:** 20dp all sides
- **Description:** "Smart Ring"

#### Info Column (Vertical Layout)

**1. Ring Name**
- **ID:** `ringName`
- **Size:** 20sp
- **Style:** Bold
- **Color:** Black
- **Margin Top:** 15dp
- **Initial Text:** "Bind the Device"
- **Connected Text:** Device name from ConnectionPreferences (e.g., "HEARTO Ring")

**2. Connection Status**
- **ID:** `connectionStatus`
- **Initial Text:** "Connecting..."
- **Drawable Start:** `@drawable/baseline_bluetooth_24` (Bluetooth icon)
- **Margin:** -5dp start, 10dp top
- **States:**
  - "Connecting..." (Yellow/Orange)
  - "Connected" (Green)
  - "Device not found" (Red)
  - "Disconnecting..." (Gray)

**3. MAC Address**
- **ID:** `macId`
- **Text:** Device MAC address (e.g., "A1:B2:C3:D4:E5:F6")
- **Margin Top:** 10dp
- **Initial:** "--"

**4. Battery Display (RelativeLayout)**
- **Battery Icon:**
  - **ID:** `batteryIcon`
  - **Drawable:** `@drawable/baseline_battery_0_bar_24`
  - **Size:** 48dp × 48dp
  - **Color:** Dynamic based on percentage:
    - **> 30%:** Green (#75F94C)
    - **10-30%:** Orange (#FFA500)
    - **< 10%:** Red (#FF0000)

- **Battery Percentage:**
  - **ID:** `batteryPercentage`
  - **Text:** "85%"
  - **Size:** 16sp
  - **Color:** Black
  - **Position:** To end of battery icon

**Data Source:**
- Battery: `YCBTClient.getDeviceBatteryValue()` (0-100)
- Battery State: `YCBTClient.getDeviceBatteryState()` (0=normal, 1=charging)

---

### Health Settings Card

```xml
┌───────────────────────────────────────┐
│  [⚙️]  Health Settings              → │
│        Monitor interval, targets      │
└───────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 16dp
- **Elevation:** 20dp
- **Margin:** 30dp horizontal, 20dp vertical
- **Clickable:** Yes (Ripple effect)

**Layout:**
- **Icon Badge:** 44dp × 44dp circular background (Light Indigo)
  - **Icon:** `baseline_settings_24` (26dp, Indigo #536DFE)
- **Title:** "Health Settings" (16sp, Bold, Black)
- **Subtitle:** "Monitor interval, targets & units" (12sp, Gray #777777)
- **Arrow:** Right-pointing arrow (20dp, Light Gray #BBBBBB)

**Action:**
- Opens `HealthSettingsFragment` with title "Health Settings"
- Adds to back stack

---

### Device Settings Card

```xml
┌───────────────────────────────────────┐
│  [🔧]  Device Settings              → │
│        Reset ring & firmware updates  │
└───────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 16dp
- **Elevation:** 20dp
- **Margin:** 30dp horizontal, 20dp bottom

**Layout:**
- **Icon Badge:** 44dp × 44dp circular background (Light Green)
  - **Icon:** `baseline_developer_board_24` (26dp, Green #66BB6A)
- **Title:** "Device Settings" (16sp, Bold, Black)
- **Subtitle:** "Reset ring & firmware updates" (12sp, Gray #777777)
- **Arrow:** Right-pointing arrow (20dp, Light Gray #BBBBBB)

**Action:**
- Opens `DeviceSettingsFragment` with title "Device Settings"
- Adds to back stack

---

### Firmware Details Row

```xml
┌──────────────────────────────────┐
│  💾  FirmWare  1.0.5             │
└──────────────────────────────────┘
```

**Layout:** RelativeLayout, horizontally centered
- **Chip Icon:** `baseline_memory_24` (36dp)
- **Label:** "FirmWareManagement" (Bold)
- **Version:** "1.0.5" (Bold)
  - **ID:** `firmWareVersion`
  - **Data:** From `YCBTClient.getBindDeviceVersion()`
  - **Stored:** ApplicationPreferences ("firmwareVersion")

---

### Disconnect Button

```xml
┌──────────────────┐
│   Disconnect     │
└──────────────────┘
```

**Button Specs:**
- **ID:** `disConnectionBtn`
- **Style:** `@style/AppButton`
- **Width:** wrap_content
- **Height:** wrap_content
- **Margin Top:** 20dp
- **Alignment:** Center
- **Text:** "Unbind" / "Disconnect"

**Action:**
1. Shows confirmation dialog
   - Title: "Unpair Device"
   - Message: "Are you sure you want to unpair the device?"
   - Buttons: Cancel | Sure
2. On confirm:
   - Shows loading dialog "Disconnecting, please wait..." (4s)
   - Sends ACTION_DISCONNECT to BackgroundService
   - Clears device info from ConnectionPreferences
   - Updates status to "Disconnecting..."
   - Waits 3 seconds
   - Calls `connectionCheck()` to update UI
   - Returns to "Bind Device" state

---

### Bind Device Card (Not Connected State)

```xml
┌───────────────────────────────────┐
│     Bind the Device               │  (Blue Card)
│     Connect your ring to          │
│     start monitoring              │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `bindDevice`
- **Background:** Blue (#01AED6)
- **Corner Radius:** 24dp
- **Elevation:** 24dp
- **Margin:** 30dp all sides
- **Min Height:** 100dp

**Content:**
- **Title:** "Bind the Device" (Bold)
- **Subtitle:** "Connect your ring to start monitoring"
- **Layout:** Vertical, center-aligned

**Action:**
- Opens `DeviceActivity` (Bluetooth scanning and pairing screen)

---

### App Version Display

```xml
App Version: 1.2.0
```

**Layout:**
- **ID:** `appVersion`
- **Position:** Bottom center
- **Margin Top:** 32dp
- **Text:** "App Version: [version]"
- **Style:** Bold
- **Data:** From `packageManager.getPackageInfo().versionName`

---

## 🎯 Context 2: Health Settings Fragment

### Screen Design

```
┌─────────────────────────────────────┐
│  Health Settings                    │  (Title in toolbar)
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🌡️ Temperature Unit           │ │
│  │    Celsius degrees (°C)       │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ⏰ Health Monitor Interval    │ │
│  │    15 min • Device not        │ │ (If disconnected)
│  │    connected                  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 👟 Daily Steps Target         │ │
│  │    10,000 steps               │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 😴 Daily Sleep Target         │ │
│  │    8h                         │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Background
- **Color:** #D9EDFF (Light Blue)

---

### 1. Temperature Unit Card

```xml
┌───────────────────────────────────┐
│  🌡️ Temperature Unit              │
│     Celsius degrees (°C)          │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `hs_tempUnitCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp
- **Clickable:** Yes

**Content:**
- **Title:** "Temperature Unit" (14sp, Bold, Black)
- **Subtitle ID:** `hs_tvTemperatureUnit`
- **Options:**
  - "Celsius degrees (°C)"
  - "Fahrenheit (°F)"

**Storage:**
- **Key:** "temperature_unit"
- **Preferences:** "UserPreferences"
- **Values:** "Celsius degrees" or "Fahrenheit"
- **Default:** "Celsius degrees"

**Picker Dialog:**
- **Style:** Bottom sheet
- **Options:** ["Celsius degrees (°C)", "Fahrenheit (°F)"]
- **Current:** Pre-selected based on saved value
- **Actions:** Cancel | Sure

---

### 2. Health Monitor Interval Card

```xml
┌───────────────────────────────────┐
│  ⏰ Health Monitor Interval       │
│     15 min                        │  (Connected)
│     OR                            │
│     15 min • Device not connected │  (Disconnected)
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `hs_healthMonitorCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp
- **Clickable:** Yes

**Content:**
- **Title:** "Health Monitor Interval" (14sp, Bold, Black)
- **Subtitle ID:** `hs_tvHealthMonitorInterval`

**Dynamic States:**

**Connected State:**
- **Alpha:** 1.0 (Full opacity)
- **Enabled:** true
- **Text:** "15 min" (Gray #777777)

**Disconnected State:**
- **Alpha:** 0.5 (Grayed out)
- **Enabled:** true (still tappable)
- **Text:** "15 min  •  Device not connected" (Red #FF5252)
- **Action:** Shows toast "Device not connected"

**Interval Options:**
- 15 min
- 30 min
- 45 min
- 60 min

**Storage:**
- **Key:** "last_ring_config"
- **Preferences:** ConnectionPreferences
- **Default:** 15 min
- **Synced to Ring:** Yes (via `AutoTestConfigSyncHelper`)

**Picker Dialog:**
- **Style:** Bottom sheet
- **Title:** "Monitor Interval"
- **Options:** ["15 min", "30 min", "45 min", "60 min"]
- **Current:** Pre-selected based on saved value
- **Requires:** BLE connection
- **Actions:** Cancel | Sure

**On Save:**
1. Updates all 7 vital types on ring:
   - Heart Rate
   - Blood Pressure
   - Blood Oxygen (SpO2)
   - ECG
   - Sleep
   - Steps
   - Body Temperature
2. Each type synced via `AutoTestConfigSyncHelper.updateAllConfigs()`
3. Shows toast: "✓ Health monitoring interval set to [X] min"
4. Tracks success/fail count (7 total callbacks)
5. Updates card display

**First-Time Connection:**
- On initial ring connection, default 15 min interval is pushed automatically
- Flag stored: `ConnectionPreferences.isIntervalInitialized()`

---

### 3. Daily Steps Target Card

```xml
┌───────────────────────────────────┐
│  👟 Daily Steps Target            │
│     10,000 steps                  │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `hs_stepsTargetCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp
- **Clickable:** Yes

**Content:**
- **Title:** "Daily Steps Target" (14sp, Bold, Black)
- **Subtitle ID:** `hs_tvStepsTarget`
- **Format:** "10,000 steps" (with thousand separator)

**Target Options:**
- 1,000 steps
- 2,000 steps
- 3,000 steps
- 4,000 steps
- 5,000 steps
- 6,000 steps
- 7,000 steps
- 7,500 steps
- 8,000 steps
- 9,000 steps
- 10,000 steps (default)
- 11,000 steps
- 12,000 steps
- 12,500 steps
- 15,000 steps
- 20,000 steps

**Storage:**
- **Key:** "steps_target"
- **Preferences:** "UserPreferences"
- **Default:** 10,000
- **Type:** Integer

**Picker Dialog:**
- **Style:** Bottom sheet
- **Title:** "Daily Steps Target"
- **Options:** All step values formatted with commas
- **Current:** Pre-selected based on saved value

---

### 4. Daily Sleep Target Card

```xml
┌───────────────────────────────────┐
│  😴 Daily Sleep Target            │
│     8h                            │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `hs_sleepTargetCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp
- **Clickable:** Yes

**Content:**
- **Title:** "Daily Sleep Target" (14sp, Bold, Black)
- **Subtitle ID:** `hs_tvSleepTarget`
- **Format:** "8h" or "8h 30m"

**Target Options (4h to 12h in 30-min steps):**
- 4h, 4h 30m
- 5h, 5h 30m
- 6h, 6h 30m
- 7h, 7h 30m
- 8h, 8h 30m (8h = default)
- 9h, 9h 30m
- 10h, 10h 30m
- 11h, 11h 30m
- 12h

**Storage:**
- **Key:** "sleep_target_minutes"
- **Preferences:** "UserPreferences"
- **Default:** 480 minutes (8 hours)
- **Type:** Integer (total minutes)

**Picker Dialog:**
- **Style:** Bottom sheet
- **Title:** "Daily Sleep Target"
- **Options:** All sleep durations formatted as "Xh" or "Xh Ym"
- **Current:** Pre-selected based on saved value

**Formatting Logic:**
```kotlin
private fun formatSleepMinutes(totalMinutes: Int): String {
    val h = totalMinutes / 60
    val m = totalMinutes % 60
    return if (m == 0) "${h}h" else "${h}h ${m}m"
}
```

---

### Shared Bottom Sheet Picker Design

**Dialog Style:**
```
┌─────────────────────────────────────┐
│                                     │ (Rounded top corners)
│  [Cancel]  Monitor Interval  [Sure] │ (Header)
│  ═══════════════════════════════════│
│           15 min                    │
│         ► 30 min ◄                  │ (Selected)
│           45 min                    │ (NumberPicker wheel)
│           60 min                    │
│                                     │
└─────────────────────────────────────┘
```

**Specs:**
- **Layout:** `dialog_number_picker.xml`
- **Position:** Bottom of screen
- **Width:** Match parent
- **Height:** Wrap content
- **Background:** Transparent (rounded corners visible)
- **Animation:** Slide up from bottom

**Header:**
- **Title:** Center-aligned (e.g., "Monitor Interval")
- **Cancel Button:** Left side (TextView, clickable)
- **Sure Button:** Right side (TextView, clickable)

**NumberPicker:**
- **ID:** `number_picker`
- **Min Value:** 0
- **Max Value:** options.size - 1
- **Displayed Values:** String array of options
- **Current Value:** Pre-selected index
- **Wrap Selector Wheel:** false

**Actions:**
- **Cancel:** Dismisses dialog
- **Sure:** Saves selection, updates display, dismisses dialog

---

## 🎯 Context 3: Device Settings Fragment

### Screen Design

```
┌─────────────────────────────────────┐
│  Device Settings                    │  (Title in toolbar)
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🔄 Reset Ring                 │ │
│  │    Restore to factory         │ │
│  │    settings                   │ │
│  │    Current: 1.0.5             │ │ (Firmware version)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📦 Update Firmware            │ │
│  │    Check for latest updates   │ │
│  │    Current: 1.0.5             │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Background
- **Color:** #D9EDFF (Light Blue)

---

### 1. Reset Ring Card

```xml
┌───────────────────────────────────┐
│  🔄 Reset Ring                    │
│     Restore to factory settings   │
│     Current: 1.0.5                │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `ds_resetRingCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin:** 20dp horizontal, 16dp vertical
- **Clickable:** Yes

**Dynamic State:**
- **Connected:** Alpha 1.0 (Full opacity)
- **Disconnected:** Alpha 0.5 (Grayed out)

**Content:**
- **Icon:** 🔄 (Circular icon, 36dp)
- **Title:** "Reset Ring" (16sp, Bold, Black)
- **Subtitle:** "Restore to factory settings" (12sp, Gray #777777)
- **Version ID:** `ds_tvFirmwareVersion`
- **Version Text:** "Current: 1.0.5"

**Action:**
1. **If Disconnected:**
   - Shows info dialog
   - Title: "Device Not Connected"
   - Message: "Please connect your ring first to perform this action."
   - Button: OK

2. **If Connected:**
   - Shows confirmation dialog
   - Title: "Reset Ring"
   - Message: "This will restore the device to factory settings. All data on the ring will be erased. Continue?"
   - Buttons: Cancel | Yes, Reset

3. **On Confirm:**
   - Shows loading dialog "Resetting device, please wait..."
   - Calls `YCBTClient.settingRestoreFactory()`
   - Waits minimum 3 seconds (even if faster)
   - On success:
     - Updates loading text to "Reset successful!"
     - Pushes default 15 min interval back to ring
     - Shows toast "Ring reset successful"
     - Navigates back to Device screen
   - On failure:
     - Dismisses loading
     - Shows toast "Reset failed. Please try again."

**Factory Reset Behavior:**
- Erases all data stored on ring
- Resets to manufacturer defaults
- Requires re-pairing (optional, depends on SDK)
- Default 15 min interval re-applied

---

### 2. Update Firmware Card

```xml
┌───────────────────────────────────┐
│  📦 Update Firmware               │
│     Check for latest updates      │
│     Current: 1.0.5                │
└───────────────────────────────────┘
```

**Card Specs:**
- **ID:** `ds_updateFirmwareCard`
- **Background:** White
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin:** 20dp horizontal, 16dp vertical
- **Clickable:** Yes

**Dynamic State:**
- **Connected:** Alpha 1.0 (Full opacity)
- **Disconnected:** Alpha 0.5 (Grayed out)

**Content:**
- **Icon:** 📦 (Box icon, 36dp)
- **Title:** "Update Firmware" (16sp, Bold, Black)
- **Subtitle:** "Check for latest updates" (12sp, Gray #777777)
- **Version:** "Current: 1.0.5"

**Action:**
1. **If Disconnected:**
   - Shows info dialog
   - Title: "Device Not Connected"
   - Message: "Please connect your ring first to perform this action."

2. **If Connected:**
   - Shows info dialog
   - Title: "Update Firmware"
   - Message: "Firmware update functionality will be available soon.\n\nCurrent Version: 1.0.5"
   - Button: OK

**Future Implementation:**
- Check for firmware updates from server
- Download new firmware binary
- Upload to ring via BLE
- Show progress (0-100%)
- Handle errors (timeout, connection lost)
- Verify successful update

---

## 📊 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background (all fragments) |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Blue | `#0D99FF` | Accents, primary actions |
| Bind Button | `#01AED6` | Bind device card background |
| Primary Text | `#000000` | Titles, labels |
| Secondary Text | `#777777` | Subtitles, descriptions |
| Success Green | `#75F94C` | Battery > 30%, connected status |
| Warning Orange | `#FFA500` | Battery 10-30% |
| Error Red | `#FF0000` | Battery < 10%, not connected |
| Light Indigo BG | Custom | Health Settings icon background |
| Indigo Icon | `#536DFE` | Health Settings icon |
| Light Green BG | Custom | Device Settings icon background |
| Green Icon | `#66BB6A` | Device Settings icon |
| Arrow Gray | `#BBBBBB` | Navigation arrows |
| Disconnected Red | `#FF5252` | Monitor interval warning text |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Ring Name | 20sp | Bold | Black |
| Card Title | 16sp | Bold | Black |
| Card Subtitle | 12sp | Normal | #777777 |
| Connection Status | 14sp | Normal | Black |
| Battery % | 16sp | Normal | Black |
| Firmware Version | 14sp | Bold | Black |
| Settings Card Title | 14sp | Bold | Black |
| Settings Subtitle | 12sp | Normal | #777777 |
| Picker Title | 16sp | Bold | Black |
| Picker Options | 14sp | Normal | Black |

### Spacing

| Element | Value |
|---------|-------|
| Screen Background | #D9EDFF |
| Card Corner Radius | 14-16dp |
| Card Elevation | 3-20dp |
| Card Margin (H) | 30dp |
| Card Margin (V) | 16-20dp |
| Card Padding | 16dp |
| Icon Badge Size | 44dp × 44dp |
| Ring Image Size | 100dp × 100dp |
| Battery Icon Size | 48dp × 48dp |
| Navigation Arrow | 20dp × 20dp |
| Button Height | 48dp |

---

## 🔄 Connection Flow & State Management

### Initial App Launch

```
App Start
    ↓
DeviceFragment.onCreateView()
    ↓
Check ConnectionPreferences
    ├─ MAC & Name found?
    │   ├─ YES → Check BLE state
    │   │   ├─ Connected → Show device info
    │   │   └─ Not connected → Start BackgroundService
    │   └─ NO → Show "Bind Device" button
    ↓
EventBus registered
    ↓
Listen for ConnectEvent
```

### Connection State Updates

**EventBus Events:**
```kotlin
@Subscribe(threadMode = ThreadMode.MAIN)
fun onBleConnectEvent(event: ConnectEvent) {
    when (event.state) {
        1 -> {
            // Connected
            - Update UI: "Connected"
            - Fetch battery info
            - Fetch firmware version
            - Check if first connection
            - If first time: push default 15 min interval
            - Save connection state
        }
        else -> {
            // Disconnected
            - Update UI: "Device not found"
            - Gray out dependent cards
        }
    }
}
```

**State Propagation:**
- DeviceFragment → Updates device card
- HealthSettingsFragment → Grays out monitor interval card
- DeviceSettingsFragment → Grays out action cards

---

### BLE Connection Lifecycle

**1. Device Not Paired:**
```
User taps "Bind Device"
    ↓
Open DeviceActivity
    ↓
Scan for nearby rings
    ↓
User selects ring
    ↓
Pair & Connect
    ↓
Save MAC + Name to ConnectionPreferences
    ↓
Return to DeviceFragment
    ↓
Start BackgroundService for connection
    ↓
Connected state displayed
```

**2. Device Already Paired:**
```
App Start / Fragment Resume
    ↓
Load MAC + Name from ConnectionPreferences
    ↓
Check YCBTClient.connectState()
    ├─ Connected → Update UI immediately
    └─ Not connected → Start BackgroundService
            ↓
        BackgroundService attempts connection
            ↓
        EventBus posts ConnectEvent
            ↓
        DeviceFragment receives event
            ↓
        UI updates
```

**3. Manual Disconnect:**
```
User taps "Disconnect"
    ↓
Confirmation dialog shown
    ↓
User confirms
    ↓
Show loading "Disconnecting..."
    ↓
Send ACTION_DISCONNECT to BackgroundService
    ↓
BackgroundService calls YCBTClient.disconnect()
    ↓
Wait 3 seconds
    ↓
Clear ConnectionPreferences
    ↓
Update UI → "Bind Device" state
```

---

### First-Time Interval Configuration

**Logic:**
```kotlin
// On first connection only
if (!ConnectionPreferences.isIntervalInitialized(context)) {
    val defaultInterval = 15
    AutoTestConfigSyncHelper(context).updateAllConfigs(defaultInterval) { type, success ->
        Log.i(TAG, "Default interval → $type success=$success")
    }
    ConnectionPreferences.markIntervalInitialized(context)
}
```

**Purpose:**
- Ensures ring has a monitoring interval set
- Default: 15 minutes
- Syncs to all 7 vital types
- Flag prevents repeated initialization
- User can change later in Health Settings

---

## 🔧 Core Functionality

### 1. Bluetooth Permission Handling

**Android 12+ (API 31+):**
- Requires `BLUETOOTH_CONNECT` permission
- Requires `BLUETOOTH_SCAN` permission

**Check Logic:**
```kotlin
private fun checkBluetoothPermissionAndProceed() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        if (needConnect || needScan) {
            // Show explanatory dialog
            showNearbyPermissionDialog()
            return
        }
    }
    checkBluetoothAndRequestEnable()
}
```

**Permission Dialog:**
- Title: "Enable Nearby Devices"
- Message: "MannaHeal needs Nearby devices permission to find and connect to your ring.\n\nPlease go to:\nPermissions → Nearby devices → Allow"
- Buttons: Cancel | Open Permissions
- Opens app settings if user agrees

**Settings Launcher:**
```kotlin
private val openSettingsLauncher =
    registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        if (isNearbyPermissionGranted()) {
            // Permission granted → continue
            checkBluetoothAndRequestEnable()
            connectionCheck()
        } else {
            Toast.makeText(context, "Permission not granted", Toast.LENGTH_SHORT).show()
        }
    }
```

---

### 2. Battery Display Logic

```kotlin
private fun updateBatteryIcon(batteryPercentage: Int) {
    binding.batteryPercentage.text = "$batteryPercentage%"
    val drawable = ContextCompat.getDrawable(context, R.drawable.baseline_battery_0_bar_24)
    
    val color = when {
        batteryPercentage > 30 -> Color.parseColor("#75F94C")  // Green
        batteryPercentage > 10 -> Color.parseColor("#FFA500")  // Orange
        else -> Color.RED                                      // Red
    }
    
    DrawableCompat.setTint(drawable!!, color)
    binding.batteryIcon.setImageDrawable(drawable)
}
```

**Battery States:**
- **Green (> 30%):** Healthy charge
- **Orange (10-30%):** Low battery warning
- **Red (< 10%):** Critical battery warning

**Battery Source:**
- `YCBTClient.getDeviceBatteryValue()` → 0-100 integer
- `YCBTClient.getDeviceBatteryState()` → 0 (normal) or 1 (charging)

---

### 3. Health Monitor Interval Sync

**Sync Process:**
```kotlin
val helper = AutoTestConfigSyncHelper(requireContext())
helper.updateAllConfigs(interval) { type, success ->
    if (success) successCount++ else failCount++
    
    val done = successCount + failCount >= totalTypes
    if (done && !resultShown) {
        resultShown = true
        view?.post {
            if (successCount > 0) {
                Toast.makeText(context, "✓ Health monitoring interval set to $interval min", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(context, "Failed to update interval. Please try again.", Toast.LENGTH_SHORT).show()
            }
            updateMonitorCardState()
        }
    }
}
```

**Vital Types Synced (7 total):**
1. Heart Rate
2. Blood Pressure
3. Blood Oxygen (SpO2)
4. ECG
5. Sleep
6. Steps
7. Body Temperature

**Success Criteria:**
- At least 1 type successful = show success message
- All types failed = show error message
- Updates card state after completion

---

### 4. Factory Reset Process

**Steps:**
1. Show loading dialog "Resetting device, please wait..."
2. Record start time
3. Call `YCBTClient.settingRestoreFactory()`
4. Wait for response + minimum 3 seconds total
5. On success:
   - Update loading text: "Reset successful!"
   - Push default 15 min interval
   - Wait 800ms
   - Dismiss loading
   - Show toast "Ring reset successful"
   - Navigate back
6. On failure:
   - Dismiss loading
   - Show toast "Reset failed. Please try again."

**Timing Logic:**
```kotlin
val elapsedTime = System.currentTimeMillis() - resetStartTime
val remainingTime = maxOf(0, 3000 - elapsedTime)

Handler(Looper.getMainLooper()).postDelayed({
    // Show result
}, remainingTime)
```
**Purpose:** Ensures loading dialog shows for minimum 3 seconds even if reset is faster

---

## 📱 User Experience Flows

### Flow 1: First-Time Device Pairing

```
Open App → Navigate to Device Tab
    ↓
"Bind Device" card visible
    ↓
Tap "Bind Device"
    ↓
Open DeviceActivity (Scanning screen)
    ↓
Bluetooth permission check
    ↓
Enable Bluetooth if needed
    ↓
Scan for nearby rings
    ↓
List of discovered devices shown
    ↓
Tap on "HEARTO Ring"
    ↓
Connecting... (loading dialog)
    ↓
Connected successfully
    ↓
Save MAC + Name to preferences
    ↓
Return to DeviceFragment
    ↓
Device card displayed with ring info
    ↓
Default 15 min interval pushed to ring
    ↓
Health & Device Settings cards visible
```

---

### Flow 2: Change Health Monitor Interval

```
Device Tab → Tap "Health Settings"
    ↓
HealthSettingsFragment opens
    ↓
Tap "Health Monitor Interval" card
    ↓
Check BLE connection
    ├─ Connected → Show picker
    └─ Not connected → Toast "Device not connected"
        ↓
Bottom sheet picker appears
    ↓
Scroll to desired interval (e.g., 30 min)
    ↓
Tap "Sure"
    ↓
Dialog dismisses
    ↓
Syncing to ring... (7 callbacks)
    ↓
Progress tracked in background
    ↓
Success toast: "✓ Health monitoring interval set to 30 min"
    ↓
Card subtitle updates: "30 min"
    ↓
Preference saved
```

---

### Flow 3: Factory Reset Ring

```
Device Tab → Tap "Device Settings"
    ↓
DeviceSettingsFragment opens
    ↓
Tap "Reset Ring" card
    ↓
Check BLE connection
    ├─ Connected → Show confirmation
    └─ Not connected → Info dialog "Device Not Connected"
        ↓
Confirmation dialog appears
    ↓
Read warning message
    ↓
Tap "Yes, Reset"
    ↓
Loading dialog: "Resetting device, please wait..."
    ↓
Factory reset command sent
    ↓
Wait 3+ seconds
    ↓
Success: "Reset successful!"
    ↓
Default 15 min interval re-applied
    ↓
Toast: "Ring reset successful"
    ↓
Navigate back to Device screen
    ↓
Ring still connected (may require re-pairing on some models)
```

---

### Flow 4: Disconnect Ring

```
Device Tab → Device connected
    ↓
Tap "Disconnect" button
    ↓
Confirmation dialog: "Unpair Device"
    ↓
Message: "Are you sure you want to unpair the device?"
    ↓
Tap "Sure"
    ↓
Loading dialog: "Disconnecting, please wait..."
    ↓
ACTION_DISCONNECT sent to BackgroundService
    ↓
Status text: "Disconnecting..."
    ↓
Button disabled temporarily
    ↓
Wait 3 seconds
    ↓
Loading updates: "Disconnected"
    ↓
Wait 800ms more
    ↓
Dialog dismisses
    ↓
UI updates:
    - Hide device card
    - Hide health/device settings cards
    - Hide firmware details
    - Hide disconnect button
    - Show "Bind Device" card
    ↓
ConnectionPreferences cleared
    ↓
Ready to pair new device
```

---

## 🧪 Testing Checklist

### Device Fragment

#### Functionality
- [ ] Bind Device button opens DeviceActivity
- [ ] Device card shows correct ring name
- [ ] Device card shows correct MAC address
- [ ] Connection status updates correctly
- [ ] Battery level displays accurately
- [ ] Battery icon color changes with percentage
- [ ] Firmware version displays correctly
- [ ] Health Settings card navigates correctly
- [ ] Device Settings card navigates correctly
- [ ] Disconnect button shows confirmation
- [ ] Disconnect clears device info
- [ ] App version displays correctly
- [ ] EventBus events received properly
- [ ] BackgroundService starts on connection attempt
- [ ] First-time interval initialization works
- [ ] Permissions requested on Android 12+
- [ ] Bluetooth enable prompt shows when needed

#### UI/UX
- [ ] Cards render with proper spacing
- [ ] Text readable on all backgrounds
- [ ] Icons display correctly
- [ ] Battery icon color-coded properly
- [ ] Connection status icon shows
- [ ] Ripple effects work on cards
- [ ] Disconnected state UI correct
- [ ] Connected state UI correct
- [ ] Loading dialogs show/hide properly
- [ ] Confirmation dialogs styled correctly

---

### Health Settings Fragment

#### Functionality
- [ ] Temperature unit picker works
- [ ] Temperature unit persists
- [ ] Temperature unit displays correctly
- [ ] Monitor interval picker requires connection
- [ ] Monitor interval shows toast if disconnected
- [ ] Monitor interval syncs to ring
- [ ] Monitor interval updates all 7 types
- [ ] Monitor interval success toast shows
- [ ] Monitor interval value persists
- [ ] Steps target picker works
- [ ] Steps target displays with commas
- [ ] Steps target persists
- [ ] Sleep target picker works
- [ ] Sleep target formats correctly (h/m)
- [ ] Sleep target persists
- [ ] Bottom sheet picker scrolls smoothly
- [ ] Cancel button works
- [ ] Sure button saves selection
- [ ] Monitor card grays out when disconnected
- [ ] Monitor card shows connection warning

#### UI/UX
- [ ] All cards render properly
- [ ] Background color correct (#D9EDFF)
- [ ] Bottom sheet animates up
- [ ] Picker wheel scrolls smoothly
- [ ] Current value pre-selected
- [ ] Text formatting correct
- [ ] Disabled state visual (alpha 0.5)
- [ ] Connection warning shows in red

---

### Device Settings Fragment

#### Functionality
- [ ] Reset ring requires connection
- [ ] Reset ring shows not connected dialog
- [ ] Reset ring shows confirmation dialog
- [ ] Reset ring performs factory reset
- [ ] Reset ring shows loading dialog
- [ ] Reset ring minimum 3s loading
- [ ] Reset ring success toast shows
- [ ] Reset ring re-applies default interval
- [ ] Reset ring navigates back
- [ ] Reset ring handles failure
- [ ] Update firmware shows info dialog
- [ ] Update firmware displays current version
- [ ] Cards gray out when disconnected
- [ ] Cards enable when connected
- [ ] Firmware version displays correctly

#### UI/UX
- [ ] Cards render properly
- [ ] Background color correct
- [ ] Disabled state alpha 0.5
- [ ] Loading dialog styled correctly
- [ ] Confirmation dialogs styled correctly
- [ ] Info dialogs styled correctly
- [ ] Text formatting correct

---

## 🚀 Future Enhancements

### 1. Firmware OTA Updates
```kotlin
// Check for updates from server
apiService.checkFirmwareUpdate(currentVersion).enqueue { response ->
    if (response.hasUpdate) {
        showUpdateAvailableDialog(response.version, response.downloadUrl)
    }
}

// Download firmware binary
fun downloadFirmware(url: String, onProgress: (Int) -> Unit) {
    // Download with progress callback
}

// Upload to ring via BLE
fun uploadFirmware(file: File, onProgress: (Int) -> Unit) {
    YCBTClient.updateFirmware(file) { progress ->
        onProgress(progress)
    }
}
```

**Features:**
- Check for updates on demand or periodically
- Download firmware binary
- Show progress bar (0-100%)
- Upload to ring via BLE
- Verify successful update
- Handle errors gracefully
- Rollback on failure

---

### 2. Advanced Battery Stats
```xml
┌───────────────────────────────────┐
│  Battery Details                  │
│                                   │
│  Current: 85%                     │
│  Estimated: 3 days remaining      │
│  Last charged: 2 hours ago        │
│  Charging cycles: 42              │
│  Health: Good                     │
└───────────────────────────────────┘
```

**Features:**
- Estimated time remaining
- Last charge timestamp
- Charging cycles count
- Battery health status
- Charging rate (if charging)
- Historical battery graph

---

### 3. Ring Calibration
```xml
┌───────────────────────────────────┐
│  Calibrate Ring                   │
│                                   │
│  Heart Rate: ✓ Calibrated         │
│  Blood Pressure: Needs calibration│
│  SpO2: ✓ Calibrated               │
│  Temperature: ✓ Calibrated        │
└───────────────────────────────────┘
```

**Features:**
- Calibrate each sensor individually
- Guided calibration wizard
- Compare with reference device
- Store calibration profiles
- Re-calibrate when needed

---

### 4. Ring Find Feature
```xml
┌───────────────────────────────────┐
│  Find My Ring                     │
│                                   │
│  [Beep Ring] [Show on Map]        │
│                                   │
│  Last seen: 10 minutes ago        │
│  Location: Home                   │
└───────────────────────────────────┘
```

**Features:**
- Make ring beep/vibrate
- Show last known location on map
- Signal strength indicator
- Lost mode (alert when found)

---

### 5. Multiple Device Support
```xml
┌───────────────────────────────────┐
│  My Devices                       │
│                                   │
│  ● HEARTO Ring (Primary)          │
│  ○ HEARTO Ring 2                  │
│                                   │
│  [Add New Device]                 │
└───────────────────────────────────┘
```

**Features:**
- Pair multiple rings
- Switch between devices
- Separate data for each device
- Primary device designation
- Sync data from all devices

---

### 6. Device Diagnostics
```xml
┌───────────────────────────────────┐
│  Diagnostics                      │
│                                   │
│  Signal Strength: Good            │
│  Connection Quality: 95%          │
│  Last Sync: 2 min ago             │
│  Data Packets: 1,234 received     │
│  Errors: 2                        │
│                                   │
│  [Run Full Test]                  │
└───────────────────────────────────┘
```

**Features:**
- BLE signal strength
- Connection quality metrics
- Sync statistics
- Error logs
- Full device test suite
- Export diagnostics report

---

### 7. Personalized Monitoring Profiles
```xml
┌───────────────────────────────────┐
│  Monitoring Profiles              │
│                                   │
│  ● Active (All vitals)            │
│  ○ Sleep Mode (Sleep + HR only)  │
│  ○ Battery Saver (60 min)        │
│  ○ Custom                         │
│                                   │
│  [Create New Profile]             │
└───────────────────────────────────┘
```

**Features:**
- Pre-defined profiles
- Custom profile creation
- Auto-switch based on time/activity
- Different intervals per vital
- Battery optimization profiles

---

### 8. Notification Preferences (Ring-Side)
```xml
┌───────────────────────────────────┐
│  Ring Notifications               │
│                                   │
│  ☑ Vibrate on alerts              │
│  ☑ LED indicator                  │
│  ☐ Sound alerts                   │
│                                   │
│  Vibration intensity: ████░░░░    │
└───────────────────────────────────┘
```

**Features:**
- Enable/disable ring vibrations
- LED color customization
- Sound alerts (if supported)
- Vibration intensity slider
- Alert types configuration

---

### 9. Ring Usage Statistics
```xml
┌───────────────────────────────────┐
│  Usage Stats                      │
│                                   │
│  Wear time today: 18h 30m         │
│  Average daily wear: 20h          │
│  Total measurements: 1,234        │
│  Data synced: 98.5%               │
│  Uptime: 7 days                   │
└───────────────────────────────────┘
```

**Features:**
- Daily/weekly wear time
- Measurement counts
- Sync success rate
- Device uptime
- Historical trends

---

### 10. Advanced Reset Options
```xml
┌───────────────────────────────────┐
│  Reset Options                    │
│                                   │
│  ○ Soft Reset (Keep settings)     │
│  ○ Factory Reset (Erase all)      │
│  ○ Reset Calibration Only         │
│  ○ Clear Logs Only                │
└───────────────────────────────────┘
```

**Features:**
- Soft reset (preserves settings)
- Factory reset (erases everything)
- Calibration reset only
- Clear error logs only
- Selective data deletion

---

## 📊 Analytics & Tracking

### Key Metrics

**Device Fragment:**
- Bind device button clicks
- Successful pairings
- Failed pairings
- Connection success rate
- Disconnection events
- Average connection time
- Battery levels distribution
- Firmware versions distribution

**Health Settings:**
- Settings screen views
- Temperature unit changes
- Monitor interval changes per value
- Steps target changes per value
- Sleep target changes per value
- Connection errors during sync

**Device Settings:**
- Settings screen views
- Reset ring attempts
- Reset ring successes/failures
- Firmware update checks
- Average reset duration

### Implementation

```kotlin
// Track pairing
Analytics.logEvent("device_paired", mapOf(
    "device_name" to deviceName,
    "firmware_version" to firmwareVersion
))

// Track interval change
Analytics.logEvent("interval_changed", mapOf(
    "old_interval" to oldInterval,
    "new_interval" to newInterval,
    "success_count" to successCount,
    "fail_count" to failCount
))

// Track factory reset
Analytics.logEvent("factory_reset", mapOf(
    "duration_ms" to duration,
    "success" to success
))
```

---

**Document Version:** 1.0  
**Last Updated:** May 22, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

