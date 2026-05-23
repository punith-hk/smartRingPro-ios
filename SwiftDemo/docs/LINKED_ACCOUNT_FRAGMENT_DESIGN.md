# Linked Account Fragment - Design & Implementation

**HEARTO App - Family Care & Account Linking System**  
**Fragments:** `CareFragment.kt`, `LinkAccountFragment.kt`, `LinkedAccountDetailsFragment.kt`  
**Layouts:** `fragment_care.xml`, `fragment_link_account.xml`, `fragment_linked_account_details.xml`  
**Repository:** `LinkedAccountRepository.kt`  
**Local Storage:** `LinkedAccountEntity.kt`, `LinkedAccountLocalRepository.kt`

---

## 📋 Overview

The Linked Account system enables users to connect with family members or caretakers for health monitoring and emergency care coordination. It provides secure OTP-based account linking, displays a list of linked accounts, and shows detailed health information and location data for each linked member. The system uses a local-first approach with Room database caching and API synchronization.

**Key Features:**
- **OTP-Based Linking:** Secure phone number verification with 60-second countdown
- **Relationship Selection:** 9 predefined relationships (Father, Mother, Sister, etc.)
- **Linked Account List:** RecyclerView display with profile initials
- **Detailed Health View:** Complete health metrics, vitals, and location map
- **Local-First Architecture:** Room database cache for offline access
- **API Synchronization:** Background refresh from backend
- **Emergency Context:** View family member's location and health status

---

## 🎨 Design Architecture

### Fragment Structure

```
CareFragment (Main List Screen)
├── Empty State View
│   ├── Illustration
│   ├── "No Linked Accounts"
│   └── "Link Account" Button
└── Linked Accounts View
    ├── "Add New Account" Button
    └── RecyclerView (Linked Account Cards)
        ├── Profile Image / Initials Circle
        ├── Name
        ├── Relationship
        ├── Health Status Indicator
        └── OnClick → LinkedAccountDetailsFragment

LinkAccountFragment (Add New Account)
├── How-To Card (Initially shown)
│   ├── Instructions
│   └── Mobile Number Input
├── Send Code Button
├── OTP Verification (After code sent)
│   ├── 6-Digit Code Input
│   ├── Relationship Spinner
│   ├── Resend Timer (60 seconds)
│   └── Confirm Association Button
└── Success → Navigate to CareFragment

LinkedAccountDetailsFragment (Member Details)
├── Profile Section
│   ├── Profile Image
│   ├── Name
│   ├── Relationship
│   ├── Age & Gender
│   ├── Height & Weight
│   ├── Blood Group
│   ├── Patient Code
│   ├── Allergy Info
│   ├── Existing Diseases
│   └── Existing Medications
├── Health Metrics Section
│   ├── Heart Rate
│   ├── Blood Pressure
│   ├── Blood Oxygen
│   ├── Blood Sugar
│   ├── Temperature
│   ├── HRV
│   ├── Stress Level
│   ├── Steps Count
│   ├── Calories Burned
│   └── Sleep Duration
├── Location Map Section
│   ├── Google Maps Embed
│   └── Last Known Location
└── Remove Linked Account Button
```

---

## 🎨 CareFragment - Main Screen Design

### Visual Layout

#### Empty State:
```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│      Family Care                    │  Background
│                                     │  #D9EDFF
│                                     │
│         👥                          │  Empty
│     [Illustration]                  │  State
│                                     │  Icon
│   No Linked Accounts Yet            │
│                                     │
│   Connect with family members       │  Message
│   to monitor their health and       │
│   receive emergency alerts          │
│                                     │
│  ┌───────────────────────────────┐ │
│  │    Link Account               │ │  Action
│  └───────────────────────────────┘ │  Button
│                                     │
└─────────────────────────────────────┘
```

