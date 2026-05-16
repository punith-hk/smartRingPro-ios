# Profile Fragment — Full Design, Logic & API Flow

---

## Overview

`ProfileFragment` is a **dual-mode form** — it handles both:

| Mode | Triggered By | Fields Shown |
|------|-------------|--------------|
| **Self Profile** | Opened from side nav → Profile Settings | All fields except Name + Relationship |
| **Family Member** | Opened from FamilyMembersFragment | Name + Relationship shown, personal fields (email, phone, address, location) hidden |

Mode is determined by argument: `isFromFamilyMembers: Boolean`  
Sub-mode for family: `isNewFamilyMember: Boolean` (new vs edit)

---

## Screen Background

`#D9EDFF` — light blue, set in `onViewCreated`

---

## Profile Image

| Property | Detail |
|----------|--------|
| View | `ImageView` (id: `ivProfileImage`) — circular via Glide `.circleCrop()` |
| Upload button | `btnUpload` → opens gallery via `ActivityResultLauncher` |
| Source | `ACTION_PICK` image/* intent |
| Processing | Compress via `compressImage()` → resize to max 1080px → JPEG quality loop until ≤ 1MB |
| Size limit | Max 2MB checked before API call; toast shown if exceeded |
| Default | `@drawable/baseline_account_circle_24` if no URL |
| API fetch bind | Loaded via Glide from `profileData.patient_image_url` |
| API send | `multipart/form-data` as `MultipartBody.Part` named `profileImage` |

---

## Field-by-Field Details

---

### 1. First Name
| Property | Detail |
|----------|--------|
| View ID | `etFirstName` (EditText) |
| Input type | Text, free text |
| Visibility | ✅ Self profile only (`etFirstNameGroup`) |
| Validation | Required — shows inline error `"First name is required"` |
| Fetch bind | `profileData.first_name` |
| API send key | `first_name` (multipart RequestBody) |

---

### 2. Last Name
| Property | Detail |
|----------|--------|
| View ID | `etLastName` (EditText) |
| Input type | Text, free text |
| Visibility | ✅ Self profile only (`etLastNameGroup`) |
| Validation | Currently **commented out** — not required |
| Fetch bind | `profileData.last_name` |
| API send key | `last_name` (multipart RequestBody) |

---

### 3. Name *(Family Member only)*
| Property | Detail |
|----------|--------|
| View ID | `etName` (EditText) |
| Input type | Text, free text |
| Visibility | ✅ Family member only (`etNameGroup`) |
| Validation | Commented out — not enforced currently |
| Fetch bind | `selectedFamilyMember.name` |
| API send key | `name` (multipart RequestBody) |

---

### 4. Email
| Property | Detail |
|----------|--------|
| View ID | `etEmailId` (EditText) |
| Input type | `textEmailAddress` |
| Visibility | ✅ Self profile only (`etEmailIdGroup`) |
| Validation | Commented out — not enforced currently |
| Fetch bind | `profileData.email` |
| API send key | `email` (multipart RequestBody) |

---

### 5. Phone Number
| Property | Detail |
|----------|--------|
| View ID | `etPhoneNumber` (EditText) |
| Input type | `number` |
| Visibility | ✅ Self profile only (`etPhoneNumberGroup`) |
| Validation | Required + exactly 10 digits → inline error `"Enter a valid phone number"` |
| Fetch bind | `profileData.phone_number` |
| API send key | `phone_number` (multipart RequestBody) |

---

### 6. Emergency Contact Number
| Property | Detail |
|----------|--------|
| View ID | `etEmergencyContactNumber` (EditText) |
| Input type | `number` |
| Visibility | ✅ Both modes (`etEmergencyContactNumberGroup` shown in both) |
| Validation | None enforced |
| Fetch bind | `profileData.emergency_phone` / `selectedFamilyMember.emergency_phone` |
| API send key | `emergency_phone` (multipart RequestBody) |

---

### 7. Date of Birth
| Property | Detail |
|----------|--------|
| View ID | `etDateOfBirth` (EditText) — read-only, calendar icon triggers picker |
| Input | `DatePickerDialog` — opens on `ivCalendar` click |
| Format | `yyyy-MM-dd` (e.g., `1995-06-15`) |
| Visibility | ✅ Both modes |
| Validation | Required → inline error `"Date of Birth is required"` |
| Fetch bind | `profileData.dob` / `selectedFamilyMember.dob` |
| API send key | `dob` (multipart RequestBody) |

---

### 8. Gender
| Property | Detail |
|----------|--------|
| View ID | `tvSelectedGender` (TextView inside `genderSelectionCard` RelativeLayout) |
| Input | Tap card → `showGenderPopup()` → bottom sheet `NumberPicker` |
| Options | `Male`, `Female`, `Other` |
| UI | Custom bottom sheet (`dialog_number_picker.xml`) with Cancel + Sure |
| Validation | Required → Toast `"Please select gender"` |
| Fetch bind | API returns `"M"` / `"F"` → mapped to `"Male"` / `"Female"` for display |
| API send value | Reversed: `"Male"` → `"M"`, `"Female"` → `"F"`, `"Other"` → `"O"` |
| API send key | `gender` (multipart RequestBody) |
| Side effect | Gender also saved to `SharedPreferences["user_gender"]` on self-profile save |

---

### 9. Blood Group
| Property | Detail |
|----------|--------|
| View ID | `tvSelectedBloodGroup` (TextView inside `bloodGroupSelectionCard`) |
| Input | Tap card → `showBloodGroupPopup()` → bottom sheet `NumberPicker` |
| Options | `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-` |
| Validation | Required → Toast `"Please select a blood group"` |
| Fetch bind | `profileData.blood_group` / `selectedFamilyMember.bloodGroup` |
| API send value | Sent as-is (e.g., `"A+"`) — empty string `""` if placeholder selected |
| API send key | `blood_group` (multipart RequestBody) |

---

### 10. Height
| Property | Detail |
|----------|--------|
| View ID | `tvSelectedHeight` (TextView inside `heightSelectionCard`) |
| Input | Tap card → `showHeightPopup()` → bottom sheet `NumberPicker` |
| Options | `100 CM` to `250 CM` (151 values) |
| Visibility | ✅ Self profile only (`etHeightGroup`) |
| Validation | Required → Toast `"Please select height"` |
| Fetch bind | `profileData.height` → converted `toDouble().toInt()` → displayed as `"176 CM"` |
| API send value | Strip `" CM"` → send just the number string `"176"` |
| API send key | `height` (multipart RequestBody) |

---

### 11. Weight
| Property | Detail |
|----------|--------|
| View ID | `tvSelectedWeight` (TextView inside `weightSelectionCard`) |
| Input | Tap card → `showWeightPopup()` → bottom sheet `NumberPicker` |
| Options | `20 KG` to `200 KG` (181 values) |
| Visibility | ✅ Self profile only (`etWeightGroup`) |
| Validation | Required → Toast `"Please select weight"` |
| Fetch bind | `profileData.weight` → converted `toDouble().toInt()` → displayed as `"70 KG"` |
| API send value | Strip `" KG"` → send just the number string `"70"` |
| API send key | `weight` (multipart RequestBody) |

---

### 12. Relationship *(Family Member only)*
| Property | Detail |
|----------|--------|
| View ID | `spinnerRelation` (Spinner) |
| Input | Standard Android Spinner dropdown |
| Options | `Select Relationship`, `Father`, `Mother`, `Sister`, `Brother`, `Cousin`, `Grandparent`, `Other` |
| Visibility | ✅ Family member only (`relationshipSelectorGroup`) |
| Validation | Commented out — position > 0 required but not enforced in validate |
| Fetch bind | `selectedFamilyMember.relation` → matched via `setSpinnerValue()` |
| API send key | `relation` (multipart RequestBody) |

---

### 13. Address
| Property | Detail |
|----------|--------|
| View ID | `etAddress` (EditText) |
| Input type | `textCapSentences|textPostalAddress` |
| Visibility | ✅ Self profile only (`etAddressGroup`) |
| Validation | Commented out — not enforced |
| Fetch bind | `profileData.address` |
| API send key | `address` (multipart RequestBody) |

---

### 14. Country
| Property | Detail |
|----------|--------|
| View ID | `etCountry` (AutoCompleteTextView) |
| Input | `inputType="none"`, not manually typeable — tap triggers `showDropDown()` |
| Data source | `R.raw.countries` JSON → parsed into `List<Country(name, code)>` |
| Visibility | ✅ Self profile only (`etCountryGroup`) |
| Cascade trigger | On item selected → enables State dropdown + loads states for selected country code |
| Fetch bind | `profileData.country` → `loadExistingLocationData()` matches country name to code → sets text + enables cascades |
| API send value | Country name string (e.g., `"India"`) |
| API send key | `country` (multipart RequestBody) |

---

### 15. State
| Property | Detail |
|----------|--------|
| View ID | `etState` (AutoCompleteTextView) |
| Input | `inputType="none"` — tap triggers `showDropDown()` |
| Default state | `android:enabled="false"` — disabled until country selected |
| Data source | `R.raw.states_cities` JSON → states loaded by `selectedCountryCode` |
| Visibility | ✅ Self profile only (`etStateGroup`) |
| Cascade trigger | On item selected → enables City dropdown + loads cities |
| Fetch bind | `profileData.state` → set via `loadExistingLocationData()` if country resolved |
| API send value | State name string (e.g., `"Karnataka"`) |
| API send key | `state` (multipart RequestBody) |

---

### 16. City
| Property | Detail |
|----------|--------|
| View ID | `etCity` (AutoCompleteTextView) |
| Input | `inputType="none"` — tap triggers `showDropDown()` |
| Default state | `android:enabled="false"` — disabled until state selected |
| Data source | `R.raw.states_cities` JSON → cities loaded by `countryCode + state` |
| Visibility | ✅ Self profile only (`etCityGroup`) |
| Fetch bind | `profileData.city` → set via `loadExistingLocationData()` |
| API send value | City name string (e.g., `"Bengaluru"`) |
| API send key | `city` (multipart RequestBody) |

---

### 17. Zip Code / Pincode
| Property | Detail |
|----------|--------|
| View ID | `etZipCode` (EditText) |
| Input type | `number` |
| Visibility | ✅ Self profile only (`etZipCodeGroup`) |
| Validation | Commented out — not enforced |
| Fetch bind | `profileData.pincode` |
| API send key | `pincode` (multipart RequestBody) |

---

### 18. Existing Diseases
| Property | Detail |
|----------|--------|
| View ID | `etExistingDiseases` (MultiAutoCompleteTextView) — keyboard disabled |
| Input | Tap field or dropdown icon → `showDiseasePopup()` → `AlertDialog` with `ListView` (CHOICE_MODE_MULTIPLE) |
| Options (24) | Cardiovascular diseases, Diabetes, Respiratory diseases, Tuberculosis, Cancer, Malaria, Stroke, Hepatitis, AIDS, COVID-19, Dengue, Kidney diseases, Hypertension, Influenza, Mental disorder, Obesity, Typhoid, COPD, Diarrhoea, Liver disease, Malignant tumours, Asthma, Gastrointestinal disease, Infectious diseases |
| Pre-selection | Previously selected items are pre-checked when dialog reopens |
| State tracking | `selectedDiseases: MutableList<String>` — persists across dialog open/close |
| Display | Comma-separated in the input field |
| Fetch bind | `profileData.existing_diseases` → split by `","` → each item trimmed → added to `selectedDiseases` |
| API send value | Comma-separated string: `"Diabetes, Hypertension"` |
| API send key | `existing_diseases` (multipart RequestBody) |

---

### 19. Existing Medications
| Property | Detail |
|----------|--------|
| View ID | `tvExistingMedications` (TextView) inside `medicationSelector` LinearLayout |
| Input | Tap → `showMedicationDialog()` → custom `Dialog` with `dialog_medication.xml` |
| Max entries | 5 medications |
| Each entry row | `item_medication_row.xml` — medication name (EditText) + checkboxes for Morning / Afternoon / Night |
| Add more | `btnAddMedication` (hidden when 5 reached) |
| Working copy | Dialog uses a copy of list — cancel doesn't affect real list |
| Confirm | `btnUpdateMedication` → filters empty names → saves to `selectedMedications` |
| Display format | `"Dolo (1-0-1), Paracetamol (1-1-1)"` — `1` = taken, `0` = not taken for (Morning-Afternoon-Night) |
| State tracking | `selectedMedications: MutableList<MedicationEntry>` |
| Parse from API | `parseMedicationsFromString()` — regex `Name (M-A-N)` or plain text fallback |
| Fetch bind | `profileData.existing_medications` / `selectedFamilyMember.existing_medications` |
| API send value | `"Dolo (1-0-1), Paracetamol (1-1-1)"` |
| API send key | `existing_medications` (multipart RequestBody) |

---

## Country → State → City Cascade Logic

```
Load page
    ├── R.raw.countries → List<Country(name, code)>
    └── R.raw.states_cities → Map<countryCode, Map<stateName, List<cityName>>>

User selects Country
    ├── selectedCountryCode = country.code
    ├── etState.setText("") + enabled = true
    ├── etCity.setText("") + enabled = false
    └── loadStatesForCountry(countryCode) → set adapter on etState

User selects State
    ├── etCity.setText("") + enabled = true
    └── loadCitiesForState(countryCode, state) → set adapter on etCity

User selects City
    └── etCity.setText(city)

If existing data from API (loadExistingLocationData):
    ├── Match country name → find code from countriesList
    ├── Set country text
    ├── loadStatesForCountry → enable state → set state text
    └── loadCitiesForState → enable city → set city text
    (if country not found in list → set raw text, no cascade)
```

---

## Validation Rules (Active — not commented out)

| Field | Rule | Error |
|-------|------|-------|
| First Name | Not empty (self only) | Inline error on field |
| Gender | Not empty / not default | Toast |
| Phone Number | Not empty + exactly 10 digits (self only) | Inline error on field |
| Date of Birth | Not empty | Inline error on field |
| Blood Group | Not empty / not default | Toast |
| Height | Not `"Select Height"` or empty (self only) | Toast |
| Weight | Not `"Select Weight"` or empty (self only) | Toast |

> **Note:** Last name, email, address, city, state, country, pincode, relation, name validations are all **commented out** — not enforced currently.

---

## API Calls

### Fetch Profile (Self)
```
GET patients/{userId}
    └── Response: ProfileDataResponse.data
        → Bind all fields
        → loadExistingLocationData() for country/state/city
        → parseMedicationsFromString() for medications
        → selectedDiseases populated from existing_diseases
```

### Save Self Profile
```
POST patients/{userId}   (multipart/form-data)
    Fields: user_id, id, first_name, last_name, email, gender (M/F/O),
            phone_number, emergency_phone, dob, blood_group,
            address, city, state, country, pincode,
            height (number only), weight (number only),
            allergy (hardcoded 0), status (hardcoded 1),
            existing_diseases, existing_medications,
            profileImage (optional, compressed JPEG ≤ 2MB)
    
    On success (response == 0):
        → fetchUserProfileData() called again to refresh
        → Toast with server message
```

### Save New Family Member
```
POST patients/{userId}/dependents   (multipart/form-data)
    Fields: name, relation, gender, dob, blood_group,
            address, city, state, country, pincode,
            height, weight, emergency_phone,
            existing_diseases, existing_medications,
            profileImage (optional)
    
    On success or failure:
        → Navigate to FamilyMembersFragment
```

### Update Family Member
```
POST patients/{userId}/dependents/{dependentId}   (multipart/form-data)
    Fields: same as save new family member
    dependentId from familyMemberId (passed via arguments as selectedFamilyMember.id)
    
    On success or failure:
        → Navigate to FamilyMembersFragment
```

---

## Image Compression Logic

```
compressImage(uri):
    1. Open InputStream from URI → decode Bitmap
    2. If width or height > 1080px → scale down maintaining aspect ratio
    3. Loop: compress to JPEG, quality starting 100, reduce by 5 each loop
       until file size ≤ 1MB or quality reaches 10
    4. Save to cacheDir as compressed_<timestamp>.jpg
    5. Return File
    
Before API call: check file size ≤ 2MB else Toast + return
```

---

## SharedPreferences Keys Used

| Key | Read / Write | When |
|-----|-------------|------|
| `"id"` | Read | Get userId on fragment create |
| `"checkProfile"` | Write (false) | On fragment create |
| `"user_gender"` | Write | After self profile save |

---

---

# Family Members — Full Design, Logic & API Flow

---

## Overview

`FamilyMembersFragment` is the **list screen** for managing dependents (family members). It is a separate screen from `ProfileFragment`. When the user adds or edits a member, it navigates to `ProfileFragment` in family member mode.

### Entry Point
- Side nav → **Family Members** menu item → `FamilyMembersFragment`

### Navigation Flow
```
FamilyMembersFragment (list)
    ├── [Add Dependents] button  →  ProfileFragment (isFromFamilyMembers=true, no selectedFamilyMember → new)
    ├── [Edit icon] on card      →  ProfileFragment (isFromFamilyMembers=true, selectedFamilyMember passed → edit)
    └── [Delete icon] on card    →  confirm dialog → DELETE API → refresh list
```

---

## Screen Design (`fragment_family_members.xml`)

| Property | Value |
|----------|-------|
| Root | `ScrollView` |
| Background | `#D9EDFF` (light blue) |
| Padding | `16dp` all sides |

### Elements

| View | ID | Description |
|------|----|-------------|
| Button | `btnAddDependent` | Top of screen, `@drawable/round_button` style, white text, `"Add Dependents"` |
| RecyclerView | `familyMembersRecyclerView` | Below button, `LinearLayoutManager` vertical, each item = `item_family_member.xml` |

---

## Family Member Card (`item_family_member.xml`)

White `CardView`, `cornerRadius=24dp`, `elevation=4dp`, `marginBottom=16dp`

```
CardView
  └── LinearLayout (vertical, padding 16dp)
        └── RelativeLayout (top row)
              ├── ImageView: profileImageView   (60×60dp, circle_shape bg, Glide circleCrop)
              ├── TextView:  nameTextView        (18sp, bold, right of photo)
              ├── ImageView: editIcon            (28×28dp, pencil icon, right side)
              └── ImageView: deleteIcon          (28×28dp, trash icon, far right)
        └── TableLayout (4 rows, stretchColumns=*)
              ├── Row 1: "Relationship"  :  [relationshipTextView]
              ├── Row 2: "Blood Group"   :  [bloodGroupTextView]
              ├── Row 3: "Gender"        :  [genderTextView]
              └── Row 4: "DOB"          :  [dobTextView]
```

### Adapter Bindings (`FamilyMembersAdapter.kt`)

| View ID | Source field | Transform |
|---------|-------------|-----------|
| `profileImageView` | `familyMember.dependentImageUrl` | Glide `.circleCrop()` — fallback: `baseline_account_circle_24` |
| `nameTextView` | `familyMember.name` | Direct |
| `relationshipTextView` | `familyMember.relation` | Direct |
| `bloodGroupTextView` | `familyMember.bloodGroup` | Direct |
| `genderTextView` | `familyMember.gender` | `"M"` → `"Male"`, `"F"` → `"Female"`, else `"Unknown"` |
| `dobTextView` | `familyMember.dob` | Direct |
| `editIcon` click | — | Calls `onEditClick(familyMember)` lambda |
| `deleteIcon` click | — | Calls `onDeleteClick(familyMember)` lambda |

---

## FamilyMember Data Model

```kotlin
FamilyMember:
  id                   Int
  patientId            Int       (@SerializedName "patient_id")
  name                 String
  relation             String
  gender               String    ("M" / "F")
  bloodGroup           String    (@SerializedName "blood_group")
  allergy              Int
  image                String?
  dob                  String
  status               Int
  filename             String?
  filepath             String?
  age                  Int
  emergency_phone      String?
  existing_diseases    String?
  existing_medications String?
  dependentImageUrl    String?   (@SerializedName "dependent_image_url")
```

Implements `Parcelable` via `@Parcelize` — passed between fragments via `Bundle.putParcelable`.

---

## API Calls

### 1. Fetch All Family Members (on load)
```
GET patients/{userId}/dependents
    └── Response: DependentsResponse { response: Int, data: List<FamilyMember> }
        → Passed to FamilyMembersAdapter
        → RecyclerView updated
```

### 2. Delete Family Member
```
Trigger: deleteIcon tap → confirm dialog shown

Dialog (dialog_confirm.xml):
    Title:   "Remove Member"
    Message: "Are you sure you want to remove <name> from your family members?"
    Buttons: "Cancel" (dismiss) | "Remove" (proceed)

On confirm:
DELETE patients/{userId}/dependents/{dependentId}
    └── Response: AddProfileDataResponse { response: Int, message: String }
        ├── Success (response == 0) → fetchDependents() refresh list → Toast(message)
        └── Failure → Toast "Failed to delete data"

Guard: dependentId null or 0 → Toast "Failed to delete data" immediately
```

### 3. Add New Family Member
```
Trigger: btnAddDependent tap
→ Navigate to ProfileFragment with:
    Bundle { isFromFamilyMembers = true }   (no selectedFamilyMember → isNewFamilyMember = true)

In ProfileFragment (new member mode):
POST patients/{userId}/dependents   (multipart/form-data)
    Fields: name, relation, gender (M/F/O), dob, blood_group,
            address, city, state, country, pincode,
            height (number string), weight (number string),
            emergency_phone, existing_diseases, existing_medications,
            profileImage (optional, compressed JPEG ≤ 2MB)

    On success or failure → navigate back to FamilyMembersFragment
```

### 4. Edit Existing Family Member
```
Trigger: editIcon tap on card
→ Navigate to ProfileFragment with:
    Bundle {
        isFromFamilyMembers = true
        selectedFamilyMember = <FamilyMember parcelable>   → isNewFamilyMember = false
    }

ProfileFragment pre-fills from selectedFamilyMember:
    name, dob, emergency_phone, existing_diseases,
    existing_medications (via parseMedicationsFromString),
    gender (M→Male / F→Female), blood_group,
    relation (spinner via setSpinnerValue),
    profile image (Glide from dependentImageUrl)

On Save:
POST patients/{userId}/dependents/{dependentId}   (multipart/form-data)
    Fields: same as add new
    Path param: dependentId = selectedFamilyMember.id

    On success or failure → navigate back to FamilyMembersFragment
```

---

## Fields Shown in ProfileFragment — Family Member Mode

| Field | Shown | Hidden |
|-------|-------|--------|
| Name (single field) | ✅ | — |
| Relationship (spinner) | ✅ | — |
| Date of Birth | ✅ | — |
| Gender | ✅ | — |
| Blood Group | ✅ | — |
| Emergency Contact | ✅ | — |
| Existing Diseases | ✅ | — |
| Existing Medications | ✅ | — |
| Profile Image | ✅ | — |
| First Name | — | ❌ Hidden |
| Last Name | — | ❌ Hidden |
| Email | — | ❌ Hidden |
| Phone Number | — | ❌ Hidden |
| Height | — | ❌ Hidden |
| Weight | — | ❌ Hidden |
| Address | — | ❌ Hidden |
| Country | — | ❌ Hidden |
| State | — | ❌ Hidden |
| City | — | ❌ Hidden |
| Zip Code | — | ❌ Hidden |

---

## Active Validation (Family Member Mode)

| Field | Rule | Error |
|-------|------|-------|
| Gender | Not empty | Toast |
| Date of Birth | Not empty | Inline error |
| Blood Group | Not default | Toast |

> Name, Relation validations are commented out — not enforced currently.

---

## Complete User Flow Diagram

```
Side Nav → Family Members
        │
        ▼
FamilyMembersFragment loads
        │
        ├── GET patients/{id}/dependents → renders list of cards
        │
        ├── [Add Dependents] ──────────────────────────────────────────────┐
        │                                                                   │
        ├── [Edit icon on card] ──────────────────────────────────────────┐│
        │                                                                  ││
        └── [Delete icon on card]                                          ││
                │                                                          ││
                ▼                                                          ││
        Confirm Dialog                                                     ││
                ├── Cancel → dismiss                                       ││
                └── Remove → DELETE API → refresh list                    ││
                                                                           ││
                ProfileFragment (Family Member Mode) ◄─────────────────────┘│
                        │                            ◄──────────────────────┘
                        │                  (new: empty) / (edit: pre-filled)
                        │
                        ├── Fill / edit fields → [Save]
                        │       ├── New  → POST /dependents
                        │       └── Edit → POST /dependents/{id}
                        │
                        └── → Back to FamilyMembersFragment (always, success or fail)
```

---

## iOS Implementation Notes (Family Members)

1. **List screen** — `UITableView` or `UICollectionView` with custom cells matching `item_family_member.xml`
2. **Card cell** — circular photo (60pt), name + edit/delete buttons, 4-row label table (relation/blood group/gender/DOB)
3. **Gender display** — always full form: `M→Male`, `F→Female`, else `Unknown`
4. **Delete** — `UIAlertController` confirm → `DELETE` API → reload table
5. **Add** — navigate to Profile screen with `isFromFamilyMembers=true`, no member object
6. **Edit** — pass `FamilyMember` struct (use `Codable`) to Profile screen → pre-fill all fields
7. **Always navigate back** to FamilyMembersFragment after save regardless of success/failure
8. **Pass data** using coordinator pattern or navigation params (equivalent of `Bundle.putParcelable`)
9. **Fields hidden** in family mode: first/last name, email, phone, height, weight, address, country, state, city, zip
10. **Fields shown** in family mode: name, relation picker, DOB, gender, blood group, emergency phone, diseases, medications, photo

---

## iOS Implementation Notes (Self Profile)

1. **Dual mode** — same screen, toggle visibility of fields based on `isFromFamilyMembers`
2. **Gender, Blood Group, Height, Weight** — use `UIPickerView` in action sheet / bottom sheet (not inline dropdowns)
3. **Date of Birth** — `UIDatePicker` in `.date` mode, format output as `yyyy-MM-dd`
4. **Country/State/City** — cascading `UIPickerView` or `UITableView` driven by local JSON (`countries.json`, `states_cities.json`)
5. **Diseases** — multi-select `UITableView` in a modal — pre-check existing selections
6. **Medications** — custom modal with dynamic rows (name field + 3 checkboxes), max 5 rows
7. **Medication format** — serialize as `"Name (1-0-1)"` — M/A/N = 1 if checked, 0 if not
8. **Image** — compress to ≤ 1MB before upload, send as `multipart/form-data`
9. **API** — all `multipart/form-data` POST — use `URLRequest` with `multipart` encoding or Alamofire
10. **Gender mapping** — display: `Male/Female/Other` → API: `M/F/O`
11. **Height/Weight** — strip `" CM"` / `" KG"` suffix before sending to API
12. **Validation** — only First Name, Gender, Phone (10 digits), DOB, Blood Group, Height, Weight are mandatory currently

