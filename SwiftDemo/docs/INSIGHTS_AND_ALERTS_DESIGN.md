# Insights & Alerts Section - Dashboard Design Document

## Overview
The **Insights & Alerts** section is a key component of the Dashboard that displays up to **3 dynamic alert cards** providing users with real-time health insights, notifications, and activity progress updates. This section is designed to keep users informed about important health events and motivate them to achieve their wellness goals.

---

## Section Location
- **Parent**: Dashboard Fragment
- **Position**: Bottom section of the dashboard, below all health metric cards
- **Container**: White card with rounded corners (16dp), 4dp elevation
- **Section Title**: "Insights & Alerts" (Bold, 18sp, black color)

---

## Alert Cards Structure

### Visual Design
Each alert card follows a consistent horizontal layout:

```
┌─────────────────────────────────────────────┐
│  [Icon]  Title                          [→] │
│          Message (max 2 lines)              │
│          Time                                │
└─────────────────────────────────────────────┐
```

**Components:**
1. **Icon Container** (40dp × 40dp)
   - Rounded background with vital-specific color
   - Centered icon (24dp × 24dp)
   - Color-tinted based on alert type

2. **Text Content** (Flexible width)
   - **Title**: 14sp, bold, #221F1F (dark gray)
   - **Message**: 12sp, regular, #666666 (medium gray)
     - Max 2 lines with ellipsize
     - Line spacing extra: 2dp
   - **Time**: 11sp, regular, #999999 (light gray)

3. **Forward Arrow**
   - 20dp × 20dp
   - Tinted #CCCCCC (very light gray)
   - Visual indicator for clickability

**Card Styling:**
- Background: `@drawable/bg_alert_item`
- Padding: 12dp all sides
- Margin bottom: 8dp (4dp for last card)

---

## Alert Card #1: Latest Health Notification

### Purpose
Displays the **most recent health notification** from the Notifications API. This is the primary alert users see first.

### Data Source
- **Source**: `NotificationCache.latest`
- **Type**: `com.smartringpro.mannaheal.api.notifications.NotificationItem`
- **Loading**: Zero API calls - reads from cached data updated by HomeActivity

### Display Logic

#### Title
- If `notification.title` is not empty → Use notification title
- If empty → Default to **"Health Alert"**

#### Message
- Direct display of `notification.message`
- Automatically truncated to 2 lines with ellipsis

#### Time
- Relative time string based on `notification.timestamp` (Unix timestamp in seconds)
- Format:
  - `< 60s` → "Just now"
  - `< 1 hour` → "X minutes ago"
  - `< 1 day` → "X hours ago"
  - `1 day` → "Yesterday"
  - `< 7 days` → "X days ago"
  - `> 7 days` → "MMM dd" format (e.g., "Apr 26")

#### Icon & Color Mapping

Based on `notification.vitals` field (case-insensitive):

| Vital Type | Icon | Icon Color | Background |
|------------|------|------------|------------|
| `heart_rate`, `heartrate` | `baseline_favorite_24` | `#FF5252` (Red) | `icon_bg_light_red` |
| `hrv` | `baseline_show_chart_24` | `#536DFE` (Indigo) | `icon_bg_light_indigo` |
| `blood_sugar`, `glucose`, `bloodsugar` | `baseline_bloodtype_24` | `#FFB300` (Amber) | `icon_bg_light_amber` |
| `blood_pressure`, `bp`, `bloodpressure` | `baseline_favorite_24` | `#FF5252` (Red) | `icon_bg_light_red` |
| `spo2`, `oxygen`, `blood_oxygen`, `bloodoxygen` | `baseline_dew_point_24` | `#536DFE` (Indigo) | `icon_bg_light_indigo` |
| `sleep` | `baseline_shield_moon_24` | `#66BB6A` (Green) | `icon_bg_light_green` |
| `ecg` | `ecg` | `#536DFE` (Indigo) | `icon_bg_light_indigo` |
| `temperature`, `temp` | `baseline_sunny_24` | `#FF9800` (Orange) | `icon_bg_light_orange` |
| **Unknown/Default** | `baseline_notifications_active_24` | `#FFA726` (Orange) | `icon_bg_light_orange` |

### Click Action
**Navigation**: Opens **NotificationsFragment**
- Target: Full notifications list
- Back stack: Added
- Fragment tag: "Notifications"

