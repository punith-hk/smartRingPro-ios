# BMI Fragment - Design & Implementation

**HEARTO App - Body Mass Index Calculator & Tracker**  
**Fragment:** `BmiFragment.kt`  
**Custom View:** `BmiMeterView.kt`  
**Layout:** `fragment_bmi.xml`

---

## 📋 Overview

The BMI (Body Mass Index) Fragment provides an intuitive interface for users to calculate and track their BMI by selecting height and weight. It features a custom-designed semi-circular gauge meter that visually displays BMI values across five color-coded categories. The BMI data integrates with the user's profile and is used throughout the app for health insights.

**Key Features:**
- Custom BMI meter gauge with 5 color-coded segments
- Height selection: 100-250 CM
- Weight selection: 20-200 KG
- Real-time BMI calculation and visualization
- Profile API integration for data persistence
- Bottom sheet pickers for easy input
- Responsive design with smooth animations

---

## 🎨 Design Architecture

### Screen Structure

```
ScrollView (Full Height)
└── LinearLayout (Vertical, Padding 20dp)
    ├── Title: "Body Mass Index"
    ├── BMI Meter Card
    │   ├── Title: "BMI Meter"
    │   └── BmiMeterView (Custom Gauge)
    ├── Height Input
    │   ├── Label: "Height (CM)"
    │   └── Selection Card (Clickable)
    ├── Weight Input
    │   ├── Label: "Weight (KG)"
    │   └── Selection Card (Clickable)
    └── Update Button
```

---

## 🎨 Screen Design

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│       Body Mass Index               │  Background
│                                     │  #D9EDFF
│  ┌───────────────────────────────┐ │
│  │       BMI Meter               │ │  White Card
│  │                               │ │
│  │    [Semi-Circular Gauge]      │ │  Custom
│  │   ┌─────────────────────┐    │ │  Meter
│  │   │   U   N   O   O   S │    │ │  View
│  │   └─────────────────────┘    │ │
│  │           [Needle]            │ │
│  │                               │ │
│  │          ○ BMI                │ │  Center
│  │        23.5 kg/m²             │ │  Display
│  │   160 CM       65 KG          │ │  with
│  │         Normal                │ │  Status
│  └───────────────────────────────┘ │
│                                     │
│  Height (CM)                        │  Input
│  ┌───────────────────────────┐   →│  Fields
│  │  170 CM                   │     │
│  └───────────────────────────┘     │
│                                     │
│  Weight (KG)                        │
│  ┌───────────────────────────┐   →│
│  │  65 KG                    │     │
│  └───────────────────────────┘     │
│                                     │
│  ┌───────────────────────────┐     │
│  │        Update             │     │  Action
│  └───────────────────────────┘     │  Button
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 BMI Meter View (Custom Component)

### Design Specifications

#### Semi-Circular Gauge

**Arc Details:**
- **Total Arc:** 180° (half circle)
- **Start Angle:** 180° (left side)
- **End Angle:** 360° (right side, through 270° at top)
- **Segments:** 5 equal segments (36° each)
- **Stroke Width:** 60% of radius
- **Arc Radius:** 36% of view width

**Segment Layout:**
```
        270° (Top)
          ↑
    ┌─────────────┐
180°│ U N O O  S  │ 360°
    └─────────────┘
   
Where:
U = Underweight (Blue)
N = Normal (Green)
O = Overweight (Yellow)
O = Obese (Orange)
S = Severely Obese (Red)
```

---

### BMI Categories & Colors

#### 1. Underweight (< 18.5)
- **Color:** `#4FC3F7` (Light Blue)
- **Arc Position:** 180° to 144° (left segment)
- **Label:** "UNDERWEIGHT\n< 18.5"
- **Status Text:** "Underweight"

#### 2. Normal (18.5 - 24.9)
- **Color:** `#4CAF50` (Green)
- **Arc Position:** 144° to 108°
- **Label:** "NORMAL\n18.5–24.9"
- **Status Text:** "Normal"

#### 3. Overweight (25.0 - 29.9)
- **Color:** `#FFC107` (Amber/Yellow)
- **Arc Position:** 108° to 72°
- **Label:** "OVERWEIGHT\n25.0–29.9"
- **Status Text:** "Overweight"

#### 4. Obese (30.0 - 39.9)
- **Color:** `#FF7043` (Deep Orange)
- **Arc Position:** 72° to 36°
- **Label:** "OBESE\n30.0–39.9"
- **Status Text:** "Obese"

#### 5. Severely Obese (≥ 40.0)
- **Color:** `#F44336` (Red)
- **Arc Position:** 36° to 0° (right segment)
- **Label:** "SEVERELY\nOBESE\n≥ 40.0"
- **Status Text:** "Severely Obese"

---

### Needle Indicator

**Design:**
```
      [Tip]
        ▲
        │   Needle
        │
    ●───────  Center dot
```

**Specs:**
- **Color:** #333333 (Dark Gray)
- **Length:** Arc radius
- **Shape:** Triangle (isosceles)
- **Base Width:** 0.15 × radius
- **Center Attachment:** Circular black dot (35% of center circle radius)
- **Rotation:** Based on BMI value (180° to 360° range)

