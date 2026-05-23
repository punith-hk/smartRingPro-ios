# Authentication Flow - Design & Implementation

**HEARTO App - Login, Registration & OTP Verification**  
**Activities:** `LoginActivity.kt`, `RegisterActivity.kt`, `OtpActivity.kt`, `RegisterProfileActivity.kt`  
**Layouts:** `activity_login.xml`, `activity_register.xml`, `activity_otp.xml`  
**Repositories:** `LoginRepository.kt`, `RegisterRepository.kt`, `OtpRepository.kt`

---

## 📋 Overview

The HEARTO app implements a secure, OTP-based authentication system without traditional passwords. Users can login or register using their mobile number, receive a 6-digit OTP via SMS, and verify their identity. After successful verification, user data and access tokens are stored locally for session management. New users are directed to complete their profile setup, while returning users proceed directly to the home screen.

**Key Features:**
- **OTP-Based Authentication:** No passwords required - mobile number + OTP
- **60-Second Countdown Timer:** Resend OTP after timeout
- **Session Management:** Access token storage in SharedPreferences
- **Referral System:** Optional referral code during registration
- **Profile Completion:** New users must complete profile after OTP verification
- **Seamless Flow:** Clear navigation between login → OTP → home/profile

---

## 🎨 Design Architecture

### Authentication Flow Structure

```
App Launch
    ↓
Check isLoggedIn (SharedPreferences)
    ├─ True → Navigate to HomeActivity
    └─ False → Navigate to LoginActivity
        ↓
        [User Choice]
        ├─ Login (Existing User)
        │   ↓
        │   Enter Mobile Number
        │   ↓
        │   POST /login → Send OTP
        │   ↓
        │   Navigate to OtpActivity
        │   ↓
        │   Enter 6-Digit OTP
        │   ↓
        │   POST /validate_otp
        │   ↓
        │   Save Token & User Data
        │   ↓
        │   Navigate to HomeActivity
        │
        └─ Sign Up (New User)
            ↓
            Enter Name + Mobile Number
            (Optional: Referral Code)
            ↓
            POST /register → Send OTP
            ↓
            Navigate to OtpActivity
            ↓
            Enter 6-Digit OTP
            ↓
            POST /validate_otp
            ↓
            Save Token & User Data
            ↓
            Navigate to RegisterProfileActivity
            ↓
            Complete Profile Setup
            ↓
            Navigate to HomeActivity
```

---

## 🔐 LoginActivity - Existing User Login

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│                                     │  Background
│                                     │  #D9EDFF
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │  White
│  │  Login                        │ │  Card
│  │                               │ │  (Centered)
│  │  We'll send a confirmation    │ │
│  │  code to your phone           │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  Mobile
│  │  │ 9876543210              │ │ │  Input
│  │  └─────────────────────────┘ │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │
│  │  │      Sign In            │ │ │  Submit
│  │  └─────────────────────────┘ │ │  Button
│  │                               │ │
│  │  ─────── or ───────          │ │  Divider
│  │                               │ │
│  │  Don't have an account?      │ │  Sign Up
│  │  Sign Up                      │ │  Link
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Components

#### Card Container

