# Appointments Tab — Design, Logic & API Flow

---

## Overview

The **Doctor** bottom nav tab (labelled as the appointments section) opens `AppointmentsFragment`. It is a **dual-tab screen** showing:

| Tab | Label | Content |
|-----|-------|---------|
| Tab 1 | Appointments | All appointments (all statuses) — sorted newest first |
| Tab 2 | Summary | Only **completed** appointments (status == 3) |

Both tabs share the **same single API call** made on screen load. The list is split at fetch time — status == 3 items go to `aSummaryList`, all items go to the appointments list.

---

## Screen Design (`fragment_appointments.xml`)

| Property | Value |
|----------|-------|
| Root | `ConstraintLayout` |
| Background | `#D9EDFF` (light blue) |

### Layout Structure

```
ConstraintLayout
  └── LinearLayout (vertical)
        ├── LinearLayout (tabContainer) ← tab switcher bar
        │     ├── TextView: appointments      (Tab 1)
        │     └── TextView: appointmentSummary (Tab 2)
        │
        ├── ListView: listView   ← Appointments list (VISIBLE by default)
        └── ListView: sListView  ← Summary list (GONE by default)
```

### Tab Bar

| Property | Value |
|----------|-------|
| Background (container) | `@drawable/tab_unselected_bg` |
| Layout | Horizontal, `margin 16dp` sides, `gravity center` |
| Each tab | `TextView`, `layout_weight=1`, `padding=12dp`, `14sp bold`, text color `@color/black` |
| Selected tab bg | `@drawable/tab_selected_bg` |
| Unselected tab bg | `@android:color/transparent` |

---

## Tab Switching Logic

### On screen load:

```kotlin
val isAppointmentSummary = sharedPreferences.getInt("isAppointmentSummary", 0)

if (isAppointmentSummary == 1) {
    // Show Summary tab
    listView.visibility = GONE
    sListView.visibility = VISIBLE
    appointmentSummary.background = tab_selected_bg
    appointments.background = transparent
} else {
    // Show Appointments tab (default)
    appointments.background = tab_selected_bg
    appointmentSummary.background = transparent
}
```

> The last selected tab is **persisted in SharedPreferences** key `"isAppointmentSummary"` (0 = Appointments, 1 = Summary). This means if the user was on Summary last time, it opens Summary on next visit.

### Tab click:

| Action | appointments tab click | appointmentSummary tab click |
|--------|----------------------|------------------------------|
| listView | VISIBLE | GONE |
| sListView | GONE | VISIBLE |
| appointments bg | `tab_selected_bg` | `transparent` |
| appointmentSummary bg | `transparent` | `tab_selected_bg` |
| SharedPref `isAppointmentSummary` | `0` | `1` |

---

## API Call — Fetch Appointments

### Trigger
Called once in `onViewCreated` via `getAppointmentList()`

### Request
```
GET patients/myappointments
    Query: patient_id = SharedPreferences["id"]
```

### Response Model
```kotlin
Appointments {
    response: Int
    data: List<AppointmentData>
}

AppointmentData {
    appt_id:          Int       // used as click argument to detail screen
    doctor_name:      String
    appt_date:        String    // format: "yyyy-MM-dd"
    appt_time:        String    // format: "HH:mm:ss"
    status:           Int       // 1=Confirmed, 2=Canceled, 3=Completed
    doctor_image_url: String
    purpose:          String
    patient_name:     String
    patient_code:     String
    patient_image_url:String
    patient_phone:    String
}
```

### Processing after fetch
```kotlin
// Sort all appointments newest first
val dataList = apiResp.data.sortedByDescending {
    LocalDateTime.parse("${it.appt_date} ${it.appt_time}", "yyyy-MM-dd HH:mm:ss")
}

// Filter only completed (status==3) for summary list
dataList.forEach {
    if (it.status == 3) aSummaryList.add(it)
}

// Set adapters
listView.adapter  = AppointmentListAdapter(dataList)     // all appointments
sListView.adapter = AppointmentSummaryAdapter(aSummaryList) // completed only
```

---

## Appointment Status Codes

Defined in `Constants.kt`:

| Status Code | Label | Color | Clickable |
|-------------|-------|-------|-----------|
| `1` | Confirmed | Green | ❌ No |
| `2` | Canceled | Red | ❌ No |
| `3` | Completed | Blue | ✅ Yes → opens AppointmentDetailsFragment |