**Angle Calculation:**
```kotlin
fun bmiToAngle(bmi: Float): Float {
    val clampedBmi = bmi.coerceIn(0f, 50f)
    
    // Find which segment the BMI falls into
    for (i in 0 until segmentCount) {
        val lo = bmiBreakpoints[i]     // [0, 18.5, 25, 30, 40, 50]
        val hi = bmiBreakpoints[i + 1]
        
        if (clampedBmi <= hi) {
            val fraction = (clampedBmi - lo) / (hi - lo)
            val segStartAngle = 180f + i * 36f
            return segStartAngle + fraction * 36f
        }
    }
    return 360f  // Max value
}
```

**Examples:**
- BMI 15.0 → ~160° (Underweight segment)
- BMI 22.0 → ~126° (Normal segment, center)
- BMI 27.5 → ~90° (Overweight segment, center)
- BMI 35.0 → ~54° (Obese segment)
- BMI 45.0 → ~18° (Severely Obese segment)

---

### Center Circle

**Design:**
```
┌─────────────┐
│             │
│      ●      │  Center dot (black)
│     ◯ ◯     │  Circle outline
│             │
└─────────────┘
```

**Specs:**
- **Outer Circle:**
  - **Radius:** 22% of stroke width
  - **Fill:** White (#FFFFFF)
  - **Border:** Dark gray (#333333)
  - **Border Width:** 2% of stroke width

- **Center Dot:**
  - **Radius:** 35% of circle radius
  - **Fill:** Black (#000000)
  - **Purpose:** Needle attachment point

---

### Text Display (Below Center Circle)

**Layout:**
```
        BMI
     23.5 kg/m²
 160 CM    65 KG
      Normal
```

#### 1. BMI Label
- **Text:** "BMI"
- **Position:** Below center circle
- **Size:** 18% of stroke width
- **Color:** #555555 (Gray)
- **Style:** Bold
- **Alignment:** Center

#### 2. BMI Value
- **Format:** "23.5 kg/m²"
- **Value:** Bold, Black, 42% of stroke width
- **Unit:** Normal, 16% of stroke width
- **Precision:** 1 decimal place
- **Alignment:** Center (value + unit together)
- **Calculation:** Weight (kg) / (Height (m))²

#### 3. Height and Weight
- **Layout:** Horizontal split
- **Height:** Left side (e.g., "160 CM")
- **Weight:** Right side (e.g., "65 KG")
- **Size:** 16% of stroke width
- **Color:** #555555 (Gray)
- **Style:** Bold
- **Position:** Below BMI value

#### 4. Status Text
- **Text:** Category name (e.g., "Normal")
- **Size:** 24% of stroke width
- **Color:** Category color (Green for Normal, etc.)
- **Style:** Bold
- **Position:** Below height/weight row

---

### Segment Labels

**Positioning:**
```
Each label at mid-angle of its segment

UNDERWEIGHT    NORMAL    OVERWEIGHT   OBESE    SEVERELY
   < 18.5    18.5–24.9   25.0–29.9  30.0–39.9   OBESE
                                                 ≥ 40.0
```

**Specs:**
- **Position:** Outer edge of arc (radius × 1.24)
- **Size:** 14% of stroke width
- **Color:** White (#FFFFFF)
- **Style:** Bold, Multi-line
- **Alignment:** Center
- **Background:** Segment color

**Angle Calculation:**
```kotlin
val midAngle = startAngle + sweepPerSegment / 2f
val labelRadius = radius * 1.24f
val angleRad = Math.toRadians(midAngle.toDouble())
val labelX = cx + labelRadius * cos(angleRad).toFloat()
val labelY = cy + labelRadius * sin(angleRad).toFloat()
```

---

### View Measurement

**Height Calculation:**
```kotlin
val radius = width * 0.36f
val strokeWidth = radius * 0.60f
val topPad = strokeWidth / 2f + 8f
val circleR = strokeWidth * 0.22f

// Text heights
val bmiLabelSize = strokeWidth * 0.18f
val valueFontSize = strokeWidth * 0.42f
val statusFontSize = strokeWidth * 0.24f

val textHeight = circleR + bmiLabelSize + 4f + valueFontSize + 2f + statusFontSize + 2f
val neededHeight = topPad + radius + strokeWidth / 2f + textHeight
```

**Result:** Dynamic height based on width (maintains proper proportions)

---

## 📱 Fragment UI Components

### Screen Background
- **Color:** #D9EDFF (Light Blue)
- **Container:** ScrollView with vertical LinearLayout
- **Padding:** 20dp all sides

---

### 1. Title Section

```xml
Body Mass Index
```

**Specs:**
- **Text:** "Body Mass Index"
- **Size:** 18sp
- **Color:** Black (#000000)
- **Style:** Bold
- **Alignment:** Center
- **Margin Bottom:** 10dp

---

### 2. BMI Meter Card

```xml
┌───────────────────────────────────┐
│       BMI Meter                   │  Card Title
│                                   │
│   [BmiMeterView Custom Gauge]     │  Custom View
│                                   │
└───────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Margin Bottom:** 24dp
- **Padding:** 16dp horizontal, 16dp top, 2dp bottom

**Card Title:**
- **Text:** "BMI Meter"
- **Size:** 16sp
- **Color:** Black
- **Style:** Bold
- **Alignment:** Center
- **Margin Bottom:** 8dp

**Custom View:**
- **Component:** `BmiMeterView`
- **Width:** Match parent
- **Height:** Wrap content (calculated dynamically)
- **Alignment:** Center

---

### 3. Height Input Card

```xml
Height (CM)
┌───────────────────────────────┐
│  170 CM                     → │
└───────────────────────────────┘
```

**Label:**
- **Text:** "Height (CM)"
- **Size:** 14sp
- **Color:** Black
- **Margin Bottom:** 4dp

**Input Card (RelativeLayout):**
- **ID:** `heightSelectionCard`
- **Clickable:** Yes
- **Focusable:** Yes
- **Elevation:** 4dp
- **Margin Bottom:** 20dp

**TextView Display:**
- **ID:** `tvSelectedHeight`
- **Background:** `@drawable/input_box_background_shadow` (White with shadow)
- **Padding:** 15dp
- **Size:** 16sp
- **Color:** Black (#000000)
- **Hint:** "Select Height"
- **Hint Color:** #777777
- **Focusable:** false
- **Clickable:** false

**Arrow Icon:**
- **Drawable:** `baseline_arrow_forward_ios_24`
- **Size:** 20dp × 20dp
- **Tint:** #999999 (Light Gray)
- **Position:** End-aligned, centered vertically
- **Margin End:** 15dp

**Action:**
- Opens bottom sheet picker with height options (100-250 CM)

---

### 4. Weight Input Card

```xml
Weight (KG)
┌───────────────────────────────┐
│  65 KG                      → │
└───────────────────────────────┘
```

**Label:**
- **Text:** "Weight (KG)"
- **Size:** 14sp
- **Color:** Black
- **Margin Bottom:** 4dp

**Input Card (RelativeLayout):**
- **ID:** `weightSelectionCard`
- **Clickable:** Yes
- **Focusable:** Yes
- **Elevation:** 4dp
- **Margin Bottom:** 28dp

**TextView Display:**
- **ID:** `tvSelectedWeight`
- **Background:** `@drawable/input_box_background_shadow`
- **Padding:** 15dp
- **Size:** 16sp
- **Color:** Black (#000000)
- **Hint:** "Select Weight"
- **Hint Color:** #777777
- **Focusable:** false
- **Clickable:** false

**Arrow Icon:**
- **Drawable:** `baseline_arrow_forward_ios_24`
- **Size:** 20dp × 20dp
- **Tint:** #999999
- **Position:** End-aligned, centered vertically
- **Margin End:** 15dp

**Action:**
- Opens bottom sheet picker with weight options (20-200 KG)

---

### 5. Update Button

```xml
┌───────────────────────────────┐
│          Update               │
└───────────────────────────────┘
```

**Button Specs:**
- **ID:** `btn_update_bmi`
- **Style:** `@style/AppButton` (Blue rounded button)
- **Width:** Match parent
- **Height:** Wrap content
- **Text:** "Update"
- **Margin Bottom:** 20dp

**Action:**
- Validates height and weight selections
- Calculates BMI
- Saves to profile via API
- Updates local SharedPreferences
- Shows success/error toast
- Refreshes meter display

---

## 🔧 Core Functionality

### 1. Data Loading (onViewCreated)

```kotlin
// Load from SharedPreferences (set by Dashboard/HomeActivity)
val prefs = getSharedPreferences("AppPreferences", MODE_PRIVATE)
userId = prefs.getInt("id", -1)

val localHeight = prefs.getString("user_height", "") ?: ""
val localWeight = prefs.getString("user_weight", "") ?: ""

// Display height (convert to int for cleaner display)
if (localHeight.isNotEmpty()) {
    val hInt = localHeight.toDoubleOrNull()?.toInt() ?: localHeight
    tvHeight.text = "$hInt CM"
}

// Display weight (convert to int)
if (localWeight.isNotEmpty()) {
    val wInt = localWeight.toDoubleOrNull()?.toInt() ?: localWeight
    tvWeight.text = "$wInt KG"
}

// Update meter display
refreshBmiDisplay()
updateMeterHeightWeight()

// Fetch other profile fields (needed for API save)
fetchProfileFieldsOnly()
```

**Data Source:**
- **Primary:** SharedPreferences ("AppPreferences")
- **Keys:** "user_height", "user_weight"
- **Stored by:** Dashboard, HomeActivity, Profile update
- **Format:** String (CM for height, KG for weight)

---

### 2. BMI Calculation

```kotlin
private fun refreshBmiDisplay() {
    // Extract values
    val heightText = tvHeight.text.toString().trim()
    val weightText = tvWeight.text.toString().trim()
    
    // Parse to float
    val heightCm = heightText.replace(" CM", "").trim().toFloatOrNull() ?: return
    val weightKg = weightText.replace(" KG", "").trim().toFloatOrNull() ?: return
    
    // Validate
    if (heightCm <= 0 || weightKg <= 0) return
    
    // Calculate BMI: weight (kg) / (height (m))²
    val heightM = heightCm / 100f
    val bmi = weightKg / (heightM * heightM)
    
    // Round to 1 decimal place
    val bmiRounded = bmi.toBigDecimal()
        .setScale(1, java.math.RoundingMode.HALF_EVEN)
        .toFloat()
    
    // Update meter
    bmiMeterView.setBmi(bmiRounded)
}
```

**Formula:**
```
BMI = Weight (kg) / Height (m)²

Example:
Height: 170 cm = 1.70 m
Weight: 65 kg
BMI = 65 / (1.70 × 1.70)
    = 65 / 2.89
    = 22.5 kg/m²
```

**Precision:**
- Rounded to 1 decimal place
- Uses `HALF_EVEN` rounding mode
- Example: 22.48 → 22.5, 22.45 → 22.4

---

### 3. Height Picker

```kotlin
private fun showHeightPicker() {
    // Generate options: 100 to 250 CM
    val options = (100..250).map { "$it CM" }.toTypedArray()
    
    // Get current value
    val current = tvHeight.text.toString().trim()
    
    // Find current index (default to 170 CM = index 70)
    val currentIdx = if (current.isNotEmpty() && current != "Select Height") {
        options.indexOfFirst { it == current }.coerceAtLeast(0)
    } else {
        70  // Default to 170 CM
    }
    
    // Show picker
    showPickerBottomSheet("Select Height", options, currentIdx) { idx ->
        tvHeight.text = options[idx]
        refreshBmiDisplay()
        updateMeterHeightWeight()
    }
}
```

**Options:**
- **Range:** 100 CM to 250 CM
- **Step:** 1 CM
- **Total Options:** 151
- **Default:** 170 CM (index 70)
- **Format:** "XXX CM"

**Example Values:**
- 100 CM (3'3")
- 150 CM (4'11")
- 170 CM (5'7")
- 200 CM (6'7")
- 250 CM (8'2")

---

### 4. Weight Picker

```kotlin
private fun showWeightPicker() {
    // Generate options: 20 to 200 KG
    val options = (20..200).map { "$it KG" }.toTypedArray()
    
    // Get current value
    val current = tvWeight.text.toString().trim()
    
    // Find current index (default to 70 KG = index 50)
    val currentIdx = if (current.isNotEmpty() && current != "Select Weight") {
        options.indexOfFirst { it == current }.coerceAtLeast(0)
    } else {
        50  // Default to 70 KG
    }
    
    // Show picker
    showPickerBottomSheet("Select Weight", options, currentIdx) { idx ->
        tvWeight.text = options[idx]
        refreshBmiDisplay()
        updateMeterHeightWeight()
    }
}
```

**Options:**
- **Range:** 20 KG to 200 KG
- **Step:** 1 KG
- **Total Options:** 181
- **Default:** 70 KG (index 50)
- **Format:** "XXX KG"

**Example Values:**
- 20 KG (44 lbs)
- 50 KG (110 lbs)
- 70 KG (154 lbs)
- 100 KG (220 lbs)
- 200 KG (440 lbs)

---

### 5. Bottom Sheet Picker

```kotlin
private fun showPickerBottomSheet(
    title: String,
    values: Array<String>,
    currentIdx: Int,
    onSure: (Int) -> Unit
) {
    val dialog = Dialog(requireContext())
    dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
    
    val dialogView = inflater.inflate(R.layout.dialog_number_picker, null)
    dialog.setContentView(dialogView)
    
    // Full-width, bottom-aligned
    dialog.window?.apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        setLayout(MATCH_PARENT, WRAP_CONTENT)
        setGravity(Gravity.BOTTOM)
        attributes?.windowAnimations = android.R.style.Animation_InputMethod
    }
    
    // Configure NumberPicker
    val picker = dialogView.findViewById<NumberPicker>(R.id.number_picker)
    picker.minValue = 0
    picker.maxValue = values.size - 1
    picker.displayedValues = values
    picker.value = currentIdx.coerceIn(0, values.size - 1)
    picker.wrapSelectorWheel = false
    
    // Buttons
    tvCancel.setOnClickListener { dialog.dismiss() }
    tvSure.setOnClickListener {
        onSure(picker.value)
        dialog.dismiss()
    }
    
    dialog.show()
}
```

**Dialog Style:**
```
┌─────────────────────────────────────┐
│                                     │  (Rounded top)
│  [Cancel]   Select Height   [Sure]  │  Header
│  ═══════════════════════════════════│
│           168 CM                    │
│         ► 169 CM ◄                  │  NumberPicker
│           170 CM                    │  (Scrollable)
│           171 CM                    │
│                                     │
└─────────────────────────────────────┘
```

**Same picker used for both height and weight with different data**

---

### 6. Update BMI (Save to Profile)

```kotlin
private fun updateBmi() {
    // 1. Validate inputs
    val heightText = tvHeight.text.toString().trim()
    val weightText = tvWeight.text.toString().trim()
    
    if (heightText == "Select Height" || heightText.isEmpty()) {
        Toast.makeText(context, "Please select height", LENGTH_SHORT).show()
        return
    }
    if (weightText == "Select Weight" || weightText.isEmpty()) {
        Toast.makeText(context, "Please select weight", LENGTH_SHORT).show()
        return
    }
    
    // 2. Extract values
    val height = heightText.replace(" CM", "").trim()
    val weight = weightText.replace(" KG", "").trim()
    
    // 3. Convert gender for API
    val genderCode = when (gender) {
        "Male" -> "M"
        "Female" -> "F"
        "Other" -> "O"
        else -> gender
    }
    
    // 4. Show loading
    showLoadingDialog("Updating BMI...")
    
    // 5. Call API
    val repository = ProfileDataRepository()
    val call = repository.saveUserProfileData(
        userResId, userId, firstName, lastName, email, genderCode,
        phoneNumber, emergencyPhone, dob, bloodGroup,
        address, city, state, country, pincode,
        height, weight, 0, 1,
        existingDiseases, existingMedications, null
    )
    
    call.enqueue(object : Callback<AddProfileDataResponse> {
        override fun onResponse(call, response) {
            dismissLoadingDialog()
            
            if (response.isSuccessful && response.body()?.response == 0) {
                // 6. Update local SharedPreferences
                prefs.edit()
                    .putString("user_height", height)
                    .putString("user_weight", weight)
                    .apply()
                
                // 7. Refresh display
                refreshBmiDisplay()
                updateMeterHeightWeight()
                
                // 8. Success feedback
                Toast.makeText(context, "BMI updated successfully", LENGTH_SHORT).show()
                Log.i(TAG, "✅ BMI updated: height=$height cm, weight=$weight kg")
            } else {
                Toast.makeText(context, "Update failed. Please try again.", LENGTH_SHORT).show()
            }
        }
        
        override fun onFailure(call, t) {
            dismissLoadingDialog()
            Toast.makeText(context, "Network error. Please try again.", LENGTH_SHORT).show()
        }
    })
}
```

**API Requirements:**
- Needs all profile fields (fetched silently on fragment load)
- Height and weight are just 2 fields in full profile update
- Other fields: name, email, gender, DOB, blood group, address, etc.
- API endpoint: `POST /add_profile_data`

**Success Flow:**
1. Validate inputs
2. Show loading dialog
3. Call API with all profile data
4. On success:
   - Update SharedPreferences
   - Refresh meter display
   - Show success toast
5. On failure:
   - Show error toast

---

### 7. Profile Fields Fetch (Silent)

```kotlin
private fun fetchProfileFieldsOnly() {
    val repository = ProfileDataRepository()
    repository.getUserProfileData(userId).enqueue(object : Callback<ProfileDataResponse> {
        override fun onResponse(call, response) {
            if (!isAdded) return
            val data = response.body()?.data ?: return
            
            // Store all fields (needed for API save)
            userResId = data.user_id
            firstName = data.first_name ?: ""
            lastName = data.last_name ?: ""
            email = data.email ?: ""
            gender = data.gender ?: ""
            phoneNumber = data.phone_number
            emergencyPhone = data.emergency_phone ?: ""
            dob = data.dob ?: ""
            bloodGroup = data.blood_group ?: ""
            address = data.address ?: ""
            city = data.city ?: ""
            state = data.state ?: ""
            country = data.country ?: ""
            pincode = data.pincode ?: ""
            existingDiseases = data.existing_diseases ?: ""
            existingMedications = data.existing_medications ?: ""
        }
        
        override fun onFailure(call, t) {
            Log.e(TAG, "Failed to fetch profile fields: ${t.message}")
        }
    })
}
```

**Purpose:**
- Fetches full profile silently in background
- Not displayed on screen (only height/weight shown)
- Required because API needs all fields for update
- Prevents overwriting existing profile data

**API Endpoint:**
- `GET /user_profile_data/{userId}`
- Returns complete profile object
- Called once on fragment load

---

### 8. Meter Update Helpers

```kotlin
// Update height/weight display on meter
private fun updateMeterHeightWeight() {
    val h = tvHeight.text.toString().trim()
        .let { if (it == "Select Height") "" else it }
    val w = tvWeight.text.toString().trim()
        .let { if (it == "Select Weight") "" else it }
    
    bmiMeterView.setHeightWeight(h, w)
}
```

**Behavior:**
- Passes height and weight strings to custom view
- Clears empty/default values
- Meter displays them below BMI value
- Updates on every selection change

---

## 📊 BMI Reference Chart

### BMI Categories (WHO Standard)

| Category | BMI Range | Health Risk | Meter Color |
|----------|-----------|-------------|-------------|
| **Underweight** | < 18.5 | Malnutrition risk | Light Blue (#4FC3F7) |
| **Normal** | 18.5 - 24.9 | Healthy | Green (#4CAF50) |
| **Overweight** | 25.0 - 29.9 | Increased risk | Yellow (#FFC107) |
| **Obese** | 30.0 - 39.9 | High risk | Orange (#FF7043) |
| **Severely Obese** | ≥ 40.0 | Very high risk | Red (#F44336) |

### Example Calculations

#### Example 1: Normal BMI
- **Height:** 170 cm (5'7")
- **Weight:** 65 kg (143 lbs)
- **BMI:** 65 / (1.7)² = 22.5
- **Category:** Normal
- **Meter:** Green segment, needle at ~126°

#### Example 2: Overweight
- **Height:** 165 cm (5'5")
- **Weight:** 70 kg (154 lbs)
- **BMI:** 70 / (1.65)² = 25.7
- **Category:** Overweight
- **Meter:** Yellow segment, needle at ~100°

#### Example 3: Obese
- **Height:** 175 cm (5'9")
- **Weight:** 95 kg (209 lbs)
- **BMI:** 95 / (1.75)² = 31.0
- **Category:** Obese
- **Meter:** Orange segment, needle at ~70°

#### Example 4: Underweight
- **Height:** 180 cm (5'11")
- **Weight:** 58 kg (128 lbs)
- **BMI:** 58 / (1.8)² = 17.9
- **Category:** Underweight
- **Meter:** Blue segment, needle at ~165°

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Text | `#000000` | Titles, labels, values |
| Secondary Text | `#555555` | Labels on meter, subtexts |
| Hint Text | `#777777` | Input hints |
| Arrow Icon | `#999999` | Navigation arrows |
| Underweight | `#4FC3F7` | BMI < 18.5 |
| Normal | `#4CAF50` | BMI 18.5-24.9 |
| Overweight | `#FFC107` | BMI 25-29.9 |
| Obese | `#FF7043` | BMI 30-39.9 |
| Severely Obese | `#F44336` | BMI ≥ 40 |
| Needle | `#333333` | Meter needle |
| Center Circle Border | `#333333` | Border around center |

### Typography

| Element | Size | Weight | Color | Usage |
|---------|------|--------|-------|-------|
| Screen Title | 18sp | Bold | Black | "Body Mass Index" |
| Card Title | 16sp | Bold | Black | "BMI Meter" |
| Input Label | 14sp | Normal | Black | "Height (CM)", "Weight (KG)" |
| Input Value | 16sp | Normal | Black | Selected height/weight |
| Meter Labels | 14% SW* | Bold | White | Segment labels on arc |
| BMI Label | 18% SW | Bold | #555555 | "BMI" text |
| BMI Value | 42% SW | Bold | Black | "23.5" number |
| BMI Unit | 16% SW | Normal | Black | "kg/m²" |
| Height/Weight | 16% SW | Bold | #555555 | On meter display |
| Status Text | 24% SW | Bold | Category Color | "Normal", "Obese", etc. |

*SW = Stroke Width (dynamic sizing based on meter size)

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 20dp |
| Card Corner Radius | 16dp |
| Card Elevation | 4dp |
| Card Margin Bottom | 24dp (meter), 20dp (inputs) |
| Card Padding | 16dp |
| Input Field Padding | 15dp |
| Input Field Elevation | 4dp |
| Button Margin Bottom | 20dp |
| Title Margin Bottom | 10dp |
| Label Margin Bottom | 4dp |

### Meter Sizing (Responsive)

```kotlin
// Based on view width
val radius = width * 0.36f
val strokeWidth = radius * 0.60f
val centerCircleRadius = strokeWidth * 0.22f
val labelRadius = radius * 1.24f

// Text sizes (based on stroke width)
val segmentLabelSize = strokeWidth * 0.14f
val bmiLabelSize = strokeWidth * 0.18f
val valueSize = strokeWidth * 0.42f
val unitSize = strokeWidth * 0.16f
val heightWeightSize = strokeWidth * 0.16f
val statusSize = strokeWidth * 0.24f
```

---

## 📱 User Experience Flows

### Flow 1: First-Time BMI Entry

```
Open BMI Fragment
    ↓
View displays:
    - Empty meter (no needle)
    - "Select Height" hint
    - "Select Weight" hint
    ↓
Tap "Select Height"
    ↓
Bottom sheet picker appears
    ↓
Scroll to 170 CM
    ↓
Tap "Sure"
    ↓
Picker closes
    ↓
Display shows "170 CM"
    ↓
Tap "Select Weight"
    ↓
Bottom sheet picker appears
    ↓
Scroll to 65 KG
    ↓
Tap "Sure"
    ↓
Picker closes
    ↓
Display shows "65 KG"
    ↓
Meter automatically updates:
    - Calculates BMI (22.5)
    - Needle points to green segment
    - Shows "22.5 kg/m²"
    - Shows "170 CM  65 KG"
    - Shows "Normal" in green
    ↓
Tap "Update" button
    ↓
Loading dialog: "Updating BMI..."
    ↓
API call with height + weight
    ↓
Success response
    ↓
SharedPreferences updated
    ↓
Loading dismisses
    ↓
Toast: "BMI updated successfully"
    ↓
Data available throughout app
```

---

### Flow 2: Update Existing BMI

```
Open BMI Fragment
    ↓
Data loads from SharedPreferences:
    - Height: 170 CM
    - Weight: 65 KG
    - BMI: 22.5
    - Meter shows green "Normal"
    ↓
User wants to update weight
    ↓
Tap "Select Weight" field
    ↓
Picker shows current: 65 KG
    ↓
Scroll to 70 KG
    ↓
Tap "Sure"
    ↓
Display updates to "70 KG"
    ↓
Meter recalculates instantly:
    - New BMI: 24.2
    - Needle adjusts to new position
    - Still shows "Normal" (green)
    - Height/weight update on meter
    ↓
Tap "Update" button
    ↓
API saves new data
    ↓
Success toast
    ↓
SharedPreferences updated
```

---

### Flow 3: Cancel Selection

```
Tap height field
    ↓
Picker opens
    ↓
Scroll through options
    ↓
Tap "Cancel"
    ↓
Picker closes
    ↓
No change to displayed value
    ↓
Meter remains unchanged
```

---

### Flow 4: Validation Error

```
Fragment loads with no height/weight
    ↓
Tap "Update" button immediately
    ↓
Validation check fails
    ↓
Toast: "Please select height"
    ↓
User selects height only
    ↓
Tap "Update" again
    ↓
Validation check fails
    ↓
Toast: "Please select weight"
    ↓
User selects weight
    ↓
Both fields valid
    ↓
Update proceeds
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### Data Loading
- [ ] Height loads from SharedPreferences
- [ ] Weight loads from SharedPreferences
- [ ] Meter displays correct BMI on load
- [ ] Empty values handled gracefully
- [ ] Conversion to integer works (150.5 → 150)
- [ ] Profile fields fetched silently

#### BMI Calculation
- [ ] Calculates correctly for valid inputs
- [ ] Rounds to 1 decimal place
- [ ] Handles edge cases (very short/tall, light/heavy)
- [ ] Updates meter in real-time
- [ ] Formula: weight / (height/100)² works

#### Pickers
- [ ] Height picker shows 100-250 CM
- [ ] Weight picker shows 20-200 KG
- [ ] Current value pre-selected
- [ ] Default values work when empty
- [ ] Scrolling smooth
- [ ] Cancel button closes without change
- [ ] Sure button saves selection
- [ ] Display updates immediately

#### Update Function
- [ ] Validates height is selected
- [ ] Validates weight is selected
- [ ] Shows loading dialog
- [ ] Calls API with all profile fields
- [ ] Updates SharedPreferences on success
- [ ] Refreshes meter on success
- [ ] Shows success toast
- [ ] Shows error toast on failure
- [ ] Dismisses loading on error
- [ ] Logs updates properly

#### Meter View
- [ ] Draws 5 colored segments
- [ ] Segment labels display correctly
- [ ] Needle points to correct angle
- [ ] BMI value displays with unit
- [ ] Height and weight show below value
- [ ] Status text shows in correct color
- [ ] Center circle renders properly
- [ ] All text readable and positioned correctly

---

### UI/UX Tests

#### Visual Design
- [ ] Background color correct (#D9EDFF)
- [ ] Cards have white background
- [ ] Corner radius 16dp
- [ ] Elevation shadows visible
- [ ] Text sizes correct
- [ ] Colors match specification
- [ ] Meter proportions correct
- [ ] Responsive to different screen sizes

#### Interactions
- [ ] Height card tappable
- [ ] Weight card tappable
- [ ] Arrow icons visible
- [ ] Pickers slide up smoothly
- [ ] NumberPicker scrollable
- [ ] Button tappable and responsive
- [ ] Loading dialog blocks interaction
- [ ] Toasts display correctly

#### Edge Cases
- [ ] Very high BMI (50+) displays correctly
- [ ] Very low BMI (< 10) displays correctly
- [ ] Maximum height (250 CM)
- [ ] Minimum height (100 CM)
- [ ] Maximum weight (200 KG)
- [ ] Minimum weight (20 KG)
- [ ] API timeout handled
- [ ] Network error handled
- [ ] Fragment destroyed during API call
- [ ] Rapid button clicks prevented

---

### BMI Category Tests

Test each category displays correctly:

- [ ] **Underweight (BMI 15.0):**
  - Needle in blue segment
  - Status: "Underweight" (blue)
  
- [ ] **Normal (BMI 22.0):**
  - Needle in green segment
  - Status: "Normal" (green)
  
- [ ] **Overweight (BMI 27.5):**
  - Needle in yellow segment
  - Status: "Overweight" (yellow)
  
- [ ] **Obese (BMI 35.0):**
  - Needle in orange segment
  - Status: "Obese" (orange)
  
- [ ] **Severely Obese (BMI 45.0):**
  - Needle in red segment
  - Status: "Severely Obese" (red)

---

## 🚀 Future Enhancements

### 1. BMI History Tracking

```xml
┌───────────────────────────────────┐
│  BMI History                      │
│                                   │
│  [Line Chart]                     │
│  Shows BMI trend over time        │
│                                   │
│  May 20: 22.5                     │
│  May 15: 23.0                     │
│  May 10: 23.2                     │
└───────────────────────────────────┘
```

**Features:**
- Store BMI values with timestamps
- Line chart visualization
- Date range filter (week/month/year)
- Export data
- Goal tracking

---

### 2. Ideal Weight Calculator

```xml
┌───────────────────────────────────┐
│  Target Weight                    │
│                                   │
│  Current: 70 KG                   │
│  Target BMI: 22.0 (Normal)        │
│  Target Weight: 65 KG             │
│                                   │
│  You need to lose: 5 KG           │
└───────────────────────────────────┘
```

**Features:**
- Set target BMI
- Calculate target weight
- Show difference
- Progress tracking
- Timeline estimation

---

### 3. Health Insights

```xml
┌───────────────────────────────────┐
│  Health Insights                  │
│                                   │
│  ✓ Maintain current weight        │
│  • BMI in healthy range           │
│  • Lower heart disease risk       │
│  • Optimal for your age           │
│                                   │
│  [Learn More]                     │
└───────────────────────────────────┘
```

**Features:**
- Personalized insights based on BMI
- Age and gender considerations
- Health risk assessment
- Recommendations
- Educational content

---

### 4. Body Fat Percentage (Advanced)

```xml
┌───────────────────────────────────┐
│  Body Composition                 │
│                                   │
│  BMI: 22.5                        │
│  Body Fat: 18%                    │
│  Muscle Mass: 55 KG               │
│  Water: 60%                       │
└───────────────────────────────────┘
```

**Features:**
- Requires additional measurements (waist, hip, etc.)
- Calculate body fat percentage
- Lean body mass
- Water percentage
- More accurate health assessment

---

### 5. Units Toggle

```xml
┌───────────────────────────────────┐
│  [Metric] [Imperial]              │
│                                   │
│  Height: 170 CM / 5'7"            │
│  Weight: 65 KG / 143 lbs          │
│  BMI: 22.5                        │
└───────────────────────────────────┘
```

**Features:**
- Toggle between metric and imperial
- Automatic conversion
- Preference saved
- Display both units
- Consistent throughout app

---

### 6. Compare with Population

```xml
┌───────────────────────────────────┐
│  Comparison                       │
│                                   │
│  Your BMI: 22.5                   │
│  Age 30-40 avg: 24.2              │
│                                   │
│  You are healthier than 65% of    │
│  people in your age group         │
└───────────────────────────────────┘
```

**Features:**
- Compare with age group average
- Gender-specific comparisons
- Percentile ranking
- Regional statistics
- Motivational messaging

---

### 7. BMI Calculator Modes

```xml
┌───────────────────────────────────┐
│  [Standard] [Athlete] [Child]     │
│                                   │
│  BMI: 26.5                        │
│  Athlete Mode: Normal             │
│  (High muscle mass detected)      │
└───────────────────────────────────┘
```

**Features:**
- Standard BMI (current)
- Athlete mode (different thresholds)
- Child mode (age-adjusted)
- Pregnancy mode
- Senior mode (65+)

---

### 8. Share Results

```xml
┌───────────────────────────────────┐
│  [Share] [Export] [Print]         │
│                                   │
│  Share your BMI progress          │
│  with your doctor or trainer      │
└───────────────────────────────────┘
```

**Features:**
- Share as image
- Export to PDF
- Email results
- Share with healthcare provider
- Privacy controls

---

### 9. Goal Setting & Reminders

```xml
┌───────────────────────────────────┐
│  Goals                            │
│                                   │
│  Target: Reach 65 KG by June 30   │
│  Progress: 70 → 67 KG (60%)       │
│                                   │
│  ⏰ Weekly check-in: Fridays      │
└───────────────────────────────────┘
```

**Features:**
- Set weight goals
- Timeline selection
- Progress tracking
- Weekly/monthly reminders
- Achievement badges

---

### 10. Integration with Other Metrics

```xml
┌───────────────────────────────────┐
│  Health Overview                  │
│                                   │
│  BMI: 22.5 ✓                      │
│  Heart Rate: 72 bpm ✓             │
│  Blood Pressure: 120/80 ✓         │
│  Steps Today: 8,500               │
│                                   │
│  Overall: Good                    │
└───────────────────────────────────┘
```

**Features:**
- Combine with vital signs
- Holistic health view
- Correlate with activity
- Sleep impact on weight
- Comprehensive dashboard

---

## 📊 Analytics & Tracking

### Key Metrics

**User Engagement:**
- BMI fragment views
- Height picker opens
- Weight picker opens
- Update button clicks
- Success rate of updates
- Average time on screen

**BMI Distribution:**
- Underweight users (%)
- Normal users (%)
- Overweight users (%)
- Obese users (%)
- Severely obese users (%)

**Usage Patterns:**
- Most common heights
- Most common weights
- Average BMI by age group
- Average BMI by gender
- Update frequency

**Conversions:**
- Users who complete first entry
- Users who update multiple times
- Users who set goals (future)
- Users who share results (future)

### Implementation

```kotlin
// Track fragment view
Analytics.logEvent("bmi_screen_viewed")

// Track selections
Analytics.logEvent("height_selected", mapOf(
    "height_cm" to height,
    "method" to "picker"
))

Analytics.logEvent("weight_selected", mapOf(
    "weight_kg" to weight,
    "method" to "picker"
))

// Track updates
Analytics.logEvent("bmi_updated", mapOf(
    "height_cm" to height,
    "weight_kg" to weight,
    "bmi" to bmi,
    "category" to category,  // "Normal", "Overweight", etc.
    "previous_bmi" to previousBmi
))

// Track errors
Analytics.logEvent("bmi_update_failed", mapOf(
    "error_type" to errorType,
    "error_message" to message
))
```

---

## 💡 Best Practices

### Code Quality

✅ **Custom View Encapsulation:** BMI meter is self-contained, reusable  
✅ **Responsive Design:** Meter scales with screen size  
✅ **Validation:** Checks inputs before API call  
✅ **Error Handling:** Graceful failure with user feedback  
✅ **Loading States:** Shows progress during API calls  
✅ **Data Persistence:** Uses SharedPreferences for instant load  
✅ **API Efficiency:** Fetches profile fields once, reuses  
✅ **Decimal Precision:** Proper rounding for BMI display  
✅ **Separation of Concerns:** Fragment handles UI, custom view handles drawing  

### UX Principles

✅ **Immediate Feedback:** BMI updates as soon as height/weight selected  
✅ **Clear Affordances:** Arrow icons indicate tappable fields  
✅ **Visual Hierarchy:** Important info (BMI value) largest  
✅ **Color Coding:** Health status immediately recognizable  
✅ **Smooth Interactions:** Bottom sheet pickers slide up nicely  
✅ **Error Prevention:** Validation before allowing save  
✅ **Progress Indication:** Loading dialog during network calls  
✅ **Success Confirmation:** Toast message on successful update  

---

**Document Version:** 1.0  
**Last Updated:** May 22, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

