# MannHeal Pro — Dashboard Screen: Design & Logic Reference

> **Purpose:** Complete reference for implementing the Dashboard screen on iOS (or any platform), mirroring the Android implementation in `DashboardFragment.kt` + `fragment_dashboard.xml`.

---

## 1. Overview

The Dashboard is the **home screen** of the app (previously called `HomeFragment`, now migrated to `DashboardFragment`). It is loaded by `HomeActivity` when the user opens the Health tab (bottom nav — first item). It aggregates all health vitals from the smart ECG ring and presents them in a structured card grid.

---

## 2. Screen Layout — Top to Bottom

```
┌────────────────────────────────────────────┐
│  [Top Blue Ellipse Background Area]        │
│  ┌────────────────────────────────────┐    │
│  │     Health Score Gauge (circle)    │    │
│  │         88 / 100                   │    │
│  │       HEALTH SCORE                 │    │
│  │   [Excellent badge]                │    │
│  │   ↑ 3pts vs Yesterday              │    │
│  └────────────────────────────────────┘    │
│                                            │
│  [Last Synced Banner]                      │
│   🟢 Last synced: 5 min ago  [sync icon]  │
│                                            │
│  ═══ Cardiovascular Vitality ═══           │
│  ┌─────────┬─────────┬─────────┐          │
│  │Heart Rate│  HRV   │   ECG  │          │
│  │  68 BPM │  55 ms  │  19    │          │
│  │●Optimal │●Good    │●Improv.│          │
│  └─────────┴─────────┴─────────┘          │
│  ┌─────────┬─────────┬─────────┐          │
│  │ECG Dtls │  Blood  │ Blood  │          │
│  │Normal ECG│Pressure│Oxygen  │          │
│  │●Healthy │118/78   │  98%   │          │
│  │         │●Normal  │●Excell.│          │
│  └─────────┴─────────┴─────────┘          │
│                                            │
│  ═══ Metabolic & Body ═══                  │
│  ┌─────────┬─────────┬─────────┐          │
│  │Calories │  Steps  │  BMI   │          │
│  │2,150kcal│ 8,500   │  23.2  │          │
│  │●Active  │●Keep Go.│●Healthy│          │
│  └─────────┴─────────┴─────────┘          │
│  ┌─────────┬─────────┬─────────┐          │
│  │Blood Glc│Body Temp│[empty] │          │
│  │  95mg/dl│  36.6°C │        │          │
│  │●Normal  │●Normal  │        │          │
│  └─────────┴─────────┴─────────┘          │
│                                            │
│  ═══ Sleep & Stress ═══                    │
│  ┌─────────┬─────────┬─────────┐          │
│  │Sleep Dur│Sleep Qty│Stress  │          │
│  │ 7h 45m  │  82%    │Coming  │          │
│  │●Good    │●Good    │ Soon   │          │
│  └─────────┴─────────┴─────────┘          │
│                                            │
│  ═══ Insights & Alerts ═══                 │
│  ┌────────────────────────────────────┐    │
│  │ [icon]  Health Alert               │    │
│  │ "Your heart rate spiked..."        │    │
│  │                          5 min ago│    │
│  └────────────────────────────────────┘    │
└────────────────────────────────────────────┘
```

---

## 3. Top Section — Health Score Gauge

### Visual Design
- **Background:** Blue ellipse shape that bleeds past the top edges (–120dp top margin, –100dp start/end) creating a clipped capsule effect. Color: `#D9EDFF`.
- **Gauge:** Custom circular arc view (`HealthScoreGaugeView`) — 240×240dp, transparent background, white circular container behind it.
- **Score display (overlaid on gauge, centered):**
  - Large score value: `46sp`, bold, black (`#000000`)
  - `/100` suffix: `23sp`, medium, grey (`#5F5F5F`)
  - Label below: `"HEALTH SCORE"`, `14sp`, bold, black
  - Status badge: rounded pill shape, `11sp` — color varies by score (see §7.1)
  - Comparison line: `"↑ 3pts vs Yesterday"` — `11sp`, black; arrow colored green/red

### Health Score Calculation
Score is computed from 6 metrics (max 100):