---

## Tab 1 — Appointments List

### Adapter: `AppointmentListAdapter`
### Item Layout: `item_appointment_view.xml`

#### Card Design (`item_appointment_view.xml`)

```
LinearLayout (vertical)
  └── CardView (id: appointmentView)
        cornerRadius=16dp, bg=#FFFFFF, marginHorizontal=30dp, marginVertical=10dp, minHeight=100dp
        │
        ├── LinearLayout (vertical, margin=10dp)
        │     ├── LinearLayout (horizontal) — doctor row
        │     │     ├── ImageView: profileImage  (42×42dp, Glide circleCrop from doctor_image_url)
        │     │     ├── TextView:  doctorName    (20sp, bold, gravity bottom)
        │     │     └── ImageView: videoButton   (31×25dp, video icon)
        │     │
        │     ├── Row: "Appointment Date"  :  [aDateValue]   (16sp)
        │     ├── Row: "Appointment Time"  :  [aTimeValue]   (16sp)
        │     └── Row: "Appointment status":  [aStatusValue] (16sp, color varies by status)
        │
        └── ImageView: fwdArrow  (end|center_vertical, GONE by default — shown only for status==3)
```

#### Adapter Bindings

| View | Source | Notes |
|------|--------|-------|
| `profileImage` | `doctor_image_url` | Glide circleCrop, try/catch for bad URIs |
| `doctorName` | `doctor_name` | Direct |
| `aDateValue` | `appt_date` | Direct (raw string from API) |
| `aTimeValue` | `appt_time` | Direct (raw string from API) |
| `aStatusValue` | `status` | `Constants.APPOINTMENTSTATUS[status-1]` + color |
| `fwdArrow` | `status` | VISIBLE only if status==3 |
| `appointmentView` click | `status` | Only status==3 is clickable → `onItemClick(appt_id)` |

#### Status Rendering

| status | aStatusValue text | Color | fwdArrow | Card clickable |
|--------|------------------|-------|----------|----------------|
| 1 | "Confirmed" | Green | GONE | No |
| 2 | "Canceled" | Red | GONE | No |
| 3 | "Completed" | Blue | VISIBLE | Yes |

---

## Tab 2 — Appointment Summary List

### Adapter: `AppointmentSummaryAdapter`
### Item Layout: `item_appointment_summary_view.xml`
### Data source: `aSummaryList` — only status==3 items

#### Card Design (`item_appointment_summary_view.xml`)

```
LinearLayout (vertical)
  └── CardView (id: appointmentView)
        cornerRadius=16dp, bg=#FFFFFF, marginHorizontal=30dp, marginVertical=10dp, minHeight=100dp
        │
        ├── LinearLayout (vertical, margin=10dp, paddingVertical=15dp)
        │     ├── Row: "Patient name"       :  [patientName]  (16sp)
        │     ├── Row: "Doctor name"        :  [doctorName]   (16sp)
        │     └── Row: "Appointment Date"   :  [aTimeValue]   (16sp) ← shows "date time" combined
        │
        └── ImageView: SummaryfwdArrow  (end|center_vertical, always VISIBLE)
```

#### Adapter Bindings

| View | Source | Notes |
|------|--------|-------|
| `patientName` | `patient_name` | Direct |
| `doctorName` | `doctor_name` | Direct |
| `aTimeValue` | `"${appt_date} ${appt_time}"` | Combined date + time string |
| `appointmentView` click | — | All summary cards clickable → `onItemClick(appt_id)` |

---

## Navigation to Appointment Details

Both list and summary cards on click call `onItemClick(appt_id)` which is defined in `AppointmentsFragment` implementing `OnItemClickListener`:

```kotlin
override fun onItemClick(position: Int) {  // position = appt_id
    val fragment = AppointmentDetailsFragment()
    val bundle = Bundle()
    bundle.putInt("appointmentId", position)  // passes appt_id
    fragment.arguments = bundle
    (activity as HomeActivity).openFragment(fragment, "Appointment Details", true)
}
```

---

## Appointment Details Screen (`AppointmentDetailsFragment`)

### Layout: `fragment_appointment_details.xml`
### Background: `#D9EDFF`
### Root: `FrameLayout → ScrollView → LinearLayout (vertical, padding 16dp)`

### API Call