#### With Linked Accounts:
```
┌─────────────────────────────────────┐
│                                     │
│      Family Care                    │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   + Add New Account           │ │  Add
│  └───────────────────────────────┘ │  Button
│                                     │
│  ┌───────────────────────────────┐ │
│  │  👤  John Doe                 │ │  Account
│  │  👨  Father                    │ │  Card 1
│  │  🟢 Healthy                    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  👤  Mary Smith               │ │  Account
│  │  👩  Mother                    │ │  Card 2
│  │  🟡 Needs Attention           │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  👤  Jane Doe                 │ │  Account
│  │  👧  Sister                    │ │  Card 3
│  │  🟢 Healthy                    │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Components

#### 1. Empty State View

**Container:** `noLinkedLayout` (ScrollView)

**Icon:**
- **Drawable:** Family/people illustration
- **Size:** 120dp × 120dp
- **Tint:** Light gray
- **Position:** Center

**Title:**
- **Text:** "No Linked Accounts Yet"
- **Size:** 20sp
- **Weight:** Bold
- **Color:** #555555
- **Alignment:** Center

**Subtitle:**
- **Text:** "Connect with family members to monitor their health and receive emergency alerts"
- **Size:** 14sp
- **Color:** #888888
- **Alignment:** Center
- **Max Width:** 280dp

**Link Account Button:**
- **ID:** `linkAccountButton`
- **Text:** "Link Account"
- **Style:** Primary button (blue)
- **Width:** Match parent
- **Margin:** 16dp horizontal

---

#### 2. Linked Accounts View

**Container:** `linkedLayout` (LinearLayout - Vertical)

**Add New Account Button:**
- **ID:** `btnAddAssociation`
- **Text:** "+ Add New Account"
- **Style:** Secondary button (outlined)
- **Width:** Match parent
- **Margin:** 16dp horizontal, 12dp vertical

**RecyclerView:**
- **ID:** `linkedAccountsRecyclerView`
- **Layout Manager:** LinearLayoutManager (Vertical)
- **Item Layout:** `item_linked_accounts.xml`
- **Padding:** 8dp
- **Item Spacing:** 8dp vertical

---

#### 3. Linked Account Card (RecyclerView Item)

**Card Specs:**
- **Type:** CardView
- **Background:** White
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Margin:** 12dp horizontal, 8dp vertical
- **Padding:** 16dp
- **Clickable:** Yes → Opens LinkedAccountDetailsFragment

**Layout:**
```xml
┌─────────────────────────────────────┐
│  [👤]  John Doe                     │  Profile + Name
│        👨 Father                     │  Relation Icon
│        🟢 Healthy                    │  Health Status
└─────────────────────────────────────┘
```

**Components:**

**Profile Image / Initials Circle:**
- **ID:** `linkedAccProfileImageView` / `linkedAccInitialsTextView`
- **Size:** 56dp × 56dp
- **Shape:** Circle
- **Background:** Generated color based on name
- **Initials:** First letter of first & last name (e.g., "JD")
- **Text Size:** 20sp
- **Text Color:** White

**Name:**
- **ID:** `linkedAccNameTextView`
- **Text:** "John Doe"
- **Size:** 18sp
- **Weight:** Bold
- **Color:** Black

**Relation:**
- **ID:** `linkedAccRelationTextView`
- **Text:** "👨 Father" (with emoji icon)
- **Size:** 14sp
- **Color:** #555555

**Health Status:**
- **ID:** `linkedAccHealthTextView`
- **Text:** "🟢 Healthy" or "🟡 Needs Attention" or "🔴 Critical"
- **Size:** 13sp
- **Color:** Based on status (Green/Orange/Red)

---

## 📱 Data Loading Flow - CareFragment

### Local-First Architecture

```
[User Opens CareFragment]
    ↓
onResume() triggered
    ↓
Load userId from SharedPreferences
    ↓
loadLinkedAccounts(userId)
    ↓
[Step 1: Load Local Data - INSTANT DISPLAY]
    ↓
    [Coroutine - IO Thread]
    LinkedAccountLocalRepository.getAll()
        ↓
        Query Room Database
        ↓
        SELECT * FROM linked_accounts
        ↓
        Return List<LinkedAccountEntity>
    ↓
    [Coroutine - Main Thread]
    Convert to UI models
        ↓
        LinkedAccount(
            id = entity.id,
            name = entity.name,
            relation = entity.relation,
            mobile = entity.phoneNumber
        )
    ↓
    setupRecyclerView(localList)
        ├─ Show linked accounts view
        ├─ Hide empty state view
        └─ Bind adapter with data
    ↓
[Step 2: Refresh from API - BACKGROUND UPDATE]
    ↓
    [API Call - Background]
    GET /getLinkedAccountData?user_id={userId}
        ↓
        Response: List<LinkedAccountInfo>
        [
            {
                "id": 123,
                "name": "John Doe",
                "phone_number": "9876543210",
                "relation": "Father"
            },
            ...
        ]
    ↓
    [Coroutine - IO Thread]
    Convert API response to entities
        ↓
        LinkedAccountEntity(
            id = apiItem.id,
            name = apiItem.name,
            relation = apiItem.relation,
            phoneNumber = apiItem.phone_number
        )
    ↓
    LinkedAccountLocalRepository.replaceAll(entities)
        ↓
        DELETE FROM linked_accounts
        INSERT INTO linked_accounts VALUES (...)
        ↓
        Database updated
    ↓
    [Coroutine - Main Thread]
    Refresh RecyclerView with updated data
        ↓
        setupRecyclerView(updatedList)
        ↓
        Adapter notifies dataset changed
