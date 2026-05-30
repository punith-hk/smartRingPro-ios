# Cardiovascular Status Fragment — Design, Logic & Conditions

## Overview
`CardiovascularStatusFragment` is a full-screen detail fragment that classifies all 5 cardiovascular vitals (HR, HRV, ECG, BP, SpO₂) into three health buckets — **Optimal**, **Caution**, and **Critical** — and renders them in side-by-side scrollable columns.

It is launched from the Dashboard when the user taps any of the cardiovascular cards (Heart Rate, HRV, ECG, Blood Pressure, Blood Oxygen) or the Cardiovascular summary card itself.

---

## Entry Points / Navigation

| Caller | `vitalType` passed | Subtitle shown |
|--------|--------------------|----------------|
| Heart Rate card | `"HEART_RATE"` | "Heart Rate Details" |
| HRV card | `"HRV"` | "HRV Details" |
| ECG card | `"ECG"` | "ECG Details" |
| Blood Pressure card | `"BLOOD_PRESSURE"` | "Blood Pressure Details" |
| Blood Oxygen card | `"BLOOD_OXYGEN"` | "Blood Oxygen (SpO2) Details" |
| Cardiovascular summary card (all vitals) | `"ALL"` (default) | "HR, HRV, ECG, BP, SpO2" |

---

## Data Passed via Bundle (Arguments)

| Key | Type | Description |
|-----|------|-------------|
| `vitalType` | String | Which vital opened the screen |
| `heartRate` | Int | Current HR value (BPM) |
| `heartRateStatus` | String | Status text (e.g. "Normal", "Excellent") |
| `previousHeartRate` | Int | Previous HR value for trend arrow |
| `hrv` | Int | Current HRV value (ms) |
| `hrvStatus` | String | HRV status text |
| `previousHrv` | Int | Previous HRV for trend arrow |
| `bloodPressureSystolic` | Int | Systolic value |
| `bloodPressureDiastolic` | Int | Diastolic value |
| `bloodPressureStatus` | String | BP status text |
| `previousBloodPressureSystolic` | Int | Previous systolic for trend |
| `previousBloodPressureDiastolic` | Int | Previous diastolic for trend |
| `spo2` | Int | SpO₂ percentage |
| `spo2Status` | String | SpO₂ status text |
| `previousSpo2` | Int | Previous SpO₂ for trend |
| `ecgValue` | Int | ECG score (tores) |
| `ecgStatus` | String | ECG status text (also used as sub-label in card) |
| `previousEcgScore` | Int | Previous ECG score for trend |
| `lastSyncBatchTimeMillis` | Long | Epoch millis of last sync for "Last synced" banner |

---

## Fragment Lifecycle & Initialization

```
onCreateView()
  → inflates fragment_cardiovascular_status.xml

onViewCreated()
  → sets background color #D9EDFF
  → reads vitalType from arguments
  → updateCardiovascularSubtitle()   ← sets subtitle text in top card
  → setupCardiovascularCardClick()   ← wires top card tap to navigation
  → loadCardiovascularData()         ← reads all vitals from bundle
      → updateLastSynced()           ← updates "Last synced" overlay
      → buildAndRenderVitals()       ← classifies + renders 3 columns
  → view.post { setupScrollHints() } ← shows scroll hint after layout pass
```

---

## Classification Logic (`classify(status: String): VitalCategory`)

> ⚠️ **Important:** Classification is based **solely on the status string** passed via Bundle.  
> The **numeric value** (e.g. heartRate = 72) is **NOT evaluated** inside this fragment.  
> The status string is pre-computed by the Dashboard/ViewModel layer before launching this fragment, and the fragment trusts it as-is.

Each vital's status string is lowercased and matched:

| Condition keywords | Category |
|--------------------|----------|
| `optimal`, `normal`, `good`, `excellent`, `healthy`, `target met` | **OPTIMAL** (green) |
| `elevated`, `fair`, `moderate`, `almost`, `halfway`, `light`, `keep going`, `just started`, `active` | **CAUTION** (yellow/amber) |
| Anything else (including `--`, `low`, `high`, `critical`, `abnormal`) | **CRITICAL** (red) |

### Complete Distribution Flow (Value → Status → Column)

```
Numeric Value (e.g. HR = 72 BPM)
        │
        ▼
Dashboard / ViewModel computes status string
  (based on clinical thresholds — see table below)
        │
        ▼
Status string passed via Bundle to CardiovascularStatusFragment
        │
        ▼
classify(status) matches keywords → VitalCategory (OPTIMAL / CAUTION / CRITICAL)
        │
        ├──► OPTIMAL  → rendered in 🟢 Left column
        ├──► CAUTION  → rendered in 🟡 Middle column
        └──► CRITICAL → rendered in 🔴 Right column
```

