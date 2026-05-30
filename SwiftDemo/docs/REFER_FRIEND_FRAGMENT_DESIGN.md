# Refer a Friend Fragment - Design & Implementation

**HEARTO App - Refer & Earn Screen**  
**Fragment:** `ReferToFriendFragment.kt`  
**Layout:** `fragment_refer_to_friend.xml`

---

## 📋 Overview

The Refer a Friend screen is a single-page promotional interface that encourages users to invite friends and family to HEARTO. It features a referral code display with copy functionality, a step-by-step explanation of the referral program, and multiple sharing options via social media and messaging platforms. Both the referrer and referee receive a 20% discount on their first treatment.

---

## 🎨 Design Architecture

### Screen Structure
```
ScrollView (Full Height)
└── LinearLayout (Vertical)
    ├── Page Header (Title + Subtitle)
    ├── Referral Code Card
    ├── How It Works Card (3 Steps)
    ├── Share Via Card (4 Platform Buttons)
    └── Share Invite Button (Full Width)
```

### Visual Layout
- **Background Color:** `#D9EDFF` (Light Blue)
- **Container:** Scrollable with vertical orientation
- **Padding:** 16dp horizontal, 20dp top, 32dp bottom
- **Card Style:** White cards with rounded corners and elevation

---

## 📄 Page Header

### Title Section
```
┌─────────────────────────────────────┐
│         Refer & Earn                │  (22sp, Bold, Centered)
│  Invite friends to HEARTO and       │  (13sp, Gray)
│  both of you get 20% off on your    │
│  first treatment                    │
└─────────────────────────────────────┘
```

**Title Styling:**
- **Text:** "Refer & Earn"
- **Size:** 22sp
- **Color:** #1A1A1A (Dark Gray)
- **Font:** sans-serif, Bold
- **Alignment:** Center
- **Margin Bottom:** 4dp

**Subtitle Styling:**
- **Text:** "Invite friends to HEARTO and both of you get 20% off on your first treatment"
- **Size:** 13sp
- **Color:** #444444 (Medium Gray)
- **Font:** sans-serif, Normal
- **Alignment:** Center
- **Line Spacing:** +3dp extra
- **Margin Bottom:** 20dp

---

## 💳 Referral Code Card

### Card Design
```
┌───────────────────────────────────────────┐
│  Your Referral Code                       │  (13sp, Bold)
│                                           │
│  ┌─────────────────────────────────────┐ │
│  │  HEARTO20          [Copy] Button    │ │  (Code + Action)
│  └─────────────────────────────────────┘ │
└───────────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp

### Label
- **Text:** "Your Referral Code"
- **Size:** 13sp
- **Color:** #1A1A1A
- **Font:** sans-serif, Bold
- **Margin Bottom:** 12dp

### Code Display Container
**Background:** Custom drawable `@drawable/bg_referral_code`
- Likely a light background with border/shadow
- **Padding:** 14dp all sides
- **Layout:** Horizontal orientation

### Referral Code Text
```xml
HEARTO20
```
- **ID:** `tvReferralCode`
- **Size:** 22sp
- **Color:** #0D99FF (Primary Blue)
- **Font:** sans-serif, Bold
- **Letter Spacing:** 0.15
- **Width:** 0dp with weight=1 (takes available space)
- **Value:** Hardcoded as "HEARTO20"

### Copy Button
```
┌──────────┐
│ [📄] Copy│  (Icon + Text)
└──────────┘
```
- **ID:** `btnCopyCode`
- **Background:** Blue rounded button (`@drawable/round_button`)
- **Padding:** 14dp horizontal, 8dp vertical
- **Layout:** Horizontal LinearLayout

**Icon:**
- **Drawable:** `baseline_content_copy_24`
- **Size:** 15dp × 15dp
- **Tint:** #1A1A1A (Dark Gray/Black)
- **Margin End:** 5dp

**Text:**
- **Label:** "Copy"
- **Size:** 13sp
- **Color:** #1A1A1A
- **Font:** sans-serif, Bold

**Action:**
- Copies `HEARTO20` to clipboard
- Shows toast: "Code copied to clipboard!"
- Uses `ClipboardManager` service

---

## 📚 How It Works Card

### Card Design
```
┌───────────────────────────────────────────┐
│  How It Works                             │  (13sp, Bold)
│                                           │
│  [1] Share your code                     │
│      Send your referral code to          │
│      friends & family                    │
│                                           │
│  [2] Friend signs up                     │
│      They register on HEARTO using       │
│      your code                           │
│                                           │
│  [3] Both get rewarded                   │
│      You both enjoy 20% off your         │
│      first treatment                     │
└───────────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp

### Section Label
- **Text:** "How It Works"
- **Size:** 13sp
- **Color:** #1A1A1A
- **Font:** sans-serif, Bold
- **Margin Bottom:** 16dp

### Step Design Pattern

Each step follows this structure:

```xml
┌────────────────────────────────────┐
│  [#]  Step Title                   │  (Number badge + Title)
│       Step description             │  (Gray subtitle)
└────────────────────────────────────┘
```

**Layout:** Horizontal LinearLayout
- **Gravity:** center_vertical
- **Margin Bottom:** 14dp (except last step)

**Number Badge:**
- **Container:** FrameLayout 40dp × 40dp
- **Background:** Colored circle (varies per step)
- **Text:** Step number (1, 2, 3)
- **Text Size:** 15sp, Bold
- **Text Color:** Matches background color theme
- **Margin End:** 14dp

**Content Container:**
- **Layout:** Vertical LinearLayout with weight=1
- **Title:** 13sp, Bold, #1A1A1A
- **Description:** 12sp, Normal, #777777
- **Description Margin Top:** 2dp

### Step 1: Share your code

**Badge:**
- **Background:** `@drawable/icon_bg_light_indigo`
- **Text Color:** #536DFE (Indigo)

**Content:**
- **Title:** "Share your code"
- **Description:** "Send your referral code to friends & family"

### Step 2: Friend signs up

**Badge:**
- **Background:** `@drawable/icon_bg_light_green`
- **Text Color:** #4CAF50 (Green)

**Content:**
- **Title:** "Friend signs up"
- **Description:** "They register on HEARTO using your code"

### Step 3: Both get rewarded

**Badge:**
- **Background:** `@drawable/icon_bg_light_amber`
- **Text Color:** #FFA000 (Amber/Orange)

**Content:**
- **Title:** "Both get rewarded"
- **Description:** "You both enjoy 20% off your first treatment"

---

## 📱 Share Via Card

### Card Design
```
┌─────────────────────────────────────────────┐
│  Share via                                  │  (13sp, Bold)
│                                             │
│  ┌─────────┬─────────┬─────────┬─────────┐ │
│  │WhatsApp │   SMS   │Facebook │  More   │ │
│  │  [📱]   │  [💬]   │  [👥]   │  [📤]   │ │
│  └─────────┴─────────┴─────────┴─────────┘ │
└─────────────────────────────────────────────┘
```

**Card Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 14dp
- **Elevation:** 3dp
- **Padding:** 16dp
- **Margin Bottom:** 16dp

### Section Label
- **Text:** "Share via"
- **Size:** 13sp
- **Color:** #1A1A1A
- **Font:** sans-serif, Bold
- **Margin Bottom:** 14dp

### Button Grid Layout

**Container:** Horizontal LinearLayout
- **Orientation:** Horizontal
- **Weight Distribution:** Equal (each button = 0dp width, weight=1)

### Platform Button Design

Each button follows this structure:

```xml
┌──────────────┐
│   [Icon]     │  (28dp × 28dp)
│   Platform   │  (11sp text)
└──────────────┘
```

**Common Specs:**
- **Layout:** Vertical LinearLayout
- **Width:** 0dp with weight=1
- **Background:** `@drawable/input_box_background_shadow` (White with shadow)
- **Padding:** 10dp all sides
- **Gravity:** center
- **Margin End:** 8dp (except last button)

**Icon:**
- **Size:** 28dp × 28dp
- **Margin Bottom:** 5dp

**Label:**
- **Size:** 11sp
- **Color:** #1A1A1A
- **Font:** sans-serif

### 1. WhatsApp Button

**ID:** `btnShareWhatsapp`