```

---

## 🔗 LinkAccountFragment - Add New Account Flow

### Visual Layout

#### Step 1: Initial State (How-To Card)
```
┌─────────────────────────────────────┐
│                                     │
│  Add a New Account                  │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📱 How to Add                 │ │  How-To
│  │                               │ │  Card
│  │ 1. Enter their mobile number │ │
│  │ 2. They'll receive an OTP     │ │  Instructions
│  │ 3. Enter the 6-digit code     │ │
│  │ 4. Select relationship        │ │
│  │ 5. Confirm association        │ │
│  └───────────────────────────────┘ │
│                                     │
│  Mobile Number                      │  Input
│  ┌───────────────────────────────┐ │  Field
│  │ 9876543210                    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │    Send Verification Code     │ │  Action
│  └───────────────────────────────┘ │  Button
│                                     │
└─────────────────────────────────────┘
```

#### Step 2: OTP Verification State
```
┌─────────────────────────────────────┐
│                                     │
│  Verify & Link Account              │
│                                     │
│  Verification Code                  │  OTP
│  ┌───────────────────────────────┐ │  Input
│  │ ● ● ● ● ● ●                   │ │  (6 digits)
│  └───────────────────────────────┘ │
│                                     │
│  Resend code in 00:45               │  Timer
│                                     │
│  Relationship                       │  Spinner
│  ┌───────────────────────────────┐ │  Label
│  │ Father                    ▼   │ │  Dropdown
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │    Confirm Association        │ │  Confirm
│  └───────────────────────────────┘ │  Button
│                                     │
└─────────────────────────────────────┘
```

---

### Complete Link Account Flow

```
[User Taps "Link Account" Button]
    ↓
Navigate to LinkAccountFragment
    ↓
Display How-To Card with Instructions
    ↓
[User Enters Mobile Number]
    ↓
    Input: 10-digit mobile number
    Validation: Regex check ^[0-9]{10}$
    ↓
[User Taps "Send Verification Code"]
    ↓
    Hide keyboard
    Disable mobile input field
    ↓
API Call: Add Linked Account
    ↓
    POST /caretaker/link-account
    Body: {
        "user_id": 123,
        "phone_number": "9876543210"
    }
    ↓
    [Backend Processing]
    ├─ Check if number exists
    ├─ Check if not already linked
    ├─ Generate 6-digit OTP
    ├─ Send SMS to mobile number
    └─ Return receiver_id
    ↓
    Response (Success):
    {
        "response": 0,
        "message": "OTP sent successfully",
        "receiver_id": 456
    }
    ↓
    Response (Already Linked):
    {
        "response": 1,
        "message": "Already linked!",
        "status": 409
    }
    ↓
[If Success]
    ↓
    Store receiver_id locally
    ↓
    Hide How-To Card
    Hide Send Code Button
    ↓
    Show OTP Input Field
    Show Relationship Spinner
    Show Confirm Button
    Show Resend Timer
    ↓
    Start 60-second countdown timer
        ├─ Display: "Resend code in 00:59"
        ├─ Update every second
        └─ At 00:00 → Enable resend
    ↓
[User Enters 6-Digit OTP]
    ↓
    Auto-focus next digit
    When 6 digits entered:
        ├─ Hide keyboard
        ├─ Clear focus
        └─ Focus relationship spinner
    ↓
[User Selects Relationship]
    ↓
    Spinner options:
    - Select Relationship (disabled)
    - Father
    - Mother
    - Sister
    - Brother
    - Grandma
    - Grandpa
    - Uncle
    - Aunt
    - Friends
    ↓
[User Taps "Confirm Association"]
    ↓
    Validation:
    ├─ OTP length = 6 digits ✓
    ├─ Relationship selected ✓
    ├─ userId != -1 ✓
    └─ receiver_id != -1 ✓
    ↓
API Call: Verify OTP & Link
    ↓
    POST /caretaker/verify-otp
    Body: {
        "user_id": 123,
        "receiver_id": 456,
        "otp": 123456,
        "relation": "Father"
    }
    ↓
    [Backend Processing]
    ├─ Validate OTP
    ├─ Check expiry (5 minutes)
    ├─ Create caretaker relationship
    ├─ Store in database
    └─ Return success
    ↓
    Response (Success):
    {
        "response": 0,
        "message": "Caretaker linked successfully"
    }
    ↓
    Response (Invalid OTP):
    {
        "response": 1,
        "message": "Invalid or expired OTP"
    }
    ↓
[If Success]
    ↓
    Show Toast: "Caretaker linked successfully"
    ↓
    Clear back stack
    ↓
    Navigate to CareFragment (refresh list)
    ↓
    CareFragment loads updated list
        ├─ Refresh from API
        ├─ Update local database
        └─ Display new linked account
