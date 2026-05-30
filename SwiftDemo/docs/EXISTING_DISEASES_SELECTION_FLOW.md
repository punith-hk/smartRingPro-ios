# Existing Diseases — Selection, Binding & API Flow

---

## Overview

The Existing Diseases field uses a **custom multi-select popup dialog** instead of a standard dropdown. The keyboard is completely disabled on the field — tapping it always opens the disease selection dialog. Selections persist across dialog open/close sessions and survive an API fetch (pre-populated from API response).

---

## UI Elements

### Input Field (`fragment_profile.xml`)

```
LinearLayout (etExistingDiseasesGroup)
  └── TextView label: "Existing Diseases" (14sp, black)
  └── LinearLayout (horizontal, background=input_box_background_shadow, elevation=4dp, marginBottom=20dp)
        ├── MultiAutoCompleteTextView (id: etExistingDiseases)
        │       layout_width=0dp, layout_weight=1
        │       inputType="none"
        │       focusable="false"
        │       cursorVisible="false"
        │       background=transparent
        │       hint="Select Diseases"
        │       singleLine=true
        │       ellipsize=end
        │       paddingVertical=15dp
        │
        └── AppCompatImageView (id: iconDropdownDiseases)
                20×20dp, arrow forward icon, tint #999999
```

**Key XML properties:**
- `inputType="none"` + `keyListener=null` set in code → keyboard never opens
- `focusable="false"` → cannot be focused manually
- `singleLine=true` + `ellipsize=end` → long selections truncate with `...`
- Both the field AND the arrow icon are separate click targets — both open the same dialog

---

## Disease List (Hardcoded in Fragment)

24 diseases, defined as a `val diseases = listOf<String>(...)` in `ProfileFragment`:

| # | Disease |
|---|---------|
| 1 | Cardiovascular diseases |
| 2 | Diabetes |
| 3 | Respiratory diseases |
| 4 | Tuberculosis |
| 5 | Cancer |
| 6 | Malaria |
| 7 | Stroke |
| 8 | Hepatitis |
| 9 | AIDS |
| 10 | COVID-19 |
| 11 | Dengue |
| 12 | Kidney diseases |
| 13 | Hypertension |
| 14 | Influenza |
| 15 | Mental disorder |
| 16 | Obesity |
| 17 | Typhoid |
| 18 | Chronic Obstructive Pulmonary Disease |
| 19 | Diarrhoea |
| 20 | Liver disease |
| 21 | Malignant tumours |
| 22 | Asthma |
| 23 | Gastrointestinal disease |
| 24 | Infectious diseases |

---

## State Tracking

```kotlin
private val selectedDiseases = mutableListOf<String>()
```

- Lives in `ProfileFragment` — persists for the **entire fragment lifecycle**
- Survives dialog open → cancel → reopen (previous selections remain)
- Cleared and repopulated on API fetch
- Used to pre-check items when dialog reopens

---

## Dialog (`showDiseasePopup()`)

Layout file: `dialog_profile_disease_selection.xml`

### Dialog Structure

```
AlertDialog
  └── dialogView (dialog_profile_disease_selection.xml)
        ├── TextView (id: dialogTitle)  → "Select Diseases"
        ├── ListView (id: listViewDiseases)
        │       CHOICE_MODE_MULTIPLE (native checkboxes)
        │       adapter = ArrayAdapter with simple_list_item_multiple_choice
        │
        ├── Button (id: btnOk)     → confirm selection
        └── Button (id: btnCancel) → dismiss without saving
```

### Dialog Open Behaviour

```
User taps etExistingDiseases  OR  iconDropdownDiseases
        │
        ▼
showDiseasePopup()
        │
        ├── Inflate dialog_profile_disease_selection.xml
        ├── Set ListView adapter = 24 disease strings
        ├── Set CHOICE_MODE_MULTIPLE
        │
        ├── Pre-check previously selected items:
        │       for (i in diseases.indices) {
        │           if (selectedDiseases.contains(diseases[i]))
        │               listView.setItemChecked(i, true)
        │       }
        │
        ├── Build selectedItems = mutableSetOf (copy of selectedDiseases)
        │
        ├── ListView item click:
        │       item in selectedItems → remove it
        │       item not in selectedItems → add it
        │
        ├── [OK] clicked:
        │       selectedDiseases.clear()
        │       selectedDiseases.addAll(selectedItems)
        │       if not empty → etExistingDiseases.setText(joined comma string)
        │       else         → etExistingDiseases.setText("")
        │       dialog.dismiss()
        │
        └── [Cancel] clicked:
                dialog.dismiss()
                (selectedDiseases unchanged — previous state preserved)
```

