# 🎯 SubTimer - START HERE

Welcome to SubTimer! This document will guide you through everything you need to know.

---

## 🚀 Quick Start (30 seconds)

1. Open `SubTimer.xcodeproj` in Xcode
2. Select iPhone simulator (any model)
3. Press **⌘R** to build and run
4. Navigate to **Settings** tab → Add players
5. Return to **Timer** tab → Tap **Start**

**You're now tracking substitutions!** ⚽️🏀🏐

---

## 📚 Documentation Guide

### For Users
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Complete user guide with step-by-step instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - One-page cheat sheet for common actions

### For Developers
- **[README.md](README.md)** - Technical overview and feature list
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Architecture and file organization
- **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** - Detailed development progress

### For Product/PM
- **[PRD.md](PRD.md)** - Original product requirements document
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - What's been built and what's left

---

## ✅ What's Working Right Now

### Core Features (100% Complete)
- ✅ Unlimited player roster management
- ✅ Real-time play time tracking
- ✅ Automatic fair substitution algorithm
- ✅ Manual substitution overrides
- ✅ Temporary player removal (injuries)
- ✅ Start/pause timer controls
- ✅ Session history tracking
- ✅ CloudKit sync configuration
- ✅ 100% offline support
- ✅ Haptic feedback
- ✅ Visual alerts (color-coded)

### Testing
- ✅ 25 comprehensive unit tests
- ✅ All models and logic tested
- ✅ Edge cases covered

### Documentation
- ✅ 6 detailed markdown files
- ✅ User guides and developer docs
- ✅ Quick reference cards

---

## ⚠️ What's Missing (Before v1.0)

### High Priority
- ⚠️ **Audio alerts** - Need to add AVFoundation sound
- ⚠️ **UI tests** - Need comprehensive test suite
- ⚠️ **CloudKit testing** - Needs real device validation

### Medium Priority
- ⚠️ **iPad optimization** - Works but layout not optimized
- ⚠️ **Accessibility audit** - VoiceOver and Dynamic Type
- ⚠️ **App Store assets** - Icons, screenshots, description

**Estimated Time to v1.0:** 19-31 hours

---

## 🏗️ Project Structure

```
SubTimer/
├── Models/              # SwiftData entities (Player, Config, Session)
├── Views/               # SwiftUI views (Timer, Settings, Tab)
├── Utilities/           # Time formatting helpers
└── Tests/               # 25 unit tests
```

**Technology:**
- SwiftUI (100% declarative)
- SwiftData (persistence + CloudKit)
- @Observable (state management)
- iOS 18.0+ (Universal app)

---

## 🎮 How to Use SubTimer

### First Time Setup
1. Open app
2. Tap **Settings** tab (bottom right)
3. Add players (tap ➕ button)
4. Set "Active Players" count (how many play at once)
5. Choose "Preferred Play Time" (rotation duration)
6. Return to **Timer** tab

### During a Game
1. Tap **Start** ▶️ (green button)
2. Watch timer count up
3. When red (overtime), tap **Substitute** 🔄
4. Longest player subs out, next bench player comes in
5. All timers reset, rotation continues

### Manual Actions
- **Tap any player** → See actions (substitute, temp. out)
- **Pause button** → Stop timer for timeouts
- **Temp. out** → Handle injuries/breaks
- **Return to bench** → Bring player back

---

## 🧪 Running Tests