```

---

### Components

#### How-To Card

**Specs:**
- **ID:** `cvHowToAdd`
- **Type:** CardView
- **Background:** White
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Padding:** 20dp
- **Margin:** 16dp horizontal

**Title:**
- **Text:** "📱 How to Add"
- **Size:** 18sp
- **Weight:** Bold
- **Color:** Black

**Instructions:**
```
1. Enter their mobile number
2. They'll receive an OTP via SMS
3. Enter the 6-digit verification code
4. Select your relationship
5. Confirm to complete linking
```
- **Size:** 14sp
- **Color:** #555555
- **Line Spacing:** 1.5

---

#### Mobile Number Input

**Specs:**
- **ID:** `etMobile`
- **Hint:** "Enter 10-digit mobile number"
- **Input Type:** Number (phone)
- **Max Length:** 10
- **Validation:** ^[0-9]{10}$

---

#### Send Code Button

**Specs:**
- **ID:** `btnSendCode`
- **Text:** "Send Verification Code"
- **Style:** Primary button (blue)
- **Width:** Match parent
- **Enabled:** Only when mobile valid

---

#### OTP Input Field

**Specs:**
- **ID:** `etVerificationCode`
- **Input Type:** Number
- **Max Length:** 6
- **Text Size:** 24sp
- **Letter Spacing:** 0.5
- **Alignment:** Center
- **Auto-focus:** Yes
- **Visibility:** Hidden initially

**Auto-advance Logic:**
```kotlin
etVerificationCode.addTextChangedListener(object : TextWatcher {
    override fun afterTextChanged(s: Editable?) {
        if (s?.length == 6) {
            hideKeyboard()
            clearFocus()
            spinnerRelation.requestFocus()
        }
    }
})
```

---

#### Relationship Spinner

**Specs:**
- **ID:** `spinnerRelation`
- **Options:**
  - Select Relationship (disabled/hint)
  - Father
  - Mother
  - Sister
  - Brother
  - Grandma
  - Grandpa
  - Uncle
  - Aunt
  - Friends
- **Style:** Material dropdown
- **Visibility:** Hidden initially

---

#### Resend Timer

**Specs:**
- **ID:** `tvResendTimer`
- **Format:** "Resend code in 00:45"
- **Duration:** 60 seconds
- **Update:** Every 1 second
- **At 00:00:** Text changes to "Resend OTP" (clickable, underlined)

**Styling:**
```kotlin
// During countdown
tvResendTimer.text = "Resend code in 00:${seconds}"
tvResendTimer.setTextColor(Color.GRAY)
tvResendTimer.isClickable = false

// After countdown
val spannableString = SpannableString("Resend OTP")
spannableString.setSpan(UnderlineSpan(), 0, 10, 0)
spannableString.setSpan(ForegroundColorSpan(Color.BLUE), 0, 10, 0)
spannableString.setSpan(StyleSpan(Typeface.BOLD), 0, 10, 0)
tvResendTimer.text = spannableString
tvResendTimer.isClickable = true
```

---

#### Confirm Association Button

**Specs:**
- **ID:** `btnConfirmAssociation`
- **Text:** "Confirm Association"
- **Style:** Primary button (blue)
- **Width:** Match parent
- **Visibility:** Hidden initially

---

## 📊 LinkedAccountDetailsFragment - Member Details

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│  Linked Account Details             │  Background
│                                     │  #D9EDFF
│  ┌───────────────────────────────┐ │
│  │     [Profile Image]           │ │  Profile
│  │      John Doe                 │ │  Card
│  │      👨 Father                 │ │  (White)
│  │      42 years  •  Male        │ │
│  │      175 cm  •  70 kg         │ │
│  │      Blood Group: O+          │ │
│  │      Patient Code: HRT001     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Health Metrics               │ │  Health
│  │                               │ │  Card
│  │  ❤️  75 bpm    🫀 120/80 mmHg │ │
│  │  🩸 98 %       🍬 95 mg/dL    │ │
│  │  🌡️  36.5 °C   📈 45 ms       │ │
│  │  😰 35 (Low)   🔥 285 kcal    │ │
│  │  👟 8,450      😴 7h 30m      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Current Location             │ │  Location
│  │  ┌─────────────────────────┐ │ │  Card
│  │  │ [Google Maps Embed]     │ │ │  (Map)
│  │  │                         │ │ │
│  │  └─────────────────────────┘ │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Medical Information          │ │  Medical
│  │                               │ │  Card
│  │  Allergy: No                  │ │
│  │  Existing Diseases:           │ │
│  │  • Hypertension               │ │
│  │  Existing Medications:        │ │
│  │  • Amlodipine 5mg             │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Remove Linked Account        │ │  Remove
│  └───────────────────────────────┘ │  Button
│                                     │
└─────────────────────────────────────┘
```

