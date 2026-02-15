# SubTimer Implementation Checklist

## ✅ Phase 1: Core Data & Settings (COMPLETE)

### Data Models
- [x] Create `Player` model with SwiftData
  - [x] UUID identifier
  - [x] Name property
  - [x] Created date
  - [x] Current play duration
  - [x] Total play time
  - [x] Status enum (active, benched, temporarilyOut)
  - [x] Sort order for roster management
- [x] Create `AppConfiguration` model
  - [x] Preferred play time (seconds)
  - [x] Active players count
  - [x] Last modified date
  - [x] Validation logic
  - [x] Time formatting helper
- [x] Create `Session` model
  - [x] Start/end dates
  - [x] Duration tracking
  - [x] Substitution count
  - [x] Configuration snapshot
  - [x] Player names list
  - [x] isActive computed property
  - [x] Duration formatting

### Settings View
- [x] Player management section
  - [x] Add player functionality
  - [x] Edit player (name, status)
  - [x] Delete players with confirmation
  - [x] Reorder players (drag & drop)
  - [x] Display player statistics
  - [x] Player count display
- [x] Configuration section
  - [x] Active players stepper with validation
  - [x] Preferred play time picker (30s - 30min)
  - [x] Auto-adjustment warning when needed
- [x] Session management section
  - [x] Session history navigation
  - [x] Clear current session button
  - [x] Session history list view
  - [x] Delete past sessions

### Unit Tests
- [x] Player model tests
  - [x] Initialization
  - [x] Status changes
  - [x] Time tracking
- [x] Configuration model tests
  - [x] Defaults
  - [x] Time formatting
  - [x] Validation logic
  - [x] Boundary conditions
- [x] Session model tests
  - [x] Initialization
  - [x] isActive logic
  - [x] Duration formatting
  - [x] Tracking functionality
- [x] Edge case tests
  - [x] Zero players
  - [x] Single player
  - [x] Players < active spots
  - [x] Preferred time = 0
- [x] Substitution logic tests
  - [x] Play time accumulation
  - [x] Find longest playing player
  - [x] Player sort order
  - [x] Fair play distribution

---

## ✅ Phase 2: Basic Timer View (COMPLETE)

### Timer View UI
- [x] Create `TimerView` structure
- [x] Empty state view (no players)
- [x] Main timer view layout
- [x] Navigation stack setup

### Timer Controls
- [x] Start/Pause button
  - [x] Visual state indication (play/pause icons)
  - [x] Color coding (green/orange)
  - [x] Disabled state handling
- [x] Timer state management
  - [x] `TimerViewModel` with @Observable
  - [x] 1-second interval timer
  - [x] Start/pause logic
  - [x] Timer cleanup on deinit

### Display Components
- [x] Active players display
  - [x] List of currently playing players
  - [x] Real-time duration updates
  - [x] Empty state message
- [x] Preferred time display
  - [x] Large timer display
  - [x] Current vs preferred time comparison
  - [x] Time remaining/overtime calculation
- [x] Timer state restoration
  - [x] Auto-activate players on start
  - [x] Session creation on timer start
  - [x] Duration tracking in active session

---

## ✅ Phase 3: Advanced Substitution (COMPLETE)

### Smart Queue Management
- [x] Bench section display
  - [x] List of benched players
  - [x] "Next Up" visual indicator
  - [x] Player count display
  - [x] Total play time for each player
- [x] Active player indicators
  - [x] Highlight next player to sub out
  - [x] Current play duration display
  - [x] Visual differentiation from bench

### Substitution Logic
- [x] Automatic substitution button
  - [x] Prominent, accessible placement
  - [x] Enabled/disabled based on availability
  - [x] One-tap substitution
- [x] Substitution algorithm
  - [x] Identify longest playing active player
  - [x] Select next bench player
  - [x] Swap player statuses
  - [x] Accumulate time to total
  - [x] Reset all active timers
  - [x] Update session substitution count
  - [x] Auto-restart timer if running

### Manual Override
- [x] Manual substitution capability
  - [x] Long-press/tap for player actions
  - [x] Player actions sheet
  - [x] Select specific player to sub out
  - [x] Choose any bench player to sub in
  - [x] Manual substitution flow
