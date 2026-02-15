# SubTimer Project Structure

## 📁 Directory Layout

```
SubTimer/
├── SubTimer/
│   ├── Models/                          # SwiftData Models
│   │   ├── Player.swift                 # Player entity with status tracking
│   │   ├── AppConfiguration.swift       # App settings & preferences
│   │   └── Session.swift                # Session history tracking
│   │
│   ├── Views/                           # SwiftUI Views
│   │   ├── MainTabView.swift            # Root tab navigation (Timer/Settings)
│   │   ├── TimerView.swift              # Main game timer interface
│   │   └── SettingsView.swift           # Configuration & player management
│   │
│   ├── Utilities/                       # Helper Utilities
│   │   └── TimeFormatter.swift          # Time formatting helpers
│   │
│   ├── Assets.xcassets/                 # App assets (icons, colors)
│   ├── SubTimerApp.swift                # App entry point & ModelContainer
│   ├── SubTimer.entitlements            # CloudKit capabilities
│   ├── Info.plist                       # App configuration
│   │
│   └── Documentation/                   # [Not in repo, but available]
│       ├── PRD.md                       # Product Requirements Document
│       ├── README.md                    # Project overview
│       ├── GETTING_STARTED.md           # User guide
│       ├── QUICK_REFERENCE.md           # Quick action reference
│       └── IMPLEMENTATION_CHECKLIST.md  # Development progress
│
├── SubTimerTests/                       # Unit Tests
│   └── SubTimerTests.swift              # Model & logic tests
│
└── SubTimerUITests/                     # UI Tests
    ├── SubTimerUITests.swift            # UI interaction tests
    └── SubTimerUITestsLaunchTests.swift # Launch tests

```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         App Layer                           │
│                      SubTimerApp.swift                      │
│                  (ModelContainer, CloudKit)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      View Layer (SwiftUI)                   │
├─────────────────────────────────────────────────────────────┤
│  MainTabView                                                │
│    ├── TimerView          [Primary Interface]              │
│    │   ├── Timer Controls (Start/Pause)                    │
│    │   ├── Preferred Time Display                          │
│    │   ├── Active Players List                             │
│    │   ├── Bench Queue                                     │
│    │   ├── Temporarily Out Section                         │
│    │   └── Substitute Button                               │
│    │                                                        │
│    └── SettingsView       [Configuration]                  │
│        ├── Player Management (CRUD)                        │
│        ├── Configuration (Active count, Time)              │
│        └── Session History                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  ViewModel Layer (@Observable)              │
├─────────────────────────────────────────────────────────────┤
│  TimerViewModel                                             │
│    ├── Timer state (running/paused)                        │
│    ├── Timer tick handler                                  │
│    └── Timer lifecycle management                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Model Layer (SwiftData)                   │
├─────────────────────────────────────────────────────────────┤
│  Player                                                     │
│    ├── id, name, createdDate                               │
│    ├── currentPlayDuration, totalPlayTime                  │
│    ├── status (active/benched/temporarilyOut)              │
│    └── sortOrder                                            │
│                                                             │
│  AppConfiguration                                           │
│    ├── preferredPlayTimeSeconds                            │
│    ├── activePlayersCount                                  │
│    ├── lastModifiedDate                                    │
│    └── validation methods                                  │
│                                                             │
│  Session                                                    │
│    ├── startDate, endDate, duration                        │
│    ├── substitutionCount                                   │
│    ├── playerNames, configuration                          │
│    └── isActive computed property                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Persistence Layer (SwiftData + CloudKit)       │
├─────────────────────────────────────────────────────────────┤
│  ModelContainer                                             │
│    ├── Local SQLite database                               │
│    ├── CloudKit automatic sync (.automatic)                │
│    ├── Offline-first design                                │
│    └── Conflict resolution (last-write-wins)               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow

### Starting a Session
```
User taps "Start"
    ↓
TimerView.toggleTimer()
    ↓
Auto-activate players (if needed)
    ↓
Create/update Session
    ↓
TimerViewModel.startTimer()
    ↓
Timer ticks every 1s → updatePlayerTimes()
    ↓
Update Player.currentPlayDuration
    ↓
Update Session.duration
    ↓
SwiftData auto-saves → CloudKit sync
```

### Making a Substitution
```
User taps "Substitute"
    ↓
performAutomaticSubstitution()
    ↓
Find longest playing player
    ↓
Find next bench player
    ↓
Swap: subOut.status = .benched
      subIn.status = .active
    ↓
Accumulate: subOut.totalPlayTime += currentDuration
    ↓
Reset: All active players.currentPlayDuration = 0
    ↓
Increment: session.substitutionCount++
    ↓
Haptic feedback
    ↓
SwiftData auto-saves → CloudKit sync
```

---

## 📊 File Statistics

| File | Lines | Purpose |
|------|-------|---------|
| `Player.swift` | ~44 | Player entity model |
| `AppConfiguration.swift` | ~39 | Settings model |
| `Session.swift` | ~57 | Session history model |
| `TimerView.swift` | ~655 | Main timer interface |
| `SettingsView.swift` | ~404 | Settings interface |
| `MainTabView.swift` | ~29 | Tab navigation |
| `SubTimerApp.swift` | ~33 | App entry point |
| `TimeFormatter.swift` | ~138 | Time utilities |
| `SubTimerTests.swift` | ~340 | Unit tests |