---

### Data Loading Flow

```
[User Taps Linked Account Card]
    ↓
Navigate to LinkedAccountDetailsFragment
    ├─ Pass linked_id
    ├─ Pass linked_name
    └─ Pass linked_relation
    ↓
onCreate() - Retrieve arguments
    ↓
onViewCreated() - Fetch data
    ↓
[Parallel API Calls]
    ├─ fetchUserProfileData()
    │   ↓
    │   GET /getUserProfileData?user_id={linked_id}
    │   ↓
    │   Response: {
    │       "data": {
    │           "first_name": "John",
    │           "last_name": "Doe",
    │           "dob": "1982-05-15",
    │           "gender": "M",
    │           "height": "175",
    │           "weight": "70",
    │           "blood_group": "O+",
    │           "patient_code": "HRT001",
    │           "patient_image_url": "https://...",
    │           "allergy": 0,
    │           "existing_diseases": "Hypertension",
    │           "existing_medications": "Amlodipine 5mg"
    │       }
    │   }
    │   ↓
    │   Update Profile Section UI
    │
    └─ getLinkedAccountHealthData()
        ↓
        GET /getLastRingData?user_id={linked_id}
        ↓
        Response: {
            "data": [
                {
                    "type": "heart_rate",
                    "value": "75"
                },
                {
                    "type": "blood_pressure",
                    "value": "120/80"
                },
                {
                    "type": "blood_oxygen",
                    "value": "98"
                },
                {
                    "type": "blood_sugar",
                    "value": "95"
                },
                {
                    "type": "temperature",
                    "value": "36.5"
                },
                {
                    "type": "hrv",
                    "value": "45"
                },
                {
                    "type": "stress",
                    "value": "35"
                },
                {
                    "type": "calories",
                    "value": "285"
                },
                {
                    "type": "steps",
                    "value": "8450"
                },
                {
                    "type": "sleep",
                    "value": "450"
                }
            ],
            "location": {
                "latitude": "12.9716",
                "longitude": "77.5946"
            }
        }
        ↓
        Update Health Metrics Section
        ↓
        Update Location Map
            ├─ If location exists:
            │   ├─ Generate Google Maps embed HTML
            │   ├─ Load in WebView
            │   └─ Show map, hide placeholder
            └─ If location null/invalid:
                ├─ Hide WebView
                └─ Show placeholder text
```

---

### Components

#### 1. Profile Section

**Profile Image:**
- **ID:** `linkedAccountProfileImage`
- **Size:** 80dp × 80dp
- **Shape:** Circle
- **Source:** API URL or default avatar
- **Library:** Glide with circleCrop()

**Name:**
- **ID:** `linkedAccountName`
- **Format:** "First Name Last Name"
- **Size:** 24sp
- **Weight:** Bold
- **Color:** Black

**Relation:**
- **ID:** `linkedAccountRelation`
- **Format:** "👨 Father" (with emoji)
- **Size:** 16sp
- **Color:** #555555

**Age & Gender:**
- **ID:** `linkedAccountAgeGender`
- **Format:** "42 years  •  Male"
- **Calculation:** Age from DOB using Period.between()
- **Size:** 14sp
- **Color:** #555555

**Height & Weight:**
- **ID:** `linkedAccountHeightWeight`
- **Format:** "175 cm  •  70 kg"
- **Size:** 14sp
- **Color:** #555555

**Blood Group:**
- **ID:** `linkedAccountBloodGroup`
- **Format:** "O+"
- **Size:** 14sp
- **Color:** #555555

**Patient Code:**
- **ID:** `linkedAccountPatientCode`
- **Format:** "HRT001"
- **Size:** 14sp
- **Color:** #555555

---

#### 2. Health Metrics Section

**Grid Layout:** 2 columns × 5 rows

**Metrics:**

| Metric | ID | Format | Icon |
|--------|----|----|------|
| Heart Rate | `linkedAccountHeartRateValue` | "75 bpm" | ❤️ |
| Blood Pressure | `linkedAccountBpValue` | "120/80 mmHg" | 🫀 |
| Blood Oxygen | `linkedAccountOxygenValue` | "98%" | 🩸 |
| Blood Sugar | `linkedAccountBgValue` | "95 mg/dL" | 🍬 |
| Temperature | `linkedAccountTemperatureValue` | "36.5°C" | 🌡️ |
| HRV | `linkedAccountHrvValue` | "45 ms" | 📈 |
| Stress Level | `linkedAccountStressValue` | "35 (Low)" | 😰 |
| Calories | `linkedAccountCalories` | "285 kcal" | 🔥 |
| Steps | `linkedAccountStepCount` | "8,450" | 👟 |
| Sleep | `linkedAccountSleepValue` | "7h 30m" | 😴 |

