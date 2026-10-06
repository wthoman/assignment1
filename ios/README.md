# Daybook for iPhone

A native SwiftUI port of Daybook. Daybook is a social-accountability habit tracker built on forgiving consistency, shared habits, sticker-book collectibles and an award-show weekly recap. "Daybook" is a temporary name: change it in `Daybook/Theme/Brand.swift` and in the `INFOPLIST_KEY_CFBundleDisplayName` build setting.

- iPhone only, iOS 17+, SwiftUI, SwiftData, Observation, Swift Charts, PhotosUI, UserNotifications, AVFoundation, Core Haptics
- No third-party packages, backend, API keys or required assets
- Light mode is the default. Dark mode is an option in Settings → Appearance.

## Run it

1. Open `ios/Daybook.xcodeproj` in Xcode 16 or newer.
2. Select the **Daybook** scheme and an iPhone simulator, then press Run.
3. On the welcome screen, choose **Explore with demo data** to skip onboarding, or go through all 11 steps.

Tests: **Product → Test** (⌘U), or run this from the `ios/` folder:

```bash
xcodebuild test -project Daybook.xcodeproj -scheme Daybook -destination 'platform=iOS Simulator,name=iPhone 17'
```

The project uses file-system synchronized folders, so new `.swift` files dropped into `Daybook/` are picked up automatically. To use the code in a different Xcode project, copy the `Daybook/` folder (except `Resources/Assets.xcassets` if you already have one). Keep exactly one `@main` (`App/DaybookApp.swift`).

## Structure

| Folder | Contents |
| --- | --- |
| `App/` | `DaybookApp` (entry point and SwiftData container), `RootView` (onboarding vs. tabs, plus toasts, reveals and celebrations), `MainTabView` (4 tabs and the route table), `AppRouter` |
| `Models/` | SwiftData `@Model`s: `UserProfile`, `Friend`, `Habit`, `HabitSchedule`, `CheckIn`, `ActivityItem`, `Reaction`, `Comment`, `Reminder`, `Gift`, `HabitGroup`, `Challenge`, `Collectible`, `CosmeticItem`, `Quiz`, `QuizResponse`, `WeeklyRecap`, `NotificationItem`, `AppPreferences`. Also includes the enums, `AvatarConfig` and `HabitDraft`. |
| `Data/` | `Catalog` (stickers, cosmetics, personalities, quiz and challenge templates), `DemoSeeder` (a deterministic demo world generated around today), `Encouragement` copy |
| `Services/` | `AppModel` and its feature extensions (every mutation goes through here), `Stats` (pure consistency math), `RecapEngine`, `SoundManager`, `HapticManager`, `NotificationScheduler`, `ShareRenderer` and the share cards |
| `Components/` | Cards, chips, buttons, avatar renderer, sticker shapes, completion stamp, week dots, toasts, `FlowLayout`, `AdaptiveStack` |
| `Theme/` | Color tokens (`Palette`, `TintToken`, `AccentChoice`), fonts and spacing |
| `Views/` | Today, Habits, Friends, Groups, Collection, Recap, Profile, Notifications, Settings, Share, Onboarding |
| `Resources/` | Asset catalog (generated app icon and accent color) |
| `../DaybookTests/` | 28 unit tests covering stats, award assignment, the model layer, seeding, onboarding, export, sound synthesis and card rendering |

Views read data with `@Query` and call `AppModel` methods to change it. To move to a cloud backend, replace the SwiftData-backed implementations in `Services/AppModel*.swift` and `DemoSeeder`. The views can stay as they are.

## How consistency works

`Stats.tally` compares expected and completed check-ins over a rolling 28-day window, and **forgives one miss per full week**:

- A day that isn't over yet never counts against you.
- Bonus check-ins on unscheduled days can make up for misses.
- Optional and paused habits are excluded.
- Flexible habits (*n times a week*) count toward a weekly target instead of fixed days.

Streaks exist but are secondary and can be turned off. A check-in after two or more missed scheduled days is a **comeback**, which earns its own stickers.

## Sounds

`SoundManager` uses the `.ambient` audio session, so sounds respect the Ring/Silent switch, mix with music, and stop when the app goes to the background. If no audio files are bundled, every sound is **synthesized in memory** as a soft marimba-like tone. Missing files never crash the app.

