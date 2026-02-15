# SubTimer - Sports Substitution Timer

A SwiftUI-based sports substitution timer application designed to help coaches and team managers fairly track player rotations during games.

## Overview

SubTimer ensures equitable playing time by automatically tracking who has played longest and managing substitution queues. Built with SwiftUI and SwiftData, it provides offline support with CloudKit sync across devices.

## Implementation Status

### ✅ Completed (Phase 1-3)

#### Phase 1: Core Data & Settings
- ✅ SwiftData models (Player, AppConfiguration, Session)
- ✅ Settings view with player management
- ✅ Configuration persistence
- ✅ Unit tests for models and logic

#### Phase 2: Basic Timer View
- ✅ Timer view UI scaffolding
- ✅ Start/pause timer functionality
- ✅ Display active players
- ✅ Basic auto-substitution
- ✅ Real-time timer updates

#### Phase 3: Advanced Substitution
- ✅ Smart queue management
- ✅ Next player indication (visual indicators)
- ✅ Substitution button logic
- ✅ Manual override capability
- ✅ Player status management (active, benched, temporarily out)
- ✅ Rotation algorithm

### 🚧 In Progress (Phase 4)

#### Phase 4: Polish & Alerts
- ✅ Haptic feedback on substitutions
- ✅ Visual alerts for preferred time (color changes)
- ⚠️ Audio feedback (placeholder for AVFoundation implementation)
- ✅ Temporary player removal
- ✅ Active session editing
- ⚠️ UI tests needed

### 📋 Remaining (Phase 5-6)

#### Phase 5: CloudKit & History
- ✅ CloudKit integration configured
- ✅ Offline support (via SwiftData)
- ✅ Session history view
- ⚠️ Sync conflict resolution (needs testing)
- ⚠️ Integration tests needed

#### Phase 6: Multi-Platform
- ⚠️ iPad optimization needed
- ⚠️ macOS support (if applicable)
- ⚠️ Cross-device testing

## Architecture

### Project Structure

```
SubTimer/
├── Models/
│   ├── Player.swift              # Player entity with status tracking
│   ├── AppConfiguration.swift    # App settings and preferences
│   └── Session.swift             # Session history tracking
├── Views/
│   ├── MainTabView.swift        # Root tab navigation
│   ├── TimerView.swift          # Main timer interface
│   └── SettingsView.swift       # Settings and configuration
├── ViewModels/
│   └── (TimerViewModel in TimerView.swift)
└── SubTimerApp.swift            # App entry point
```

### Data Models

#### Player
- Tracks player name, status, play durations
- Status: `.active`, `.benched`, `.temporarilyOut`
- Maintains both current shift time and total play time
- Sortable for roster management

#### AppConfiguration
- Preferred play time (30s - 30min)
- Number of active players
- Validation logic for configuration
- Auto-adjusts when player count < active spots

#### Session
- Captures game/practice session data
- Tracks duration, substitution count
- Stores configuration snapshot
- Session history for analysis

### Key Features Implemented

#### Settings View
- **Player Management:**
  - Add/edit/delete/reorder players
  - View player statistics
  - Status management (active, bench, temporarily out)
- **Configuration:**
  - Set active player count (with validation)
  - Configure preferred play time
  - Auto-adjustment when needed
- **Session Management:**
  - View session history
  - Clear current session
  - Delete past sessions

#### Timer View
- **Timer Controls:**
  - Start/pause with visual state indication
  - Persistent timer through app lifecycle
  - Automatic session creation
- **Active Players Display:**
  - Shows currently playing players
  - Real-time duration updates
  - Visual indicator for next substitution
- **Bench Display:**
  - Queue of waiting players
  - "Next Up" indicator
  - Quick activation when spots available
- **Preferred Time Display:**
  - Large, readable timer
  - Visual warnings when over time
  - Countdown/countup display
- **Substitution:**
  - One-tap automatic substitution
  - Manual player-specific substitution
  - Haptic feedback on substitutions
  - Auto-reset timers after substitution
- **Player Actions:**
  - Long-press for player-specific actions
  - Temporary removal (injury, break)
  - Quick return to bench
  - View player statistics

