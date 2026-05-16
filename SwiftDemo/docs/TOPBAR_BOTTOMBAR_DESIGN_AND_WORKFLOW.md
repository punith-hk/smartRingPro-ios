# MannHeal Pro — Top Bar & Bottom Bar: Design & Workflow Reference

> **Purpose:** Complete reference for implementing the Top Navigation Bar, Bottom Navigation Bar, and Side Drawer for iOS (or any platform), mirroring the Android implementation in `HomeActivity.kt` + `activity_home.xml`.

---

## 1. Overall Screen Structure

```
┌─────────────────────────────────────────────────────┐
│                   TOP BAR (64dp)                    │
│  [☰ Menu]    [HEARTO Logo]         [🔔 Bell + Badge]│
└─────────────────────────────────────────────────────┘
│                                                     │
│              FRAGMENT CONTAINER                     │
│         (fills remaining space)                     │
│                                                     │
└─────────────────────────────────────────────────────┘
│               BOTTOM NAV BAR                        │
│  [Health] [Doctor] [Appointment] [Device] [FamCare] │
└─────────────────────────────────────────────────────┘

Side Drawer (slides from LEFT — triggered by ☰ Menu):
┌──────────────────────────────┐
│  [User Avatar]               │
│  User Name                   │
│  Phone Number      [✕ close] │
│ ─────────────────────────── │
│  👨‍👩‍👧‍👦  Family Members          │
│  📅  Appointment Summary     │
│ ─────────────────────────── │
│  👤  Profile Settings        │
│  🎁  Refer A Friend          │
│ ─────────────────────────── │
│  ❓  Help & Support          │
│  🚪  Logout                  │
└──────────────────────────────┘
```

---

## 2. Top Bar (Toolbar)

### Visual Design
| Property | Value |
|----------|-------|
| Height | `64dp` |
| Background color | `#15558D` (dark blue) |
| Elevation | `4dp` |
| Text color | White |

### Layout (Left → Right)
```
[☰ Hamburger/Menu Icon]   [HEARTO Logo — centered, fills space]   [🔔 Bell Icon + Badge]
```

### Left Side — Hamburger Menu Icon (`drawerIcon`)
- **Widget:** `ImageButton`
- **Size:** `56dp` width, `wrap_content` height
- **Icon:** `baseline_menu_24` drawable
- **Tint:** White (`#FFFFFF`)
- **Background:** Transparent
- **Padding:** top/bottom `16dp`
- **Behavior:**
  - Visible → **only on root fragments** (Dashboard, Specialists, Appointments, Device, Appointments)
  - Hidden (replaced by back arrow) → on sub-fragments

### Center — HEARTO Logo (`toolbarLogo`)
- **Widget:** `ImageView`
- **Width:** `0dp` (fills remaining space using `weight=1` in LinearLayout)
- **Height:** `38dp`
- **Scale type:** `centerInside`, `adjustViewBounds = true`
- **Source:** `@drawable/ic_logo_hearto`
- **The logo is ALWAYS fixed** — title text is hidden (`toolbarTitle` is `gone`)
- **Title TextView exists but is never shown** (legacy code, kept commented out)

### Right Side — Notification Bell
#### Bell Icon (`notificationIcon`)
- **Widget:** `ImageButton`
- **Size:** `56dp` × `wrap_content`
- **Icon:** `baseline_notifications_24`
- **Tint:** White
- **Background:** Transparent
- **Padding:** all sides `16dp`
- **Visibility rules:**
  - **Always visible** except when `NotificationsFragment` is active
  - When navigating to `NotificationsFragment` → bell is hidden
  - When navigating back from `NotificationsFragment` → bell is restored

#### Notification Badge (`notificationBadge`)
- **Widget:** `TextView`
- **Size:** `18dp` × `18dp`
- **Position:** `top|end` overlay on the bell icon (top-right corner)
- **Margins:** `8dp` top, `6dp` end
- **Background:** `badge_background` drawable (red circle)
- **Text color:** White
- **Text size:** `10sp`, bold
- **Visibility:** `VISIBLE` only if unread count > 0; `GONE` otherwise
- **Text:** count number; if count > 99 → shows `"99+"`

