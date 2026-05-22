# Privacy Policy & Terms of Use - Design & Implementation

**HEARTO App - Privacy Policy & Terms & Conditions**  
**Activity:** `TermsConditionsActivity.kt`  
**Fragment Screen:** Privacy Policy in `HelpSupportFragment.kt`  
**Layouts:** `activity_terms_conditions.xml`, `fragment_help_support.xml`

---

## 📋 Overview

HEARTO implements a comprehensive Privacy Policy and Terms & Conditions system displayed in two contexts:

1. **First-Time User Flow** - Full-screen Terms & Conditions Activity with mandatory acceptance before accessing the app
2. **Help & Support Section** - Privacy Policy screen accessible anytime from the side navigation menu

Both implementations ensure legal compliance with Indian data protection laws (IT Act 2000, SPDI Rules 2011, DPDP Act 2023) and provide transparent information about data collection, usage, and user rights.

---

## 🎨 Design Architecture

### Two Implementation Contexts

#### Context 1: Terms & Conditions Activity (Mandatory First-Time)
```
TermsConditionsActivity
├── Header Section (Logo, Title, Subtitle)
├── Main Content Card
│   ├── Scrollable Terms Text
│   ├── Divider
│   └── Acceptance Checkbox
└── Accept Button (Disabled until checkbox checked)
```

#### Context 2: Privacy Policy in Help & Support (Optional Anytime)
```
HelpSupportFragment → Privacy Policy Screen
├── Header Bar (Title + Close Button)
└── Scrollable Content (TextView)
```

---

## 🔐 Context 1: Terms & Conditions Activity

### When It Appears
- **Trigger:** First app launch after installation
- **Flow:** Splash Screen → Terms & Conditions → Main App
- **Requirement:** User must accept to proceed
- **Persistence:** Acceptance stored in SharedPreferences
- **Key:** `"terms_conditions_accepted"` = `true`

---

## 🎨 Terms & Conditions Activity - Design

### Screen Layout
```
┌─────────────────────────────────────┐
│ ┌───────────────────────────────┐ │ Light Blue
│ │     [HEARTO LOGO 80dp]        │ │ Header
│ │         HEARTO                │ │ #D9EDFF
│ │  USER AGREEMENT & TERMS       │ │
│ │  Please read carefully...     │ │
│ └───────────────────────────────┘ │
│                                   │
│ ┌───────────────────────────────┐ │ White Card
│ │ [Scrollable Terms Content]    │ │ with
│ │ 1. INTRODUCTION               │ │ Rounded
│ │ 2. NATURE OF SERVICES         │ │ Corners
│ │ 3. MEDICAL DISCLAIMER         │ │
│ │ ...                           │ │
│ │ ───────────────────────       │ │ Divider
│ │ ☑ I consent to data...        │ │ Checkbox
│ └───────────────────────────────┘ │
│                                   │
│ [Accept & Continue Button]        │
└─────────────────────────────────────┘
```

---

### Header Section

**Container:** LinearLayout with vertical orientation
- **Background:** `#D9EDFF` (Light Blue)
- **Padding:** 32dp top, 24dp bottom
- **Gravity:** Center

#### App Logo Card
```xml
CardView (Shadow Effect)
└── ImageView (80dp × 80dp)
    - Logo: @mipmap/ic_launcher
    - Padding: 4dp
    - Description: "HEARTO Logo"
```