| Metric | Max Points | Logic |
|--------|-----------|-------|
| Heart Rate | 20 | 60–100 BPM = 20, 50–110 = 15, 40–120 = 10, else 5 |
| HRV | 20 | ≥50ms = 20, ≥30ms = 15, ≥20ms = 10, else 5 |
| Blood Pressure | 15 | 90–120/60–80 = 15, elevated = 10, else 5 |
| SpO2 | 15 | ≥95% = 15, ≥90% = 10, else 5 |
| ECG Score | 15 | ≥15 pts = 15, ≥10 = 10, else 5 |
| Activity (Calories) | 15 | ≥2000kcal = 15, ≥1500 = 10, else 5 |

**Score clamped to 0–100.**

### Score Status Badge
| Score Range | Label | Text Color | Background |
|-------------|-------|-----------|-----------|
| ≥ 85 | Excellent | `#005809` | `rounded_green_background` |
| ≥ 70 | Good | `#FF8F00` | `rounded_orange_background` |
| ≥ 50 | Fair | `#F57C00` | `rounded_yellow_background` |
| < 50 | Poor | `#C62828` | `rounded_red_background` |

### Yesterday Comparison
- Persisted via `SharedPreferences ("HealthScorePrefs")`.
- Keys: `last_saved_date`, `yesterday_score`, `today_score`.
- On new day: yesterday's score is archived, today's score is reset.
- Arrow: `↑` green if improvement, `↓` red if decline; styled as bold 1.5× size.

---

## 4. Last Synced Banner

Positioned just below the gauge area (above the card sections). Uses **relative/absolute positioning** — no extra space taken; overlays the card below.

### Elements
- **Dot icon** (`ivSyncStatus`): colored dot image, tint reflects recency
- **Text** (`tvLastSynced`): e.g. `"Last synced: 5 min ago"`
- **Progress spinner** (`syncProgressBar`): shown during active sync; dot hidden
- **Manual sync button** (`ivManualSync`): tap to trigger manual sync

### Dot Color Logic
| Time Since Sync | Color |
|----------------|-------|
| < 2 hours | `#4CAF50` (green) |
| 2–12 hours | `#FFA726` (orange) |
| > 12 hours | `#F44336` (red) |

### Relative Time Text
| Elapsed | Display |
|---------|---------|
| < 1 min | "just now" |
| < 60 min | "X min ago" |
| < 24 hrs | "X hr(s) ago" |
| ≥ 24 hrs | "X day(s) ago" |
| No data | "Last synced: No data yet" |

### Text Color
Same as Cardiovascular Status Summary fragment — use `#546E7A` or match app theme subtitle color.

---

## 5. Card Sections — Common Design Rules

All health metric cards share these layout rules:

### Card Style
- White background (`#FFFFFF`)
- Corner radius: `12dp`
- Elevation: `6dp`
- Fixed height: `140dp`
- Uses `cardUseCompatPadding = true`
- Internal padding: `8dp` all sides

### Card Internal Layout (RelativeLayout)
```
TOP:     [Icon (28×28dp circle bg)] [Title 13sp bold]
MIDDLE:  [Value large text] [Unit small grey text]   ← centered vertically in card
BOTTOM:  [● Status text 11sp]                        ← aligned to bottom-left
```

### Icon Containers (28×28dp)
Each vital type uses a colored circle background:

| Background Drawable | Color | Used For |
|---------------------|-------|----------|
| `icon_bg_light_red` | Light red | Heart Rate, Blood Oxygen, Calories |
| `icon_bg_light_purple` | Light purple | HRV |
| `icon_bg_light_indigo` | Light indigo | ECG, Steps, Sleep Duration |
| `icon_bg_light_amber` | Light amber | ECG Details |
| `icon_bg_light_green` | Light green | Blood Pressure, BMI |
| `icon_bg_light_orange` | Light orange | Blood Glucose, Body Temp |

### Value Alignment
- Value text: **center of the card vertically**, aligned to **start (left)** horizontally
- Implemented via `android:layout_centerVertical="true"` + `android:layout_alignParentStart="true"`

