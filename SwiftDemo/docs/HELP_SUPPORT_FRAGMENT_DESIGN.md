# Help & Support Fragment - Design & Implementation

**HEARTO App - Help & Support Screen**  
**Fragment:** `HelpSupportFragment.kt`  
**Layout:** `fragment_help_support.xml`

---

## 📋 Overview

The Help & Support screen is a comprehensive multi-screen interface that provides users with FAQs, contact options, issue reporting, app guide, and privacy policy. It uses a card-based navigation system with 6 different screens managed by visibility toggling.

---

## 🎨 Design Architecture

### Screen Structure
```
Main Container (FrameLayout)
├── Screen 0: Menu (Default)
├── Screen 1: FAQ
├── Screen 2: Contact Us
├── Screen 3: Report an Issue
├── Screen 4: App Guide
└── Screen 5: Privacy Policy
```

### Navigation Flow
- **Main Menu** → Sub-screens via card clicks
- **Sub-screens** → Main Menu via close button (X)
- **Back Press** → Returns to main menu from any sub-screen
- **Exit** → Exits fragment only when on main menu

---

## 🏠 Screen 0: Main Menu

### Layout Design
- **Background Color:** `#D9EDFF` (Light Blue)
- **Container:** Scrollable LinearLayout with vertical orientation
- **Padding:** 20dp all sides

### Header Section
```
┌─────────────────────────┐
│    [Info Icon 72dp]     │  (Blue tinted)
│   Help & Support        │  (22sp, Bold, Black)
│  We're here to help you │  (14sp, #1A1A1A)
└─────────────────────────┘
```

### Menu Cards (5 Cards)

Each card follows this design pattern:

#### Card Structure
```xml
CardView
├── Background: White (#FFFFFF)
├── Corner Radius: 12dp
├── Elevation: 4dp
├── Margin Bottom: 12dp
├── Foreground: Ripple effect
└── Content:
    ├── Icon (36dp × 36dp, Blue tinted #0D99FF)
    ├── Title (15sp, Bold, #1A1A1A)
    ├── Subtitle (12sp, #888888)
    └── Arrow Icon (20dp × 20dp, Gray #AAAAAA)
```

#### 1. FAQ Card
- **Icon:** `@drawable/baseline_list_alt_24`
- **Title:** "Frequently Asked Questions"
- **Subtitle:** "Find answers to common questions"
- **Action:** Navigate to FAQ screen

#### 2. Contact Us Card
- **Icon:** `@drawable/baseline_message_24`
- **Title:** "Contact Us"
- **Subtitle:** "Get in touch with our support team"
- **Action:** Navigate to Contact screen

#### 3. Report an Issue Card
- **Icon:** `@drawable/baseline_info_24`
- **Title:** "Report an Issue"
- **Subtitle:** "Let us know if something isn't working"
- **Action:** Navigate to Report Issue screen

#### 4. App Guide Card
- **Icon:** `@drawable/baseline_edit_note_24`
- **Title:** "App Guide"
- **Subtitle:** "Learn how to use HEARTO"
- **Action:** Navigate to App Guide screen

#### 5. Privacy Policy Card
- **Icon:** `@drawable/baseline_shield_moon_24`
- **Title:** "Privacy Policy"
- **Subtitle:** "Read how we protect your data"
- **Action:** Load and show Privacy Policy screen

---

## ❓ Screen 1: FAQ (Frequently Asked Questions)

