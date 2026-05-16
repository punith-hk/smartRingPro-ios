# API Endpoints & Token Flow — HEARTO Android App

## Base URL

```
https://hearto.in/api/
```

### All 3 Environments (in `ApiClient.kt` & `UserDataApiClient.kt`)

| Environment | Base URL | Status |
|-------------|----------|--------|
| Test | `https://app.mannaheal.com/api/` | ❌ Commented out |
| Production | `https://webapi.mannaheal.com/api/` | ❌ Commented out |
| **Current (Active)** | `https://hearto.in/api/` | ✅ Active |

---

## Two Retrofit Instances

The BASE_URL is defined **twice** — in two separate Retrofit singletons:

| Singleton | File | Purpose |
|-----------|------|---------|
| `ApiClient` | `ApiClient.kt` | Main REST client — all API calls |
| `UserDataApiClient` | `UserDataApiClient.kt` | Health/ring data API calls (separate instance, same BASE_URL, same `AuthInterceptor`) |

Both are initialized in `Application.onCreate()` or `HomeActivity.onCreate()` via:
```kotlin
ApiClient.init(context)
UserDataApiClient.init(context)
```

Both use the same `AuthInterceptor` and same `BASE_URL`.

---

## Token Flow

### Step 1 — Login (no token)
```
User enters mobile number
        │
        ▼
POST /login
  Body: mobile_number
        │
        ▼
Response: { response: 0, message: "OTP sent", user_id: Int }
  user_id saved to SharedPreferences["user_id"]
```

### Step 2 — OTP Verify (no token)
```
User enters OTP
        │
        ▼
POST /verifyotp
  Body: user_id, otp
        │
        ▼
Response:
  {
    response: 0,
    id, user_id, user, email, role_code, mobile_number,
    tokenData: {
      access_token: "eyJ...",
      token_type: "Bearer",
      expires_at: "2026-...",
      token: { id, user_id, client_id, scopes, revoked, created_at, expires_at }
    }
  }
        │
        ▼
Save to SharedPreferences:
  - "accessToken"  ← tokenData.access_token
  - "isLoggedIn"   ← true
  - "user_id"      ← user_id
```

### Step 3 — Authenticated Requests (with token)
```
Every API call
        │
        ▼
AuthInterceptor.intercept()
        │
        ├── Check if endpoint is PUBLIC (/login, /verifyotp, /register)
        │       └── YES → Skip token, send as-is
        │
        └── NO (private endpoint)
                │
                ▼
        Read SharedPreferences["accessToken"]
                │
                ▼
        Add header:  Authorization: Bearer <token>
                │
                ▼
        Proceed with request
```

### Step 4 — Token Expiry / 401 Handling
```
API returns 401
        │
        ▼
AuthInterceptor detects response.code == 401
        │
        ▼
synchronized(lock) — only ONE refresh at a time
        │
        ▼
POST /refresh-token
  Header: Authorization: Bearer <oldToken>
        │
        ├── SUCCESS → New access_token received
        │       ├── Save to SharedPreferences["accessToken"]
        │       └── Retry original request with new token → return response
        │
        └── FAILURE (null / error)
                ├── SharedPreferences["isLoggedIn"] = false
                ├── SharedPreferences["accessToken"] removed
                └── App forces logout (redirects to Login screen)
```

### Concurrent Request Handling During Refresh
```
If another request hits 401 while refresh is in progress:
  → Thread.sleep(100ms) loop until isRefreshing == false
  → Read new token from SharedPreferences
  → Retry with new token
```

---

## Token Storage — SharedPreferences

| Key | Value | Set When |
|-----|-------|----------|
| `accessToken` | `"eyJ..."` (Bearer token string) | OTP verify success / refresh success |
| `isLoggedIn` | `true` / `false` | OTP verify success / logout / refresh fail |
| `user_id` | `Int` | OTP verify success |

SharedPreferences file name: `"AppPreferences"`, mode: `MODE_PRIVATE`

---

## Public Endpoints (No Auth Header)