**Icon:**
- **Drawable:** `@drawable/whatsapp` (WhatsApp brand icon)
- **Description:** "whatsapp"

**Label:** "WhatsApp"

**Action:**
- Opens WhatsApp with referral message
- Intent type: `ACTION_SEND`
- Package: `com.whatsapp`
- Fallback: Opens system share sheet if WhatsApp not installed

### 2. SMS Button

**ID:** `btnShareSms`

**Icon:**
- **Drawable:** `baseline_message_24`
- **Tint:** #0D99FF (Blue)
- **Description:** "sms"

**Label:** "SMS"

**Action:**
- Opens SMS composer
- Intent type: `ACTION_VIEW`
- URI: `sms:`
- Pre-fills message body with referral text

### 3. Facebook Button

**ID:** `btnShareFacebook`

**Icon:**
- **Drawable:** `@drawable/facebook` (Facebook brand icon)
- **Description:** "facebook"

**Label:** "Facebook"

**Action:**
- Opens Facebook app with referral message
- Intent type: `ACTION_SEND`
- Package: `com.facebook.katana`
- Fallback: Opens system share sheet if Facebook not installed

### 4. More Button

**ID:** `btnShareMore`

**Icon:**
- **Drawable:** `baseline_share_24`
- **Tint:** #555555 (Gray)
- **Description:** "more"

**Label:** "More"

**Action:**
- Opens system share sheet
- Allows sharing via any installed app
- Intent type: `ACTION_SEND` with `createChooser`

---

## 🔘 Share Invite Button

### Full Width Action Button
```
┌─────────────────────────────────────┐
│      Share Invite Link              │  (52dp height)
└─────────────────────────────────────┘
```

**Button Specs:**
- **ID:** `btnShareInvite`
- **Width:** match_parent
- **Height:** 52dp
- **Background:** `@drawable/round_button` (Blue rounded)
- **Elevation:** 4dp
- **Text:** "Share Invite Link"
- **Text Size:** 15sp
- **Text Color:** #1A1A1A (Dark/Black)
- **Font:** sans-serif, Bold

**Action:**
- Opens system share sheet
- Same functionality as "More" button
- Provides clear primary action for users

---

## 🎯 Core Functionality

### Referral System

#### Referral Code
```kotlin
private val referralCode = "HEARTO20"
```
- **Type:** Hardcoded constant
- **Value:** "HEARTO20"
- **Format:** Uppercase alphanumeric
- **Usage:** Displayed prominently and shared in all messages

#### Share Message
```kotlin
private val shareMessage get() = 
    "Join HEARTO — the smart health app! " +
    "Use my referral code $referralCode to get 20% off your first treatment. " +
    "Download now: https://hearto.app"
```

**Message Components:**
1. **Introduction:** "Join HEARTO — the smart health app!"
2. **Referral Code:** "Use my referral code HEARTO20"
3. **Benefit:** "to get 20% off your first treatment"
4. **Call to Action:** "Download now: https://hearto.app"

**Dynamic Property:**
- Uses `get()` to compute message with current `referralCode`
- Allows potential future customization per user

### Copy to Clipboard

```kotlin
view.findViewById<LinearLayout>(R.id.btnCopyCode).setOnClickListener {
    val clipboard = requireContext()
        .getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(
        ClipData.newPlainText("Referral Code", referralCode)
    )
    Toast.makeText(
        requireContext(), 
        "Code copied to clipboard!", 
        Toast.LENGTH_SHORT
    ).show()
}
```

**Behavior:**
1. Gets system clipboard service
2. Creates ClipData with label "Referral Code"
3. Sets code as primary clip
4. Shows confirmation toast
5. User can paste code elsewhere

### WhatsApp Sharing

```kotlin
view.findViewById<LinearLayout>(R.id.btnShareWhatsapp).setOnClickListener {
    try {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            setPackage("com.whatsapp")
            putExtra(Intent.EXTRA_TEXT, shareMessage)
        }
        startActivity(intent)
    } catch (e: Exception) {
        shareGeneral()
    }
}
```

**Behavior:**
1. Creates SEND intent with text/plain type
2. Targets WhatsApp package (`com.whatsapp`)
3. Includes full share message
4. Opens WhatsApp composer with pre-filled text
5. Fallback: Opens generic share sheet if WhatsApp not available