### Visibility
- **Visible**: When `NotificationCache.latest` has data
- **Hidden**: When no cached notification exists

### Update Trigger
Called by `onNotificationsUpdated()` which is invoked:
1. On fragment view creation (instant cache read)
2. By HomeActivity after refreshing notification cache

---

## Alert Card #2: Sleep Quality Summary

### Purpose
Provides feedback on the previous night's sleep quality and duration, encouraging users to maintain healthy sleep habits.

### Data Source
- **Sleep Duration**: `sleepDurationHours` + `sleepDurationMinutes`
- **Sleep Quality Score**: `sleepQuality` (0-100%)
- **Source**: Local database (Room) + `ConnectionPreferences`

### Display Logic

Sleep quality and duration are evaluated together to generate contextual messages:

#### Excellent Sleep Quality (Score ≥ 90% AND Duration ≥ 420 min)
- **Title**: "Excellent Sleep Quality"
- **Message**: "You had Xh Ym of quality sleep. Keep up the excellent work!"
- **Icon**: `baseline_check_circle_24`
- **Icon Color**: `#66BB6A` (Green)
- **Background**: `icon_bg_light_green`
- **Time**: "Last night"

#### Great Sleep Quality (Score ≥ 80% AND Duration ≥ 360 min)
- **Title**: "Great Sleep Quality"
- **Message**: "You had Xh Ym of quality sleep. Keep up the good work!"
- **Icon**: `baseline_check_circle_24`
- **Icon Color**: `#66BB6A` (Green)
- **Background**: `icon_bg_light_green`
- **Time**: "Last night"

#### Good Sleep (Score ≥ 70%)
- **Title**: "Good Sleep"
- **Message**: "You slept for Xh Ym. Try to maintain consistency!"
- **Icon**: `baseline_shield_moon_24`
- **Icon Color**: `#FFA726` (Orange)
- **Background**: `icon_bg_light_orange`
- **Time**: "Last night"

#### Sleep Needs Improvement (Score < 70%)
- **Title**: "Sleep Needs Improvement"
- **Message**: "You had Xh Ym of sleep. Aim for better rest tonight!"
- **Icon**: `baseline_shield_moon_24`
- **Icon Color**: `#FF5252` (Red)
- **Background**: `icon_bg_light_red`
- **Time**: "Last night"

### Click Action
**Navigation**: Opens **SleepFragment**
- Target: Detailed sleep analysis with charts and session breakdown
- Back stack: Added
- Fragment tag: "Sleep"

### Visibility
- **Visible**: When `sleepDurationHours > 0` OR `sleepDurationMinutes > 0`
- **Hidden**: When no sleep data is available

### Update Trigger
Called by `updateSleepAlertCard()` which is invoked:
1. On `loadHealthData()` (fragment creation/resume)
2. On `updateRecoveryStressData()` (after vitals refresh)
3. Via EventBus when `SleepSyncEvent` is received (background worker completion)

---

## Alert Card #3: Steps & Activity Progress

### Purpose
Motivates users by showing their daily step progress toward their goal, along with calories burned. Dynamically adjusts messaging based on achievement level.

### Data Source
- **Steps Count**: `stepsCount` (from `ConnectionPreferences.loadTodayTotals()`)
- **Calories Burned**: `caloriesBurned`
- **Steps Target**: From `ApplicationPreferences` (key: `steps_target`, default: 10,000)

### Display Logic

Progress percentage calculated as: `(stepsCount / stepsTarget) * 100`

#### Goal Achieved (Steps ≥ Target)
- **Title**: "Daily Step Goal Achieved!"
- **Message**: "Great job! You've walked X steps and burned Y kcal today. Keep it up!"
- **Icon**: `baseline_check_circle_24`
- **Icon Color**: `#66BB6A` (Green)
- **Background**: `icon_bg_light_green`
- **Time**: "Today"

#### Almost There (Progress ≥ 75%)
- **Title**: "Almost There!"
- **Message**: "You're X% to your goal! Just Y more steps to go. You've burned Z kcal."
  - Y = `stepsTarget - stepsCount`
- **Icon**: `baseline_directions_walk_24`
- **Icon Color**: `#4CAF50` (Green)
- **Background**: `icon_bg_light_green`
- **Time**: "Today"