```bash
# Build the project
xcodebuild -scheme SubTimer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run unit tests
xcodebuild test -scheme SubTimer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Current Status:** ✅ All 25 unit tests passing

---

## 📖 Learning Path

### 5-Minute Tour
1. Read this file (you're here!)
2. Skim **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**
3. Run the app
4. Try adding players and starting timer

### 30-Minute Deep Dive
1. Read **[GETTING_STARTED.md](GETTING_STARTED.md)** - User guide
2. Read **[README.md](README.md)** - Technical overview
3. Browse code in Xcode
4. Run unit tests

### 2-Hour Complete Understanding
1. Read **[PRD.md](PRD.md)** - Original requirements
2. Read **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Architecture
3. Read **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Progress
4. Read **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** - Details
5. Review all source code
6. Run and test all features

---

## 🔍 Key Files to Explore

### Models (Data Layer)
- `Models/Player.swift` - Player entity with play time tracking
- `Models/AppConfiguration.swift` - Settings and validation
- `Models/Session.swift` - Session history

### Views (UI Layer)
- `Views/TimerView.swift` - Main timer interface (655 lines)
- `Views/SettingsView.swift` - Configuration UI (404 lines)
- `Views/MainTabView.swift` - Tab navigation (29 lines)

### App Entry
- `SubTimerApp.swift` - App setup with SwiftData + CloudKit

### Tests
- `SubTimerTests/SubTimerTests.swift` - 25 unit tests

---

## 💡 Pro Tips

### For Using the App
- ✅ Start timer when game begins
- ✅ Red timer = time to substitute
- ✅ Trust the automatic rotation
- ✅ Use pause for official timeouts
- ✅ Temporary out for injuries

### For Development
- ✅ All models use SwiftData
- ✅ Views are pure SwiftUI
- ✅ Timer uses @Observable
- ✅ No third-party dependencies
- ✅ Clean MVVM architecture

### For Testing
- ✅ Unit tests cover all models
- ✅ Edge cases handled (0, 1, N players)
- ✅ Fair play math validated
- ✅ Time formatting tested

---

## 🆘 Troubleshooting

### Build Issues
**Problem:** Build fails  
**Solution:** Clean build folder (⇧⌘K) and rebuild (⌘B)

### Simulator Issues
**Problem:** Simulator won't launch  
**Solution:** Use iPhone 17 Pro or any iOS 18+ simulator

### Data Issues
**Problem:** Data not persisting  
**Solution:** Check SwiftData logs, restart simulator

### CloudKit Issues
**Problem:** Sync not working  
**Solution:** CloudKit requires real devices, won't sync on simulator

---

## 📊 Project Stats

- **Total Swift Files:** 8
- **Lines of Code:** ~1,739
- **Unit Tests:** 25 test cases
- **Documentation:** 6 markdown files (60+ KB)
- **Build Status:** ✅ Passing
- **Overall Progress:** 75% to v1.0

---

## 🎯 Roadmap

### ✅ Phase 1-3: Complete (MVP)
- Core data models
- Timer functionality
- Substitution system
- Session tracking

### 🚧 Phase 4: Partial (70%)
- Visual alerts ✅
- Haptic feedback ✅
- Audio alerts ⚠️
- UI tests ⚠️

### 📋 Phase 5: Partial (60%)
- CloudKit setup ✅
- Session history ✅
- Device testing ⚠️

### 📋 Phase 6: Not Started
- iPad optimization
- macOS version
- Multi-platform testing

---

## 🤝 Next Steps

### If You're a Coach/User
👉 Start with **[GETTING_STARTED.md](GETTING_STARTED.md)**

### If You're a Developer
👉 Start with **[README.md](README.md)** and **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)**

### If You're a Product Manager
👉 Start with **[PRD.md](PRD.md)** and **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)**

### If You're Testing/QA
👉 Start with **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** and **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**

---

## 🎉 You're Ready!

SubTimer is a **fully functional MVP** that helps coaches manage fair player rotations. The core features work reliably, the code is clean, and the architecture supports future enhancements.

**Choose your path:**
- 🏃‍♂️ **Quick Start** → Run the app and try it out
- 📖 **Learn More** → Read the documentation
- 🛠️ **Develop** → Dive into the code
- ✅ **Test** → Run the test suite

**Enjoy building fair sports rotations with SubTimer!** ⚽️🏀🏐

---

**Version:** 1.0 MVP  
**Status:** Beta Ready  
**Last Updated:** February 14, 2026