**Error Handling:**
- Catches exceptions (app not installed, etc.)
- Falls back to `shareGeneral()` method

### SMS Sharing

```kotlin
view.findViewById<LinearLayout>(R.id.btnShareSms).setOnClickListener {
    val intent = Intent(Intent.ACTION_VIEW).apply {
        data = Uri.parse("sms:")
        putExtra("sms_body", shareMessage)
    }
    startActivity(intent)
}
```

**Behavior:**
1. Creates VIEW intent with `sms:` URI
2. Pre-fills message body with share text
3. Opens default SMS app
4. User selects recipient(s) and sends
5. No error handling needed (SMS always available)

### Facebook Sharing

```kotlin
view.findViewById<LinearLayout>(R.id.btnShareFacebook).setOnClickListener {
    try {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            setPackage("com.facebook.katana")
            putExtra(Intent.EXTRA_TEXT, shareMessage)
        }
        startActivity(intent)
    } catch (e: Exception) {
        shareGeneral()
    }
}
```

**Behavior:**
1. Creates SEND intent with text/plain type
2. Targets Facebook package (`com.facebook.katana`)
3. Includes full share message
4. Opens Facebook share dialog
5. Fallback: Opens generic share sheet if Facebook not available

**Note:** Facebook may restrict text-only sharing in some scenarios

### Generic Share (More + Button)

```kotlin
private fun shareGeneral() {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, "Join HEARTO with my referral code")
        putExtra(Intent.EXTRA_TEXT, shareMessage)
    }
    startActivity(Intent.createChooser(intent, "Share via"))
}
```

**Behavior:**
1. Creates SEND intent without specific package
2. Includes subject line (useful for email)
3. Includes full share message
4. Opens Android share sheet with all compatible apps
5. User selects preferred sharing method

**Compatible Apps:**
- Email clients
- Messaging apps (Telegram, Signal, etc.)
- Social media apps (Twitter, Instagram, LinkedIn, etc.)
- Note-taking apps
- Cloud storage apps
- Any app that accepts text sharing

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background |
| Card Background | `#FFFFFF` | All card backgrounds |
| Primary Text | `#1A1A1A` | Titles, button text |
| Secondary Text | `#444444` | Subtitle |
| Tertiary Text | `#777777` | Step descriptions |
| Primary Blue | `#0D99FF` | Referral code, SMS icon |
| Step 1 Badge | `#536DFE` | Indigo (Share) |
| Step 2 Badge | `#4CAF50` | Green (Sign up) |
| Step 3 Badge | `#FFA000` | Amber (Reward) |
| More Icon | `#555555` | Gray tint |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Page Title | 22sp | Bold | #1A1A1A |
| Page Subtitle | 13sp | Normal | #444444 |
| Card Title | 13sp | Bold | #1A1A1A |
| Referral Code | 22sp | Bold | #0D99FF |
| Copy Button | 13sp | Bold | #1A1A1A |
| Step Title | 13sp | Bold | #1A1A1A |
| Step Description | 12sp | Normal | #777777 |
| Platform Label | 11sp | Normal | #1A1A1A |
| Share Button | 15sp | Bold | #1A1A1A |

### Spacing

| Element | Value |
|---------|-------|
| Container Padding (H) | 16dp |
| Container Padding (Top) | 20dp |
| Container Padding (Bottom) | 32dp |
| Card Corner Radius | 14dp |
| Card Elevation | 3dp |
| Card Padding | 16dp |
| Card Margin Bottom | 16dp |
| Step Badge Size | 40dp × 40dp |
| Platform Icon Size | 28dp × 28dp |
| Copy Icon Size | 15dp × 15dp |
| Share Button Height | 52dp |
| Line Spacing (Subtitle) | +3dp |

### Drawables Required