### Back Arrow (Sub-Fragment State)
- Shown instead of hamburger when navigating into sub-fragments
- **Icon:** `baseline_arrow_back_ios_24`
- **Tint:** Always white (`#FFFFFF`)
- **On tap:** triggers `backPressed()` → `supportFragmentManager.popBackStack()`

---

## 3. Top Bar — State Matrix

| Fragment Type | Hamburger | Back Arrow | Notification Bell |
|--------------|-----------|-----------|------------------|
| Root fragment (Dashboard, Specialists, etc.) | ✅ Visible | ❌ Hidden | ✅ Visible |
| Sub-fragment (ECG, Profile, Sleep, etc.) | ❌ Hidden | ✅ Visible | ✅ Visible |
| `NotificationsFragment` | ❌ Hidden | ✅ Visible | ❌ Hidden |

---

## 4. Notification Bell — Full Workflow

```
App Launch / onResume
      │
      ▼
refreshNotifications(forceRefresh = false)
      │
      ├── NotificationCache.isValid? (TTL: 5 min)
      │       YES → updateBadge from cache + notifyDashboard()
      │       NO  → fetch from API
      │
      ▼
API: NotificationsRepository.getNotifications(userId, unreadOnly=true)
      │
      ├── Success → NotificationCache.update(items)
      │             updateNotificationBadge(unreadCount)
      │             notifyDashboard()
      │
      └── Failure → use cache fallback (still update badge + dashboard)

updateNotificationBadge(count):
  - notificationIcon always VISIBLE
  - if count > 0  → badge VISIBLE, text = count (max "99+")
  - if count == 0 → badge GONE

Tapping Bell Icon:
  - if current fragment == NotificationsFragment → do NOTHING (return)
  - else → openFragment(NotificationsFragment, addToBackStack = true)
         → bell icon becomes GONE while inside NotificationsFragment
         → badge cleared to 0 visually (updateNotificationBadge(0))
```

### NotificationCache
- **In-memory cache** — set by `HomeActivity.refreshNotifications()`
- **TTL:** 5 minutes
- **Properties:** `latest` (most recent `NotificationItem`), `unreadCount`, `isValid`
- **DashboardFragment** reads from cache directly — zero API calls

---

## 5. Bottom Navigation Bar

### Visual Design
| Property | Value |
|----------|-------|
| Background color | `#15558D` (same dark blue as top bar) |
| Icon tint — selected | White (`#FFFFFF`) |
| Icon tint — unselected | Semi-transparent white (~60%) |
| Text color — selected | White |
| Text color — unselected | Semi-transparent white |
| Label mode | Always visible (`labeled`) |
| Theme | `ThemeOverlay.MaterialComponents` |

Icon tint state list (`bottom_nav_item_tint`):
```xml
<!-- selected state → white; default → 60% white -->
```

### 5 Tab Items

| Position | Tab ID | Icon | Label | Fragment |
|---------|--------|------|-------|----------|
| 1 | `R.id.home` | `baseline_monitor_heart_24` | Health | `DashboardFragment` |
| 2 | `R.id.specialists` | `baseline_local_hospital_24` | Doctor | `SpecialistsFragment` |
| 3 | `R.id.appointments` | `baseline_event_note_24` | Appointment | `AppointmentsFragment` |
| 4 | `R.id.device` | `baseline_album_24` | Device | `DeviceFragment` |
| 5 | `R.id.activity` | `baseline_diversity_3_24` | Family Care | `CareFragment` |

---

## 6. Bottom Navigation — Full Workflow

### Tab Selection Logic

```
User taps tab item
      │
      ▼
Is the tapped tab already selected AND not Health tab?
  YES → return (no navigation)
  NO  → navigate

Health tab (R.id.home):
  Is current fragment DashboardFragment?
    YES → do nothing (return true)
    NO  → openFragment(DashboardFragment, clearBackStack = true)

Other tabs (Doctor / Appointment / Device / Family Care):
  Is tapped tab already selectedItemId?
    YES → return (do nothing)
    NO  → openFragment(respective fragment, clearBackStack = true)
```

