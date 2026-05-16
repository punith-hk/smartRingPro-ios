# Side Navigation Menu — Design & Workflow

## Overview
The side navigation drawer slides in from the **left** when the user taps the hamburger menu icon (`☰`) on the top toolbar. It is implemented using `DrawerLayout` + `NavigationView` in `activity_home.xml`.

---

## Trigger / Entry Point

| Trigger | Action |
|---------|--------|
| Hamburger icon (`drawerIcon`) in top toolbar | Opens drawer from the left (`GravityCompat.START`) |
| Back arrow (`closeIcon`) in drawer header | Closes the drawer |
| Selecting any menu item | Navigates to destination + closes drawer |
| Back press while drawer is open | Closes the drawer |

---

## Layout Structure

```
DrawerLayout (full screen)
  ├── Main Content (ConstraintLayout)
  │     ├── Toolbar (top bar)
  │     ├── FragmentContainer
  │     └── BottomNavigationView
  └── NavigationView  ← Side Drawer
        ├── Header (drawer_header.xml)
        └── Menu Items (drawer_menu.xml)
```

### NavigationView Properties

| Property | Value |
|----------|-------|
| Width | `280dp` |
| Height | `match_parent` |
| Gravity | `start` (slides from left) |
| Background | `#FFFFFF` (white) |
| Elevation | `8dp` |
| Item text color | `#333333` |
| Text appearance | `@style/DrawerMenuTextStyle` |
| Fits system windows | `true` |

---

## Drawer Header (`drawer_header.xml`)

Background color: `#D9EDFF` (light blue, same as cardiovascular screen)  
Padding: `16dp` all sides, `20dp` bottom  
Elevation: `4dp`  
Layout type: `RelativeLayout`

### Header Elements

```
RelativeLayout (header)
  ├── ImageView: closeIcon          ← top-right, 28×28dp, back arrow icon, tint #000000
  ├── ImageView: profileImage       ← 88×88dp, circle shape (@drawable/circle_shape), centerCrop
  └── LinearLayout (textSection)    ← right of profileImage, vertical, center_vertical
        ├── TextView: userName      ← 18sp, bold, black, default "Unknown User"
        └── TextView: userNumber    ← 14sp, darker_gray, default "Not Available"
```

### Header Data Binding (from API / SharedPreferences)

| Field | Source | Fallback |
|-------|--------|----------|
| Profile image | API profile photo URL → Glide/Picasso load | App launcher icon |
| User name | API user profile name | `"Unknown User"` |
| User number | API mobile number / email | `"Not Available"` |

The header is updated in `setupDrawer()` via `binding.sideNavigationView.getHeaderView(0)`.

---

## Menu Items (`drawer_menu.xml`)

All items use `checkableBehavior="none"` (no item stays highlighted/selected).

### Group 1 — Main

| ID | Icon (emoji in title) | Title | Navigation Destination |
|----|----------------------|-------|------------------------|
| `nav_family_members` | 👨‍👩‍👧‍👦 | Family Members | `FamilyMembersFragment` |
| `nav_settings` | 📅 | Appointment Summary | `AppointmentsFragment` (sets checked item) |
| `nav_vitals` | 📋 | Vitals | *(hidden — `android:visible="false"`)* |

### Group 2 — Account

| ID | Icon (emoji in title) | Title | Navigation Destination |
|----|----------------------|-------|------------------------|
| `nav_about` | 👤 | Profile Settings | `ProfileFragment` |
| `nav_refer_friend` | 🎁 | Refer A Friend | *(Refer screen / web view)* |

### Group 3 — Support

| ID | Icon (emoji in title) | Title | Navigation Destination |
|----|----------------------|-------|------------------------|
| `nav_help_support` | ❓ | Help & Support | `HelpSupportFragment` |
| `nav_logout` | 🚪 | Logout | Clears session → `LoginActivity` |

> **Note:** Icons are embedded as part of the title string (emoji prefix + spaces). No separate `android:icon` attribute is used.

---

## Navigation Behavior

```
User taps menu item
        │
        ▼
setNavigationItemSelectedListener fires
        │
        ├── Close drawer (closeDrawer GravityCompat.START)
        │
        └── Navigate to corresponding fragment / action
              ├── nav_family_members  → FamilyMembersFragment
              ├── nav_settings        → AppointmentsFragment
                                        + binding.sideNavigationView.setCheckedItem(nav_settings)
              ├── nav_about           → ProfileFragment
              ├── nav_refer_friend    → Refer screen
              ├── nav_help_support    → HelpSupportFragment
              └── nav_logout          → Clear prefs/session → LoginActivity
```

### Toolbar Icon Visibility (per fragment)

When navigating, the toolbar adjusts:

| Fragment | Drawer Icon (`☰`) | Notification Icon (`🔔`) |
|----------|-------------------|--------------------------|
| Dashboard / main screens | ✅ Visible | ✅ Visible |
| Detail sub-screens (pushed) | ❌ Hidden | ❌ Hidden (or back arrow shown) |

---

## Visual Design Summary

```
┌──────────────────────────────────┐
│  [←]                             │  ← closeIcon (top-right), 28dp, black arrow
│                                  │
│  [  Profile Photo  ]  User Name  │  ← 88dp circle photo + name/number right
│  (88×88, circle)   User Number   │
│  ─────────────────────────────── │  ← background #D9EDFF (light blue)
│                                  │
│  👨‍👩‍👧‍👦      Family Members        │
│  📅      Appointment Summary     │
│  ─────────────────────────────── │
│  👤      Profile Settings        │
│  🎁      Refer A Friend          │
│  ─────────────────────────────── │
│  ❓      Help & Support          │
│  🚪      Logout                  │
└──────────────────────────────────┘
  Width: 280dp | Background: #FFFFFF
  Item text: #333333 | Elevation: 8dp
```

---

## iOS Implementation Notes

1. Use a **slide-in panel** from the left (like `UISideMenuController` or a custom `UIView` with transform animation).
2. Drawer width: **280pt**.
3. Header background: `#D9EDFF`.
4. Profile image: circular clip, `88×88pt`.
5. Menu groups separated by dividers.
6. No item should stay in "selected" state after tap (except Appointment Summary which explicitly sets checked).
7. Close button (back arrow) in top-right of header.
8. On logout: clear all local storage/keychain → navigate to login screen.
9. `nav_vitals` item is **hidden** — do not show it.
10. Emoji icons are part of the label string — replicate the same emoji prefixes in iOS labels.