| Drawable Name | Type | Usage |
|---------------|------|-------|
| `round_button` | Shape | Button backgrounds |
| `bg_referral_code` | Shape | Code container background |
| `input_box_background_shadow` | Shape | Platform button backgrounds |
| `icon_bg_light_indigo` | Shape | Step 1 badge background |
| `icon_bg_light_green` | Shape | Step 2 badge background |
| `icon_bg_light_amber` | Shape | Step 3 badge background |
| `baseline_content_copy_24` | Vector | Copy icon |
| `whatsapp` | Vector/PNG | WhatsApp brand icon |
| `baseline_message_24` | Vector | SMS icon |
| `facebook` | Vector/PNG | Facebook brand icon |
| `baseline_share_24` | Vector | Share/More icon |

---

## 📱 User Experience Flow

### Primary User Journeys

#### 1. Copy and Share Manually
```
View Screen → Tap "Copy" → Toast Confirmation → 
Paste in messaging app → Send to friend
```

#### 2. Quick WhatsApp Share
```
View Screen → Tap "WhatsApp" → Select Contact(s) → 
Confirm and Send
```

#### 3. SMS Share
```
View Screen → Tap "SMS" → Select Contact(s) → 
Edit message (optional) → Send
```

#### 4. Facebook Share
```
View Screen → Tap "Facebook" → Choose share type 
(Post/Story/Message) → Share
```

#### 5. Other Platform Share
```
View Screen → Tap "More" or "Share Invite Link" → 
Choose App from Sheet → Complete sharing
```

### Success Metrics

**User Actions:**
- Copy button clicks
- Share button clicks per platform
- Successful shares completed
- Referral link clicks from shared messages
- New registrations with referral code

**Engagement Indicators:**
- Time spent on screen
- Number of different platforms used
- Repeat sharing behavior
- Referral conversion rate

---

## 🔗 Integration with Registration

### Referral Code Entry (RegisterActivity)

When a new user registers, they can enter a referral code:

**UI Elements:**
- "Have a referral code?" clickable text
- Dialog with input field
- Code validation and display tag
- Remove code option

**Code Entry Dialog:**
```xml
┌─────────────────────────────┐
│  Enter Referral Code        │
│  [Input Field]              │
│  [Cancel] [Submit]          │
└─────────────────────────────┘
```

**Validation Rules:**
1. Code must not be empty
2. Code must be at least 5 characters
3. Code converted to uppercase
4. Success toast: "Referral code applied successfully!"

**Display Tag:**
```
┌──────────────────┐
│ HEARTO20    [X]  │  (Removable tag)
└──────────────────┘
```

**Storage:**
```kotlin
private var referralCode: String? = null
```
- Stored temporarily during registration
- Sent to API during registration submission
- Backend validates code and applies discount

### API Integration

**Registration Endpoint:**
```
POST /register
{
  "name": "...",
  "mobile": "...",
  "referral_code": "HEARTO20"
}
```

**Backend Processing:**
1. Validates referral code exists and is active
2. Associates referee with referrer
3. Marks both accounts for 20% discount on first treatment
4. Updates referral statistics
5. Sends notification to referrer (optional)

---

## 🚀 Future Enhancements

### Planned Features

#### 1. Personalized Referral Codes
```kotlin
// Fetch user's unique code from API
private lateinit var referralCode: String
private lateinit var userId: String

fun fetchReferralCode() {
    apiService.getUserReferralCode(userId).enqueue { response ->
        referralCode = response.code // e.g., "JOHN2024"
        updateUI()
    }
}
```
- Each user gets unique code
- Code based on name + number or random generation
- Easier tracking of individual referrals

#### 2. Referral Statistics
```xml
┌─────────────────────────────────────┐
│  Your Referral Stats                │
│                                     │
│  👥 Friends Invited: 12             │
│  ✅ Successful Signups: 8           │
│  💰 Rewards Earned: $160            │
└─────────────────────────────────────┘
```
- Show number of shares
- Track successful registrations
- Display total rewards/savings
- Gamification elements

#### 3. Referral History
```xml
┌─────────────────────────────────────┐
│  Recent Referrals                   │
│                                     │
│  John Doe     - May 15, 2026       │
│  Status: Signed up ✓               │
│                                     │
│  Jane Smith   - May 10, 2026       │
│  Status: Pending                   │
└─────────────────────────────────────┘
```
- List of referred friends
- Status tracking (pending/completed)
- Reward redemption status