### Status Text
- Always `11sp`, starts with `●` bullet
- Always at **bottom-left** of card: `layout_alignParentBottom="true"` + `layout_alignParentStart="true"`

---

## 6. Section 1 — Cardiovascular Vitality

**Section background:** `#D9EDFF` (light blue card)
**Section title:** "Cardiovascular Vitality", `18sp`, bold, black

### Row 1: Heart Rate | HRV | ECG

#### Heart Rate Card (`heart_rate_card`)
- Icon: heart (`baseline_favorite_24`), tint `#FF5252`, bg `icon_bg_light_red`
- Value: `heartRate` (Int), `28sp`, unit `"BPM"` grey `12sp`
- **Status logic:**
  | HR Range | Status | Color |
  |----------|--------|-------|
  | 60–100 | ● Optimal | `#4CAF50` |
  | 50–59 or 101–110 | ● Good | `#FFA726` |
  | Otherwise | ● Alert | `#FF5252` |
- **On tap:** Navigate to `CardiovascularStatusFragment` with `vitalType = "HEART_RATE"`

#### HRV Card (`hrv_card`)
- Icon: chart (`baseline_show_chart_24`), tint `#9C27B0`, bg `icon_bg_light_purple`
- Value: `hrv` (Int), `28sp`, unit `"ms"` grey
- **Status logic:**
  | HRV | Status | Color |
  |-----|--------|-------|
  | ≥ 50 | ● Good | `#4CAF50` |
  | ≥ 30 | ● Fair | `#FFA726` |
  | < 30 | ● Low | `#FF5252` |
- **On tap:** Navigate to `CardiovascularStatusFragment` with `vitalType = "HRV"`

#### ECG Card (`ecg_card`)
- Icon: ECG waveform (`ecg`), tint `#536DFE`, bg `icon_bg_light_indigo`
- Value: `ecgScore` (Int, 0–20), `28sp`, unit `"tores"` grey (i.e., "scores")
- **Status logic:**
  | ECG Score | Status | Color |
  |-----------|--------|-------|
  | ≥ 15 | ● Improving | `#536DFE` |
  | ≥ 10 | ● Fair | `#FFA726` |
  | < 10 | ● Low | `#FF5252` |
- **On tap:** Navigate directly to **ECG Fragment**

---

### Row 2: ECG Details | Blood Pressure | Blood Oxygen

#### ECG Details Card (`ecg_status_card`)
- Icon: ECG waveform (`ecg`), tint `#FFB300`, bg `icon_bg_light_amber`
- Value: `ecgStatus` (String), `16sp`, bold — e.g. `"Normal ECG"`, `"Bradycardia"`, `"Atrial Fibrillation"`
- **Status logic (from text):**
  | ECG Status | Indicator | Color |
  |-----------|-----------|-------|
  | "Normal ECG", "Normal Sinus", "Normal" | ● Healthy | `#FFB300` |
  | "Irregular" | ● Alert | `#FF5252` |
  | Others | ● Review | `#FFA726` |
- **On tap:** Navigate directly to **ECG Fragment**

#### ECG Status Text — Source Logic
```
isAfib == true          → "Atrial Fibrillation"
diagnoseType == 5       → "Ventricular Premature"
diagnoseType == 9       → "Atrial Premature"
heartRate ≤ 50          → "Bradycardia"
heartRate ≥ 120         → "Tachycardia"
hrv ≥ 125               → "Sinus Arrhythmia"
else                    → "Normal ECG"
```

#### ECG Score — Calculation
From ring's ECG indices (each 0–10 float):
```
avgIndex = (loadIndex + hrvIndex + pressureIndex + bodyIndex + symParaIndex) / 5
score = (avgIndex × 2).toInt(), clamped 0–20

Exceptions:
  isAfib == true  → score = 3
  diagnoseType == 5 or 9 → score = 5
```

#### Blood Pressure Card (`blood_pressure_card`)
- Icon: blood drop (`baseline_bloodtype_24`), tint `#4CAF50`, bg `icon_bg_light_green`
- Value: `"systolic/diastolic"` e.g. `"118/78"`, `24sp`; unit label `"mmHg"` at bottom-end
- **Status logic:**
  | BP | Status | Color |
  |----|--------|-------|
  | 90–120 / 60–80 | ● Normal | `#4CAF50` |
  | 121–139 or 81–89 | ● Elevated | `#FFA726` |
  | Outside above | ● High | `#FF5252` |