### Header Bar
```
┌───────────────────────────────────┐
│  Frequently Asked Questions   [X] │  (Blue #0D99FF, 56dp height)
└───────────────────────────────────┘
```
- **Background:** Blue (#0D99FF)
- **Title:** Centered, white, 17sp, bold
- **Close Button:** Right-aligned X icon, white tint

### Content Sections

Content is organized into 3 categories:

#### 1. Ring Issues (Section Header: Blue, 13sp, Bold)

**FAQ Cards:**

1. **Why won't my ring connect to the app?**
   - Answer: Ensure Bluetooth is ON. Restart the ring by charging it for 10 seconds. Force-close and reopen the HEARTO app, then tap + Add Device to re-pair.

2. **My ring battery drains very fast. What can I do?**
   - Answer: Continuous heart rate or SpO2 monitoring consumes extra battery. Try setting measurements to interval mode (e.g. every 5 min) in Device Settings. Also ensure the firmware is up to date.

3. **Ring firmware update failed. How do I retry?**
   - Answer: Keep the ring on the charger and close to the phone. Go to Device Settings → Firmware Update and tap Retry. Ensure your phone has at least 30% battery and a stable internet connection.

4. **Health data is not syncing to the dashboard.**
   - Answer: Pull down the dashboard to manually refresh. Make sure the ring is connected (green dot in top bar). If it still doesn't sync, disconnect and reconnect the ring from Device Settings.

#### 2. App Issues (Section Header: Blue, 13sp, Bold)

**FAQ Cards:**

1. **How do I book an appointment with a doctor?**
   - Answer: Tap the Appointments tab at the bottom. Select a specialist, choose a date and time slot, then confirm. You will receive a confirmation notification. Ensure your profile is complete before booking.

2. **I'm not receiving notifications from the app.**
   - Answer: Go to Android Settings → Apps → HEARTO → Notifications and ensure they are enabled. Also disable Battery Optimization for HEARTO so the background service can run uninterrupted.

3. **My ECG report is not generating.**
   - Answer: Keep your finger still on the ring sensor throughout the full 30-second ECG measurement. Ensure the ring is correctly positioned on your finger. After recording, the report generates within a few seconds on the ECG screen.

4. **How do I add a family member / linked account?**
   - Answer: Go to Profile → Linked Accounts → Add Member. Enter their mobile number and confirm. They will receive a link request. Once accepted, you can switch between linked profiles from the Profile screen.

#### 3. General (Section Header: Blue, 13sp, Bold)

**FAQ Cards:**

1. **Is my health data secure?**
   - Answer: Yes. All data is encrypted in transit (TLS 1.2+) and at rest. We do not sell your personal or health data. Read our full Privacy Policy for details.

2. **How do I delete my account and data?**
   - Answer: Go to Profile → Account Settings → Delete Account. Confirm with your password. Your data will be permanently removed within 30 days. Alternatively email us at support@mannaheal.com.

### FAQ Card Design
```xml
CardView (White, 10dp radius, 3dp elevation)
└── Question (14sp, Bold, #1A1A1A)
└── Answer (13sp, #555555, 2dp line spacing)
```

---

## 📞 Screen 2: Contact Us

### Header Bar
```
┌───────────────────────────────────┐
│        Contact Us              [X] │  (Blue #0D99FF)
└───────────────────────────────────┘
```

### Description Text
"Reach out to our support team — we're happy to help!"  
(14sp, #555555, top margin 8dp, bottom margin 20dp)

### Contact Cards

#### 1. Email Support Card
```
┌─────────────────────────────────────┐
│  [📧 Icon]  Email Support           │
│             support@mannaheal.com   │  (Blue, clickable)
└─────────────────────────────────────┘
```
- **Background:** Light blue (#F0F8FF)
- **Icon:** `baseline_message_24` (36dp, blue tinted)
- **Title:** "Email Support" (14sp, Bold)
- **Email:** "support@mannaheal.com" (13sp, Blue)
- **Action:** Opens email client with pre-filled subject "HEARTO App Support Request"

#### 2. Phone Support Card
```
┌─────────────────────────────────────┐
│  [📞 Icon]  Phone Support           │
│             +91 98765 43210         │  (Blue, clickable)
└─────────────────────────────────────┘
```
- **Background:** Light blue (#F0F8FF)
- **Icon:** `baseline_local_hospital_24` (36dp, blue tinted)
- **Title:** "Phone Support" (14sp, Bold)
- **Phone:** "+91 98765 43210" (13sp, Blue)
- **Action:** Opens phone dialer with number

#### 3. Support Hours Info Card
```
┌─────────────────────────────────────┐
│  [⏰ Icon]  Support Hours            │
│             Mon–Sat: 9:00 AM – 6:00 │
│             PM IST                  │
└─────────────────────────────────────┘
```
- **Background:** Light yellow (#FFF8E1)
- **Icon:** `baseline_timer_24` (28dp, orange tinted #FFA000)
- **Title:** "Support Hours" (14sp, Bold)
- **Hours:** "Mon–Sat: 9:00 AM – 6:00 PM IST" (13sp, #666666)
- **Action:** None (informational only)

---

## 🐛 Screen 3: Report an Issue

### Header Bar
```
┌───────────────────────────────────┐
│     Report an Issue            [X] │  (Blue #0D99FF)
└───────────────────────────────────┘
```

### Form Fields

#### 1. Issue Category Dropdown

**Label:** "Issue Category" (14sp, Black, sans-serif)

**Spinner Design:**
- **Background:** White with shadow (`input_box_background_shadow`)
- **Height:** Wrap content
- **Padding:** 15dp all sides, 40dp end (for arrow)
- **Elevation:** 4dp
- **Arrow:** Rotating chevron (270° closed → 0° open)

**Categories List (72 items):**

**Hint Row:**
- "Select a category" (Position 0, disabled, gray)

**Ring Issues Section:** `── Ring Issues ──` (Header, disabled, gray, bold)
1. Ring Not Connecting
2. Ring Not Charging
3. Ring Not Pairing / Pairing Failed
4. Ring Disconnects Frequently
5. Ring Not Syncing Data
6. Ring Battery Drains Too Fast
7. Ring Firmware Update Failed
8. Ring Not Tracking Heart Rate
9. Ring Not Tracking Blood Pressure
10. Ring Not Tracking Blood Oxygen (SpO2)
11. Ring Not Tracking ECG
12. Ring Not Tracking Sleep
13. Ring Not Tracking Steps
14. Ring Not Tracking Body Temperature
15. Ring Display / LED Issue
16. Ring Physical Damage

**App Issues Section:** `── App Issues ──` (Header, disabled, gray, bold)
17. App Crashes or Freezes
18. App Not Loading Data / Dashboard Empty
19. Notifications Not Working
20. Health Data Not Showing Correctly
21. ECG Report Not Generating
22. Appointment Booking Issue
23. Doctor / Specialist Not Available
24. Profile / Account Settings Issue
25. Linked Account / Family Member Issue
26. Login / Authentication Issue
27. App Running Slow

**Other Section:** `── Other ──` (Header, disabled, gray, bold)
28. Other / Not Listed Above

**Dropdown Styling:**
- Headers: Gray, 12sp, Bold, padding 32dp start, disabled
- Items: Black, 14sp, padding 48dp start, selectable
- Hint: Hidden in dropdown (0 height)

**Arrow Animation:**
- **Closed state:** Rotated 270° (points right →)
- **Open state:** Rotated 0° (points down ↓)
- **Animation duration:** 200ms smooth rotation

#### 2. Problem Description Field

**Label:** "Problem Description" (14sp, Black, sans-serif)

**EditText:**
- **Background:** White with shadow
- **Input Type:** Multi-line text with auto-capitalization
- **Min Lines:** 4
- **Max Lines:** 6
- **Padding:** 15dp all sides
- **Hint:** "Describe the issue in detail..."
- **Text Color:** #1A1A1A
- **Hint Color:** #AAAAAA
- **Font:** 14sp, sans-serif
- **Elevation:** 4dp
- **Scrollbars:** Vertical

#### 3. Attach Screenshots (Optional)

**Label:** "Attach Screenshots (optional)" (14sp, Black, sans-serif)

**Upload Area:**
```
┌─────────────────────────────────────┐
│        [📤 Upload Icon]             │
│   Tap to upload images (max 3)      │  (12sp, Blue)
└─────────────────────────────────────┘
```
- **Background:** Dashed border (`bg_upload_area`)
- **Min Height:** 80dp
- **Clickable:** Opens image picker
- **Icon:** Upload icon (32dp, blue tinted)
- **Max Images:** 3

**Image Picker Behavior:**
- Opens system image picker
- Allows multiple selection
- Supports `clipData` for batch selection
- Falls back to single selection if needed
- Limit: Maximum 3 images

**Thumbnail Display:**

When images are selected:
```
┌──────┬──────┬──────┐
│ IMG1 │ IMG2 │ IMG3 │  (72dp × 72dp each)
│  [X] │  [X] │  [X] │  (Delete button overlay)
└──────┴──────┴──────┘
```

**Thumbnail Specs:**
- **Container:** HorizontalScrollView
- **Size:** 72dp × 72dp
- **Scale Type:** CENTER_CROP
- **Corner:** Rounded (`clipToOutline = true`)
- **Margin:** 8dp right spacing
- **Delete Icon:** 22dp red icon at top-right corner
- **Delete Background:** White circle background

**Status Text:**
- No images: "Tap to upload images (max 3)"
- With images: "2/3 image(s) selected"

**Delete Functionality:**
- Tap red X icon on thumbnail
- Removes image from list
- Refreshes thumbnail display
- Updates counter text

#### 4. Submit Button

**Button Design:**
```
┌─────────────────────────────────────┐
│        Submit Report                │  (Blue button)
└─────────────────────────────────────┘
```
- **Background:** Blue rounded (`round_button`)
- **Text:** "Submit Report" (15sp, Bold, White, not all caps)
- **Elevation:** 4dp
- **Full width**

**Validation Rules:**

1. **Category Selection:**
   - Must not be hint (position 0)
   - Must not be section header (starts with `──`)
   - Must not be empty
   - Error: Toast "Please select an issue category"

2. **Description:**
   - Must not be empty
   - Must not be only whitespace
   - Error: EditText error "Please describe the issue"

**On Successful Submit:**
1. Show toast: "Report submitted successfully!"
2. Clear description field
3. Reset spinner to position 0
4. Clear all selected images
5. Return to main menu

**Future Implementation:**
- TODO: Wire to API endpoint
- Send category, description, and image URIs
- Handle server response
- Show loading state during submission

---

## 📖 Screen 4: App Guide

### Header Bar
```
┌───────────────────────────────────┐
│         App Guide              [X] │  (Blue #0D99FF)
└───────────────────────────────────┘
```

### Guide Steps

Each step follows this card design:

```xml
┌─────────────────────────────────────┐
│  [1]  Step Title                    │  (Number in blue circle)
│       Step description with         │
│       detailed instructions...      │
└─────────────────────────────────────┘
```

**Card Design:**
- **Background:** White
- **Corner Radius:** 10dp
- **Elevation:** 3dp
- **Margin Bottom:** 10dp

**Number Badge:**
- **Size:** 36dp × 36dp
- **Background:** Blue circle (`step_circle_bg`)
- **Text:** Step number (15sp, Bold, White)
- **Alignment:** Centered

**Content:**
- **Title:** 14sp, Bold, #1A1A1A
- **Description:** 13sp, #555555, 2dp line spacing

### Guide Content

#### Step 1: Create Your Account
"Download HEARTO, open the app and sign up with your mobile number. Complete your profile (name, DOB, gender, height, weight) for accurate health insights."

#### Step 2: Pair Your HEARTO Ring
"Enable Bluetooth. On the Dashboard tap the + icon or go to Device Settings → Add Device. Place the ring near your phone and follow the on-screen pairing steps."

#### Step 3: Sync Your Health Data
"Once paired, the ring automatically starts tracking heart rate, blood pressure, SpO2, steps, sleep, and ECG. Pull down the dashboard to manually sync latest data."

#### Step 4: View Your Health Dashboard
"Navigate using the bottom tabs: Health (Dashboard), Appointments, Device, and Family Care. Tap any health card to view detailed trends and history."

#### Step 5: Book an Appointment
"Tap Appointments → Book New Appointment. Choose a specialist, select date/time, and confirm. You'll receive a notification and can manage appointments from the Appointments tab."

#### Step 6: Configure Ring Settings
"Go to Device Settings to adjust measurement intervals (15, 30, 45, or 60 min), update firmware, calibrate sensors, or disconnect the ring."

#### Step 7: Add Family Members
"From Profile → Linked Accounts, add family members by entering their mobile number. Once accepted, switch between profiles to monitor their health."

#### Step 8: Review Notifications
"Enable notifications for health alerts, appointment reminders, and ring battery warnings. Configure sound and vibration in Profile → Settings."

*(Layout file continues with similar step cards)*

---

## 🔒 Screen 5: Privacy Policy

### Header Bar
```
┌───────────────────────────────────┐
│      Privacy Policy            [X] │  (Blue #0D99FF)
└───────────────────────────────────┘
```

### Content Display

**Container:** Scrollable TextView inside LinearLayout

**Text Content:** (Loaded dynamically in `loadPrivacyContent()`)

```
HEARTO – Privacy Policy & Terms of Use

Last Updated: April 2026

1. INTRODUCTION
Welcome to HEARTO, a smart health monitoring application developed by MannaHeal. 
By using this app, you agree to the terms outlined in this policy.

2. DATA WE COLLECT
• Health metrics: Heart rate, blood pressure, SpO2, ECG, sleep, steps, body temperature
• Personal information: Name, mobile number, date of birth, gender, profile photo
• Device information: Ring MAC address, firmware version, BLE connection data
• Usage data: App interactions, appointment history, linked accounts

3. HOW WE USE YOUR DATA
• To provide personalised health monitoring and insights
• To connect you with healthcare specialists for appointments
• To sync ring data to our secure cloud servers
• To send health alerts and notifications
• To improve app performance and features

4. DATA SHARING
We do not sell your personal data. We may share data with:
• Licensed healthcare providers for appointment purposes
• Cloud infrastructure providers (under strict confidentiality agreements)
• Legal authorities if required by law

5. DATA SECURITY
All data is encrypted in transit (TLS 1.2+) and at rest. We follow industry-standard 
security practices to protect your health information.

6. YOUR RIGHTS
• Access or export your health data at any time
• Request deletion of your account and data
• Opt out of non-essential notifications
• Contact us at support@mannaheal.com for any data requests

7. RETENTION
Health data is retained for up to 5 years to support your health history. 
Account data is deleted within 30 days of account deletion request.

8. CHILDREN'S PRIVACY
This app is not intended for users under 13 years of age.

9. CHANGES TO THIS POLICY
We will notify you of any material changes via in-app notification or email.

10. CONTACT
MannaHeal Pvt. Ltd.
Email: support@mannaheal.com
Phone: +91 98765 43210
```

**TextView Styling:**
- **Font:** System default, monospace for clarity
- **Text Size:** 14sp
- **Text Color:** #1A1A1A
- **Line Spacing:** Standard (readable)
- **Padding:** 16dp all sides
- **Background:** White card or light background
- **Scrollable:** Vertically scrollable

---

## 🎯 Core Functionality

### Navigation Logic

```kotlin
private fun showScreen(target: View) {
    allScreens.forEach { it.visibility = View.GONE }
    target.visibility = View.VISIBLE
}
```

**Screen Management:**
- All 6 screens exist in the layout simultaneously
- Only one screen visible at a time
- Toggle visibility using `View.VISIBLE` / `View.GONE`
- Smooth transition without fragment transactions

### Back Press Handling

```kotlin
OnBackPressedCallback(true) {
    override fun handleOnBackPressed() {
        if (screenMenu.visibility != View.VISIBLE) {
            showScreen(screenMenu)  // Return to menu
        } else {
            isEnabled = false
            requireActivity().onBackPressedDispatcher.onBackPressed()  // Exit fragment
        }
    }
}
```

**Behavior:**
1. **From Sub-screen:** Returns to main menu
2. **From Main Menu:** Passes back press to activity (exits fragment)
3. **Callback:** Registered with viewLifecycleOwner for proper cleanup

### External Intent Actions

#### 1. Email Support
```kotlin
Intent(Intent.ACTION_SENDTO).apply {
    data = Uri.parse("mailto:support@mannaheal.com")
    putExtra(Intent.EXTRA_SUBJECT, "HEARTO App Support Request")
}
```
- Opens default email client
- Pre-fills recipient and subject line

#### 2. Phone Support
```kotlin
Intent(Intent.ACTION_DIAL).apply {
    data = Uri.parse("tel:+919876543210")
}
```
- Opens phone dialer
- Pre-fills phone number (doesn't auto-dial)

### Image Picker Implementation

**Activity Result Contract:**
```kotlin
registerForActivityResult(ActivityResultContracts.StartActivityForResult())
```

**Intent Configuration:**
```kotlin
Intent(Intent.ACTION_PICK).apply {
    type = "image/*"
    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
}
```

**Result Handling:**
1. **Multiple images:** Loops through `clipData`
2. **Single image:** Uses `data` URI
3. **Limit enforcement:** Stops at `maxImages` (3)
4. **Refresh:** Calls `refreshThumbnails()` to update UI

### Thumbnail Management

**Dynamic Generation:**
```kotlin
private fun refreshThumbnails() {
    // Clear existing thumbnails
    container.removeAllViews()
    
    if (selectedImages.isEmpty()) {
        // Show upload prompt
        scroll.visibility = View.GONE
        hint.text = "Tap to upload images (max $maxImages)"
    } else {
        // Show thumbnails with delete buttons
        scroll.visibility = View.VISIBLE
        hint.text = "${selectedImages.size}/$maxImages image(s) selected"
        
        selectedImages.forEachIndexed { idx, uri ->
            // Create FrameLayout with ImageView and delete button
            // Set onClick to remove and refresh
        }
    }
}
```

**Components:**
- **Container:** HorizontalScrollView with LinearLayout
- **Thumbnail:** 72dp FrameLayout containing ImageView and delete button
- **Delete Button:** 22dp ImageView with red tint, positioned top-right
- **Spacing:** 8dp margin between thumbnails

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Main screen background |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Blue | `#0D99FF` | Icons, links, headers |
| Header Bar | `#0D99FF` | Sub-screen header background |
| Text Primary | `#1A1A1A` | Titles, main text |
| Text Secondary | `#555555` | Descriptions, answers |
| Text Tertiary | `#888888` | Subtitles, hints |
| Text Hint | `#AAAAAA` | Input placeholders |
| Contact Card BG | `#F0F8FF` | Email/Phone cards |
| Hours Card BG | `#FFF8E1` | Support hours card |
| Hours Icon | `#FFA000` | Timer icon tint |
| Delete Icon | `holo_red_dark` | Thumbnail delete button |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Screen Title | 22sp | Bold | Black |
| Subtitle | 14sp | Normal | #1A1A1A |
| Card Title | 15sp | Bold | #1A1A1A |
| Card Subtitle | 12sp | Normal | #888888 |
| Header Title | 17sp | Bold | White |
| Section Header | 13sp | Bold | #0D99FF |
| FAQ Question | 14sp | Bold | #1A1A1A |
| FAQ Answer | 13sp | Normal | #555555 |
| Form Label | 14sp | Normal | Black |
| Input Text | 14sp | Normal | #1A1A1A |
| Button Text | 15sp | Bold | White |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 20dp |
| Card Margin Bottom | 12dp |
| Card Padding | 16dp |
| Icon Size (Large) | 72dp |
| Icon Size (Medium) | 36dp |
| Icon Size (Small) | 20dp |
| Corner Radius | 10-12dp |
| Elevation (Card) | 3-4dp |
| Line Spacing (Text) | 2dp extra |

### Animations

**Arrow Rotation (Spinner):**
- **Duration:** 200ms
- **Closed → Open:** 270° → 0° (smooth rotation)
- **Open → Closed:** 0° → 270° (smooth rotation)
- **Property:** `rotation` using ObjectAnimator

**Ripple Effects:**
- All cards use `?attr/selectableItemBackground` foreground
- Provides material design touch feedback

---

## 🔧 Technical Implementation

### Key Components

```kotlin
// Screen References
private lateinit var screenMenu: ScrollView
private lateinit var screenFaq: ScrollView
private lateinit var screenContactUs: ScrollView
private lateinit var screenReportIssue: ScrollView
private lateinit var screenAppGuide: ScrollView
private lateinit var screenPrivacyPolicy: LinearLayout

// Data
private val selectedImages = mutableListOf<Uri>()
private val maxImages = 3
private val categories = listOf(/* 72 items */)

// Image Picker Contract
private val pickImages = registerForActivityResult(
    ActivityResultContracts.StartActivityForResult()
) { result -> /* handle */ }
```

### Custom Spinner Adapter

**Features:**
1. **Position-based logic:**
   - Position 0: Hint (disabled, gray)
   - Headers (start with `──`): Disabled, bold, gray
   - Regular items: Enabled, selectable

2. **View customization:**
   - `getView()`: Closed spinner display
   - `getDropDownView()`: Dropdown list appearance

3. **Styling:**
   - Headers: 12sp, bold, 32dp left padding
   - Items: 14sp, normal, 48dp left padding
   - Hint: Hidden in dropdown (0 height, GONE)

### Lifecycle Management

**Fragment Lifecycle:**
- `onCreateView`: Inflates layout
- `onViewCreated`: Binds views, sets up listeners
- `viewLifecycleOwner`: Used for back press callback

**Memory Considerations:**
- Image URIs stored as list (not bitmap)
- Thumbnails loaded on-demand via `setImageURI()`
- Views recycled properly in scrollable containers

---

## 📱 User Experience Flow

### Primary User Journeys

#### 1. Finding an Answer (FAQ)
```
Menu → FAQ Card Click → Browse Categories → Read Answer → Close Button → Menu
```

#### 2. Contacting Support
```
Menu → Contact Us Card → Choose Email/Phone → External App Opens
```

#### 3. Reporting an Issue
```
Menu → Report Issue Card → Select Category → Type Description → 
Optional: Add Screenshots → Submit → Success Toast → Menu
```

#### 4. Learning App Features
```
Menu → App Guide Card → Read Steps 1-8 → Close Button → Menu
```

#### 5. Reading Privacy Policy
```
Menu → Privacy Policy Card → Scroll Through Policy → Close Button → Menu
```

### Error Handling

**Validation Errors:**
- **No category selected:** Toast "Please select an issue category"
- **Empty description:** EditText error "Please describe the issue"
- **Max images reached:** Toast "Maximum 3 images allowed"

**Success Feedback:**
- **Report submitted:** Toast "Report submitted successfully!"
- **Form cleared:** All fields reset to initial state

---

## 🚀 Future Enhancements

### Planned Features
1. **API Integration:**
   - Submit issue reports to backend
   - Track report status
   - Receive support responses

2. **Search in FAQ:**
   - Add search bar to quickly find questions
   - Highlight matching text

3. **Chat Support:**
   - In-app live chat with support team
   - Real-time messaging

4. **Video Tutorials:**
   - Embed tutorial videos in App Guide
   - Screen recordings for complex features

5. **Feedback Form:**
   - Rate app experience
   - Submit feature requests

6. **Offline Support:**
   - Cache FAQ content
   - Queue issue reports when offline

---

## 📊 Accessibility

### Current Implementation
- **Content Descriptions:** All icons have proper descriptions
- **Touch Targets:** All clickable elements ≥ 48dp
- **Color Contrast:** Text meets WCAG AA standards
- **Font Scaling:** Uses SP units for all text
- **Scrollable Content:** All screens support vertical scrolling

### Recommendations
- Add TalkBack announcements for screen changes
- Support RTL layouts for international users
- Provide alternative text for all images
- Ensure form errors are announced by screen readers

---

## 🎭 Design Consistency

This Help & Support screen follows HEARTO's overall design language:

✅ **Material Design 3** principles  
✅ **Card-based** layout for grouped content  
✅ **Blue (#0D99FF)** as primary brand color  
✅ **White cards** on light blue background  
✅ **Sans-serif** font family throughout  
✅ **12dp corner radius** for modern look  
✅ **Elevation shadows** for depth perception  
✅ **Touch ripple effects** for interactivity  

---

## 📝 Testing Checklist

- [ ] All menu cards navigate to correct screens
- [ ] Back button returns to menu from all sub-screens
- [ ] Close buttons work on all sub-screens
- [ ] System back press handled correctly (menu vs exit)
- [ ] Email intent opens with correct recipient and subject
- [ ] Phone intent opens dialer with correct number
- [ ] Spinner shows hint as default selection
- [ ] Spinner headers are disabled and styled correctly
- [ ] Spinner arrow rotates smoothly on open/close
- [ ] Form validation works for category and description
- [ ] Image picker opens and handles multiple selection
- [ ] Thumbnail display updates correctly
- [ ] Delete button removes thumbnails and updates counter
- [ ] Max 3 images limit is enforced
- [ ] Submit button triggers validation and success flow
- [ ] Privacy policy text loads and displays correctly
- [ ] All FAQ cards are readable and formatted properly
- [ ] App Guide steps display in correct order
- [ ] Support hours card shows correct information
- [ ] All screens are scrollable with sufficient padding
- [ ] Ripple effects work on all interactive elements

---

**Document Version:** 1.0  
**Last Updated:** May 22, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