#### Halfway (Progress ≥ 50%)
- **Title**: "Halfway to Your Goal!"
- **Message**: "You've completed X steps (Y%). Burned Z kcal so far. Keep moving!"
- **Icon**: `baseline_directions_walk_24`
- **Icon Color**: `#FFA726` (Orange)
- **Background**: `icon_bg_light_orange`
- **Time**: "Today"

#### Keep Moving (Steps > 0, Progress < 50%)
- **Title**: "Keep Moving!"
- **Message**: "You've taken X steps and burned Y kcal. You're Z% to your goal!"
- **Icon**: `baseline_directions_run_24`
- **Icon Color**: `#536DFE` (Indigo)
- **Background**: `icon_bg_light_indigo`
- **Time**: "Today"

#### No Activity Yet (Steps = 0)
- **Title**: "Start Your Day Active!"
- **Message**: "No steps recorded yet. Get moving to reach your X step goal!"
- **Icon**: `baseline_directions_run_24`
- **Icon Color**: `#999999` (Gray)
- **Background**: `icon_bg_light_amber`
- **Time**: "Today"

### Click Action
**Navigation**: Opens **StepsFragment**
- Target: Detailed steps tracking with charts and history
- Back stack: Added
- Fragment tag: "Activity"

### Visibility
- **Always Visible**: Shows even when steps = 0 (to encourage activity)

### Update Trigger
Called by `updateStepsActivityAlertCard()` which is invoked:
1. On `loadHealthData()` (fragment creation/resume)
2. On `updateMetabolicData()` (after steps/calories update)

---

## Data Flow & API Integration

### Alert Card #1 (Latest Notification)
```
HomeActivity (Startup/Resume)
    ↓
Fetch Notifications API
    ↓
Update NotificationCache.latest
    ↓
Call dashboardFragment.onNotificationsUpdated()
    ↓
Read from cache (zero API call in Dashboard)
    ↓
Update Alert Card #1 UI
```

**Key Features:**
- **Zero API calls** in DashboardFragment
- **Instant display** from cache
- **Automatic refresh** when HomeActivity updates cache
- **Efficient**: Prevents duplicate notification API calls

### Alert Card #2 (Sleep Quality)
```
DashboardFragment.loadHealthData()
    ↓
loadVitalsFromLocalThenApi() on IO thread
    ↓
Query Room database (SleepDao)
    ↓
Read ConnectionPreferences (cached score)
    ↓
Calculate sleep quality (if not cached)
    ↓
Update UI on Main thread
    ↓
updateRecoveryStressData()
    ↓
updateSleepAlertCard()
```

**EventBus Integration:**
```
BackgroundService / OtherVitalsSyncWorker
    ↓
AutoSyncSleepHelper.computeAndSaveSleepScore()
    ↓
Save to ConnectionPreferences
    ↓
Post SleepSyncEvent on EventBus
    ↓
DashboardFragment.onSleepSyncEvent()
    ↓
Refresh sleep card only (no full reload)
```

### Alert Card #3 (Steps & Activity)
```
DashboardFragment.loadHealthData()
    ↓
ConnectionPreferences.loadTodayTotals()
    ↓
Read cached steps & calories
    ↓
ApplicationPreferences.getInt("steps_target")
    ↓
Calculate progress percentage
    ↓
updateMetabolicData()
    ↓
updateStepsActivityAlertCard()
```

---

## Design Principles

### User Experience
1. **Instant Feedback**: All data displayed from cache for immediate visibility
2. **Contextual Messaging**: Dynamic text adapts to user's health status
3. **Visual Hierarchy**: Color-coded icons indicate urgency/importance
4. **Actionable**: Every card is tappable to view detailed information
5. **Motivational**: Positive reinforcement for good habits, gentle nudges for improvement

### Performance Optimization
1. **Cache-First Strategy**: Alert #1 reads from memory cache (no API call)
2. **Local Database Priority**: Sleep & steps data loaded from Room first
3. **Selective Updates**: EventBus allows updating specific cards without full refresh
4. **Efficient Calculations**: Progress percentages calculated on-demand

### Accessibility
1. **Content Descriptions**: All icons have meaningful descriptions
2. **Sufficient Contrast**: Text colors meet WCAG guidelines
3. **Touch Targets**: Minimum 40dp for icon containers
4. **Clear Hierarchy**: Bold titles, readable message text