### How Column Distribution Actually Works (Inside the Fragment)

The fragment calls `classify(statusString)` for each vital. **The numeric value is never checked** inside this fragment for column placement. Only the status string keyword determines the column:

```kotlin
// HR example — value 72 is displayed, but column is decided by classify(heartRateStatus)
val hrVital = VitalData(
    label = "HR", value = if (heartRate > 0) heartRate.toString() else "--",
    unit = "BPM", previousValue = previousHeartRate, currentValueInt = heartRate,
    category = classify(heartRateStatus)   // ← ONLY this drives column placement
)
```

Same pattern for all 5 vitals:

| Vital | Column driven by |
|-------|-----------------|
| HR | `classify(heartRateStatus)` |
| BP | `classify(bloodPressureStatus)` |
| HRV | `classify(hrvStatus)` |
| ECG | `classify(ecgStatus)` |
| SpO₂ | `classify(spo2Status)` |

### Status String → Column (keyword matching in `classify()`)

| Status string contains | → Column |
|------------------------|----------|
| `optimal`, `normal`, `good`, `excellent`, `healthy`, `target met` | 🟢 OPTIMAL |
| `elevated`, `fair`, `moderate`, `almost`, `halfway`, `light`, `keep going`, `just started`, `active` | 🟡 CAUTION |
| Anything else — `low`, `high`, `critical`, `abnormal`, `--` | 🔴 CRITICAL |

### Value Threshold → Status String (computed UPSTREAM before launching fragment)

The status strings passed in the Bundle must be pre-computed by the caller (Dashboard/HomeFragment) using clinical thresholds. The fragment trusts whatever string it receives:

| Vital | Value crosses threshold | Expected status string passed | → Column |
|-------|------------------------|-------------------------------|----------|
| **HR** | 60–100 BPM | `"Normal"` / `"Healthy"` | 🟢 OPTIMAL |
| **HR** | 50–59 or 101–120 BPM | `"Elevated"` / `"Active"` | 🟡 CAUTION |
| **HR** | < 50 or > 120 BPM | `"Low"` / `"High"` / `"Critical"` | 🔴 CRITICAL |
| **HRV** | ≥ 50 ms | `"Good"` / `"Excellent"` | 🟢 OPTIMAL |
| **HRV** | 20–49 ms | `"Fair"` / `"Moderate"` | 🟡 CAUTION |
| **HRV** | < 20 ms | `"Low"` / `"Critical"` | 🔴 CRITICAL |
| **BP** | Systolic 90–120, Diastolic 60–80 | `"Normal"` / `"Optimal"` | 🟢 OPTIMAL |
| **BP** | Systolic 121–139 or Diastolic 81–89 | `"Elevated"` | 🟡 CAUTION |
| **BP** | Systolic ≥ 140 or Diastolic ≥ 90 | `"High"` / `"Critical"` | 🔴 CRITICAL |
| **SpO₂** | 95–100% | `"Normal"` / `"Excellent"` | 🟢 OPTIMAL |
| **SpO₂** | 90–94% | `"Fair"` / `"Moderate"` | 🟡 CAUTION |
| **SpO₂** | < 90% | `"Low"` / `"Critical"` | 🔴 CRITICAL |
| **ECG** | Normal sinus rhythm score | `"Normal ECG"` / `"Healthy"` | 🟢 OPTIMAL |
| **ECG** | Mild irregularity score | `"Moderate"` / `"Fair"` | 🟡 CAUTION |
| **ECG** | Arrhythmia / AF score | `"Abnormal"` / `"Critical"` | 🔴 CRITICAL |

> **Note:** If a vital value is `0` or no data, status will be `"--"` → falls into **CRITICAL** column by default.  
> iOS should visually differentiate "no data" vitals from genuinely critical ones (e.g. dimmed style, "No data" label).

---

## VitalData Model

```kotlin
data class VitalData(
    val label: String,           // "HR", "BP", "HRV", "ECG", "SpO2"
    val value: String,           // Display value e.g. "72", "120/80", "--"
    val unit: String,            // "BPM", "mmHg", "ms", "tores", "%"
    val subLabel: String = "",   // Extra text below unit (only ECG uses this — shows ecgStatus)
    val previousValue: Int,      // For single-arrow vitals: previous reading
    val currentValueInt: Int,    // For single-arrow vitals: current reading
    val hasTwoArrows: Boolean,   // true only for BP (two trend arrows)
    val previousValueLeft: Int,  // BP: previous systolic
    val previousValueRight: Int, // BP: previous diastolic
    val currentValueLeft: Int,   // BP: current systolic
    val currentValueRight: Int,  // BP: current diastolic
    val category: VitalCategory  // OPTIMAL / CAUTION / CRITICAL
)
```