- **On tap:** Navigate to `CardiovascularStatusFragment` with `vitalType = "BLOOD_PRESSURE"`

#### Blood Oxygen Card (`blood_oxygen_card`)
- Icon: blood drop, tint `#F44336`, bg `icon_bg_light_red`
- Value: `bloodOxygen` (Int), `28sp`, unit `"%"` grey
- **Status logic:**
  | SpO2 | Status | Color |
  |------|--------|-------|
  | ≥ 95 | ● Excellent | `#4CAF50` |
  | ≥ 90 | ● Good | `#FFA726` |
  | < 90 | ● Low | `#FF5252` |
- **On tap:** Navigate to `CardiovascularStatusFragment` with `vitalType = "BLOOD_OXYGEN"`

---

## 7. Section 2 — Metabolic & Body

**Section background:** White, bordered with `border_metabolic` drawable (dashed/colored border)
**Section title:** "Metabolic & Body", `18sp`, bold

### Row 1: Calories | Steps | BMI

#### Calories Card (`calories_card`)
- Icon: fire (`baseline_local_fire_department_24`), tint `#EF5350`, bg `icon_bg_light_red`
- Value: formatted with commas e.g. `"2,150"`, `28sp`, unit `"kcal"` grey
- **Status:**
  | Calories | Status | Color |
  |---------|--------|-------|
  | ≥ 2000 | ● Active | `#EF5350` |
  | ≥ 1500 | ● Moderate | `#FFA726` |
  | < 1500 | ● Light | `#FFB300` |
- **On tap:** Navigate to `CaloriesFragment`

#### Steps Card (`steps_card`)
- Icon: walking figure (`baseline_directions_walk_24`), tint `#536DFE`, bg `icon_bg_light_indigo`
- Value: formatted with commas e.g. `"8,500"`, `28sp`, no unit label
- **Status (relative to daily target, default 10,000):**
  | Steps | Status | Color |
  |-------|--------|-------|
  | ≥ target | ● Target Met | `#4CAF50` |
  | ≥ 75% target | ● Almost There | `#66BB6A` |
  | ≥ 50% target | ● Halfway | `#FFA726` |
  | ≥ 20% target | ● Keep Going | `#536DFE` |
  | < 20% | ● Just Started | `#999999` |
- **On tap:** Navigate to `StepsFragment`
- **Insights & Alerts card** also reflects steps — tapping it also navigates to `StepsFragment`

#### BMI Card (`bmi_card`)
- Icon: walking figure, tint `#66BB6A`, bg `icon_bg_light_green`
- Value: 1 decimal e.g. `"23.2"`, `28sp`, unit `"kg/m²"` grey
- **Calculated from profile** (height + weight in SharedPreferences, not from ring):
  ```
  BMI = weight(kg) / (height(m))²
  Height handling: if < 10 → assumed feet.inches format → convert to cm
  ```
- **Status:**
  | BMI | Status | Color |
  |-----|--------|-------|
  | 18.5–24.9 | ● Healthy | `#66BB6A` |
  | 25–29.9 | ● Overweight | `#FFA726` |
  | < 18.5 | ● Underweight | `#FFB300` |
  | ≥ 30 | ● Obese | `#FF5252` |
- **On tap:** Navigate to `BmiFragment`

### Row 2: Blood Glucose | Body Temperature | (empty spacer)

#### Blood Glucose Card (`blood_glucose_card`)
- Icon: blood drop, tint `#FFA726`, bg `icon_bg_light_orange`
- Value: `bloodGlucose` (Int), `28sp`, unit `"mg/dl"` grey
- **Status:**
  | Glucose | Status | Color |
  |---------|--------|-------|
  | 70–99 | ● Normal | `#FFA726` |
  | 100–125 | ● Elevated | `#FFB300` |
  | Otherwise | ● High | `#FF5252` |
- **On tap:** Navigate to health data detail for `"blood_sugar"`