#### 4. Dynamic Rewards
```kotlin
// Fetch current promotion from API
data class ReferralPromotion(
    val discount: Int,        // 20
    val discountType: String, // "percentage"
    val maxRewards: Int?,     // Limit per user
    val expiryDate: String?   // Promotion end date
)
```
- Variable discount amounts
- Seasonal promotions
- Tiered rewards (refer 5+ friends = bonus)
- Limited-time offers

#### 5. Social Proof
```xml
┌─────────────────────────────────────┐
│  🎉 1,234 users joined via          │
│     referrals this month!           │
└─────────────────────────────────────┘
```
- Show total referral count
- Display success stories
- Add trust indicators

#### 6. Deep Linking
```kotlin
val deepLink = "https://hearto.app/invite?code=$referralCode"
```
- Direct app download + code auto-fill
- Track referral source
- Seamless onboarding experience
- Attribution analytics

#### 7. Email Sharing
- Add dedicated email button
- Pre-formatted email template
- Subject: "Join me on HEARTO"
- Professional formatting

#### 8. QR Code Sharing
```xml
┌──────────────────┐
│   [QR Code]      │  (Scannable code)
│   HEARTO20       │
└──────────────────┘
```
- Generate QR code for referral link
- In-person sharing at events
- Print-friendly format

#### 9. Reward Redemption
- Track available discounts
- Apply automatically at checkout
- Show expiry dates
- Notification when earned

#### 10. Leaderboard
```xml
┌─────────────────────────────────────┐
│  Top Referrers This Month           │
│                                     │
│  🥇 Sarah J.    - 45 referrals      │
│  🥈 Mike R.     - 38 referrals      │
│  🥉 Lisa K.     - 32 referrals      │
└─────────────────────────────────────┘
```
- Competitive element
- Monthly/weekly rankings
- Special badges/rewards for top referrers

---

## 🔒 Privacy & Compliance

### Data Handling

**What We Track:**
- Referral code used during registration
- Share button clicks (analytics)
- Successful referral conversions
- Reward redemption status

**What We DON'T Share:**
- Contact lists (user manually selects contacts)
- Referrer's personal information with referee
- Referee's personal information with referrer
- Share message contents beyond what user sends

### Consent & Transparency

**User Consent:**
- User explicitly chooses to share
- No automatic contact list access
- All sharing via user-initiated actions

**Data Storage:**
- Referral codes stored securely
- Encrypted in transit and at rest
- Access limited to authorized systems
- Compliant with GDPR, CCPA regulations

### Terms & Conditions

**Referral Program Rules:**
1. Both parties must be new HEARTO users
2. Discount valid on first treatment only
3. Cannot be combined with other offers
4. Referral must complete registration and verification
5. Rewards expire after 6 months (example)
6. Program subject to change or cancellation

**Abuse Prevention:**
- Limit referrals per user (e.g., 50 max)
- Detect and flag suspicious activity
- Verify unique users (no duplicate accounts)
- Block fraudulent referral patterns

---

## 🧪 Testing Checklist

### Functionality Tests
- [ ] Referral code displays correctly (HEARTO20)
- [ ] Copy button copies code to clipboard
- [ ] Copy confirmation toast appears
- [ ] Pasted code matches original
- [ ] WhatsApp button opens WhatsApp with message
- [ ] WhatsApp fallback works if app not installed
- [ ] SMS button opens SMS composer
- [ ] SMS body pre-filled correctly
- [ ] Facebook button opens Facebook app
- [ ] Facebook fallback works if app not installed
- [ ] More button opens system share sheet
- [ ] Share Invite button opens system share sheet
- [ ] Share message format is correct
- [ ] All sharing methods include referral code
- [ ] Download link works in shared messages

### UI/UX Tests
- [ ] All cards render with proper spacing
- [ ] Text is readable on all backgrounds
- [ ] Icons display correctly at proper sizes
- [ ] Step numbers and badges align properly
- [ ] Platform buttons have equal width
- [ ] Buttons respond to touch (ripple effect)
- [ ] Screen scrolls smoothly
- [ ] Layout adapts to different screen sizes
- [ ] Colors match design specifications
- [ ] Fonts render consistently