```
GET appointments/{appointmentId}/answers
    Path: appointmentId = arguments["appointmentId"]  (= appt_id)
    Response: List<Answers>  — uses index [0]
```

### Response Model (`Answers`)
```kotlin
Answers {
    id, appt_date, appt_time
    patient_id, doctor_id
    purpose          // comma-separated symptoms
    dependent_id
    slot
    remarks
    disease_name     // comma-separated diagnosis
    patient_name, patient_code, patient_type
    patient_image_url, patient_status
    doctor_name, doctor_department, doctor_specialization, doctor_image_url
    vittals:      List<Vital>
    diseases:     List<Disease>
    prescriptions: List<Prescription>
    dependent:    Dependant
}

Vital { id, appointment_id, question_vittal_id, value, vittal_question,
        low_value, high_value, normal_value, unit }

Prescription { id, appointment_id, medicine, notes, duration }

Disease { id, appointment_id, question_disease_id, question, answer, disease_question }
```

---

### Detail Screen Layout — Cards (top to bottom)

#### 1. Header Card (Logo + Doctor + Patient)

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white, marginBottom=12dp)
  └── LinearLayout (vertical, padding=16dp)
        ├── LinearLayout (horizontal, gravity=center_vertical)
        │     ├── ImageView: logoImage
        │     │       64×64dp, bg=#15558D (blue), padding=8dp
        │     │       src = ic_logo_hearto (set programmatically)
        │     │       bg = @drawable/logo_bg_shadow
        │     │
        │     └── LinearLayout (vertical, weight=1, marginStart=12dp)
        │           ├── TextView: dName   (18sp, bold, black)   ← doctor_name
        │           └── TextView: dPhone  (14sp, #555555)       ← doctor_department
        │
        ├── Divider (height=1dp, color=#E0E0E0, marginVertical=12dp)
        │
        └── LinearLayout (horizontal)
              ├── LinearLayout (vertical, weight=1)
              │     ├── TextView: pName  (15sp, bold, black)    ← patient_name
              │     └── TextView: pid    (13sp, #555555)        ← "Patient ID : {patient_code}"
              │
              └── LinearLayout (vertical, gravity=end)
                    ├── TextView: aDate  (13sp, bold, black)    ← appt_date
                    └── TextView: aTime  (13sp, #555555)        ← appt_time
```

**Binding:**
| View ID | Source field | Transform |
|---------|-------------|-----------|
| `logoImage` | — | Set programmatically: `R.drawable.ic_logo_hearto`, clearColorFilter() |
| `dName` | `answers.doctor_name` | Direct |
| `dPhone` | `answers.doctor_department` | Direct |
| `pName` | `answers.patient_name` | Direct |
| `pid` | `answers.patient_code` | `"Patient ID : ${patient_code}"` |
| `aDate` | `answers.appt_date` | Direct |
| `aTime` | `answers.appt_time` | Direct |

---

#### 2. Vitals Card

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white)
  └── LinearLayout (vertical, padding=16dp)
        ├── TextView label: "Vitals" (16sp, bold)
        └── TableLayout: VitalTable  ← rows added programmatically
```

**Binding (programmatic rows):**
```kotlin
for each vital in answers.vittals:
    // Deduplicate by vittal_question (only first occurrence of each question added)
    if (!addedVitals.contains(vQuestion)):
        TableRow:
          col 1: vittal_question  (13sp, #555555, padding=16dp, weight=1)
          col 2: "${value} ${unit}" (13sp, black, bold, padding=16dp, weight=1)
        Alternating row bg: even=#F5F5F5, odd=white
```

---

#### 3. Symptoms Card

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white)
  └── LinearLayout (vertical, padding=16dp)
        ├── TextView label: "Symptoms" (16sp, bold)
        └── TextView: text_symptoms  (14sp, #333333, lineSpacingExtra=4dp)
```

**Binding:**
```kotlin
binding.textSymptoms.text = answers.purpose
    .split(",").map { it.trim() }.filter { it.isNotEmpty() }.joinToString(", ")
```
`purpose` is comma-separated symptoms string from API.

---

#### 4. Diagnosis Card

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white)
  └── LinearLayout (vertical, padding=16dp)
        ├── TextView label: "Diagnosis" (16sp, bold)
        └── TextView: text_diagnosis  (14sp, #333333, lineSpacingExtra=4dp)
```

**Binding:**
```kotlin
binding.textDiagnosis.text = answers.disease_name
    .split(",").map { it.trim() }.filter { it.isNotEmpty() }.joinToString(", ")
```

---

#### 5. Medicine Card

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white)
  └── LinearLayout (vertical, padding=16dp)
        ├── TextView label: "Medicine" (16sp, bold)
        └── TableLayout: medicine_table
              ├── Header row (static, bg=#F5F5F5):
              │     col 1: "Medicine" (13sp, bold)
              │     col 2: "Dosage"   (13sp, bold)
              │     col 3: "Duration" (13sp, bold)
              └── Data rows (added programmatically)
```

**Binding (programmatic rows):**
```kotlin
for each prescription in answers.prescriptions:
    TableRow:
      col 1: prescription.medicine  (13sp, black, padding=8dp, weight=1)
      col 2: prescription.notes     (13sp, #555555, padding=8dp, weight=1)
      col 3: prescription.duration  (13sp, #555555, padding=8dp, weight=1)
    Alternating row bg: even=white, odd=#F5F5F5
```

---

#### 6. Remarks Card

```
CardView (cornerRadius=16dp, elevation=6dp, bg=white)
  └── LinearLayout (vertical, padding=16dp)
        ├── TextView label: "Remarks" (16sp, bold)
        └── TextView: text_remarks  (14sp, #333333, lineSpacingExtra=4dp)
```

**Binding:**
```kotlin
binding.textRemarks.text = answers.remarks
```

---

#### 7. Download & Share Buttons

```
LinearLayout (horizontal, weightSum=2, marginTop=4dp, marginBottom=24dp)
  ├── Button: btnDownload  (weight=1, marginEnd=6dp, style=AppButton) ← TODO: PDF download
  └── Button: btnShare     (weight=1, marginStart=6dp, style=AppButton) ← TODO: share
```

> Both buttons are **not yet implemented** — click listeners are TODOs.

---

## Complete Flow Diagram

```
Bottom Nav → Doctor tab
        │
        ▼
AppointmentsFragment loads
        │
        ├── Read SharedPref["isAppointmentSummary"]
        │       0 → show Appointments tab (default)
        │       1 → show Summary tab
        │
        ├── GET patients/myappointments?patient_id=userId
        │       │
        │       ├── Sort by date+time descending
        │       ├── Split: all → listView adapter
        │       │         status==3 only → sListView adapter
        │       └── Render both lists (only one visible at a time)
        │
        ├── User taps "Appointments" tab → listView VISIBLE, sListView GONE
        └── User taps "Summary" tab     → sListView VISIBLE, listView GONE

User taps a Completed appointment (status==3) card in either tab
        │
        ▼
AppointmentDetailsFragment
        │
        ├── GET appointments/{appt_id}/answers
        │       Response: List<Answers>[0]
        │
        ├── Bind Header card  (doctor name, dept, patient name, ID, date, time)
        ├── Build Vitals table (deduplicated by question)
        ├── Bind Symptoms      (purpose split by comma)
        ├── Bind Diagnosis     (disease_name split by comma)
        ├── Build Medicine table (medicine / notes / duration rows)
        └── Bind Remarks
```

---

## iOS Implementation Notes

1. **Tab switcher** — use `UISegmentedControl` or custom `UIButton` pair with selected/unselected background — persist last selected tab in `UserDefaults["isAppointmentSummary"]`
2. **Single API call** — fetch once, split into two arrays: all items + status==3 only
3. **Sort** — sort by `appt_date + appt_time` combined as `Date`, descending
4. **Status colours** — status 1 = green, 2 = red, 3 = blue (use `UIColor`)
5. **Only status==3 is tappable** in the appointments list — disable tap for 1 and 2
6. **Summary list** — all cards always tappable
7. **Forward arrow** — show only for status==3 in appointments tab; always show in summary tab
8. **Detail screen** — separate screen, pass `appt_id` as navigation param
9. **Vitals table** — `UITableView` or `UIStackView` rows, deduplicate by `vittal_question`, alternating row bg
10. **Medicine table** — `UITableView` with 3 columns (Medicine / Dosage / Duration), static header row
11. **Symptoms + Diagnosis** — split API comma string → join with `", "` → bind to label
12. **Download + Share** — not yet implemented, placeholder buttons