---

## Binding from API Response

### On `fetchUserProfileData()` success:

```kotlin
val existingDiseases = profileData.existing_diseases?.trim()

if (!existingDiseases.isNullOrEmpty()) {
    val apiDiseases = existingDiseases.split(",").map { it.trim() }
    selectedDiseases.clear()
    selectedDiseases.addAll(apiDiseases.filter { it.isNotEmpty() })
    binding.etExistingDiseases.setText(selectedDiseases.joinToString(", "))
} else {
    selectedDiseases.clear()
    binding.etExistingDiseases.setText("")
}
```

**Flow:**
```
API response: existing_diseases = "Diabetes, Hypertension, Cancer"
        │
        ├── split(",") → ["Diabetes", " Hypertension", " Cancer"]
        ├── map { it.trim() } → ["Diabetes", "Hypertension", "Cancer"]
        ├── filter { it.isNotEmpty() } → removes blanks
        ├── selectedDiseases = ["Diabetes", "Hypertension", "Cancer"]
        └── etExistingDiseases.setText("Diabetes, Hypertension, Cancer")

Next time user opens dialog:
        └── "Diabetes", "Hypertension", "Cancer" are pre-checked ✅
```

### Family Member Pre-fill (`isFromFamilyMembers = true`):

```kotlin
binding.etExistingDiseases.setText(selectedFamilyMember.existing_diseases ?: "")
```

> **Note:** For family members, `parseMedicationsFromString()` is called for medications but diseases are set directly via `setText`. The `selectedDiseases` list is **not** populated from family member data on initial pre-fill — meaning if the user opens the dialog after pre-fill, no items will be pre-checked. This is a known gap in the current implementation.

---

## Sending to API

On save (self profile or family member):

```kotlin
val existingDiseases = binding.etExistingDiseases.text.toString().trim()
```

Sent as multipart `RequestBody`:

```
Key:   existing_diseases
Value: "Diabetes, Hypertension, Cancer"   ← comma-separated display names
```

No encoding or ID mapping — raw disease name strings exactly as shown in the list.

---

## Complete Flow Diagram

```
Fragment loads
        │
        ├── (Self profile) fetchUserProfileData()
        │       API returns existing_diseases = "Diabetes, Hypertension"
        │       → split → trim → selectedDiseases = ["Diabetes", "Hypertension"]
        │       → etExistingDiseases.setText("Diabetes, Hypertension")
        │
        └── (Family member) setText(selectedFamilyMember.existing_diseases)
                → selectedDiseases list NOT populated (gap)

User taps field or arrow icon
        │
        ▼
showDiseasePopup()
        ├── 24 diseases listed with checkboxes
        ├── Pre-checked: items in selectedDiseases
        ├── User toggles checkboxes
        │
        ├── [Cancel] → no change
        └── [OK]     → selectedDiseases updated → field text updated

User taps [Save]
        └── existingDiseases = etExistingDiseases.text.toString().trim()
            → sent as "existing_diseases" in multipart POST
```

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| User selects nothing and taps OK | `etExistingDiseases.setText("")`, `selectedDiseases` cleared |
| User cancels after selecting | `selectedDiseases` unchanged, field text unchanged |
| API returns empty / null | `selectedDiseases` cleared, field set to `""` |
| API returns disease not in the 24-item list | Added to `selectedDiseases` and shown in field text, but will NOT be pre-checked in dialog (not in `diseases` list) |
| Family member pre-fill | Field text set but `selectedDiseases` not populated — dialog opens with no pre-checks |

---

## iOS Implementation Notes

1. **Input field** — non-editable `UITextField` or `UILabel`-style tap target — tap opens modal
2. **Modal** — `UITableViewController` with `UITableViewCell` checkmark style — `allowsMultipleSelection = true`
3. **State** — `var selectedDiseases: [String] = []` — persists in the ViewController
4. **Pre-check** — on modal open, for each cell check if its disease is in `selectedDiseases` → set accessory to `.checkmark`
5. **Toggle** — `didSelectRowAt` → add/remove from a working set
6. **Cancel** — dismiss modal, discard working set
7. **OK / Done** — `selectedDiseases = workingSet` → update field text as `joined(separator: ", ")`
8. **Bind from API** — `split(",")` → `map { $0.trimmingCharacters(in: .whitespaces) }` → assign to `selectedDiseases` → update field text
9. **Send to API** — `selectedDiseases.joined(separator: ", ")` as plain string value
10. **Family member pre-fill gap** — populate `selectedDiseases` from `existing_diseases` string (same split/trim logic) so dialog pre-checks work correctly on iOS