### Back Stack Behavior
- All bottom nav tab navigations use `clearBackStack = true`
  → `supportFragmentManager.popBackStack(null, POP_BACK_STACK_INCLUSIVE)` before replacing
- This ensures no stale fragments remain when switching tabs

### Bottom Nav Selection Sync (on back press)
When user presses back from a sub-fragment, the bottom nav selection is synced:
```
popBackStack()
      │
      ▼
getCurrentFragment()
      │
      ├── DashboardFragment or HomeFragment → select "Health" tab
      ├── SpecialistsFragment → select "Doctor" tab
      ├── AppointmentsFragment → select "Appointment" tab
      ├── DeviceFragment → select "Device" tab
      └── CareFragment → select "Family Care" tab
```

### Root Fragments (back stack is NOT added)
These fragments replace content without adding to back stack:
- `HomeFragment` (legacy)
- `DashboardFragment`
- `SpecialistsFragment`
- `DeviceFragment`
- `AppointmentsFragment`

### Special Case — Device Tab on Startup
If a device MAC is saved but BLE is NOT connected:
```
onCreate → bottomNavigationView.selectedItemId = R.id.device
         → sideNavigationView.setCheckedItem(R.id.nav_settings)
```
Otherwise → open `DashboardFragment` on startup.

---

## 7. Fragment Navigation — `openFragment()` Function

```kotlin
fun openFragment(
    fragment: Fragment,
    title: String,
    addToBackStack: Boolean = false,
    clearBackStack: Boolean = false
)
```

### Steps executed:
1. If `clearBackStack` → pop entire back stack
2. `fragmentManager.beginTransaction().replace(R.id.fragmentContainer, fragment)`
3. If `addToBackStack` → `addToBackStack(null)`
4. Commit transaction
5. If fragment == `NotificationsFragment` → hide bell, clear badge
6. Else → show bell + refresh badge
7. If `isRootFragment(fragment)` → hide back arrow, show hamburger
8. Else → show back arrow (white tinted), hide hamburger

### `isRootFragment()` check
Fragments considered root (no back arrow, hamburger shown):
- `HomeFragment` (legacy)
- `DashboardFragment`
- `SpecialistsFragment`
- `DeviceFragment`
- `AppointmentsFragment`

---

## 8. Side Drawer (Left Navigation Drawer)

### Visual Design
| Property | Value |
|----------|-------|
| Width | `280dp` |
| Height | `match_parent` |
| Background | `#FFFFFF` |
| Elevation | `8dp` |
| Slides from | Left (`GravityCompat.START`) |
| Item text color | `#333333` |

### Opening
- Tapping `☰` hamburger icon → `drawerLayout.openDrawer(GravityCompat.START)`

### Closing
- Tapping `✕` close icon in header
- After any menu item selection → auto closes

---

### Drawer Header (`drawer_header` layout)

| Element | Detail |
|---------|--------|
| Profile image (`profileImage`) | Circular, loaded via Glide; fallback: `baseline_account_circle_24` |
| Profile image source | Fetched from API (`patient_image_url`) on launch |
| User name (`userName`) | From `AppPreferences → "user"` key, title-cased |
| Phone number (`userNumber`) | From `AppPreferences → "mobileNumber"` |
| Close icon (`closeIcon`) | Taps close the drawer |

---

### Drawer Menu Items

| Group | Item ID | Emoji | Label | Action |
|-------|---------|-------|-------|--------|
| Main | `nav_family_members` | 👨‍👩‍👧‍👦 | Family Members | `openFragment(FamilyMembersFragment, addToBackStack=true)` |
| Main | `nav_settings` | 📅 | Appointment Summary | Sets `isAppointmentSummary=1` in prefs, `openFragment(AppointmentsFragment)` |
| Main | `nav_vitals` | 📋 | Vitals | `openFragment(VitalsFragment, addToBackStack=true)` — **hidden** (visibility=false) |
| Account | `nav_about` | 👤 | Profile Settings | `openFragment(ProfileFragment, addToBackStack=true)` + reset bottom nav |
| Account | `nav_refer_friend` | 🎁 | Refer A Friend | `openFragment(ReferToFriendFragment, addToBackStack=true)` |
| Settings | `nav_help_support` | ❓ | Help & Support | `openFragment(HelpSupportFragment, addToBackStack=true)` |
| Settings | `nav_logout` | 🚪 | Logout | Show logout confirmation dialog |