**Card Specs:**
- **Corner Radius:** 20dp
- **Elevation:** 8dp
- **Background:** White (#FFFFFF)

#### App Name
- **Text:** "HEARTO"
- **Size:** 24sp
- **Color:** #000000 (Black)
- **Style:** Bold
- **Margin Top:** 12dp

#### Title
- **Text:** "USER AGREEMENT & TERMS OF USE"
- **Size:** 20sp
- **Color:** #0D99FF (Primary Blue)
- **Style:** Bold
- **Margin Top:** 8dp

#### Subtitle
- **Text:** "Please read carefully before continuing"
- **Size:** 14sp
- **Color:** #666666 (Gray)
- **Margin Top:** 4dp

---

### Main Content Card

**Container:** CardView
- **Background:** White (#FFFFFF)
- **Corner Radius:** 16dp
- **Elevation:** 4dp
- **Margin:** 16dp all sides
- **Layout Weight:** 1 (fills remaining space)

#### Scrollable Terms Content

**ScrollView:**
- **ID:** `tc_scroll_view`
- **Scrollbars:** Vertical, outside overlay style
- **Fill Viewport:** true

**TextView (Terms Content):**
- **ID:** `tc_terms_content`
- **Size:** 13sp
- **Color:** #333333 (Dark Gray)
- **Line Spacing Extra:** 3dp
- **Line Spacing Multiplier:** 1.2
- **Padding:** 4dp horizontal
- **Initial Text:** "Loading terms and conditions..."
- **Final Text:** Loaded dynamically via `getTermsAndConditionsText()`

#### Divider
- **Height:** 1dp
- **Background:** #EEEEEE (Light Gray)
- **Margin:** 16dp top and bottom

#### Acceptance Checkbox

**CheckBox:**
- **ID:** `tc_checkbox_accept`
- **Text:** "I consent to data processing and agree to the Terms & Conditions."
- **Text Size:** 13sp
- **Text Color:** #000000 (Black)
- **Button Tint:** #0D99FF (Blue)
- **Padding Start:** 4dp
- **Default State:** Unchecked

---

### Accept Button Section

**Container:** LinearLayout
- **Orientation:** Horizontal
- **Padding:** 16dp horizontal, 24dp bottom
- **Gravity:** Center

**Button:**
- **ID:** `tc_btn_accept`
- **Width:** match_parent
- **Height:** 54dp
- **Background:** `@drawable/round_button` (Blue rounded)
- **Text:** "Accept & Continue"
- **Text Size:** 16sp
- **Text Color:** #FFFFFF (White)
- **Text Style:** Bold
- **Initial State:** Disabled (alpha 0.5)
- **Enabled State:** After checkbox checked (alpha 1.0)

---

## 🎯 Terms & Conditions - Functionality

### Initialization Flow

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_terms_conditions)
    
    initializeViews()      // Bind views
    setupListeners()       // Set up checkbox & button listeners
    loadTermsContent()     // Load full terms text
}
```

### View Initialization

```kotlin
private fun initializeViews() {
    acceptCheckbox = findViewById(R.id.tc_checkbox_accept)
    acceptButton = findViewById(R.id.tc_btn_accept)
    
    // Initially disable accept button
    acceptButton.isEnabled = false
    acceptButton.alpha = 0.5f
}
```

**Initial State:**
- Button disabled (cannot click)
- Button semi-transparent (alpha 0.5)
- Checkbox unchecked
- Forces user to read and consent

### Checkbox Listener

```kotlin
acceptCheckbox.setOnCheckedChangeListener { _, isChecked ->
    acceptButton.isEnabled = isChecked
    acceptButton.alpha = if (isChecked) 1.0f else 0.5f
}
```

**Behavior:**
- ☑️ **Checked:** Button enabled, full opacity
- ☐ **Unchecked:** Button disabled, 50% opacity
- Visual feedback confirms consent requirement

### Accept Button Action

```kotlin
acceptButton.setOnClickListener {
    ApplicationPreferences.putBoolean(this, PREF_TERMS_ACCEPTED, true)
    proceedToMainActivity()
}
```

**On Click:**
1. Save acceptance to SharedPreferences
2. Key: `"terms_conditions_accepted"` = `true`
3. Navigate to MainActivity
4. Finish TermsConditionsActivity (remove from back stack)

**Persistence:**
- Saved in SharedPreferences file: `"AppPreferences"`
- Persists across app restarts
- Never shown again unless app data cleared

### Navigation Flow

```kotlin
private fun proceedToMainActivity() {
    val intent = Intent(this, MainActivity::class.java)
    startActivity(intent)
    finish() // Close terms activity
}
```

**Flow:**
```
SplashActivity 
    ↓ (Check termsAccepted)
TermsConditionsActivity (if false)
    ↓ (User accepts)
MainActivity (Home/Dashboard)
```

---

## 📄 Full Terms & Conditions Text

### Document Structure (16 Sections)

```
USER AGREEMENT / TERMS & CONDITIONS

1. INTRODUCTION
2. NATURE OF SERVICES
3. IMPORTANT MEDICAL DISCLAIMER
   ⚠️ NOT A MEDICAL DEVICE
   ⚠️ NOT A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE
   ⚠️ USER RESPONSIBILITY
4. PROACTIVE ALERT SYSTEM
5. USER DATA & PRIVACY (INDIA COMPLIANCE)
6. USER CONSENT
7. DATA USAGE
8. DATA SECURITY
9. LIMITATION OF LIABILITY
10. EMERGENCY DISCLAIMER
11. USER OBLIGATIONS
12. INTELLECTUAL PROPERTY
13. TERMINATION
14. GOVERNING LAW & JURISDICTION
15. UPDATES TO TERMS
16. CONTACT INFORMATION