**Total:** ~1,739 lines of Swift code (excluding UI tests)

---

## 🎯 Key Design Patterns

### 1. MVVM (Model-View-ViewModel)
- **Models**: SwiftData entities
- **Views**: SwiftUI views (declarative)
- **ViewModels**: @Observable classes for state

### 2. Repository Pattern (via SwiftData)
- `@Query` for reactive data access
- `ModelContext` for CRUD operations
- Automatic persistence

### 3. Observer Pattern
- `@Observable` for ViewModel state
- `@Query` for model changes
- SwiftUI automatic re-rendering

### 4. Strategy Pattern
- TimeFormatter for various formatting needs
- Status enum for player states
- Substitution algorithms (auto vs manual)

---

## 🔌 Dependencies

### Apple Frameworks
- **SwiftUI**: UI framework
- **SwiftData**: Persistence layer
- **CloudKit**: Cloud sync
- **Foundation**: Core utilities
- **UIKit**: Haptic feedback (UIFeedbackGenerator)

### No Third-Party Dependencies
- Pure Swift/Apple ecosystem
- No CocoaPods, SPM, or Carthage
- Zero external libraries

---

## 🧪 Testing Structure

### Unit Tests (SubTimerTests/)
- ✅ Model initialization
- ✅ Status transitions
- ✅ Time tracking logic
- ✅ Configuration validation
- ✅ Session management
- ✅ Edge cases (0, 1, N players)
- ✅ Fair play distribution
- ✅ Time formatting utilities

### UI Tests (SubTimerUITests/)
- ⚠️ TODO: Tab navigation
- ⚠️ TODO: Player CRUD flows
- ⚠️ TODO: Timer controls
- ⚠️ TODO: Substitution flows

### Integration Tests
- ⚠️ TODO: CloudKit sync
- ⚠️ TODO: Offline scenarios
- ⚠️ TODO: App lifecycle

---

## 📦 Build Configuration

### Target: SubTimer
- **Platform**: iOS 18.0+
- **Language**: Swift 5.9+
- **Build System**: Xcode Build System
- **Signing**: Automatic

### Capabilities
- ✅ iCloud (CloudKit)
- ✅ Background Modes (future)
- ✅ Push Notifications (configured)

### Build Settings
- Swift Optimization Level: -O (Release)
- Debug Information Format: DWARF with dSYM
- Enable Bitcode: No
- Module Verifier: Yes

---

## 🚀 Deployment Info

### App Identifier
- Bundle ID: `com.yourcompany.SubTimer`
- Team ID: (Configure in Xcode)

### Supported Devices
- iPhone (primary)
- iPad (universal, needs optimization)
- Mac Catalyst (future)

### Minimum OS Versions
- iOS: 18.0
- iPadOS: 18.0
- macOS: (future)

---

## 📝 Code Conventions

### Naming
- **Models**: Singular nouns (Player, Session)
- **Views**: Descriptive names + "View" (TimerView)
- **ViewModels**: Name + "ViewModel" (TimerViewModel)
- **Methods**: Verb phrases (performSubstitution)
- **Properties**: Noun phrases (currentPlayDuration)

### Organization
- **MARK comments**: Organize code sections
- **Extensions**: Separate file or bottom of file
- **Protocols**: Top of file or separate
- **Private methods**: Bottom of implementation

### SwiftUI Style
- Property wrappers first
- Computed properties
- Body
- Private views
- Private methods

---

## 🔐 Security & Privacy

### Data Storage
- Local: SwiftData (encrypted at rest)
- Cloud: CloudKit (end-to-end encrypted)
- No third-party servers

### Permissions Required
- iCloud: For sync (optional)
- None required for basic functionality

### Data Collection
- Zero analytics
- Zero telemetry
- Zero tracking
- User data stays on device

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `PRD.md` | Product requirements (full spec) |
| `README.md` | Technical overview |
| `GETTING_STARTED.md` | User onboarding guide |
| `QUICK_REFERENCE.md` | One-page cheat sheet |
| `IMPLEMENTATION_CHECKLIST.md` | Development progress |
| `PROJECT_STRUCTURE.md` | This file |

---

## 🎨 UI Component Hierarchy

### Timer Tab
```
NavigationStack
└── ScrollView
    ├── Timer Controls (Start/Pause)
    ├── Preferred Time Display
    ├── Active Players Section
    │   └── ForEach(activePlayers) { PlayerCard }
    ├── Bench Section
    │   └── ForEach(benchPlayers) { PlayerCard }
    ├── Temporarily Out Section (conditional)
    │   └── ForEach(tempOutPlayers) { PlayerCard }
    └── Substitute Button
```

### Settings Tab
```
NavigationStack
└── Form
    ├── Player Management Section
    │   └── List(players) { PlayerRow }
    ├── Configuration Section
    │   ├── Stepper (Active Players)
    │   └── Picker (Preferred Time)
    ├── Session Management Section
    │   ├── NavigationLink (History)
    │   └── Button (Clear Session)
    └── Sheets
        ├── Add Player Sheet
        └── Edit Player Sheet
```

---

**Last Updated**: February 13, 2026  
**Version**: 1.0  
**Status**: MVP Complete (Phases 1-3)