- [x] Temporary player removal
  - [x] Mark player as temporarily out
  - [x] Separate "Temporarily Out" section
  - [x] Return to bench functionality
  - [x] Time accumulation on removal
- [x] Quick actions
  - [x] Activate player (when spots available)
  - [x] Direct substitution
  - [x] View player statistics in action sheet

---

## 🚧 Phase 4: Polish & Alerts (PARTIAL)

### Visual Alerts
- [x] Preferred time reached
  - [x] Color change (red text for overtime)
  - [x] Warning icon display
  - [x] "Over by X:XX" message
- [x] Player status visual indicators
  - [x] Color-coded backgrounds
  - [x] Status icons (arrows, badges)
  - [x] Next up/sub out highlights

### Haptic Feedback
- [x] Substitution feedback
  - [x] Medium impact on substitution
- [x] Alert feedback
  - [x] Warning notification at preferred time
- [ ] Additional haptics
  - [ ] Light impact on button taps
  - [ ] Success feedback on player actions

### Audio Feedback
- [ ] Sound system setup
  - [ ] Import AVFoundation
  - [ ] Load alert sounds
  - [ ] Play sound at preferred time
  - [ ] Background audio configuration
  - [ ] Sound on/off setting

### Active Session Editing
- [x] Add players during session
  - [x] Settings updates reflect immediately
- [x] Remove players during session
  - [x] Handle active player removal
  - [x] Recalculate rotations
- [x] Status changes during session
  - [x] Temporary removal flow
  - [x] Return to rotation

### UI Tests
- [ ] Tab navigation tests
- [ ] Player CRUD operations
- [ ] Timer start/pause/resume
- [ ] Automatic substitution flow
- [ ] Manual substitution flow
- [ ] Temporary removal/return
- [ ] Settings changes during session
- [ ] Empty state handling

---

## 🚧 Phase 5: CloudKit & History (PARTIAL)

### CloudKit Integration
- [x] Entitlements configuration
  - [x] CloudKit capability enabled
  - [x] iCloud container setup
- [x] ModelConfiguration setup
  - [x] `.automatic` CloudKit database
  - [x] Offline-first configuration
- [ ] Sync testing
  - [ ] Multi-device testing
  - [ ] Offline mode validation
  - [ ] Network interruption handling
- [ ] Conflict resolution
  - [ ] Last-write-wins for settings
  - [ ] Merge strategy for sessions
  - [ ] Conflict resolution testing

### Session History
- [x] History view implementation
  - [x] List past sessions
  - [x] Sort by date (newest first)
  - [x] Display session details
  - [x] Delete sessions
- [x] Empty state
  - [x] ContentUnavailableView
  - [x] Helpful message
- [ ] Enhanced history features
  - [ ] Session detail view
  - [ ] Player breakdown per session
  - [ ] Statistics and charts
  - [ ] Filter/search sessions

### Offline Support
- [x] SwiftData automatic caching
- [x] Local-first data operations
- [ ] Network status monitoring
- [ ] Sync indicator in UI
- [ ] Manual sync trigger
- [ ] Sync error handling

### Integration Tests
- [ ] CloudKit sync scenarios
  - [ ] Create data on device A, sync to device B
  - [ ] Edit same record on both devices
  - [ ] Delete on one device, sync to other
- [ ] Offline functionality
  - [ ] Create/edit while offline
  - [ ] Automatic sync when online
  - [ ] Verify no data loss
- [ ] App lifecycle
  - [ ] Background/foreground transitions
  - [ ] Force quit recovery
  - [ ] Lock screen handling
  - [ ] Notification handling

---

## 📋 Phase 6: Multi-Platform (TODO)

### iPad Optimization
- [ ] Landscape layout
  - [ ] Split view (timer + bench)
  - [ ] Larger touch targets
  - [ ] Better use of screen space
- [ ] Portrait layout
  - [ ] Adapt to narrower width
  - [ ] Maintain readability
- [ ] Multitasking support
  - [ ] Split view compatibility
  - [ ] Slide over support
- [ ] Pointer interactions
  - [ ] Hover states
  - [ ] Pointer shape changes

### macOS Support
- [ ] Decide on approach
  - [ ] Mac Catalyst
  - [ ] Native SwiftUI