**Note:** After every menu item tap → drawer auto-closes.

### Bottom Nav Reset on Profile
When opening Profile from drawer:
```kotlin
openFragment(ProfileFragment(), "Profile", true)
resetBottomNavSelection()  // unchecks all tabs
```

---

## 9. Back Button Handling

```
User presses Back (hardware or gesture)
      │
      ▼
backStackEntryCount > 0?
  YES → popBackStack()
        (100ms delay)
        → get current fragment
        → update hamburger/back arrow state
        → if NotificationsFragment → hide bell
          else → show bell + refreshNotifications()
        → if rootFragment → sync bottom nav selection
  NO  → show "Exit" confirmation dialog
```

### Exit Confirmation Dialog
- Title: `"Exit"`
- Message: `"Are you sure you want to exit?"`
- Buttons: `"No"` (dismiss) / `"Yes"` (finish activity)
- Not cancelable (user must tap a button)

### Logout Confirmation Dialog
- Title: `"Logout"`
- Message: `"Are you sure you want to logout?"`
- Buttons: `"Cancel"` / `"Yes, Logout"`
- On confirm:
  1. `clearUserData()` — clears all SharedPreferences, Room DB, cache, files
  2. Stop `BackgroundService`
  3. Navigate to `LoginActivity`
  4. `finish()` HomeActivity

---

## 10. Startup Flow (HomeActivity.onCreate)

```
onCreate()
  │
  ├── Inflate layout, setup toolbar
  ├── Read deviceMacAddress + deviceName from ConnectionPreferences
  ├── Check BLE state
  ├── setSupportActionBar(toolbar)
  ├── Set toolbar back arrow tint → WHITE
  ├── setupDrawer()
  │     ├── Load user name/number from SharedPreferences
  │     └── fetchUserProfileData(userId) from API
  │           ├── Save height/weight/gender/age to SharedPreferences
  │           ├── Load profile image via Glide into drawer header
  │           ├── requestLocationPermissions()
  │           └── If profile incomplete → redirect to RegisterProfileActivity
  │
  ├── Setup notification bell click listener
  ├── Setup bottom nav listener (5 tabs)
  │
  ├── Determine initial screen:
  │     ├── Device paired but NOT connected → show DeviceFragment
  │     └── Otherwise → show DashboardFragment
  │
  ├── Setup back press callback → backPressed()
  └── checkAndRequestNotificationPermission() (Android 13+)

onResume():
  └── refreshNotifications()  (uses 5-min TTL cache)
```

---

## 11. Permissions Requested on Launch

| Permission | When | Purpose |
|-----------|------|---------|
| `ACCESS_FINE_LOCATION` | On startup | GPS for location worker |
| `ACCESS_COARSE_LOCATION` | On startup | GPS fallback |
| `ACCESS_BACKGROUND_LOCATION` | Android 10+ after foreground granted | Background GPS |
| `BLUETOOTH_CONNECT` | Android 12+ | BLE connection to ring |
| `POST_NOTIFICATIONS` | Android 13+ | Push notification delivery |

### Location Permission Flow
```
Check if fine/coarse already granted
  YES → schedule LocationWorker (every 15 min)
        → checkBluetoothReadyAndStartService()
  NO  → request permissions via ActivityResultContracts
        on grant → schedule LocationWorker
                → check if background location also needed (Android 10+)
                → show background location dialog
        on deny → show toast "Location permission is required"
```

---

## 12. Profile Fetch on Launch

On every app launch, HomeActivity calls `fetchUserProfileData(userId)`:
- **Source:** `ProfileDataRepository.getUserProfileData(userId)` (API)
- **Saved keys** (AppPreferences):