---

## Vital Display Rules

| Vital | Value shown if 0 | Unit | Sub-label | Arrow style |
|-------|-----------------|------|-----------|-------------|
| HR | `"--"` | BPM | — | Single arrow |
| BP | `"--/--"` | mmHg | — | Two arrows (systolic left, diastolic right) |
| HRV | `"--"` | ms | — | Single arrow |
| ECG | `"--"` | tores | ecgStatus text (if not "--") | Single arrow |
| SpO₂ | `"--"` | % | — | Single arrow |

---

## Trend Arrow Logic (`buildArrow(current, previous)`)

The arrow indicates **change direction** between the previous reading and the current reading:

| Condition | Meaning | Arrow | Color |
|-----------|---------|-------|-------|
| `current > previous` | Value **increased** | ↑ Up | Green `#4CAF50` |
| `current == previous` | Value **unchanged** | ↑ Up | Green `#4CAF50` |
| `previous == 0` | **No previous data** (first reading) | ↑ Up | Green `#4CAF50` |
| `current < previous` | Value **decreased** | ↓ Down | Red `#F44336` |

### Examples

| Vital | Previous | Current | Arrow |
|-------|----------|---------|-------|
| **HR** | 85 BPM | 72 BPM | ↓ Red (decreased) |
| **HR** | 65 BPM | 78 BPM | ↑ Green (increased) |
| **HR** | 0 (no data) | 72 BPM | ↑ Green (no previous) |
| **HRV** | 45 ms | 60 ms | ↑ Green (increased) |
| **HRV** | 60 ms | 38 ms | ↓ Red (decreased) |
| **HRV** | 0 (no data) | 45 ms | ↑ Green (no previous) |
| **ECG** | 85 tores | 92 tores | ↑ Green (increased) |
| **ECG** | 90 tores | 75 tores | ↓ Red (decreased) |
| **ECG** | 0 (no data) | 88 tores | ↑ Green (no previous) |
| **BP systolic** | 120 | 130 | ↑ Green (increased) |
| **BP systolic** | 130 | 120 | ↓ Red (decreased) |
| **BP diastolic** | 80 | 85 | ↑ Green (increased) |
| **BP diastolic** | 85 | 78 | ↓ Red (decreased) |
| **SpO₂** | 96% | 98% | ↑ Green (increased) |
| **SpO₂** | 98% | 94% | ↓ Red (decreased) |
| **SpO₂** | 0 (no data) | 97% | ↑ Green (no previous) |

> ⚠️ **Note:** The arrow color is purely directional (up/down vs previous), **not clinical** — e.g. a BP drop from 130→120 shows ↓ Red even though clinically it's an improvement. iOS should implement the same raw directional logic to match Android behavior.

> Arrow size is **12×12 dp**.  
> For single-value vitals (HR, HRV, ECG, SpO₂), an **invisible placeholder arrow** of equal size is added on the left side to keep the value text visually centered between the two sides.  
> For BP, the **left arrow** tracks systolic (previous → current systolic) and the **right arrow** tracks diastolic (previous → current diastolic) independently.

---

## Three-Column Layout

The fragment renders three columns side-by-side:

```
┌─────────────┬─────────────┬─────────────┐
│  🟢 OPTIMAL │  🟡 CAUTION │  🔴 CRITICAL│
│  Baseline:  │  Recent     │  Immediate  │
│  Excellent  │  Deviation  │  Attention  │
│─────────────│─────────────│─────────────│
│ [vitals...] │ [vitals...] │ [vitals...] │
│ (scrollable)│ (scrollable)│ (scrollable)│
└─────────────┴─────────────┴─────────────┘
```

- Each column is fixed **360dp** tall with a scrollable inner `ScrollView`.
- Header section (circle icon, status label, sub-text, divider) is **fixed/non-scrollable**.
- The vital cards inside are scrollable.

### Column Headers

| Column | Circle bg | Label color | Label text | Sub-text |
|--------|-----------|-------------|-----------|---------|
| Optimal | `circle_green_shadow` + `gradient_green_circle` | `#4CAF50` | OPTIMAL | "Baseline: Excellent" |
| Caution | `circle_yellow_shadow` + `gradient_yellow_circle` | `#FFB300` | CAUTION | "Recent Deviation" |
| Critical | `circle_red_shadow` + `gradient_red_circle` | `#F44336` | CRITICAL | "Immediate Attention" |