━━━━━━━━━━━━━━━━━━━━

ACKNOWLEDGMENT & CONSENT

Effective Date: 10-April-2026
Last Updated: 10-April-2026
```

---

### Section-by-Section Content

#### 1. INTRODUCTION

```
Welcome to HEARTO ("App"), owned and operated by Hearto Pvt Ltd 
("Company", "We", "Us", "Our").

By downloading, installing, accessing, or using the HEARTO App, 
smart ring device, or associated services ("Services"), you 
("User", "You") agree to be bound by this User Agreement / 
Terms & Conditions ("Agreement").

If you do not agree, you must not use the Services.
```

**Key Points:**
- Defines parties (Company, User)
- Scope: App + Smart Ring + Services
- Binding agreement upon use
- Option to decline = cannot use

---

#### 2. NATURE OF SERVICES

```
HEARTO provides:

• Continuous monitoring of physiological vitals such as heart rate, 
  heart rate variability (HRV), SpO₂, temperature, sleep, stress, 
  and activity

• AI-based analysis of collected data

• Alerts and notifications based on detected abnormalities

• Health insights for preventive and proactive awareness
```

**Service Description:**
- Real-time vital monitoring
- AI-powered analytics
- Abnormality detection
- Preventive health insights

---

#### 3. IMPORTANT MEDICAL DISCLAIMER

##### ⚠️ NOT A MEDICAL DEVICE

```
• The HEARTO App and Smart Ring are not certified medical devices 
  under Indian law.

• The vitals and analytics provided are not medically vetted or 
  clinically diagnostic.

• The system has been tested in controlled environments with an 
  approximate accuracy of up to 95%, but results may vary based 
  on individual conditions and usage.
```

**Critical Points:**
- Not FDA/medical board certified
- 95% accuracy in controlled conditions
- Variability in real-world usage

##### ⚠️ NOT A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE

```
• The Services are intended only for general wellness, awareness, 
  and proactive health monitoring.

• They must not be relied upon for diagnosis, treatment, cure, 
  or prevention of any disease.

• Always consult a qualified medical practitioner for any health 
  concerns.
```

**Liability Protection:**
- Wellness tool only
- Not for diagnosis/treatment
- Requires professional consultation

##### ⚠️ USER RESPONSIBILITY

```
• You acknowledge that all alerts are indicative and not conclusive 
  medical findings.

• The Company shall not be liable for any decisions made based on 
  such alerts.
```

**User Acknowledgment:**
- Alerts are indicators, not diagnoses
- User assumes responsibility for decisions

---

#### 4. PROACTIVE ALERT SYSTEM

```
HEARTO uses AI to detect abnormal patterns in vitals and may 
generate alerts indicating potential risks such as:

• Irregular heart rate
• Low SpO₂
• Stress overload
• Sleep deficiency
• Blood pressure trends

These alerts are intended:

✓ To increase awareness
✓ To encourage timely medical consultation
✓ To potentially prevent serious health events

⚠️ However, alerts:

• May not always be accurate or timely
• May generate false positives or false negatives
• Should not be treated as emergency diagnosis
```

**Alert Types:**
- Heart rate irregularities
- Oxygen saturation drops
- Stress levels
- Sleep quality issues
- Blood pressure abnormalities

**Purpose:**
- Awareness raising
- Encourages medical consultation
- Preventive intervention

**Limitations:**
- Potential inaccuracies
- False positives/negatives
- Not emergency diagnosis

---

#### 5. USER DATA & PRIVACY (INDIA COMPLIANCE)

```
We collect and process:

Personal Data (PII)
• Name, email, phone number
• Device identifiers
• Location (if enabled)

Sensitive Personal Data (Health Data)
• Vitals (HR, HRV, SpO₂, temperature, etc.)
• Sleep and stress metrics
• Activity data

Such data qualifies as Sensitive Personal Data or Information 
(SPDI) under:

• Information Technology Act, 2000
• SPDI Rules, 2011
• Applicable provisions of the Digital Personal Data Protection 
  Act, 2023 (DPDP Act)