These endpoints are **bypassed** by `AuthInterceptor` — no `Authorization` header injected:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/login` | POST | Send OTP to mobile number |
| `/verifyotp` | POST | Verify OTP, returns access token |
| `/register` | POST | Register new user |

---

## All API Endpoints

### 🔐 Auth

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `login` | POST (Form) | `LoginApiService` | `mobile_number` | `{ response, message, user_id }` |
| `verifyotp` | POST (Form) | `OtpApiService` | `user_id`, `otp` | `{ response, id, user_id, tokenData }` |
| `register` | POST (Form) | `RegisterApiService` | `mobile_number`, `name` | `RegisterResponse` |
| `refresh-token` | POST | `RefreshTokenApiService` | Header: `Authorization: Bearer <token>` | `{ response, access_token, token, token_type, expires_at }` |

---

### 👤 Profile

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `patients/{id}` | GET | `ProfileDataApiService` | `id` = userId | `ProfileDataResponse` |
| `patients/{id}` | POST (Multipart) | `ProfileDataApiService` | Full profile fields + optional profile image | `AddProfileDataResponse` |

**Profile fields (POST):** `user_id, id, first_name, last_name, email, gender, phone_number, emergency_phone, dob, blood_group, address, city, state, country, pincode, height, weight, allergy, status, existing_diseases, existing_medications, profileImage`

---

### 👨‍👩‍👧‍👦 Family Members / Dependents

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `patients/{id}/dependents` | GET | `ProfileDataApiService` | `id` = userId | `DependentsResponse` |
| `patients/{id}/dependents` | POST (Multipart) | `ProfileDataApiService` | Family member fields + image | `AddProfileDataResponse` |
| `patients/{id}/dependents/{dependentId}` | POST (Multipart) | `ProfileDataApiService` | Update member fields | `AddProfileDataResponse` |
| `patients/{id}/dependents/{dependentId}` | DELETE | `ProfileDataApiService` | userId + dependentId | `AddProfileDataResponse` |

---

### 🏥 Appointments & Doctors

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `departments` | GET | `SpecializationApiService` | — | `List<Specializations>` |
| `departments/{id}` | GET | `SpecializationApiService` | `id` = dept id | `Departments` |
| `doctors/{id}/schedules` | GET | `SpecializationApiService` | `id` = doctor id | `Schedules` |
| `appointments` | POST (Form) | `SpecializationApiService` | `appointment_date, time, doctor_id, patient_id, purpose, status, dependent_id, type` | `bookAppointmentResponse` |
| `patients/myappointments` | GET | `SpecializationApiService` | `patient_id` | `Appointments` |
| `doctors/myappointments` | GET | `SpecializationApiService` | `doctor_id` | `Appointments` |
| `appointments/{id}/answers` | GET | `SpecializationApiService` | `id` = appt id | `List<Answers>` |

---

### 🩺 Symptoms & Diseases

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `getAllSymptoms` | GET | `SymptomsApiService` | — | `SymptomsResponse` |
| `diseases/list` | GET | `SymptomsApiService` | — | `List<Disease>` |
| `patients/{id}/symptoms` | POST (Multipart) | `SymptomsApiService` | `dependent_id, appt_time, symptom` | `SaveSymptomsResponse` |

---

### 💓 Ring / Health Data (`UserDataApiClient`)

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `CreateRingValue` | POST | `UserHealthDataApiService` | `user_id, type, value, timestamp` (query) | `AddUserHealthDataResponse` |
| `CreateRingValues` | POST (JSON Body) | `UserHealthDataApiService` | `CreateRingValuesRequest` (batch) | `AddUserHealthDataResponse` |
| `getRingDataByType` | GET | `UserHealthDataApiService` | `user_id, type, page, limit` | `GetUserHealthDataResponse` |
| `getRingDataByDay` | GET | `UserHealthDataApiService` | `user_id, type` | `GetUserHealthDataByDayResponse` |
| `getLastRingData` | GET | `UserHealthDataApiService` | `user_id` | `GetLastUserHealthDataResponse` |
| `getSleepData` | GET | `UserHealthDataApiService` | `user_id, selectedDate` OR `startDate, endDate` | `SleepResponse` |
| `getSleepSessions` | GET | `UserHealthDataApiService` | `user_id` | `SleepResponseSessions` |
| `CreateSleepData` | POST | `UserHealthDataApiService` | `user_id` + `SleepBean` body | `Void` |
| `ecg-records` | POST (JSON Body) | `UserHealthDataApiService` | `EcgRecordsRequest` | `EcgRecordsPostResponse` |
| `ecg-records/{userId}` | GET | `UserHealthDataApiService` | `userId` (path) | `EcgPaginationResponse` |
| `user-app-details` | POST (JSON Body) | `UserHealthDataApiService` | `DeviceStatusRequest` | `AddUserAppDetailResponse` |
| `getAutoSyncConfig` | GET | `RingApiService` | — | `RingConfigResponse` |

#### Ring Data Types (used in `type` param)

| Type String | Vital |
|-------------|-------|
| `"heart_rate"` | Heart Rate (BPM) |
| `"hrv"` | Heart Rate Variability |
| `"blood_oxygen"` | SpO2 / Blood Oxygen |
| `"blood_pressure"` | Blood Pressure |
| `"ecg"` | ECG |
| `"steps"` | Steps |
| `"calories"` | Calories |
| `"temperature"` | Body Temperature |

---

### 🔗 Linked Accounts / Caretaker

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `getLastRingData` | GET | `LinkedAccountApiService` | `user_id` (query) | `LastRingDataResponse` |
| `caretaker/{user_id}` | GET | `LinkedAccountApiService` | `user_id` (path) | `List<LinkedAccountInfo>` |
| `caretaker/request` | POST (JSON Body) | `LinkedAccountApiService` | `CaretakerRequestBody` | `AddLinkedAccountResponse` |
| `caretaker/verify` | POST (JSON Body) | `LinkedAccountApiService` | `CaretakerVerifyOtpRequestBody` | `CaretakerVerifyOtpResponse` |

---

### 🔔 Notifications

| Endpoint | Method | Service | Params | Response |
|----------|--------|---------|--------|----------|
| `user/notifications` | GET | `NotificationsApiService` | `user_id`, `unread_only: Boolean` | `NotificationsResponse` |
| `user/notifications/{id}/read` | POST | `NotificationsApiService` | `id` (path), `userId` (body) | `SimpleResponse` |
| `user/fcm-token` | POST (JSON Body) | `RegisterApiService` | `FcmTokenRequest` | `FcmTokenResponse` |

---

## OkHttp Client Configuration

Both `ApiClient` and `UserDataApiClient` use the same config:

```
OkHttpClient
  ├── AuthInterceptor(context.applicationContext)   ← injects Bearer token
  ├── HttpLoggingInterceptor (Level.BODY)            ← logs all req/res bodies
  ├── connectTimeout: 30s
  ├── readTimeout:    30s
  └── writeTimeout:   30s
```

---

## iOS Implementation Notes

1. **Base URL:** `https://hearto.in/api/` — single base for all calls
2. **Token storage:** Use `UserDefaults` or `Keychain` — key: `accessToken`
3. **Auth header:** Every private request → `Authorization: Bearer <token>`
4. **Public endpoints** (`/login`, `/verifyotp`, `/register`) → skip auth header
5. **Token refresh:** On 401 → call `POST /refresh-token` with old token in header → save new token → retry original request
6. **Logout on refresh fail:** Clear token + `isLoggedIn` flag → navigate to login
7. **Two client instances** → can simplify to one in iOS with a single `URLSession` + interceptor pattern (`URLProtocol` or `Alamofire RequestInterceptor`)
8. **FCM token** → call `POST user/fcm-token` after login/OTP verify success (use APNs token mapped to FCM on iOS)
9. **Multipart uploads** (profile, family member) → use `multipart/form-data` encoding
10. **Batch health data** → `POST CreateRingValues` with JSON body (preferred over single `CreateRingValue`)

