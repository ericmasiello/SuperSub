# Product Requirements Document: SubTimer
**Version:** 1.0  
**Date:** February 13, 2026  
**Author:** Product Team  
**Status:** Draft

---

## 1. Executive Summary

SubTimer is a SwiftUI-based sports substitution timer application designed to help coaches and team managers fairly track player rotations during games. The app ensures equitable playing time by automatically tracking who has played longest and managing substitution queues.

---

## 2. Product Overview

### 2.1 Vision
Create a simple, reliable tool that eliminates the mental burden of tracking player rotations, ensuring every player gets fair playing time.

### 2.2 Target Users
- Youth sports coaches
- Recreational league managers
- Parents managing team rotations
- Any team sports requiring equal playing time distribution

### 2.3 Platform Support
- **Primary:** iPhone (iOS 18+)
- **Secondary:** iPad (Universal app)
- **Tertiary:** macOS (Mac Catalyst or native SwiftUI)

---

## 3. Core Features

### 3.1 Application Structure

#### Tab Navigation
The app uses a two-tab interface:
1. **Timer Tab** (Primary view)
2. **Settings Tab** (Configuration view)

### 3.2 Settings/Configuration View

#### 3.2.1 Player Management
- **Add Players:** Unlimited player roster
  - Input: Player name (required)
  - Players stored in a list
  - Ability to reorder players
  - Ability to delete players
  - Ability to edit player names

- **Active Players Configuration**
  - Set number of simultaneous active players (e.g., 4 out of 10 total)
  - Validation: Cannot exceed total player count
  - **Automatic Adjustment:** If total players < active spots, automatically reduce active spots to match available players

- **Preferred Play Time**
  - Configurable duration per rotation
  - Format options: Minutes:Seconds (e.g., 3:00, 3:30)
  - Range: 30 seconds - 30 minutes
  - Default: 3:00 minutes

#### 3.2.2 Session Configuration
- Display current session settings summary
- Clear/reset current session button
- View basic session history (list of past sessions with date/time)

### 3.3 Timer View (Main Interface)

#### 3.3.1 Active Players Display
- Shows currently playing players
- Count matches "active players" configuration
- Each player displays:
  - Player name
  - Current play duration for this shift
  - Visual indicator showing who will substitute out next (longest playing time)

#### 3.3.2 Bench/Queue Display
- Shows players waiting to substitute in
- Clear indication of "Next Up" player
- Shows order of substitution queue

#### 3.3.3 Timer Controls
- **Start/Pause Button**
  - Starts/pauses all timers simultaneously
  - Clear visual state indication
  - Persists state through app suspension

- **Preferred Time Display**
  - Shows countdown/countup relative to preferred play time
  - Visual indicator when preferred time is reached
  - **Alerts:** Both visual (color change, flashing) and audio/haptic feedback when time reached
  - Timer continues beyond preferred time (does not auto-pause)

- **Substitute Button**
  - Prominent, accessible button
  - Triggers the substitution process:
    1. Player with longest play time moves to end of bench queue
    2. "Next Up" player moves to active roster
    3. All active player timers reset to 0:00
    4. Timer automatically restarts
    5. UI updates to show new next substitution

#### 3.3.4 Manual Override Capability
- Long-press or secondary action on player allows:
  - **Manual Substitution:** Swap specific player out for any bench player
  - **Temporary Removal:** Mark player as temporarily unavailable (e.g., injury, bathroom break)
    - Player removed from rotation
    - Can quickly add back to bench queue
  - **Quick Swap:** Direct drag-and-drop between active and bench

#### 3.3.5 Active Session Editing
- Allow adding new players during active session
- Allow removing players (with confirmation if currently active)
- Allow temporary player status changes
- Changes take effect immediately with smart rotation preservation

---

## 4. Data & Storage

### 4.1 Data Models

#### Player
- UUID
- Name (String)
- Created date
- Current play duration (for active session)
- Total play time (historical)
- Status: Active, Benched, Temporarily Out

#### Session
- UUID
- Date/Time started
- Duration
- Players involved
- Substitution count
- Configuration snapshot (preferred time, active count)

#### Configuration
- Preferred play time (seconds)
- Active players count
- Last modified date

### 4.2 Persistence
- **Framework:** SwiftData
- **Sync:** CloudKit integration
  - Full offline support
  - Automatic sync when connection restored
  - Conflict resolution: Last-write-wins for settings, merge strategy for session history
- **Model Container** shared across all platforms

---

## 5. User Experience Requirements

### 5.1 Core UX Principles
- **Clarity:** Coach should understand state at a glance
- **Speed:** All actions accessible within 1-2 taps
- **Reliability:** No data loss during session
- **Simplicity:** Minimal learning curve

### 5.2 Visual Design
- Large, tappable buttons suitable for sideline use
- High contrast for outdoor visibility
- Landscape and portrait support
- iPad: Take advantage of larger screen with split views

### 5.3 Accessibility
- VoiceOver support for all interactive elements
- Dynamic Type support
- Minimum touch target size: 44x44 points
- Sufficient color contrast (WCAG AA)

### 5.4 Performance
- Instantaneous timer updates (60fps)
- No lag on substitution actions
- App state restoration after backgrounding
- Battery efficient timer implementation