**Sleep Duration Formatting:**
```kotlin
val totalMinutes = value.toIntOrNull() ?: 0
val hours = totalMinutes / 60
val minutes = totalMinutes % 60

val displayText = if (hours > 0) {
    "${hours}h ${minutes}m"
} else {
    "${minutes}m"
}
```

---

#### 3. Location Map Section

**WebView:**
- **ID:** `mapWebView`
- **Height:** 200dp
- **Width:** Match parent
- **JavaScript:** Enabled
- **Content:** Google Maps embed

**HTML Template:**
```html
<html>
    <body style="margin:0;padding:0;">
        <iframe width="100%" height="100%" frameborder="0" style="border:0"
            src="https://www.google.com/maps?q=12.9716,77.5946&output=embed" 
            allowfullscreen>
        </iframe>
    </body>
</html>
```

**Placeholder:**
- **ID:** `mapPlaceholderText`
- **Text:** "Location not available"
- **Visibility:** Shown when location is null/invalid

**Logic:**
```kotlin
if (!latitude.isNullOrEmpty() && !longitude.isNullOrEmpty()) {
    // Generate HTML with lat/lng
    webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
    webView.visibility = View.VISIBLE
    placeholder.visibility = View.GONE
} else {
    webView.visibility = View.GONE
    placeholder.visibility = View.VISIBLE
}
```

---

#### 4. Medical Information Section

**Allergy:**
- **ID:** `linkedAccountAllergy`
- **Format:** "Yes" or "No"
- **Value:** Based on allergy field (1 = Yes, 0 = No)

**Existing Diseases:**
- **ID:** `linkedAccountExistingDiseases`
- **Format:** Comma-separated list or "None reported"
- **Multi-line:** Yes

**Existing Medications:**
- **ID:** `linkedAccountExistingMedications`
- **Format:** Comma-separated list or "None reported"
- **Multi-line:** Yes

---

#### 5. Remove Linked Account Button

**Specs:**
- **ID:** `btnDisassociation`
- **Text:** "Remove Linked Account"
- **Style:** Danger button (red outlined)
- **Width:** Match parent
- **Margin:** 16dp horizontal

**Action:**
```kotlin
btnDisassociation.setOnClickListener {
    // Show confirmation dialog
    AlertDialog with:
        - Title: "Remove Linked Account"
        - Message: "Are you sure you want to remove this linked account?"
        - Negative: "Cancel"
        - Positive: "Yes"
        
    On Confirm:
        // API not implemented yet
        Toast: "Unable to remove linked account. Please try again later."
}
```

---

## 🗄️ Local Database Structure

### LinkedAccountEntity

```kotlin
@Entity(tableName = "linked_accounts")
data class LinkedAccountEntity(
    @PrimaryKey 
    val id: Int,              // User ID of linked account
    val name: String,          // Full name
    val relation: String,      // Father, Mother, etc.
    val phoneNumber: String    // Mobile number
)
```

**DAO Methods:**
```kotlin
@Dao
interface LinkedAccountDao {
    @Query("SELECT * FROM linked_accounts")
    suspend fun getAll(): List<LinkedAccountEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(accounts: List<LinkedAccountEntity>)
    
    @Query("DELETE FROM linked_accounts")
    suspend fun deleteAll()
    
    @Transaction
    suspend fun replaceAll(accounts: List<LinkedAccountEntity>) {
        deleteAll()
        insertAll(accounts)
    }
}
```

---

## 🔌 API Endpoints

### 1. Get Linked Accounts

**Endpoint:**
```
GET /getLinkedAccountData?user_id={userId}
```

**Response:**
```json
[
    {
        "id": 123,
        "name": "John Doe",
        "phone_number": "9876543210",
        "relation": "Father"
    },
    {
        "id": 124,
        "name": "Mary Smith",
        "phone_number": "9876543211",
        "relation": "Mother"
    }
]
```

---

### 2. Add Linked Account (Send OTP)

**Endpoint:**
```
POST /caretaker/link-account
```

**Request Body:**
```json
{
    "user_id": 123,
    "phone_number": "9876543210"
}
```

**Response (Success):**
```json
{
    "response": 0,
    "message": "OTP sent successfully",
    "receiver_id": 456
}
```

**Response (Already Linked):**
```json
{
    "response": 1,
    "message": "Already linked!",
    "status": 409
}
```

---

### 3. Verify OTP & Link Account

**Endpoint:**
```
POST /caretaker/verify-otp
```

**Request Body:**
```json
{
    "user_id": 123,
    "receiver_id": 456,
    "otp": 123456,
    "relation": "Father"
}
```