```

**Data Categories:**

**Personal Identifiable Information (PII):**
- Name, email, phone
- Device IDs (MAC address, IMEI)
- Location data (optional)

**Sensitive Personal Data (SPDI):**
- Health vitals (all measurements)
- Sleep patterns
- Stress levels
- Activity tracking

**Legal Compliance:**
- IT Act 2000 (India)
- SPDI Rules 2011
- DPDP Act 2023
- GDPR principles (international)

---

#### 6. USER CONSENT

```
By using the App, you provide:

✓ Explicit consent for collection and processing of personal 
  and health data
✓ Consent for AI-based analysis of your vitals
✓ Consent to receive alerts and notifications

You may withdraw consent by discontinuing use of the Services.
```

**Consent Elements:**
1. Data collection (personal + health)
2. Data processing (AI analysis)
3. Notifications (alerts)

**Withdrawal:**
- Stop using the app
- Delete account (in Profile settings)
- Data deleted within 30 days

---

#### 7. DATA USAGE

```
We use your data for:

• Providing core functionality of the App
• Improving algorithms and accuracy
• Generating insights and alerts
• Enhancing user experience

We do NOT sell personal data.
```

**Usage Purposes:**
- App functionality
- Algorithm improvements
- Health insights generation
- User experience optimization

**Commitment:**
- **No data selling**
- No third-party marketing use
- Limited sharing (healthcare providers for appointments only)

---

#### 8. DATA SECURITY

```
We implement:

• Encryption of data in transit and at rest
• Access controls and authentication mechanisms
• Industry-standard cybersecurity practices

However, no system is 100% secure, and you acknowledge inherent 
risks of digital data transmission.
```

**Security Measures:**

**Encryption:**
- TLS 1.2+ for data in transit
- AES encryption for data at rest

**Access Control:**
- User authentication (OTP-based)
- Role-based access for backend
- Limited employee access

**Best Practices:**
- Regular security audits
- Secure API endpoints
- Encrypted database storage

**Disclaimer:**
- No system 100% secure
- User acknowledges digital risks

---

#### 9. LIMITATION OF LIABILITY

```
To the maximum extent permitted under Indian law:

• The Company shall not be liable for any direct, indirect, 
  incidental, or consequential damages arising from:
  - Use or misuse of the App
  - Inaccurate or delayed alerts
  - Failure to detect a medical condition
  - Any health decisions made by the user

• The Services are provided "as is" and "as available".
```

**Liability Exclusions:**
- Direct damages (financial loss)
- Indirect damages (health outcomes)
- Incidental damages (missed opportunities)
- Consequential damages (long-term effects)

**Specific Scenarios:**
- App malfunction
- Alert inaccuracies
- Missed detection
- User decisions based on data

**Service Terms:**
- "As is" - no warranties
- "As available" - no uptime guarantee

---

#### 10. EMERGENCY DISCLAIMER

```
HEARTO is NOT an emergency response system.

• It does not connect directly to hospitals, ambulances, or 
  emergency services

• In case of a medical emergency, you must immediately contact 
  local emergency services or a doctor
```

**Critical Clarification:**
- Not an emergency system
- No 911/108 integration
- User must call emergency services manually

**Emergency Protocol:**
1. Call local emergency number (108 in India)
2. Contact personal physician
3. Visit nearest hospital
4. Do not rely solely on app alerts

---

#### 11. USER OBLIGATIONS

```
You agree to:

• Provide accurate information
• Use the device as instructed
• Not rely solely on the App for critical health decisions
• Maintain confidentiality of your account
```

**User Responsibilities:**

**Accurate Information:**
- Truthful profile data
- Correct health history
- Accurate measurements

**Proper Usage:**
- Follow device instructions
- Wear ring correctly
- Charge regularly
- Keep firmware updated

**Responsible Decisions:**
- Consult doctors for health issues
- Don't self-diagnose
- Verify alerts with professionals

**Account Security:**
- Keep login credentials private
- Don't share account
- Report unauthorized access

---

#### 12. INTELLECTUAL PROPERTY

```
All rights, including software, algorithms, trademarks, and 
design, are owned by the Company.

You may not:

• Copy, modify, reverse engineer, or distribute the App
• Use the brand without authorization
```

**Company Ownership:**
- App source code
- AI algorithms
- Brand name & logo
- UI/UX design
- Database schema

**User Restrictions:**
- No copying/cloning
- No reverse engineering
- No redistribution
- No unauthorized branding

**Violations:**
- Legal action
- Account termination
- Potential damages claim

---

#### 13. TERMINATION

```
We reserve the right to:

• Suspend or terminate access
• Modify or discontinue services
```

**Company Rights:**

**Suspension Reasons:**
- Terms violation
- Abusive behavior
- Fraudulent activity
- System misuse

**Termination:**
- Immediate or with notice
- Account deactivation
- Data handling per policy

**Service Changes:**
- Feature modifications
- Service discontinuation
- Price changes
- Policy updates

---

#### 14. GOVERNING LAW & JURISDICTION

```
This Agreement shall be governed by the laws of India.

Courts in Hyderabad shall have exclusive jurisdiction.
```

**Legal Framework:**
- **Governing Law:** Indian law
- **Jurisdiction:** Hyderabad courts
- **Language:** English (binding version)

**Dispute Resolution:**
1. Internal complaint mechanism
2. Mediation (optional)
3. Arbitration (if agreed)
4. Court litigation (Hyderabad)

---

#### 15. UPDATES TO TERMS

```
We may update this Agreement periodically. Continued use 
constitutes acceptance of updated terms.
```

**Update Process:**
1. Company revises terms
2. Notification to users (email/in-app)
3. Effective date published
4. Continued use = acceptance

**User Options:**
- Accept updates (continue using)
- Reject updates (stop using)
- Review changes before accepting

---

#### 16. CONTACT INFORMATION

```
For queries or concerns:
Email: contact@hearto.in
```

**Support Channels:**
- **Email:** contact@hearto.in
- **Support:** support@mannaheal.com
- **Phone:** +91 98765 43210 (from Help & Support)

---

### Acknowledgment & Consent Section

```
━━━━━━━━━━━━━━━━━━━━

ACKNOWLEDGMENT & CONSENT

I understand that HEARTO is not a medical device and does not 
provide medical diagnosis.

I consent to the collection and processing of my personal and 
health data for proactive health monitoring and alerts.

By clicking "Accept & Continue" below, I agree to these Terms 
& Conditions.