### Integration Tests
- [ ] Referral code entry works in RegisterActivity
- [ ] Code validation prevents invalid entries
- [ ] Code tag displays and removes correctly
- [ ] Registration API receives referral code
- [ ] Backend validates and processes referral
- [ ] Both accounts receive discount tracking
- [ ] Referral attribution recorded correctly

### Edge Cases
- [ ] App behavior when clipboard permission denied
- [ ] Handling of apps not installed (graceful fallback)
- [ ] Very long referral codes (if dynamic)
- [ ] Special characters in codes
- [ ] Network offline during share attempt
- [ ] Multiple rapid share attempts
- [ ] Share cancellation by user

### Accessibility Tests
- [ ] All buttons have content descriptions
- [ ] Screen reader announces card contents
- [ ] Touch targets ≥ 48dp
- [ ] Color contrast meets WCAG standards
- [ ] Text scales with system font size
- [ ] Keyboard navigation support (if applicable)

---

## 📊 Analytics & Tracking

### Key Metrics to Track

**Screen Analytics:**
- Screen view count
- Average time on screen
- Bounce rate (immediate exit)

**Engagement Metrics:**
- Copy button click rate
- Share button clicks by platform:
  - WhatsApp share rate
  - SMS share rate
  - Facebook share rate
  - More/Generic share rate
- Share Invite button clicks

**Conversion Funnel:**
1. Screen views
2. Copy/Share actions
3. Referral link clicks (external)
4. App downloads from referrals
5. Registrations with referral code
6. First treatment bookings (discount applied)

**Platform Performance:**
- Most popular sharing platform
- Highest conversion platform
- Platform-specific completion rates

**User Segments:**
- Active referrers (1+ shares)
- Super referrers (5+ successful referrals)
- Conversion rate by user demographics
- Geographic distribution of referrals

### Implementation

```kotlin
// Example analytics tracking
class ReferToFriendFragment : Fragment() {
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Track screen view
        Analytics.logEvent("referral_screen_viewed")
        
        // Track copy action
        btnCopyCode.setOnClickListener {
            Analytics.logEvent("referral_code_copied", 
                mapOf("code" to referralCode))
            // ... existing code
        }
        
        // Track shares by platform
        btnShareWhatsapp.setOnClickListener {
            Analytics.logEvent("referral_shared", 
                mapOf("platform" to "whatsapp"))
            // ... existing code
        }
    }
}
```

---

## 🎭 Design Consistency

This Refer a Friend screen follows HEARTO's design language:

✅ **Consistent Color Scheme:** Light blue background with white cards  
✅ **Material Design:** Rounded corners, elevation, ripple effects  
✅ **Typography:** Sans-serif font family throughout  
✅ **Iconography:** Consistent icon style and sizing  
✅ **Spacing:** Uniform padding and margins  
✅ **Card-Based Layout:** Grouped content in distinct sections  
✅ **Clear Hierarchy:** Title → Cards → Call-to-Action  
✅ **Brand Colors:** Blue (#0D99FF) as primary accent  

**Design Philosophy:**
- Simple and straightforward
- Emphasizes benefits (20% off)
- Multiple sharing options for user preference
- Clear call-to-action (Share Invite Link button)
- Visual step-by-step guide
- Professional yet friendly tone

---

## 💡 Best Practices

### UX Principles Applied

1. **Clarity:** Clear title and benefit statement upfront
2. **Simplicity:** One-tap sharing to major platforms
3. **Flexibility:** Multiple sharing options for different preferences
4. **Feedback:** Immediate confirmation (toast) for copy action
5. **Guidance:** "How It Works" explains the process
6. **Accessibility:** Large touch targets, readable text
7. **Trust:** Professional design builds credibility
8. **Motivation:** 20% discount benefit prominently displayed

### Code Quality

```kotlin
// Good practices in implementation:

✅ Immutable referral code (val)
✅ Computed property for dynamic message
✅ Try-catch for platform-specific intents
✅ Graceful fallback to generic share
✅ Descriptive variable names
✅ Consistent intent creation pattern
✅ Toast feedback for user actions
✅ Proper use of Android services (ClipboardManager)
```

---

**Document Version:** 1.0  
**Last Updated:** May 22, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