#### Body Temperature Card (`body_temp_card`)
- Icon: thermometer (`baseline_device_thermostat_24`), tint `#FF9800`, bg `icon_bg_light_orange`
- Value: `36.6`, `28sp`; unit (`°C` or `°F`) in separate `TextView`
- **Unit conversion:**
  - If user setting = Fahrenheit AND stored value < 45 → convert C→F
  - If user setting = Celsius AND stored value > 45 → convert F→C
  - Formula: `F = C × 9/5 + 32`; rounded to 1 decimal
- **Status (always evaluated in °C):**
  | Temp °C | Status | Color |
  |---------|--------|-------|
  | 36.1–37.2 | ● Normal | `#FF9800` |
  | 37.3–38.0 | ● Elevated | `#FFA726` |
  | > 38.0 | ● Fever | `#FF5252` |
  | < 36.1 | ● Low | `#536DFE` |
- **On tap:** Navigate to health data detail for `"temperature"`

---

## 8. Section 3 — Sleep & Stress

**Section background:** `#D9EDFF` (light blue card)
**Section title:** "Sleep & Stress", `18sp`, bold

### Row: Sleep Duration | Sleep Quality | Stress (Coming Soon)

#### Sleep Duration Card (`sleep_duration_card`)
- Icon: moon (`baseline_shield_moon_24`), tint `#536DFE`, bg `icon_bg_light_indigo`
- Value: `"7h 45m"` (hours + minutes), `20sp`, bold
- **Source:** `ConnectionPreferences.getLastDayTotalSleep(context)` → saved by `AutoSyncSleepHelper`
- **Sleep window:** previous day 20:00 → current day 19:59 (IST)
- **Status (vs target, default 8h = 480 min):**
  | Duration | Status | Color |
  |----------|--------|-------|
  | ≥ target | ● Target Met | `#536DFE` |
  | ≥ 87.5% | ● Almost There | `#66BB6A` |
  | ≥ 75% | ● Good | `#FFA726` |
  | ≥ 50% | ● Halfway | `#FFB300` |
  | < 50% | ● Low | `#FF5252` |
- **On tap:** Navigate to `SleepFragment`

#### Sleep Quality Card (`sleep_quality_card`)
- Icon: moon (same), tint different
- Value: `sleepQuality` (Int, 0–100), `28sp`, unit `"%"` grey
- **Source priority:**
  1. `ConnectionPreferences.getLastSleepQualityScore(context)` — cached by `SleepFragment`
  2. Fallback: recalculate from Room DB using same formula as `SleepFragment`
- **Score formula (per session):**
  ```
  sessionMinutes = deepSleepMin + lightSleepMin + remSleepMin
  rawScore = (sessionMin / 480.0 × 100).toInt()
  clamp: min 12, max 100
  final = average of all session scores in the sleep window
  ```
- **Status:**
  | Quality | Status | Color |
  |---------|--------|-------|
  | ≥ 90 | ● Excellent | `#66BB6A` |
  | ≥ 80 | ● Good | `#4CAF50` |
  | ≥ 70 | ● Fair | `#FFA726` |
  | < 70 | ● Poor | `#FF5252` |
- **On tap:** Navigate to `SleepFragment`

#### Stress Card
- Shows "Coming Soon" — no data binding
- No click handler

---

## 9. Section 4 — Insights & Alerts

**Single notification card** (`alert_card_1`) showing the latest push notification from `NotificationCache`.

### Design
- Left: colored icon container (28×28dp circle)
- Right: title (`14sp` bold) + message (`12sp` grey, max 2 lines, ellipsize end)
- Bottom-right: relative time label (`11sp` grey)

### Logic
```
Source: NotificationCache.latest (in-memory, set by HomeActivity after FCM/API fetch)
Zero API calls — purely read from cache.
```

### Icon Colors by Vital Type
| vital key | Icon | Color |
|-----------|------|-------|
| `heart_rate` | heart | `#FF5252` red |
| `hrv` | chart | `#9C27B0` purple |
| `blood_pressure` | blood drop | `#4CAF50` green |
| `blood_oxygen` | blood drop | `#F44336` red |
| `blood_sugar` | blood drop | `#FFA726` amber |
| `temperature` | thermometer | `#FF9800` orange |
| `sleep` | moon | `#536DFE` indigo |
| (default) | bell/info | grey |