---

## Edge Cases & Error Handling

### Alert Card #1
- **No Notification Data**: Card hidden (`View.GONE`)
- **Empty Title**: Defaults to "Health Alert"
- **Unknown Vital Type**: Uses warning icon with orange theme
- **Invalid Timestamp**: Displays relative time based on current system time

### Alert Card #2
- **No Sleep Data**: Card hidden (`View.GONE`)
- **Zero Duration**: Card not shown
- **Score Not Calculated**: Falls back to recalculation from database

### Alert Card #3
- **Zero Steps**: Shows "Start Your Day Active!" message
- **Invalid Target**: Uses default 10,000 steps
- **Negative Progress**: Handled by when-expression conditions

---

## Future Enhancements

### Planned Features
1. **Swipeable Cards**: Allow users to dismiss/snooze alerts
2. **Custom Alerts**: User-defined thresholds for personalized notifications
3. **Priority Sorting**: Dynamic reordering based on urgency
4. **Historical Insights**: "Last week you averaged..." comparisons
5. **AI Recommendations**: Smart suggestions based on patterns

### Extensibility
- Additional alert cards can be added by:
  1. Adding new card layout in XML
  2. Creating update method (e.g., `updateAlertCard4()`)
  3. Defining display logic and click action
  4. Calling update method in `loadHealthData()`

---

## Technical Implementation

### Key Methods

#### Update Methods
- `updateFirstAlertCard(notification)` - Alert #1 (Latest Notification)
- `hideFirstAlertCard()` - Hides Alert #1 when no data
- `updateSleepAlertCard()` - Alert #2 (Sleep Quality)
- `updateStepsActivityAlertCard()` - Alert #3 (Steps Progress)
- `updateAlertIcon(vitalType)` - Dynamic icon/color assignment

#### Helper Methods
- `getRelativeTimeString(timestamp)` - Converts Unix timestamp to relative time
- `onNotificationsUpdated()` - Called by HomeActivity to refresh Alert #1

### EventBus Subscriptions
```kotlin
@Subscribe(threadMode = ThreadMode.MAIN)
fun onSleepSyncEvent(event: SleepSyncEvent) {
    // Updates sleep quality card when background sync completes
}
```

### Lifecycle Integration
- **onViewCreated**: Initial load from cache/database
- **onResume**: Refresh all cards with latest data
- **onStart**: Register EventBus
- **onStop**: Unregister EventBus

---

## Dependencies

### Libraries
- **EventBus**: Background sync notifications
- **Room Database**: Local data persistence
- **Gson**: JSON parsing for API responses
- **Material Components**: CardView styling

### Custom Components
- `NotificationCache` - In-memory notification storage
- `ConnectionPreferences` - Steps/calories/sleep data cache
- `ApplicationPreferences` - User settings (targets, preferences)
- `DatabaseProvider` - Room database access

---

## Testing Checklist

### Functional Tests
- ✅ Alert #1 displays latest notification from cache
- ✅ Alert #1 hides when no notification exists
- ✅ Alert #1 navigates to NotificationsFragment on click
- ✅ Alert #2 shows correct sleep quality message
- ✅ Alert #2 hides when no sleep data
- ✅ Alert #2 navigates to SleepFragment on click
- ✅ Alert #3 calculates progress percentage correctly
- ✅ Alert #3 always visible (even with 0 steps)
- ✅ Alert #3 navigates to StepsFragment on click

### Edge Case Tests
- ✅ Empty notification title defaults to "Health Alert"
- ✅ Unknown vital type shows warning icon
- ✅ Zero steps shows motivational message
- ✅ Invalid timestamps handled gracefully
- ✅ Missing target values use defaults

### UI Tests
- ✅ Icons color-coded correctly per vital type
- ✅ Text truncation works (max 2 lines)
- ✅ Relative time formats correctly
- ✅ Forward arrows visible on all cards
- ✅ Cards have proper spacing and padding

---

## Summary

The **Insights & Alerts** section provides a powerful, dynamic interface for users to stay informed about their health status. By combining real-time notifications, sleep quality feedback, and activity progress tracking in a visually appealing card layout, it serves as both an information hub and motivational tool. The cache-first architecture ensures instant load times while EventBus integration enables seamless background updates without performance overhead.