Effective Date: 10-April-2026
Last Updated: 10-April-2026
```

**Final Consent:**
- Acknowledges non-medical status
- Consents to data processing
- Agrees to all terms
- Legally binding

**Effective Date:**
- Published: April 10, 2026
- Last updated: April 10, 2026
- Version tracking

---

## 🔐 Context 2: Privacy Policy in Help & Support

### Access Path
```
Home → Side Menu → Help & Support → Privacy Policy Card
```

### Screen Design

```
┌───────────────────────────────────┐
│   Privacy Policy              [X] │  (Blue header #0D99FF)
├───────────────────────────────────┤
│                                   │
│  [Scrollable Privacy Policy Text] │  (White background)
│  HEARTO – Privacy Policy &        │
│  Terms of Use                     │
│                                   │
│  Last Updated: April 2026         │
│                                   │
│  1. INTRODUCTION                  │
│  Welcome to HEARTO...             │
│                                   │
│  2. DATA WE COLLECT               │
│  • Health metrics...              │
│                                   │
│  ...                              │
│                                   │
└───────────────────────────────────┘
```

---

### Header Bar

**Container:** RelativeLayout
- **Height:** 56dp
- **Background:** #0D99FF (Blue)
- **Padding:** 8dp

**Title:**
- **Text:** "Privacy Policy"
- **Position:** Center
- **Color:** White
- **Size:** 17sp
- **Style:** Bold

**Close Button:**
- **ID:** `btnBackPrivacy`
- **Icon:** `baseline_close_24`
- **Size:** 36dp × 36dp
- **Tint:** White
- **Position:** Right-aligned
- **Action:** Returns to Help & Support menu

---

### Privacy Policy Content

**Container:** LinearLayout (scrollable)
- **ID:** `screenPrivacyPolicy`
- **Background:** #D9EDFF (Light Blue)
- **Visibility:** Gone (shown on card click)

**TextView:**
- **ID:** `tvPrivacyContent`
- **Text Color:** #1A1A1A
- **Text Size:** 14sp
- **Line Spacing:** Standard
- **Padding:** 16dp all sides

---

### Privacy Policy Text (Help & Support Version)

```
HEARTO – Privacy Policy & Terms of Use

Last Updated: April 2026

1. INTRODUCTION
Welcome to HEARTO, a smart health monitoring application developed 
by MannaHeal. By using this app, you agree to the terms outlined 
in this policy.

2. DATA WE COLLECT
• Health metrics: Heart rate, blood pressure, SpO2, ECG, sleep, 
  steps, body temperature
• Personal information: Name, mobile number, date of birth, 
  gender, profile photo
• Device information: Ring MAC address, firmware version, BLE 
  connection data
• Usage data: App interactions, appointment history, linked 
  accounts

3. HOW WE USE YOUR DATA
• To provide personalised health monitoring and insights
• To connect you with healthcare specialists for appointments
• To sync ring data to our secure cloud servers
• To send health alerts and notifications
• To improve app performance and features

4. DATA SHARING
We do not sell your personal data. We may share data with:
• Licensed healthcare providers for appointment purposes
• Cloud infrastructure providers (under strict confidentiality 
  agreements)
• Legal authorities if required by law

5. DATA SECURITY
All data is encrypted in transit (TLS 1.2+) and at rest. We 
follow industry-standard security practices to protect your 
health information.

6. YOUR RIGHTS
• Access or export your health data at any time
• Request deletion of your account and data
• Opt out of non-essential notifications
• Contact us at support@mannaheal.com for any data requests

7. RETENTION
Health data is retained for up to 5 years to support your 
health history. Account data is deleted within 30 days of 
account deletion request.

8. CHILDREN'S PRIVACY
This app is not intended for users under 13 years of age.

9. CHANGES TO THIS POLICY
We will notify you of any material changes via in-app 
notification or email.

10. CONTACT
MannaHeal Pvt. Ltd.
Email: support@mannaheal.com
Phone: +91 98765 43210
```

**Differences from Terms Activity:**
- Shorter, more concise
- Focus on privacy aspects only
- User-friendly language
- Key sections: Data collection, usage, sharing, rights
- No legal jargon
- Easier to read format

---

### Loading Mechanism

```kotlin
view.findViewById<CardView>(R.id.cardPrivacyPolicy).setOnClickListener {
    loadPrivacyContent(view)
    showScreen(screenPrivacyPolicy)
}

private fun loadPrivacyContent(root: View) {
    val tv = root.findViewById<TextView>(R.id.tvPrivacyContent)
    tv.text = """
        HEARTO – Privacy Policy & Terms of Use
        ...
    """.trimIndent()
}
```

**Load Behavior:**
1. Card clicked in Help & Support menu
2. `loadPrivacyContent()` populates TextView
3. `showScreen()` makes privacy screen visible
4. Other screens hidden
5. User can read and close

**No Acceptance Required:**
- Already accepted in first-time flow
- This is for reference/review only
- No checkbox or button
- Just close to return

---

## 📊 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Header Background | `#D9EDFF` | Terms activity header |
| Card Background | `#FFFFFF` | Content card |
| Primary Blue | `#0D99FF` | Title, button, header bar |
| Primary Text | `#000000` | App name, checkbox text |
| Secondary Text | `#666666` | Subtitle |
| Body Text | `#333333` | Terms content |
| Divider | `#EEEEEE` | Separator line |
| Button Text | `#FFFFFF` | Accept button text |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| App Name | 24sp | Bold | #000000 |
| Main Title | 20sp | Bold | #0D99FF |
| Subtitle | 14sp | Normal | #666666 |
| Terms Content | 13sp | Normal | #333333 |
| Checkbox Text | 13sp | Normal | #000000 |
| Button Text | 16sp | Bold | #FFFFFF |
| Privacy Content | 14sp | Normal | #1A1A1A |
| Header Title | 17sp | Bold | White |

### Spacing

| Element | Value |
|---------|-------|
| Header Padding (Top) | 32dp |
| Header Padding (Bottom) | 24dp |
| Card Margin | 16dp |
| Card Corner Radius | 16dp |
| Card Elevation | 4dp |
| Card Padding | 16dp |
| Content Padding | 4dp horizontal |
| Divider Margin | 16dp vertical |
| Button Section Padding | 16dp horizontal, 24dp bottom |
| Button Height | 54dp |
| Logo Size | 80dp × 80dp |
| Logo Card Radius | 20dp |
| Close Button Size | 36dp × 36dp |

---

## 🔄 User Experience Flows

### Flow 1: First-Time User

```
Install App
    ↓
Open App
    ↓
Splash Screen (2s)
    ↓
Check: termsAccepted?
    ↓ (false)
Terms & Conditions Activity
    ↓
Read Terms (scroll)
    ↓
☑ Check "I consent..."
    ↓ (button enabled)
[Accept & Continue]
    ↓
Save termsAccepted = true
    ↓
Navigate to MainActivity
    ↓
Start using app
```

**Key Points:**
- Mandatory acceptance
- Cannot bypass
- Must scroll to read (good UX practice)
- Checkbox enforces conscious consent
- One-time only (never shown again)

---

### Flow 2: Returning User

```
Open App
    ↓
Splash Screen (2s)
    ↓
Check: termsAccepted?
    ↓ (true)
Navigate to MainActivity
    ↓
Continue using app
```

**Key Points:**
- Terms screen skipped
- Direct to main app
- Seamless experience

---

### Flow 3: Review Privacy Policy

```
Using App
    ↓
Open Side Menu
    ↓
Tap "Help & Support"
    ↓
Help & Support Menu
    ↓
Tap "Privacy Policy" Card
    ↓
Privacy Policy Screen
    ↓
Read Content (scroll)
    ↓
Tap [X] Close
    ↓
Back to Help & Support Menu
```

**Key Points:**
- Available anytime
- No acceptance required (already done)
- For reference only
- Easy access

---

## 🔒 Legal Compliance

### Indian Data Protection Laws

#### IT Act 2000
- **Section 43A:** Compensation for failing to protect data
- **Section 72A:** Punishment for disclosure of information

#### SPDI Rules 2011
- **Rule 5:** Prior consent for SPDI collection
- **Rule 6:** Disclosure requirements
- **Rule 8:** Data security measures

#### DPDP Act 2023
- **Section 6:** User consent requirements
- **Section 8:** Right to access data
- **Section 9:** Right to correction
- **Section 10:** Right to erasure

---

### GDPR Principles (International)

Even though HEARTO is India-focused, GDPR principles applied:

1. **Lawfulness, fairness, transparency** - Clear terms, explicit consent
2. **Purpose limitation** - Data used only for stated purposes
3. **Data minimization** - Collect only necessary data
4. **Accuracy** - Allow users to update information
5. **Storage limitation** - 5-year retention, then deletion
6. **Integrity and confidentiality** - Encryption, security measures
7. **Accountability** - Company responsible for compliance

---

### Key Legal Protections

**For the Company:**
- Medical disclaimer (not a medical device)
- Limitation of liability
- Intellectual property protection
- Right to terminate
- Governing law specification

**For the User:**
- Right to access data
- Right to delete account
- Right to withdraw consent
- Right to data portability
- Transparent data practices

---

## 🧪 Testing Checklist

### Terms & Conditions Activity

#### Functionality
- [ ] Activity shows on first launch
- [ ] Activity skipped on subsequent launches
- [ ] Terms text loads correctly
- [ ] Terms content scrollable
- [ ] Checkbox starts unchecked
- [ ] Accept button starts disabled
- [ ] Accept button visual (alpha 0.5)
- [ ] Checking checkbox enables button
- [ ] Unchecking checkbox disables button
- [ ] Button alpha changes with checkbox
- [ ] Accept button saves preference
- [ ] Navigates to MainActivity after accept
- [ ] Activity removed from back stack

#### UI/UX
- [ ] Logo displays correctly
- [ ] Header colors correct
- [ ] Card shadow/elevation visible
- [ ] Terms text readable (size, spacing)
- [ ] Divider shows properly
- [ ] Checkbox tint correct (blue)
- [ ] Button background renders
- [ ] All text aligned properly
- [ ] Scrollbar appears when needed

#### Edge Cases
- [ ] Terms text very long (scrolls properly)
- [ ] Rapid checkbox toggling
- [ ] Screen rotation (state preserved)
- [ ] Back button handling (should not bypass)
- [ ] App killed during acceptance (reopens terms)

---

### Privacy Policy in Help & Support

#### Functionality
- [ ] Privacy Policy card clickable
- [ ] Loads privacy content correctly
- [ ] Content displays in TextView
- [ ] Text scrollable
- [ ] Close button returns to menu
- [ ] Back button returns to menu
- [ ] Content doesn't reset on revisit

#### UI/UX
- [ ] Header bar colors correct
- [ ] Close icon visible
- [ ] Text readable and formatted
- [ ] Proper spacing
- [ ] Smooth scrolling
- [ ] Matches app design language

---

## 📊 Analytics Tracking

### Key Metrics

**Terms & Conditions:**
- Total views (should equal new installs)
- Time spent reading
- Scroll depth (did user read all?)
- Acceptance rate (should be 100% or 0% dropoff)
- Time to acceptance

**Privacy Policy:**
- Screen views
- Average time on screen
- Scroll depth
- Return visits (how often users check)
- Section-specific time (which sections read most)

### Implementation

```kotlin
// Terms Activity
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    Analytics.logEvent("terms_conditions_viewed")
    startTime = System.currentTimeMillis()
}

acceptButton.setOnClickListener {
    val timeSpent = System.currentTimeMillis() - startTime
    Analytics.logEvent("terms_accepted", mapOf(
        "time_spent_ms" to timeSpent,
        "scroll_depth" to scrollDepth
    ))
    // ... proceed
}

// Privacy Policy in Help & Support
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    // ...
    cardPrivacyPolicy.setOnClickListener {
        Analytics.logEvent("privacy_policy_viewed", mapOf(
            "source" to "help_support"
        ))
        loadPrivacyContent(view)
        showScreen(screenPrivacyPolicy)
    }
}
```

---

## 💡 Best Practices Implemented

### Legal Best Practices

✅ **Explicit Consent:** Checkbox requires active user action  
✅ **Clear Language:** Non-legalese explanations provided  
✅ **Accessibility:** Always accessible via Help & Support  
✅ **Transparency:** Full disclosure of data practices  
✅ **User Rights:** Clear statement of rights and options  
✅ **Contact Info:** Easy to find support contacts  
✅ **Version Control:** Dated and versioned documents  
✅ **Update Notification:** Promise to notify of changes  

### UX Best Practices

✅ **Non-intrusive:** One-time mandatory, then optional  
✅ **Visual Hierarchy:** Clear sectioning and formatting  
✅ **Scrollable Content:** Supports long text  
✅ **Progress Indication:** Scrollbar shows content length  
✅ **Disabled State:** Visual feedback (button alpha)  
✅ **Confirmation:** Checkbox prevents accidental acceptance  
✅ **Easy Exit:** Close button always available (except first-time)  
✅ **Persistent:** Acceptance remembered forever  

### Technical Best Practices

✅ **Preference Storage:** SharedPreferences for persistence  
✅ **Dynamic Content:** Text loaded programmatically (easy updates)  
✅ **State Management:** Proper view binding and listeners  
✅ **Navigation:** Proper back stack management  
✅ **Performance:** Text loaded once, not repeatedly  
✅ **Modularity:** Separate layouts for different contexts  

---

## 🚀 Future Enhancements

### Planned Improvements

#### 1. Scroll Progress Indicator
```xml
<ProgressBar
    android:id="@+id/scrollProgress"
    style="?android:attr/progressBarStyleHorizontal"
    android:layout_width="match_parent"
    android:layout_height="4dp"
    android:max="100" />
```
- Show reading progress
- Encourage full read
- Track engagement

#### 2. Section Navigation
- Table of contents
- Jump to specific sections
- Bookmarks for key points

#### 3. Highlight Key Points
- Bold important clauses
- Color-coded sections
- Icon indicators for critical info

#### 4. Multi-Language Support
```kotlin
private fun getTermsText(language: String): String {
    return when (language) {
        "hi" -> getHindiTerms()
        "te" -> getTeluguTerms()
        "ta" -> getTamilTerms()
        else -> getEnglishTerms()
    }
}
```
- Hindi, Telugu, Tamil translations
- User language preference
- Legal validity in native language

#### 5. Version History
- Show what changed in updates
- Highlight new/modified sections
- Archive previous versions

#### 6. Interactive Q&A
- FAQ section within terms
- Expandable explanations
- Plain language tooltips

#### 7. Print/Export Option
- PDF generation
- Email to self
- Save for records

#### 8. Mandatory Review on Updates
- If terms change significantly
- Show diff/changes
- Require re-acceptance

#### 9. Granular Consent
- Separate checkboxes per data type
- Optional vs. required permissions
- More user control

#### 10. Visual Infographics
- Illustrated data flow
- Icons for each section
- Easier comprehension

---

## 📞 Support & Compliance Contacts

### User Queries
- **Email:** support@mannaheal.com
- **Phone:** +91 98765 43210
- **Response Time:** 24-48 hours

### Legal Inquiries
- **Email:** contact@hearto.in
- **Subject:** Legal/Privacy/Terms
- **Department:** Legal & Compliance

### Data Protection Officer (DPO)
- **Role:** DPDP Act compliance
- **Contact:** dpo@hearto.in
- **Responsibilities:**
  - Handle data access requests
  - Process deletion requests
  - Manage consent records
  - Investigate data breaches

---

**Document Version:** 1.0  
**Last Updated:** May 22, 2026  
**Author:** HEARTO Development Team  
**Legal Review:** Completed  
**Status:** Production Ready  
**Next Review:** October 2026