To replace a sound, add an optional file to the app target. Supported extensions are `.caf`, `.wav`, `.m4a`, `.mp3` and `.aiff`.

| File name | Moment |
| --- | --- |
| `daybook_complete` | Complete a habit |
| `daybook_undo` | Undo a completion |
| `daybook_reaction` | Receive a reaction |
| `daybook_send` | Send a reminder, reaction or comment |
| `daybook_unlock` | Unlock a sticker |
| `daybook_unlockRare` | Unlock a rare or legendary sticker |
| `daybook_reveal` | Superlative or award reveal |
| `daybook_pageTurn` | Advance a recap card |
| `daybook_groupGoal` | Group goal reached |
| `daybook_error` | Something went wrong |

Settings → Sounds has toggles (app, completion, recap), a volume slider and preview buttons.

## Haptics

`HapticManager` uses UIKit feedback generators for everyday moments (selection, card press, success, undo, warning). It uses Core Haptics patterns for rare sticker unlocks, award reveals and group celebrations, but only when `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is true. Otherwise it falls back to UIKit, and in the simulator it does nothing. Settings → Haptics has an on/off toggle, reduced intensity, celebration patterns and previews.

## Things to try

| Where | What to do |
| --- | --- |
| Today | Tap a stamp to complete a habit: the stamp animates, a sound and haptic play, and a toast offers Undo. Swipe right to complete or undo. Swipe left for Note and History. Long-press for the full menu and a history preview. Tap days in the week strip to log past days. Pull to refresh. |
| Today → Delete… | A warning haptic and a confirmation dialog appear first. Archiving is offered as the safer option. |
| Today → `+` | Opens the habit form. Validation messages appear if you save with an empty name or a shared habit with no friends. |
| Today → Month view | Colored dots per completed habit, a stamped ring on days where everything was done. Filter by habit and log past days. |
| Today → avatar | Profile → avatar editor, gifts inbox (open Theo's gift to unlock the bandana) and Settings. |
| Today → bell | Accept Dev's friend request or the Touch Grass Club invite inline. Swipe to mark read or dismiss. |
| Friends | React (sheet with a selection haptic and a send sound), comment, celebrate Theo's comeback, tap **Me too** on Maya's walk, send a reminder or a gift. The toolbar opens Quizzes, Groups and Add friends. |
| Groups → Hydration Station | Tap **Log one** twice to reach the goal: a full-screen stamp, the group sound and haptic pattern, and a sticker reveal. Library Goblins has a prediction to vote on and reveal. |
| Collection | Sticker book with page tabs, or the grid toggle. Filter by type. Long-press for a preview. In the detail sheet, drag the sticker to tilt it, favorite or showcase it, and share a rendered card. |
| Recap | Tap **Play recap**. Tap the right side to go forward, the left side to go back, swipe, or hold to pause. Mute sound or reduce motion from the top bar. Share a single card or the final summary. Replay at the end. |
| Settings | Appearance (theme, accent, density, first weekday, encouragement tone, streaks, celebration intensity), accessibility, sounds, haptics, notifications (permission, types, quiet hours, per-habit and per-group), privacy, blocked users, connected services (mock), JSON export, reset demo data, reset onboarding, log out, delete account. |

Notification permission is requested only when a reminder is turned on (in onboarding, in the habit form, or in the reminder sheet), never at launch.

Debug-only launch arguments (scheme → Run → Arguments), useful for screenshots:

- `-seedDemo`: skip onboarding with demo data
- `-tab friends|collection|recap`: open a tab
- `-route profile|settings|notifications|groups|group|friend|habit|calendar|quizzes|avatar|share`: open a screen
- `-dark`: use dark mode
- `-resetAll`: wipe everything

## Mocked or simulated

- Friends, their check-ins, groups and quizzes are seeded locally. Friend requests you send are accepted automatically after a moment, and new feed items are added when you pull to refresh.
- About 40% of your check-ins receive a simulated friend reaction a few seconds later, to show the "receiving a reaction" feedback.
- The contacts list and connected services are mock data. The app never reads your address book or other apps.
- Accounts exist only on the device. Log out and Delete account wipe the local store.