---

## 6. Technical Requirements

### 6.1 Architecture
- **UI Framework:** SwiftUI
- **Data Layer:** SwiftData
- **Cloud Sync:** CloudKit
- **Minimum iOS Version:** iOS 18.0
- **Architecture Pattern:** MVVM with ViewModels

### 6.2 Testing Strategy

#### Unit Tests
- [ ] Player management logic (add, remove, edit)
- [ ] Timer calculation logic
- [ ] Substitution rotation algorithm
- [ ] Configuration validation
- [ ] Edge case handling (0 players, 1 player, etc.)
- [ ] SwiftData model operations
- [ ] Session state management

#### UI Tests
- [ ] Tab navigation
- [ ] Player list CRUD operations
- [ ] Timer start/pause functionality
- [ ] Substitution flow
- [ ] Settings persistence
- [ ] Manual override actions
- [ ] Temporary player removal/restoration
- [ ] Session history viewing

#### Integration Tests
- [ ] CloudKit sync scenarios
- [ ] Offline mode functionality
- [ ] Conflict resolution
- [ ] App lifecycle (background/foreground)

### 6.3 Development Approach
**Phased Implementation:**

**Phase 1: Core Data & Settings**
- SwiftData models
- Settings view with player management
- Configuration persistence
- Unit tests for models and logic

**Phase 2: Basic Timer View**
- Timer view UI scaffolding
- Start/pause timer
- Display active players
- Simple auto-substitution
- UI tests for timer controls

**Phase 3: Advanced Substitution**
- Smart queue management
- Next player indication
- Substitution button logic
- Manual override capability
- Unit tests for rotation algorithm

**Phase 4: Polish & Alerts**
- Audio/haptic feedback
- Visual alerts for preferred time
- Temporary player removal
- Active session editing
- Comprehensive UI tests

**Phase 5: CloudKit & History**
- CloudKit integration
- Offline support
- Session history
- Sync conflict resolution
- Integration tests

**Phase 6: Multi-Platform**
- iPad optimization
- macOS support (if applicable)
- Cross-device testing

---

## 7. Edge Cases & Validation

### 7.1 Player Count Scenarios
- **0 Players:** Disable timer, show empty state with prompt to add players
- **1 Player:** Allow timer but disable substitution
- **Players < Active Spots:** Automatically reduce active spots to match player count
- **All Players Temporarily Out:** Pause session, show alert

### 7.2 Timer Edge Cases
- **App Backgrounded:** Continue timer, show notification if preferred time reached
- **Device Locked:** Persist timer state, resume on unlock
- **App Force Quit:** Restore last known session state
- **Preferred Time = 0:** Treat as "no preferred time", no alerts

### 7.3 Substitution Edge Cases
- **Manual Override During Auto-Sub:** User action takes precedence
- **Player Removed Mid-Session:** Recalculate rotation, maintain fairness
- **Configuration Changed Mid-Session:** Apply with smart merging

---

## 8. Success Metrics

### 8.1 Functional Requirements
- ✅ All players receive equal +/- 10% playing time over full session
- ✅ Substitution takes < 2 seconds to process
- ✅ Zero data loss during normal operation
- ✅ 100% offline capability

### 8.2 User Experience
- App usable in bright sunlight
- No learning curve for basic features
- Recovery from all error states

---

## 9. Future Considerations (Out of Scope for v1)

- Multi-team management
- Advanced statistics and analytics
- Export session data (CSV, PDF)
- Custom rotation strategies (e.g., keep certain players together)
- Integration with league management systems
- Apple Watch companion app
- widgets for quick access
- Share session summaries

---

## 10. Open Questions

1. Should the app support multiple simultaneous games/sessions?
2. Do we need coach authentication or can sessions be anonymous?
3. Should we support undo for accidental substitutions?
4. Maximum recommended player count before performance degradation?

---

## 11. Approval & Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Engineering Lead | | | |
| Design Lead | | | |

---

## Appendix A: Glossary

- **Active Players:** Players currently on the field/court
- **Bench:** Players waiting to substitute in
- **Rotation:** The order in which players substitute
- **Shift:** A single period of play time for a player
- **Session:** A complete game/practice with start and end time

---

## Appendix B: User Stories

### Epic: Player Management
- As a coach, I want to add unlimited players so I can manage my full roster
- As a coach, I want to set how many players are active so I can match game rules
- As a coach, I want to edit player names so I can fix typos

### Epic: Fair Play Tracking
- As a coach, I want to see who's been playing longest so I know who to substitute
- As a coach, I want automatic rotation so I don't have to calculate mentally
- As a coach, I want to set preferred play time so players get fair time

### Epic: Game Management
- As a coach, I want to start/pause the timer so I can control the session
- As a coach, I want to substitute with one tap so I can act quickly
- As a coach, I want visual alerts so I know when it's time to substitute
- As a coach, I want to handle injuries mid-game so I can adapt to situations

### Epic: Data Persistence
- As a coach, I want my data synced so I can use multiple devices
- As a coach, I want offline support so I can use it anywhere
- As a coach, I want to see session history so I can track trends

---

**End of PRD**