**Specs:**
- **Background:** White (#FFFFFF)
- **Corner Radius:** 20dp
- **Elevation:** 8dp
- **Padding:** 32dp horizontal, 40dp vertical
- **Position:** Vertically centered
- **Margin:** 12dp horizontal

---

#### Title

**Specs:**
- **Text:** "Login"
- **Size:** 24sp
- **Weight:** Bold
- **Color:** Black (#000000)
- **Font:** Sans-serif
- **Margin Bottom:** 16dp

---

#### Subtitle

**Specs:**
- **Text:** "We'll send a confirmation code to your phone"
- **Size:** 16sp
- **Color:** Black (#000000)
- **Font:** Sans-serif
- **Margin Bottom:** 12dp

---

#### Mobile Number Input

**Specs:**
- **ID:** `etMobileNumber`
- **Hint:** "Mobile Number"
- **Input Type:** Phone
- **Max Length:** 10
- **Digits Only:** 0-9
- **Background:** Custom drawable with shadow
- **Padding:** 15dp
- **Elevation:** 4dp
- **Text Color:** Black
- **Hint Color:** Gray (#808080)
- **Margin Bottom:** 24dp

**Validation:**
```kotlin
if (mobileNumber.isEmpty()) {
    Toast: "Please enter all fields"
    return
}

if (mobileNumber.length != 10) {
    Toast: "Mobile number must be 10 digits"
    return
}

if (!mobileNumber.matches(Regex("^[0-9]{10}$"))) {
    Invalid format
    return
}
```

---

#### Sign In Button

**Specs:**
- **ID:** `btnSubmit`
- **Text:** "Sign In"
- **Style:** `@style/AppButton` (Green background)
- **Width:** Match parent
- **Height:** Wrap content
- **Text Size:** 18sp
- **Margin Bottom:** 16dp

**Action:**
```kotlin
btnSubmit.setOnClickListener {
    val mobileNumber = etMobileNumber.text.toString().trim()
    
    // Validation
    if (mobileNumber.isEmpty()) {
        Toast: "Please enter all fields"
        return
    }
    
    if (mobileNumber.length != 10) {
        Toast: "Mobile number must be 10 digits"
        return
    }
    
    // Call login API
    login(mobileNumber)
}
```

---

#### Divider with "or"

**Specs:**
- **Layout:** Horizontal LinearLayout
- **Alignment:** Center vertical
- **Margin Bottom:** 16dp

**Components:**
- **Left Line:** View, 1dp height, gray background
- **Text:** "or", 24sp, bold, black
- **Right Line:** View, 1dp height, gray background

---

#### Sign Up Link

**Specs:**
- **ID:** `tvSignUp`
- **Text:** "Don't have an account? Sign Up"
- **Size:** 18sp
- **Color:** Gray (#808080)
- **Alignment:** Center
- **Margin Bottom:** 24dp
- **Clickable:** Yes

**Styling:**
```kotlin
val text = "Don't have an account? Sign Up"
val spannableString = SpannableString(text)

// "Sign Up" text styling
val startIndex = text.indexOf("Sign Up")
val endIndex = startIndex + "Sign Up".length

spannableString.setSpan(
    UnderlineSpan(), 
    startIndex, endIndex, 
    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
)

spannableString.setSpan(
    ForegroundColorSpan(Color.BLUE), 
    startIndex, endIndex, 
    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
)

spannableString.setSpan(
    StyleSpan(Typeface.BOLD), 
    startIndex, endIndex, 
    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
)

tvSignUp.text = spannableString
```

**Action:**
```kotlin
tvSignUp.setOnClickListener {
    val intent = Intent(this, RegisterActivity::class.java)
    startActivity(intent)
}
```

---

### Login API Flow

```
[User Enters Mobile Number: "9876543210"]
    ↓
[User Taps "Sign In" Button]
    ↓
Validate Input
    ├─ Not empty ✓
    ├─ Length = 10 ✓
    └─ Only digits ✓
    ↓
Show Loading Dialog
    "Sending OTP, please wait..."
    ↓
API Call: POST /login
    ↓
Request Body:
{
    "mobile_number": "9876543210"
}
    ↓
[Backend Processing]
    ├─ Check if mobile exists in database
    ├─ If exists:
    │   ├─ Generate 6-digit OTP
    │   ├─ Send SMS to mobile
    │   ├─ Store OTP with 5-min expiry
    │   └─ Return user_id
    └─ If not exists:
        └─ Return error: "User not found"
    ↓
Response (Success):
{
    "response": 0,
    "message": "OTP sent successfully",
    "user_id": 123
}
    ↓
Response (Error - User Not Found):
{
    "response": 1,
    "message": "User not found. Please register first."
}
    ↓
[If Success]
    ↓
    Update Loading Dialog
        "OTP sent successfully!"
    ↓
    Wait 1 second (smooth UX)
    ↓
    Dismiss Loading Dialog
    ↓
    Navigate to OtpActivity
        ├─ Pass: mobileNumber
        ├─ Pass: user_id
        └─ Pass: new_account = false
    ↓
    Finish LoginActivity
    ↓
[User sees OtpActivity]
```

**API Implementation:**
```kotlin
private fun login(mobileNumber: String) {
    // Show loading dialog
    showLoadingDialog("Sending OTP, please wait...")
    
    loginRepository.login(mobileNumber)
        .enqueue(object : Callback<LoginResponse> {
            override fun onResponse(call, response) {
                if (response.isSuccessful && response.body() != null) {
                    val loginResponse = response.body()!!
                    val message = loginResponse.getFormattedMessage()
                    
                    if (loginResponse.response == 0) {
                        // Success
                        updateLoadingDialog("OTP sent successfully!")
                        
                        Handler(Looper.getMainLooper()).postDelayed({
                            dismissLoadingDialog()
                            
                            val intent = Intent(this@LoginActivity, OtpActivity::class.java)
                            intent.putExtra("mobileNumber", mobileNumber)
                            intent.putExtra("user_id", loginResponse.user_id)
                            intent.putExtra("new_account", false)
                            startActivity(intent)
                            finish()
                        }, 1000)
                    } else {
                        // Error
                        dismissLoadingDialog()
                        Toast.makeText(this@LoginActivity, message, Toast.LENGTH_SHORT).show()
                    }
                } else {
                    dismissLoadingDialog()
                    Toast.makeText(
                        this@LoginActivity,
                        "Login failed: ${response.message()}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            
            override fun onFailure(call, t) {
                dismissLoadingDialog()
                Toast.makeText(
                    this@LoginActivity,
                    "Network error: ${t.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        })
}
```

---

## 📝 RegisterActivity - New User Registration

### Visual Layout

```
┌─────────────────────────────────────┐
│                                     │  Light Blue
│                                     │  Background
│                                     │  #D9EDFF
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │  White
│  │  Register                     │ │  Card
│  │                               │ │  (Centered)
│  │  Create your account to get   │ │
│  │  started with HEARTO          │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  Name
│  │  │ John Doe                │ │ │  Input
│  │  └─────────────────────────┘ │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  Mobile
│  │  │ 9876543210              │ │ │  Input
│  │  └─────────────────────────┘ │ │
│  │                               │ │
│  │  Have a referral code?       │ │  Referral
│  │                               │ │  Link
│  │  [REF123 ✕]                  │ │  (Optional)
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │
│  │  │      Register           │ │ │  Submit
│  │  └─────────────────────────┘ │ │  Button
│  │                               │ │
│  │  ─────── or ───────          │ │  Divider
│  │                               │ │
│  │  Already have an account?    │ │  Sign In
│  │                               │ │  Link
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Components

#### Name Input

**Specs:**
- **ID:** `etName`
- **Hint:** "Full Name"
- **Input Type:** Text
- **Capitalization:** Words
- **Background:** Custom drawable with shadow
- **Padding:** 15dp
- **Margin Bottom:** 16dp

---

#### Mobile Number Input

**Specs:**
- **ID:** `etMobileNumber`
- **Hint:** "Mobile Number"
- **Input Type:** Phone
- **Max Length:** 10
- **Digits Only:** 0-9
- **Margin Bottom:** 16dp

**Validation:** Same as LoginActivity

---

#### Referral Code Section

**Components:**

**Have Referral Code Link:**
- **ID:** `tvHaveReferralCode`
- **Text:** "Have a referral code?"
- **Size:** 14sp
- **Color:** Blue
- **Underlined:** Yes
- **Clickable:** Yes

**Referral Code Tag (After Added):**
- **ID:** `llReferralCodeTag`
- **Layout:** Horizontal LinearLayout
- **Background:** Light blue rounded rectangle
- **Padding:** 8dp horizontal, 6dp vertical
- **Visibility:** Gone initially

**Referral Code Display:**
- **ID:** `tvReferralCodeDisplay`
- **Text:** "REF123"
- **Size:** 14sp
- **Color:** Blue

**Remove Icon:**
- **ID:** `ivRemoveReferralCode`
- **Icon:** ✕ (close icon)
- **Size:** 16dp × 16dp
- **Clickable:** Yes

**Flow:**
```kotlin
tvHaveReferralCode.setOnClickListener {
    // Show input dialog
    showReferralCodeDialog()
}

private fun showReferralCodeDialog() {
    val dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_referral_code, null)
    val etReferralCode = dialogView.findViewById<EditText>(R.id.etReferralCode)
    val btnSubmit = dialogView.findViewById<Button>(R.id.btnSubmit)
    
    val dialog = AlertDialog.Builder(this)
        .setView(dialogView)
        .create()
    
    btnSubmit.setOnClickListener {
        val code = etReferralCode.text.toString().trim()
        if (code.isNotEmpty()) {
            referralCode = code
            tvHaveReferralCode.visibility = View.GONE
            llReferralCodeTag.visibility = View.VISIBLE
            tvReferralCodeDisplay.text = code
            dialog.dismiss()
        }
    }
    
    dialog.show()
}

ivRemoveReferralCode.setOnClickListener {
    referralCode = null
    llReferralCodeTag.visibility = View.GONE
    tvHaveReferralCode.visibility = View.VISIBLE
}
```

---

#### Register Button

**Specs:**
- **ID:** `btnSubmit`
- **Text:** "Register"
- **Style:** `@style/AppButton`
- **Width:** Match parent
- **Margin Bottom:** 16dp

---

#### Sign In Link

**Specs:**
- **ID:** `tvSignIn`
- **Text:** "Already have an account?"
- **Size:** 18sp
- **Color:** Gray
- **"Sign In" portion:** Blue, underlined, bold

---

### Register API Flow

```
[User Enters Details]
    Name: "John Doe"
    Mobile: "9876543210"
    Referral: "REF123" (optional)
    ↓
[User Taps "Register" Button]
    ↓
Validate Input
    ├─ Name not empty ✓
    ├─ Mobile not empty ✓
    └─ Mobile length = 10 ✓
    ↓
Show Loading Dialog
    "Sending OTP, please wait..."
    ↓
API Call: POST /register
    ↓
Request Body:
{
    "mobile_number": "9876543210",
    "name": "John Doe",
    "referral_code": "REF123"  // optional
}
    ↓
[Backend Processing]
    ├─ Check if mobile already exists
    ├─ If exists:
    │   └─ Return error: "Mobile number already registered"
    ├─ If not exists:
    │   ├─ Create user account
    │   ├─ Generate patient_id
    │   ├─ Generate 6-digit OTP
    │   ├─ Send SMS to mobile
    │   ├─ Store OTP with 5-min expiry
    │   ├─ If referral code valid:
    │   │   └─ Link to referrer account
    │   └─ Return user_id + patient_id
    ↓
Response (Success):
{
    "response": 0,
    "message": "OTP sent successfully",
    "user_id": 123,
    "patient_id": 456
}
    ↓
Response (Error - Already Exists):
{
    "response": 1,
    "message": "Mobile number already registered. Please login."
}
    ↓
[If Success]
    ↓
    Update Loading Dialog
        "OTP sent successfully!"
    ↓
    Wait 1 second
    ↓
    Dismiss Loading Dialog
    ↓
    Navigate to OtpActivity
        ├─ Pass: user_id
        ├─ Pass: patient_id
        ├─ Pass: name
        ├─ Pass: mobileNumber
        └─ Pass: new_account = true
    ↓
    Finish RegisterActivity
    ↓
[User sees OtpActivity]
```

**API Implementation:**
```kotlin
private fun register(mobileNumber: String, name: String) {
    showLoadingDialog("Sending OTP, please wait...")
    
    registerRepository.register(mobileNumber, name, referralCode)
        .enqueue(object : Callback<RegisterResponse> {
            override fun onResponse(call, response) {
                if (response.isSuccessful && response.body() != null) {
                    val registerResponse = response.body()!!
                    
                    if (registerResponse.response == 0) {
                        // Success
                        updateLoadingDialog("OTP sent successfully!")
                        
                        Handler(Looper.getMainLooper()).postDelayed({
                            dismissLoadingDialog()
                            
                            val intent = Intent(this@RegisterActivity, OtpActivity::class.java)
                            intent.putExtra("user_id", registerResponse.user_id)
                            intent.putExtra("patient_id", registerResponse.patient_id)
                            intent.putExtra("name", name)
                            intent.putExtra("mobileNumber", mobileNumber)
                            intent.putExtra("new_account", true)
                            startActivity(intent)
                            finish()
                        }, 1000)
                    } else {
                        dismissLoadingDialog()
                        Toast.makeText(
                            this@RegisterActivity,
                            registerResponse.getFormattedMessage(),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                } else {
                    dismissLoadingDialog()
                    Toast.makeText(
                        this@RegisterActivity,
                        "Register failed: ${response.message()}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            
            override fun onFailure(call, t) {
                dismissLoadingDialog()
                Toast.makeText(
                    this@RegisterActivity,
                    "Network error: ${t.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        })
}
```

---

## 🔢 OtpActivity - OTP Verification

### Visual Layout

```
┌─────────────────────────────────────┐
│  ◄                                  │  Back
│                                     │  Icon
│      Verification                   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │  White
│  │  Verify Your Number           │ │  Card
│  │                               │ │
│  │  OTP sent to your mobile      │ │  Message
│  │  number 9876543210            │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │  OTP
│  │  │ ● ● ● ● ● ●             │ │ │  Input
│  │  └─────────────────────────┘ │ │  (6 digits)
│  │                               │ │
│  │  Resend code in 00:45         │ │  Timer
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │
│  │  │      Verify OTP         │ │ │  Submit
│  │  └─────────────────────────┘ │ │  Button
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

### Components

#### Back Button

**Specs:**
- **ID:** `backIcon`
- **Icon:** ◄ (back arrow)
- **Size:** 24dp × 24dp
- **Position:** Top-left
- **Clickable:** Yes

**Action:**
```kotlin
backIcon.setOnClickListener {
    if (isNewAccount) {
        // Go back to RegisterActivity
        val intent = Intent(this, RegisterActivity::class.java)
        startActivity(intent)
    } else {
        // Go back to LoginActivity
        val intent = Intent(this, LoginActivity::class.java)
        startActivity(intent)
    }
    finish()
}
```

---

#### Title

**Specs:**
- **Text:** "Verify Your Number"
- **Size:** 24sp
- **Weight:** Bold
- **Color:** Black
- **Margin Bottom:** 16dp

---

#### OTP Message

**Specs:**
- **ID:** `tvOtpMessage`
- **Text:** "OTP sent to your mobile number 9876543210"
- **Size:** 16sp
- **Color:** Black
- **Margin Bottom:** 24dp

**Dynamic Text:**
```kotlin
val message = "OTP sent to your mobile number $mobileNumber"
tvOtpMessage.text = message
```

---

#### OTP Input Field

**Specs:**
- **ID:** `etOtp`
- **Input Type:** Number
- **Max Length:** 6
- **Hint:** "● ● ● ● ● ●"
- **Text Size:** 24sp
- **Letter Spacing:** 0.5
- **Alignment:** Center
- **Background:** Custom drawable with shadow
- **Padding:** 15dp
- **Margin Bottom:** 16dp

**Validation:**
```kotlin
if (otp.isEmpty()) {
    Toast: "Please enter the OTP"
    return
}

if (otp.length != 6) {
    Toast: "OTP must be 6 digits"
    return
}
```

---

#### Resend Timer

**Specs:**
- **ID:** `tvResendOtp`
- **Initial Text:** "Resend code in 00:60"
- **After Timeout:** "Resend OTP" (clickable, blue, underlined)
- **Duration:** 60 seconds
- **Update Interval:** 1 second

**Implementation:**
```kotlin
private fun startCountDown() {
    isTimerRunning = true
    updateResendOtpText(timeLeftInMillis)
    
    countDownTimer = object : CountDownTimer(timeLeftInMillis, 1000) {
        override fun onTick(millisUntilFinished: Long) {
            timeLeftInMillis = millisUntilFinished
            updateResendOtpText(timeLeftInMillis)
        }
        
        override fun onFinish() {
            isTimerRunning = false
            // Enable resend
            val spannableString = SpannableString("Resend OTP")
            spannableString.setSpan(UnderlineSpan(), 0, 10, 0)
            spannableString.setSpan(ForegroundColorSpan(Color.BLUE), 0, 10, 0)
            spannableString.setSpan(StyleSpan(Typeface.BOLD), 0, 10, 0)
            tvResendOtp.text = spannableString
        }
    }.start()
}

private fun updateResendOtpText(millis: Long) {
    val seconds = (millis / 1000).toInt()
    val text = "Resend code in 00:${String.format("%02d", seconds)}"
    tvResendOtp.text = text
    tvResendOtp.setTextColor(Color.GRAY)
}
```

**Resend Action:**
```kotlin
tvResendOtp.setOnClickListener {
    if (!isTimerRunning) {
        resendOtp()
        timeLeftInMillis = 60000
        startCountDown()
    }
}

private fun resendOtp() {
    loginRepository.login(mobileNumber).enqueue(object : Callback<LoginResponse> {
        override fun onResponse(call, response) {
            if (response.isSuccessful && response.body()?.response == 0) {
                Toast.makeText(this@OtpActivity, "OTP resent successfully!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@OtpActivity, "Failed to resend OTP", Toast.LENGTH_SHORT).show()
            }
        }
        
        override fun onFailure(call, t) {
            Toast.makeText(this@OtpActivity, "Error: ${t.message}", Toast.LENGTH_SHORT).show()
        }
    })
}
```

---

#### Verify OTP Button

**Specs:**
- **ID:** `btnSubmit`
- **Text:** "Verify OTP"
- **Style:** `@style/AppButton`
- **Width:** Match parent

---

### OTP Verification Flow

```
[User on OtpActivity]
    Received Data:
    - user_id: 123
    - patient_id: 456 (if new account)
    - name: "John Doe" (if new account)
    - mobileNumber: "9876543210"
    - new_account: true/false
    ↓
Display:
    "OTP sent to your mobile number 9876543210"
    ↓
Start 60-second countdown timer
    ↓
[User Receives SMS]
    "Your HEARTO OTP is: 123456"
    ↓
[User Enters OTP: "123456"]
    ↓
[User Taps "Verify OTP" Button]
    ↓
Validate Input
    ├─ Not empty ✓
    └─ Length = 6 ✓
    ↓
Show Loading Dialog
    "Verifying OTP, please wait..."
    ↓
API Call: POST /validate_otp
    ↓
Request Body:
{
    "user_id": 123,
    "otp": "123456"
}
    ↓
[Backend Processing]
    ├─ Check if OTP matches stored value
    ├─ Check if OTP not expired (< 5 minutes)
    ├─ If valid:
    │   ├─ Mark OTP as used
    │   ├─ Generate access token (JWT)
    │   ├─ Set token expiry (30 days)
    │   ├─ Return user data + token
    │   └─ Return success
    └─ If invalid/expired:
        └─ Return error
    ↓
Response (Success):
{
    "response": 0,
    "message": "OTP verified successfully",
    "id": 123,
    "user_id": 123,
    "user": "John Doe",
    "email": "john@example.com",
    "role_code": "patient",
    "mobile_number": "9876543210",
    "tokenData": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "token_type": "Bearer",
        "expires_at": "2026-06-23T14:30:00.000000Z",
        "token": {
            "id": "token_id_123",
            "user_id": 123,
            "client_id": 1,
            "name": "Personal Access Token",
            "scopes": [],
            "revoked": false,
            "created_at": "2026-05-24T14:30:00.000000Z",
            "updated_at": "2026-05-24T14:30:00.000000Z",
            "expires_at": "2026-06-23T14:30:00.000000Z"
        }
    },
    "status": 1
}
    ↓
Response (Error - Invalid OTP):
{
    "response": 1,
    "message": "Invalid OTP. Please try again.",
    "status": 0
}
    ↓
Response (Error - Expired OTP):
{
    "response": 1,
    "message": "OTP expired. Please request a new one.",
    "status": 0
}
    ↓
[If Success]
    ↓
    Update Loading Dialog
        "OTP verified successfully!"
    ↓
    Wait 1 second
    ↓
    Save User Data to SharedPreferences
        ├─ accessToken
        ├─ user (name)
        ├─ email
        ├─ roleCode
        ├─ mobileNumber
        ├─ id
        ├─ user_id
        └─ isLoggedIn = true
    ↓
    Dismiss Loading Dialog
    ↓
    Check: new_account flag
        ├─ If true (New User):
        │   ↓
        │   Navigate to RegisterProfileActivity
        │   (Complete profile setup)
        │   ↓
        │   Clear task flags
        │   (Can't go back to OTP screen)
        │
        └─ If false (Existing User):
            ↓
            Navigate to HomeActivity
            ↓
            Clear task flags
            (Can't go back to OTP screen)
```

**API Implementation:**
```kotlin
btnSubmit.setOnClickListener {
    val otp = etOtp.text.toString().trim()
    
    if (otp.isEmpty()) {
        Toast.makeText(this, "Please enter the OTP", Toast.LENGTH_SHORT).show()
        return@setOnClickListener
    }
    
    if (otp.length != 6) {
        Toast.makeText(this, "OTP must be 6 digits", Toast.LENGTH_SHORT).show()
        return@setOnClickListener
    }
    
    // Show loading
    showLoadingDialog("Verifying OTP, please wait...")
    
    otpRepository.validateOtp(userId, otp)
        .enqueue(object : Callback<OtpResponse> {
            override fun onResponse(call, response) {
                if (response.isSuccessful && response.body() != null) {
                    val otpResponse = response.body()!!
                    
                    if (otpResponse.response == 0) {
                        // Success
                        updateLoadingDialog("OTP verified successfully!")
                        
                        Handler(Looper.getMainLooper()).postDelayed({
                            dismissLoadingDialog()
                            
                            // Save user data
                            saveOtpResponseDetails(otpResponse)
                            
                            // Navigate based on account type
                            if (isNewAccount) {
                                // New user → Profile setup
                                val intent = Intent(this@OtpActivity, RegisterProfileActivity::class.java)
                                intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK
                                startActivity(intent)
                                finish()
                            } else {
                                // Existing user → Home
                                val intent = Intent(this@OtpActivity, HomeActivity::class.java)
                                intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK
                                startActivity(intent)
                                finish()
                            }
                        }, 1000)
                    } else {
                        dismissLoadingDialog()
                        Toast.makeText(
                            this@OtpActivity,
                            otpResponse.message ?: "OTP verification failed",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                } else {
                    dismissLoadingDialog()
                    Toast.makeText(
                        this@OtpActivity,
                        "Verification failed: ${response.message()}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            
            override fun onFailure(call, t) {
                dismissLoadingDialog()
                Toast.makeText(
                    this@OtpActivity,
                    "Network error: ${t.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        })
}
```

---

## 💾 Data Storage After OTP Verification

### SharedPreferences Structure

**File:** `AppPreferences`

**Stored Data:**
```kotlin
private fun saveOtpResponseDetails(otpResponse: OtpResponse) {
    val sharedPreferences = getSharedPreferences("AppPreferences", MODE_PRIVATE)
    sharedPreferences.edit {
        // Access Token (JWT)
        putString("accessToken", otpResponse.tokenData?.access_token)
        
        // User Information
        putString("user", otpResponse.user)                    // Name
        putString("email", otpResponse.email)                  // Email
        putString("roleCode", otpResponse.role_code)           // "patient"
        putString("mobileNumber", otpResponse.mobile_number)   // Mobile
        
        // User IDs
        putInt("id", otpResponse.id ?: -1)                     // Primary ID
        putInt("user_id", otpResponse.user_id ?: -1)           // User ID
        
        // Session Status
        putBoolean("isLoggedIn", true)                         // Login flag
    }
}
```

**Data Breakdown:**

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `accessToken` | String | JWT Bearer token for API authentication | "eyJhbGciOiJIUzI1NiIs..." |
| `user` | String | User's full name | "John Doe" |
| `email` | String | User's email address | "john@example.com" |
| `roleCode` | String | User role (always "patient" for app users) | "patient" |
| `mobileNumber` | String | User's registered mobile number | "9876543210" |
| `id` | Int | Primary user identifier | 123 |
| `user_id` | Int | User ID (same as id) | 123 |
| `isLoggedIn` | Boolean | Session status flag | true |

---

### Token Data Structure

**TokenData Object:**
```kotlin
data class TokenData(
    val access_token: String?,      // JWT token
    val token_type: String?,         // "Bearer"
    val expires_at: String?,         // ISO 8601 format
    val token: TokenDetails?
)

data class TokenDetails(
    val id: String?,                 // Token ID
    val user_id: Int?,               // User ID
    val client_id: Int?,             // OAuth client ID
    val name: String?,               // "Personal Access Token"
    val scopes: List<String>?,       // Empty array
    val revoked: Boolean?,           // false
    val created_at: String?,         // Creation timestamp
    val updated_at: String?,         // Update timestamp
    val expires_at: String?          // Expiry timestamp (30 days)
)
```

---

### Usage of Stored Data

#### 1. API Authentication
```kotlin
// All API calls include Authorization header
@Headers("Authorization: Bearer {accessToken}")

// Example: Fetching user profile
val token = sharedPreferences.getString("accessToken", "")
val userId = sharedPreferences.getInt("user_id", -1)

profileRepository.getUserProfile(userId)
    // Token automatically included in headers
```

#### 2. Session Validation
```kotlin
// On app launch (SplashActivity or MainActivity)
val isLoggedIn = sharedPreferences.getBoolean("isLoggedIn", false)
val accessToken = sharedPreferences.getString("accessToken", null)

if (isLoggedIn && !accessToken.isNullOrEmpty()) {
    // Valid session → HomeActivity
    startActivity(Intent(this, HomeActivity::class.java))
} else {
    // No session → LoginActivity
    startActivity(Intent(this, LoginActivity::class.java))
}
finish()
```

#### 3. User Identification
```kotlin
// Get current user details
val userId = sharedPreferences.getInt("user_id", -1)
val userName = sharedPreferences.getString("user", "")
val userMobile = sharedPreferences.getString("mobileNumber", "")
val userEmail = sharedPreferences.getString("email", "")
```

#### 4. Logout
```kotlin
fun logout() {
    val sharedPreferences = getSharedPreferences("AppPreferences", MODE_PRIVATE)
    sharedPreferences.edit {
        clear()  // Remove all data
    }
    
    // Navigate to LoginActivity
    val intent = Intent(this, LoginActivity::class.java)
    intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK
    startActivity(intent)
    finish()
}
```

---

## 🎨 Design Specifications

### Color Palette

| Element | Color Code | Usage |
|---------|-----------|-------|
| Background | `#D9EDFF` | Screen background (light blue) |
| Card Background | `#FFFFFF` | White cards |
| Primary Text | `#000000` | Titles, labels, input text |
| Secondary Text | `#808080` | Hints, placeholders, dividers |
| Link Text | `#0D99FF` | Clickable links (Sign Up, Sign In) |
| Primary Button | `#15558D` | Submit buttons (green/blue) |
| Input Background | `#FFFFFF` | Input fields with shadow |
| Timer Text (Active) | `#808080` | Countdown timer (gray) |
| Timer Text (Ready) | `#0D99FF` | Resend available (blue) |
| Error Text | `#F44336` | Error messages (red) |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Screen Title | 24sp | Bold | Black |
| Subtitle | 16sp | Normal | Black |
| Input Text | 16sp | Normal | Black |
| Input Hint | 16sp | Normal | Gray (#808080) |
| Button Text | 18sp | Bold | White |
| Link Text | 18sp | Normal | Gray/Blue |
| OTP Input | 24sp | Bold | Black |
| Timer Text | 14sp | Normal | Gray/Blue |
| Loading Text | 16sp | Normal | Black |

### Spacing

| Element | Value |
|---------|-------|
| Screen Padding | 16dp |
| Card Padding | 32dp horizontal, 40dp vertical |
| Card Margin | 12dp horizontal |
| Card Corner Radius | 20dp |
| Card Elevation | 8dp |
| Input Padding | 15dp |
| Input Margin Bottom | 16-24dp |
| Button Margin Bottom | 16dp |
| Section Spacing | 24dp |

---

## 📱 User Experience Flows

### Flow 1: New User Registration

```
App Launch
    ↓
User not logged in
    ↓
LoginActivity displays
    ↓
User taps "Sign Up"
    ↓
RegisterActivity displays
    ↓
User enters:
    Name: "John Doe"
    Mobile: "9876543210"
    ↓
User taps "Have a referral code?"
    ↓
Dialog appears
    ↓
User enters: "REF123"
    ↓
Referral tag shows: [REF123 ✕]
    ↓
User taps "Register"
    ↓
Loading: "Sending OTP..."
    ↓
API creates account
    ↓
SMS sent: "Your OTP is: 123456"
    ↓
Loading: "OTP sent successfully!"
    ↓
Navigate to OtpActivity
    ↓
User sees:
    "OTP sent to 9876543210"
    Timer: "Resend code in 00:60"
    ↓
User enters OTP: "123456"
    ↓
User taps "Verify OTP"
    ↓
Loading: "Verifying OTP..."
    ↓
API validates OTP
    ↓
Loading: "OTP verified successfully!"
    ↓
Data saved to SharedPreferences:
    - accessToken
    - user: "John Doe"
    - mobileNumber: "9876543210"
    - isLoggedIn: true
    ↓
Navigate to RegisterProfileActivity
    (Complete profile: DOB, Gender, Height, etc.)
    ↓
After profile completion
    ↓
Navigate to HomeActivity
    ↓
User logged in ✓
```

---

### Flow 2: Existing User Login

```
App Launch
    ↓
Check isLoggedIn
    ↓
False → LoginActivity
    ↓
User enters Mobile: "9876543210"
    ↓
User taps "Sign In"
    ↓
Loading: "Sending OTP..."
    ↓
API checks user exists
    ↓
SMS sent: "Your OTP is: 654321"
    ↓
Loading: "OTP sent successfully!"
    ↓
Navigate to OtpActivity
    ↓
User enters OTP: "654321"
    ↓
User taps "Verify OTP"
    ↓
Loading: "Verifying OTP..."
    ↓
API validates OTP
    ↓
Loading: "OTP verified successfully!"
    ↓
Data saved to SharedPreferences
    ↓
Navigate to HomeActivity (DIRECT)
    ↓
User logged in ✓
```

---

### Flow 3: OTP Resend

```
User on OtpActivity
    ↓
Didn't receive OTP
    ↓
Wait for 60-second timer
    ↓
Timer: "00:60" → "00:45" → "00:30" → ... → "00:00"
    ↓
Text changes: "Resend OTP" (blue, underlined)
    ↓
User taps "Resend OTP"
    ↓
API call: POST /login (same as before)
    ↓
New OTP generated
    ↓
SMS sent: "Your OTP is: 789012"
    ↓
Toast: "OTP resent successfully!"
    ↓
Timer resets: "00:60"
    ↓
User enters new OTP
```

---

### Flow 4: Session Persistence

```
User logged in previously
    ↓
User closes app
    ↓
[Next Day]
    ↓
User opens app
    ↓
App checks SharedPreferences:
    isLoggedIn: true
    accessToken: "eyJhbGc..."
    user_id: 123
    ↓
Token valid (not expired)
    ↓
Navigate directly to HomeActivity
    ↓
User continues where they left off ✓
```

---

## 🔌 API Endpoints Summary

### 1. Login (Send OTP)

**Endpoint:** `POST /login`

**Request:**
```json
{
    "mobile_number": "9876543210"
}
```

**Response (Success):**
```json
{
    "response": 0,
    "message": "OTP sent successfully",
    "user_id": 123
}
```

---

### 2. Register (Send OTP)

**Endpoint:** `POST /register`

**Request:**
```json
{
    "mobile_number": "9876543210",
    "name": "John Doe",
    "referral_code": "REF123"
}
```

**Response (Success):**
```json
{
    "response": 0,
    "message": "OTP sent successfully",
    "user_id": 123,
    "patient_id": 456
}
```

---

### 3. Validate OTP

**Endpoint:** `POST /validate_otp`

**Request:**
```json
{
    "user_id": 123,
    "otp": "123456"
}
```

**Response (Success):**
```json
{
    "response": 0,
    "message": "OTP verified successfully",
    "id": 123,
    "user_id": 123,
    "user": "John Doe",
    "email": "john@example.com",
    "role_code": "patient",
    "mobile_number": "9876543210",
    "tokenData": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "token_type": "Bearer",
        "expires_at": "2026-06-23T14:30:00.000000Z",
        "token": {
            "id": "token_id_123",
            "user_id": 123,
            "client_id": 1,
            "name": "Personal Access Token",
            "scopes": [],
            "revoked": false,
            "created_at": "2026-05-24T14:30:00.000000Z",
            "updated_at": "2026-05-24T14:30:00.000000Z",
            "expires_at": "2026-06-23T14:30:00.000000Z"
        }
    },
    "status": 1
}
```

---

## 🧪 Testing Checklist

### Functionality Tests

#### LoginActivity
- [ ] Mobile input validation (10 digits)
- [ ] API call successful
- [ ] Loading dialog displays
- [ ] Navigation to OtpActivity
- [ ] Sign Up link navigates to RegisterActivity
- [ ] Error handling (user not found)

#### RegisterActivity
- [ ] Name and mobile validation
- [ ] Referral code dialog
- [ ] Referral tag display/remove
- [ ] API call successful
- [ ] Navigation to OtpActivity
- [ ] Sign In link navigates to LoginActivity
- [ ] Error handling (mobile exists)

#### OtpActivity
- [ ] Receives intent extras correctly
- [ ] OTP input validation (6 digits)
- [ ] 60-second countdown timer
- [ ] Resend OTP functionality
- [ ] API call successful
- [ ] SharedPreferences data saved
- [ ] Navigation based on new_account flag
- [ ] Back button navigation
- [ ] Error handling (invalid OTP)

#### Data Storage
- [ ] All fields saved correctly
- [ ] Token stored successfully
- [ ] isLoggedIn flag set to true
- [ ] Data retrieved correctly
- [ ] Logout clears all data

---

### UI/UX Tests
- [ ] Background color correct
- [ ] Card elevation visible
- [ ] Input shadows display
- [ ] Button styling correct
- [ ] Text formatting correct
- [ ] Spannable text (links) styled
- [ ] Loading dialog animates
- [ ] Keyboard auto-shows/hides
- [ ] Timer updates every second
- [ ] Smooth transitions

---

## 🚀 Security Considerations

### 1. OTP Expiry
- OTP valid for 5 minutes only
- Expired OTPs rejected by backend

### 2. Rate Limiting
- Maximum OTP requests: 3 per mobile per hour
- Prevents spam/abuse

### 3. Token Security
- JWT tokens stored in encrypted SharedPreferences (if using EncryptedSharedPreferences)
- Token expires after 30 days
- Refresh token mechanism (future enhancement)

### 4. Mobile Verification
- Only verified mobile numbers can access app
- SMS OTP validates phone ownership

### 5. Logout Security
- Clear all data on logout
- Revoke token on server (future enhancement)

---

**Document Version:** 1.0  
**Last Updated:** May 24, 2026  
**Author:** HEARTO Development Team  
**Status:** Production Ready