- [ ] Menu bar integration
- [ ] Keyboard shortcuts
- [ ] Window management
- [ ] macOS-specific UI patterns
- [ ] TouchBar support (if applicable)

### Cross-Platform Testing
- [ ] iPhone SE (small screen)
- [ ] iPhone Pro Max (large screen)
- [ ] iPad mini
- [ ] iPad Pro 13"
- [ ] Mac (if supported)
- [ ] Rotation handling
- [ ] Dynamic Type sizes
- [ ] Accessibility features

---

## 🔍 Quality Assurance

### Accessibility
- [ ] VoiceOver support
  - [ ] All buttons labeled
  - [ ] Meaningful labels for all elements
  - [ ] Proper navigation order
- [ ] Dynamic Type
  - [ ] Support all text sizes
  - [ ] Layout adapts to larger text
- [ ] Color Contrast
  - [ ] WCAG AA compliance
  - [ ] Test in accessibility inspector
- [ ] Touch Targets
  - [ ] Minimum 44x44 points
  - [ ] Adequate spacing between targets
- [ ] Reduce Motion
  - [ ] Respect user preference
  - [ ] Alternative animations

### Performance
- [ ] Timer efficiency
  - [ ] Battery usage testing
  - [ ] Background performance
- [ ] Data loading
  - [ ] Large rosters (100+ players)
  - [ ] Many sessions (100+ history items)
- [ ] Animation performance
  - [ ] 60fps target
  - [ ] No dropped frames
- [ ] Memory usage
  - [ ] Monitor for leaks
  - [ ] Profile in Instruments

### Error Handling
- [ ] Data validation
  - [ ] Empty name handling
  - [ ] Invalid configurations
- [ ] Network errors
  - [ ] CloudKit failures
  - [ ] Timeout handling
- [ ] User-facing errors
  - [ ] Clear error messages
  - [ ] Recovery options
  - [ ] Non-blocking alerts

### Edge Cases
- [x] Zero players (handled)
- [x] One player (handled)
- [x] Players < active spots (handled)
- [x] All players temporarily out (need alert)
- [ ] Very long session (24+ hours)
- [ ] Very long player names
- [ ] Special characters in names
- [ ] Rapid substitutions
- [ ] App force quit during timer

---

## 📚 Documentation

### Code Documentation
- [ ] Public API documentation
- [ ] Complex algorithm comments
- [ ] Architecture decision records
- [x] README.md (created)
- [x] IMPLEMENTATION_CHECKLIST.md (this file)

### User Documentation
- [ ] In-app help/tutorial
- [ ] Onboarding flow
- [ ] FAQ section
- [ ] Tips and best practices

### Developer Documentation
- [ ] Setup instructions
- [ ] Build configuration
- [ ] Testing guide
- [ ] Contribution guidelines

---

## 🚀 Deployment

### App Store Preparation
- [ ] App icon (all sizes)
- [ ] Launch screen
- [ ] Screenshots
  - [ ] iPhone (6.5", 6.9", 5.5")
  - [ ] iPad Pro (12.9", 11")
- [ ] App Store description
- [ ] Keywords
- [ ] Privacy policy
- [ ] Support URL
- [ ] Marketing materials

### Release Checklist
- [ ] Version number increment
- [ ] Build number increment
- [ ] Release notes
- [ ] Crash reporting setup
- [ ] Analytics (if applicable)
- [ ] Beta testing (TestFlight)
- [ ] App Store review
- [ ] Post-launch monitoring

---

## Summary

**Current Status:** MVP Complete (Phases 1-3) ✅  
**In Progress:** Phase 4 (Polish & Alerts) 🚧  
**Next Priority:** Complete Phase 4 (Audio, UI Tests)  
**Overall Progress:** ~65% Complete

### Immediate Next Steps
1. Implement audio feedback system (AVFoundation)
2. Write comprehensive UI tests
3. Add remaining haptic feedback
4. Test CloudKit sync on real devices
5. Add alert for "all players temporarily out"
6. Optimize for iPad layouts

### Critical Path to v1.0
1. Complete audio alerts ⚠️ HIGH
2. Complete UI tests ⚠️ HIGH
3. CloudKit sync testing ⚠️ HIGH
4. Accessibility audit ⚠️ MEDIUM
5. iPad optimization ⚠️ MEDIUM
6. App Store assets ⚠️ MEDIUM