### Smart Substitution Algorithm

1. **Automatic Substitution:**
   - Identifies player with longest current play time
   - Subs out longest player with next bench player
   - Resets all active player timers to 0:00
   - Accumulates time to total play time
   - Updates session substitution count

2. **Manual Substitution:**
   - Allows coach to choose specific player to sub out
   - Select any bench player to sub in
   - Same reset and tracking logic

3. **Fair Play Tracking:**
   - Maintains total play time per player
   - Visual indicators for play time disparities
   - Goal: All players within ±10% playing time

## Testing

### Unit Tests (Completed)
- ✅ Player initialization and status changes
- ✅ Configuration validation and formatting
- ✅ Session tracking and duration formatting
- ✅ Edge cases (0 players, 1 player, player < active spots)
- ✅ Time formatting utilities
- ✅ Fair play distribution calculations
- ✅ Substitution logic validation

### UI Tests (TODO)
- Tab navigation
- Player CRUD operations
- Timer controls
- Substitution flows
- Settings persistence
- Manual overrides

### Integration Tests (TODO)
- CloudKit sync scenarios
- Offline mode
- App lifecycle
- Conflict resolution

## Usage

### Getting Started
1. Launch app and navigate to **Settings** tab
2. Add players to your roster
3. Configure active player count
4. Set preferred play time
5. Return to **Timer** tab

### During a Game
1. Tap **Start** to begin session
2. Timer tracks all active players
3. Visual and haptic alerts at preferred time
4. Tap **Substitute** for automatic rotation
5. Long-press players for manual actions
6. Use **Pause** for timeouts/breaks

### Player Management
- **Add Player:** Settings > Add Player button
- **Edit Player:** Tap pencil icon in Settings
- **Reorder:** Drag players in Settings list
- **Temporary Removal:** Long-press player > Mark Temporarily Out
- **Return to Bench:** Tap "Return to Bench" button

## Technical Details

### Requirements
- **Platform:** iOS 18.0+
- **Framework:** SwiftUI
- **Data:** SwiftData with CloudKit
- **Architecture:** MVVM pattern

### Key Technologies
- **SwiftUI:** Declarative UI framework
- **SwiftData:** Modern persistence framework
- **CloudKit:** Cloud sync and backup
- **Observation Framework:** Reactive state management
- **Combine:** Timer management

### Performance Considerations
- Timer updates at 1-second intervals (battery efficient)
- SwiftData queries optimized with sorting
- Minimal re-renders with `@Query` and `@Observable`
- Haptic feedback for tactile responses

## Future Enhancements (Out of Scope for v1)

- Multi-team management
- Advanced statistics and analytics
- Export session data (CSV, PDF)
- Custom rotation strategies
- League management integration
- Apple Watch companion app
- Home screen widgets
- Share session summaries
- Audio feedback (requires AVFoundation)

## Known Limitations

1. **Audio Alerts:** Visual and haptic only (audio requires AVFoundation setup)
2. **Background Timers:** Timer pauses when app is backgrounded (iOS limitation)
3. **Multi-Session:** Only one active session at a time
4. **CloudKit Testing:** Requires real device testing for full validation
5. **Undo:** No undo functionality for substitutions (v2 feature)

## Development Notes

### Building
```bash
xcodebuild -scheme SubTimer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Testing
```bash
xcodebuild test -scheme SubTimer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### CloudKit Setup
- Entitlements file configured with CloudKit capability
- Container ID: (auto-generated)
- Uses `.automatic` database for sync
- Offline-first design with automatic sync

## Contributing

This is a reference implementation based on the PRD. Key areas for improvement:

1. Complete UI and integration tests
2. Implement audio feedback system
3. Optimize for iPad layouts
4. Add macOS support
5. Enhance error handling
6. Add data export features
7. Improve accessibility (VoiceOver)

## License

Copyright © 2026 SubTimer Team. All rights reserved.

---

**Version:** 1.0  
**Last Updated:** February 13, 2026  
**Status:** MVP Complete (Phases 1-3), Polish In Progress (Phase 4)