**Response (Success):**
```json
{
    "response": 0,
    "message": "Caretaker linked successfully"
}
```

**Response (Invalid OTP):**
```json
{
    "response": 1,
    "message": "Invalid or expired OTP"
}
```

---

### 4. Get Last Ring Data (Health Metrics)

**Endpoint:**
```
GET /getLastRingData?user_id={linkedId}
```

**Response:**
```json
{
    "data": [
        {
            "type": "heart_rate",
            "value": "75"
        },
        {
            "type": "blood_pressure",
            "value": "120/80"
        },
        {
            "type": "blood_oxygen",
            "value": "98"
        },
        {
            "type": "blood_sugar",
            "value": "95"
        },
        {
            "type": "temperature",
            "value": "36.5"
        },
        {
            "type": "hrv",
            "value": "45"
        },
        {
            "type": "stress",
            "value": "35"
        },
        {
            "type": "calories",
            "value": "285"
        },
        {
            "type": "steps",
            "value": "8450"
        },
        {
            "type": "sleep",
            "value": "450"
        }
    ],
    "location": {
        "latitude": "12.9716",
        "longitude": "77.5946"
    }
}
```

---

### 5. Get User Profile Data

**Endpoint:**
```
GET /getUserProfileData?user_id={linkedId}
```

**Response:**
```json
{
    "data": {
        "first_name": "John",
        "last_name": "Doe",
        "dob": "1982-05-15",
        "gender": "M",
        "height": "175",
        "weight": "70",
        "blood_group": "O+",
        "patient_code": "HRT001",
        "patient_image_url": "https://example.com/profile.jpg",
        "allergy": 0,
        "existing_diseases": "Hypertension",
        "existing_medications": "Amlodipine 5mg"
    }
}
```

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background |
| Card Background | `#FFFFFF` | All cards |
| Primary Text | `#000000` | Names, titles |
| Secondary Text | `#555555` | Relations, descriptions |
| Tertiary Text | `#888888` | Hints, placeholders |
| Primary Button | `#15558D` | Action buttons (blue) |
| Secondary Button | `#E0E0E0` | Outlined buttons |
| Danger Button | `#F44336` | Remove account (red) |
| Success Indicator | `#4CAF50` | Healthy status (green) |
| Warning Indicator | `#FF9800` | Needs attention (orange) |
| Critical Indicator | `#F44336` | Critical status (red) |
| Initials Background | Generated | Based on name hash |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Screen Title | 22sp | Bold | Black |
| Card Title | 18sp | Bold | Black |
| Name | 18-24sp | Bold | Black |
| Relation | 14-16sp | Normal | #555555 |
| Health Status | 13sp | Normal | Green/Orange/Red |
| Metric Label | 14sp | Normal | #555555 |
| Metric Value | 16sp | Bold | Black |
| Button Text | 16sp | Bold | White |
| Instructions | 14sp | Normal | #555555 |
| Timer Text | 14sp | Normal | Gray/#0D99FF |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 16dp |
| Card Margin | 12dp horizontal, 8dp vertical |
| Card Padding | 16-20dp |
| Card Corner Radius | 16dp |
| Card Elevation | 4dp |
| Profile Image Size | 56dp (list), 80dp (details) |
| Button Margin | 16dp horizontal |
| Icon Size | 24dp × 24dp |
| OTP Input Height | 56dp |

---

## 📱 User Experience Flows

### Flow 1: Link New Family Member

```
User opens Family Care tab
    ↓
Empty state displayed
    ↓
Tap "Link Account" button
    ↓
Navigate to LinkAccountFragment
    ↓
See how-to instructions
    ↓
Enter family member's mobile: "9876543210"
    ↓
Tap "Send Verification Code"
    ↓
API sends OTP to that number
    ↓
How-to card hides
OTP field, relationship spinner appear
    ↓
Family member receives SMS:
"Your OTP for Hearto family linking is: 123456"
    ↓
User enters OTP: "123456"
    ↓
Keyboard auto-hides after 6 digits
    ↓
Select relationship: "Father"
    ↓
Tap "Confirm Association"
    ↓
API verifies OTP
    ↓
Link created successfully
    ↓
Navigate back to Family Care tab
    ↓
List refreshes with new member
    ↓
"John Doe - Father" card appears
```

---

### Flow 2: View Family Member Details