| Key | Value |
|-----|-------|
| `user_gender` | gender string |
| `user_age` | Int |
| `first_name` | String |
| `last_name` | String |
| `user_height` | String (cm or feet.inches) |
| `user_weight` | String (kg) |

- **Profile image:** loaded via Glide into `sideNavigationView` header `ImageView` (circular crop)
- **Incomplete profile check:**
  - If gender, dob, height are all null AND `checkProfile` pref is false → redirect to `RegisterProfileActivity`
  - Sets `checkProfile = true` so redirect only happens once

---

## 13. Logout Flow — clearUserData()

Clears everything on logout:

| Action | Detail |
|--------|--------|
| SharedPreferences: AppPreferences | Removes: `accessToken`, `user`, `email`, `roleCode`, `mobileNumber`, `id`, `isLoggedIn` |
| SharedPreferences: UserPreferences | Full clear |
| ConnectionPreferences | `clearAll()` |
| ApplicationPreferences | `clearAll()` |
| BackgroundService | `stopService()` |
| Room DB | `clearAllTables()` on IO dispatcher |
| Cache dir | `deleteRecursively()` |
| Files dir | each file `deleteRecursively()` |

---

## 14. iOS Implementation Notes

| Android | iOS Equivalent |
|---------|---------------|
| `Toolbar` | `UINavigationBar` or custom `UIView` (64pt height) |
| `DrawerLayout` + `NavigationView` | `UISideMenuNavigationController` or custom slide-in panel |
| `BottomNavigationView` | `UITabBarController` |
| `supportFragmentManager.replace()` | `UINavigationController.pushViewController()` or tab's root VC swap |
| `popBackStack()` | `navigationController.popViewController(animated:)` |
| `addToBackStack` | push to navigation stack |
| `clearBackStack` | `popToRootViewController` before pushing |
| `NotificationsFragment` hide bell | in `viewWillAppear` / `viewWillDisappear` of notification VC |
| `ActivityResultContracts` | `CLLocationManager`, `CBCentralManager` authorization |
| `DrawerLayout.openDrawer()` | custom side panel animation or `UIPresentationController` |
| `ImageButton` with `tint` | `UIButton` with `UIImage.withRenderingMode(.alwaysTemplate)` + `tintColor` |
| `NotificationCache` TTL | `NSCache` or singleton with `Date` timestamp check |
| `SharedPreferences` | `UserDefaults` |
| `Glide` circular crop | `SDWebImage` + `UIImage` corner radius mask |

---

## 15. Color Reference

| Element | Color |
|---------|-------|
| Top bar background | `#15558D` |
| Bottom nav background | `#15558D` |
| Top bar icon tint | `#FFFFFF` (white) |
| Bottom nav selected icon/text | `#FFFFFF` |
| Bottom nav unselected | ~60% white (semi-transparent) |
| Drawer background | `#FFFFFF` |
| Drawer item text | `#333333` |
| Notification badge background | Red (`badge_background` drawable) |
| Notification badge text | `#FFFFFF` |

---

## 16. Key IDs Reference

| ID | Widget | Description |
|----|--------|-------------|
| `toolbar` | `Toolbar` | Top app bar |
| `drawerIcon` | `ImageButton` | Hamburger menu (☰) |
| `toolbarLogo` | `ImageView` | HEARTO logo (center) |
| `toolbarTitle` | `TextView` | Title text (always `gone`) |
| `notificationIcon` | `ImageButton` | Bell icon |
| `notificationBadge` | `TextView` | Red badge count |
| `notificationIconWrapper` | `FrameLayout` | Container for bell + badge |
| `fragmentContainer` | `FrameLayout` | Main content area |
| `bottomNavigationView` | `BottomNavigationView` | 5-tab bottom bar |
| `drawerLayout` | `DrawerLayout` | Root layout with drawer |
| `sideNavigationView` | `NavigationView` | Left side drawer |
| `profileImage` | `ImageView` (in header) | User avatar in drawer |
| `userName` | `TextView` (in header) | User name in drawer |
| `userNumber` | `TextView` (in header) | Phone number in drawer |
| `closeIcon` | `ImageView` (in header) | Close drawer button |