### On Tap
→ Navigate to `NotificationsFragment`

### Relative Time Display
| Elapsed | Text |
|---------|------|
| < 60s | "Just now" |
| < 1h | "X minutes ago" |
| < 24h | "X hours ago" |
| < 48h | "Yesterday" |
| < 7d | "X days ago" |
| ≥ 7d | "MMM dd" formatted |

---

## 10. Data Flow & Loading Strategy

### Priority Order
```
1. Local Room DB (instant, no network)
   → heartRepo, bpRepo, bloodOxygenRepo, bloodGlucoseRepo, tempRepo, hrvRepo, ecgRepo
   → Today's latest entry preferred (API ≥ Android O); fallback to global latest

2. Sleep: ConnectionPreferences.getLastSleepQualityScore() cache first
   → Fallback: Room DB recalculation (same formula as SleepFragment)

3. Steps & Calories: ConnectionPreferences.loadTodayTotals()

4. BMI: Calculated from user profile (SharedPreferences "AppPreferences")
   → keys: user_height, user_weight

5. API fallback: Only if heartRate == 0 && bloodPressureSystolic == 0 && bloodOxygen == 0 && hrv == 0
   → Endpoint: getLastHealthDataById(userId)
   → Maps: heart_rate, blood_pressure, blood_oxygen, blood_sugar, temperature, hrv, sleep
```

### Update triggers
- `onViewCreated` → `loadHealthData()` → immediate local load
- BLE ConnectEvent (via EventBus) → may trigger `startHeartAndSleepSync()` if `pendingSyncAfterConnect == true`
- Auto-sync: If elapsed time ≥ user's configured interval (15/30/45/60 min) AND BLE connected → auto sync
- Manual sync button tap → if BLE connected: sync now; else: reconnect via BackgroundService then sync

### Trend/Previous Values
For `CardiovascularStatusFragment` (opened on card tap), previous values are also fetched:
- `heartRepo.getPreviousEntry()`
- `bpRepo.getPreviousEntry()`
- `bloodOxygenRepo.getPreviousEntry()`
- `hrvRepo.getPreviousEntry()`
- `ecgRepo.getPreviousEntry()`

---

## 11. Auto-Sync Logic

### Trigger Condition
```
elapsedMinutes = (now - lastSyncBatchTimeMillis) / 60_000
interval = ConnectionPreferences.getLastRingConfig(context)  // 15/30/45/60

if (elapsedMinutes >= interval && BLE connected && !isSyncing) → startHeartAndSleepSync()
```

### Sync Process
1. `AutoSyncHeartHelper.startSync()` — syncs heart rate from ring to Room DB + API
2. `AutoSyncSleepHelper.startSync()` — syncs sleep data from ring to Room DB + API
3. Both use callbacks (`AutoSyncListener`)
4. When both complete → refresh all UI + show Toast `"✓ Health data synced"`
5. Safety timeout: 30 seconds — if BLE callbacks never fire, reset spinner

### Manual Sync — BLE Disconnected Flow
1. User taps sync button
2. Banner shows `"Connecting…"` + spinner
3. `BackgroundService` started with device MAC + name
4. `pendingSyncAfterConnect = true`
5. On `ConnectEvent` (EventBus) received with `BLEState.ReadWriteOK` → fire `startHeartAndSleepSync()`
6. Safety timeout: 20 seconds → reset banner with `"Connection failed. Try again."`

---

## 12. Navigation Rules

### Bottom Navigation
- **Health (first tab):** If dashboard is showing → do nothing. Else → show dashboard.
- **Doctor, Appointment, Device, Family Care:** standard fragment replacement

### Top Nav — Notification Bell
- Bell icon **always visible**
- Badge (count) shown only if unread count > 0
- Tapping bell: if already on `NotificationsFragment` → do nothing; else → open `NotificationsFragment`

### Insight & Alerts — Steps card click
- Navigates to **StepsFragment** (not CaloriesFragment)