### Empty State Messages

| Column empty | Message | Color |
|-------------|---------|-------|
| Optimal | "⚠ No vitals in\noptimal range" | `#999999` gray |
| Caution | "✓ No caution\nalerts" | `#4CAF50` green |
| Critical | "✓ No critical\nalerts" | `#4CAF50` green |

---

## Scroll Hint Behavior

After the layout is drawn (`view.post`):
- For each column's `ScrollView`, if the child height > the scroll view height, the scroll hint bar (`"scroll ↓"`) is shown.
- While scrolling, if `scrollY >= maxScroll - 4`, the hint is hidden (user reached the bottom).
- The hint re-appears while not at the bottom.

---

## Vital Item View Structure (per vital in each column)

```
[LinearLayout - vertical, center_horizontal]
  ├── TextView: Label (e.g. "HR")        → bold, 12sp, black
  ├── LinearLayout (horizontal):
  │     ├── ImageView: Left arrow / invisible placeholder
  │     ├── TextView: Value (e.g. "72")  → bold, 20sp (18sp for BP), black
  │     └── ImageView: Right arrow (trend)
  ├── TextView: Unit (e.g. "BPM")        → 10sp, #999999 gray
  └── TextView: Sub-label (ECG only)     → 9sp, #666666 (only if not empty/"--")
```

Each vital is separated by a thin `#E0E0E0` divider (1dp height, 8dp horizontal margin).

---

## Top Card — Cardiovascular Summary

A tappable `CardView` at the top of the screen. On tap, navigates based on `vitalType`:

| `vitalType` | Navigation |
|-------------|-----------|
| `"HEART_RATE"` | `openHealthDataFragment("heart_rate", "Heart Rate")` |
| `"HRV"` | `openHealthDataFragment("hrv", "Heart Rate Variability")` |
| `"ECG"` | `openFragment(EcgFragment(), "ECG", true)` |
| `"BLOOD_PRESSURE"` | `openHealthDataFragment("blood_pressure", "Blood Pressure")` |
| `"BLOOD_OXYGEN"` | `openHealthDataFragment("blood_oxygen", "Blood Oxygen")` |
| `"ALL"` | Shows Toast: "Please select a specific vital from dashboard" |

---

## Last Synced Overlay (Top-Right Corner)

Position: absolute top-right overlay using `RelativeLayout` parent.
Shows sync icon + text + colored dot.

### Text Format

| Condition | Text |
|-----------|------|
| `lastSyncBatchTimeMillis <= 0` | "Last synced: No data yet" |
| `< 1 min` | "Last data synced: just now" |
| `< 60 min` | "Last data synced: X min ago" |
| `< 24 hrs` | "Last data synced: X hr(s) ago" |
| `≥ 24 hrs` | "Last data synced: X day(s) ago" |

### Status Dot Color

| Time since last sync | Dot Color |
|---------------------|----------|
| `< 2 hours` | `#4CAF50` Green |
| `2 – 12 hours` | `#FFA726` Orange |
| `> 12 hours` | `#F44336` Red |

### Text Color
`#0D99FF` (blue) — same as in Dashboard fragment.

---

## Health Status Legend (Bottom)

Shown at the bottom of the scroll view:
- **● Optimal** – Within Normal Range → `#4CAF50`
- **● Caution** – Requires Attention → `#FFB300`
- **● Critical** – Immediate Action Required → `#F44336`

---

## Background & Colors

| Element | Color |
|---------|-------|
| Screen background | `#D9EDFF` (light blue) |
| Card backgrounds | White (`card_rounded_white` drawable) |
| Column elevation | 4dp |
| Section title "CARDIOVASCULAR HEALTH" | `#221F1F` bold |
| Top screen title "CARDIOVASCULAR STATUS SUMMARY" | `#000000` bold 18sp |

---

## iOS Implementation Notes

1. The fragment is launched as a **child screen** (push navigation) from dashboard cards.
2. All data is **passed as arguments** — no API calls inside this fragment.
3. Classification is purely **string-matching** on the status field (lowercase).
4. The three columns are **always visible** (no toggle/collapse).
5. Each column scrolls **independently**.
6. Trend arrows compare `current vs previous` reading — **green up if current ≥ previous or previous == 0**.
7. The "Last Synced" overlay should be **position absolute** (top-right), should not take layout space.
8. ECG is the only vital with a sub-label (the ECG status text is shown below the unit).
9. BP is the only vital with **two** trend arrows (one for systolic, one for diastolic).