```
User on Family Care tab
    ↓
See list of linked accounts
    ↓
Tap on "John Doe - Father" card
    ↓
Navigate to LinkedAccountDetailsFragment
    ↓
[Loading State]
Shimmer placeholders shown
    ↓
[API Calls - Parallel]
├─ Fetch profile data
└─ Fetch health metrics
    ↓
[Profile Section Loads]
    ├─ Profile image
    ├─ Name: "John Doe"
    ├─ Relation: "👨 Father"
    ├─ Age: "42 years  •  Male"
    ├─ Height/Weight: "175 cm  •  70 kg"
    ├─ Blood Group: "O+"
    └─ Patient Code: "HRT001"
    ↓
[Health Metrics Load]
    ├─ Heart Rate: "75 bpm"
    ├─ Blood Pressure: "120/80 mmHg"
    ├─ Blood Oxygen: "98%"
    ├─ Blood Sugar: "95 mg/dL"
    ├─ Temperature: "36.5°C"
    ├─ HRV: "45 ms"
    ├─ Stress: "35 (Low)"
    ├─ Calories: "285 kcal"
    ├─ Steps: "8,450"
    └─ Sleep: "7h 30m"
    ↓
[Location Map Loads]
    ├─ Latitude: 12.9716
    ├─ Longitude: 77.5946
    ├─ Generate Google Maps embed
    └─ Display interactive map
    ↓
[Medical Information Displays]
    ├─ Allergy: "No"
    ├─ Existing Diseases: "Hypertension"
    └─ Existing Medications: "Amlodipine 5mg"
    ↓
User can view all details
    ├─ Scroll through sections
    ├─ Interact with map
    └─ Monitor health status
```

---

### Flow 3: Resend OTP

```
User linking account
    ↓
Entered mobile number
    ↓
Sent verification code
    ↓
OTP not received
    ↓
Wait for 60-second timer
    ↓
Timer counts down: "00:59" → "00:00"
    ↓
Text changes to "Resend OTP" (clickable, blue, underlined)
    ↓
Tap "Resend OTP"
    ↓
New OTP generated and sent
    ↓
Toast: "OTP resent successfully!"
    ↓
Timer resets to 60 seconds
    ↓
Enter new OTP code
```

---

### Flow 4: Emergency Monitoring

```
User receives emergency alert
    ↓
"Father's heart rate is elevated!"
    ↓
Tap notification → Opens app
    ↓
Navigate to Family Care
    ↓
Tap "John Doe - Father" card
    ↓
Details screen opens immediately
    ↓
See real-time health metrics:
    ❤️ Heart Rate: 145 bpm (High!)
    🫀 Blood Pressure: 145/95 mmHg
    ↓
View current location on map
    ↓
See address: "MG Road, Bangalore"
    ↓
[Action Options]
    ├─ Call emergency contact
    ├─ Navigate to location
    └─ Contact healthcare provider
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### CareFragment
- [ ] Empty state displays when no linked accounts
- [ ] Link Account button works
- [ ] Add New Account button works
- [ ] Local data loads instantly
- [ ] API refresh updates list
- [ ] RecyclerView displays cards correctly
- [ ] Card click navigates to details

#### LinkAccountFragment
- [ ] How-to card displays initially
- [ ] Mobile validation works (10 digits)
- [ ] Send OTP API call successful
- [ ] OTP field appears after send
- [ ] Relationship spinner appears
- [ ] 60-second timer counts down
- [ ] Resend OTP works after timer
- [ ] Auto-advance after 6 digits
- [ ] Verify OTP API call works
- [ ] Navigation to CareFragment on success
- [ ] Already linked error handled

#### LinkedAccountDetailsFragment
- [ ] Profile data fetches correctly
- [ ] Health metrics display
- [ ] Sleep duration converts properly
- [ ] Location map displays
- [ ] Map placeholder shows when no location
- [ ] Age calculates from DOB
- [ ] Gender formats correctly (M → Male)
- [ ] Medical info displays
- [ ] Remove button shows dialog
- [ ] Fragment survives config changes

---

### UI/UX Tests
- [ ] Background color correct
- [ ] Cards have proper elevation
- [ ] Profile initials generate correctly
- [ ] Health status colors correct
- [ ] Timer styling correct
- [ ] OTP input centered
- [ ] Spinner dropdown works
- [ ] Map interactive
- [ ] Text doesn't overflow
- [ ] Images load with Glide

---

## 🚀 Future Enhancements

### 1. Real-time Alerts
- Push notifications for critical vitals
- Emergency SOS button
- Auto-call emergency contact

### 2. Health Trends
- View weekly/monthly trends
- Compare with previous data
- Health score calculation

### 3. Video Call
- Integrated video consultation
- Check-in feature
- Quick chat messaging

### 4. Medication Reminders
- Set reminders for linked accounts
- Track medication adherence
- Refill notifications

### 5. Geofencing
- Set safe zones
- Alert when leaving zone
- Track movement patterns

---

**Document Version:** 1.0  
**Last Updated:** May 24, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