### ECG Card (both) click
- Navigates directly to **EcgFragment** (skips `CardiovascularStatusFragment`)

### Cardiovascular Cards click
- Heart Rate → `CardiovascularStatusFragment(vitalType="HEART_RATE")`
- HRV → `CardiovascularStatusFragment(vitalType="HRV")`
- Blood Pressure → `CardiovascularStatusFragment(vitalType="BLOOD_PRESSURE")`
- Blood Oxygen → `CardiovascularStatusFragment(vitalType="BLOOD_OXYGEN")`

All navigations use `HomeActivity.openFragment()` with `addToBackStack = true`.

---

## 13. SharedPreferences Keys Used

| Preference File | Key | Purpose |
|----------------|-----|---------|
| `AppPreferences` | `id` | User ID (Int) |
| `AppPreferences` | `user_height` | For BMI calc |
| `AppPreferences` | `user_weight` | For BMI calc |
| `UserPreferences` | `temperature_unit` | `"Celsius degrees"` or `"Fahrenheit"` |
| `UserPreferences` | `steps_target` | Daily step goal (default 10000) |
| `UserPreferences` | `sleep_target_minutes` | Sleep goal in minutes (default 480) |
| `HealthScorePrefs` | `last_saved_date`, `yesterday_score`, `today_score` | Health score comparison |
| `ConnectionPreferences` | `lastSleepQualityScore` | Cached sleep quality score from SleepFragment |
| `ConnectionPreferences` | `lastDayTotalSleep` | Total sleep in minutes |
| `ConnectionPreferences` | `ringConfig` | BLE interval setting 15/30/45/60 |
| `ConnectionPreferences` | `macAddress`, `deviceName` | Paired ring info |

---

## 14. State Variables

```
isBleConnected: Boolean          — current BLE state
isSyncing: Boolean               — prevents duplicate syncs
pendingSyncAfterConnect: Boolean — queued sync waiting for BLE connect
lastSyncBatchTimeMillis: Long    — timestamp of most recent ring data batch

// Current health values
heartRate, hrv, ecgScore: Int
ecgStatus: String
bloodPressureSystolic, bloodPressureDiastolic: Int
bloodOxygen, bloodGlucose: Int
bodyTemperature: Float
bmi: Float
caloriesBurned, stepsCount: Int
sleepDurationHours, sleepDurationMinutes, sleepQuality: Int
sleepLevel: String

// Previous values (for trend comparison in CardiovascularStatusFragment)
previousHeartRate, previousHrv: Int
previousBloodPressureSystolic, previousBloodPressureDiastolic: Int
previousBloodOxygen, previousEcgScore: Int
```

---

## 15. iOS Implementation Notes

- Replace `SharedPreferences` → `UserDefaults`
- Replace `Room DB` → `Core Data` or `SQLite` or `Realm`
- Replace `EventBus` → `NotificationCenter` or `Combine`
- Replace `WorkManager` → `BackgroundTasks` framework
- Replace `CardView` → `UIView` with `layer.cornerRadius` + `layer.shadowOpacity`
- Replace `RelativeLayout` → `UIKit AutoLayout` constraints (top/center-vertical/bottom anchor)
- Replace `ProgressBar` (circular indeterminate) → `UIActivityIndicatorView`
- `HealthScoreGaugeView` → Custom `CAShapeLayer`-based arc view
- All health thresholds, status text, and color logic are **identical** to Android — use same constants

---

## 16. Color Reference

| Color | Hex | Usage |
|-------|-----|-------|
| Page background | `#D9EDFF` | Top gauge area, Cardiovascular section, Sleep section |
| Card background | `#FFFFFF` | Individual metric cards |
| Primary text | `#000000` | Values, titles |
| Secondary text | `#999999` | Units |
| Card title | `#221F1F` | Dark near-black |
| Green status | `#4CAF50` / `#66BB6A` | Optimal / excellent |
| Orange status | `#FFA726` | Moderate / fair |
| Amber | `#FFB300` | ECG details, some alerts |
| Red status | `#FF5252` / `#F44336` | Alert / high risk |
| Indigo | `#536DFE` | ECG, Steps, Sleep |
| Purple | `#9C27B0` | HRV |

