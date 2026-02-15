# Getting Started with SubTimer

Welcome to SubTimer! This guide will help you understand and use the implemented sports substitution timer app.

## Quick Start

### 1. Build and Run
```bash
# Open in Xcode
open SubTimer.xcodeproj

# Or build from command line
xcodebuild -scheme SubTimer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### 2. First Launch Setup

When you first launch SubTimer, you'll see an empty timer view. Here's how to get started:

1. **Navigate to Settings Tab** (bottom right)
2. **Add Your Players**
   - Tap "Add Player" button
   - Enter player name
   - Tap "Add"
   - Repeat for all team members
3. **Configure Settings**
   - Set "Active Players" count (how many play at once)
   - Choose "Preferred Play Time" (how long each rotation should be)
4. **Return to Timer Tab** (bottom left)

## Using the Timer Tab

### Starting a Session

1. Tap the **Start** button (green)
   - Timer automatically activates first X players (based on your active player count)
   - Timer begins counting up for all active players
   - A session is created in history

### During a Game

#### Monitoring Play Time
- **Large Timer Display**: Shows current play time for the longest-playing active player
- **Active Players Section**: Lists who's currently playing with individual times
- **Orange Arrow (↓)**: Indicates which player will be substituted out next
- **Bench Section**: Shows waiting players in queue order
- **Green Arrow (↑)**: Indicates "Next Up" player

#### Making Substitutions

**Automatic Substitution** (Recommended):
1. Wait until preferred time is reached (display turns red)
2. Tap the blue **Substitute** button
3. Longest-playing player moves to bench
4. Next player enters the game
5. All active timers reset to 0:00
6. Timer automatically resumes

**Manual Substitution**:
1. Tap on any **Active Player**
2. Select "Substitute Out"
3. Choose which bench player to bring in
4. Substitution completes with same reset logic

#### Player Management During Game

**Temporary Removal** (Injury, Bathroom Break, etc.):
1. Long-press or tap on player (active or benched)
2. Select "Mark Temporarily Out"
3. Player moves to "Temporarily Out" section
4. When ready, tap "Return to Bench"

**Quick Activation** (When spots available):
- If you have fewer active players than configured, you'll see a **+** button next to bench players
- Tap to immediately activate them

### Pausing and Resuming

- Tap **Pause** (orange) to stop the timer
- All times freeze in place
- Tap **Start** to resume
- Great for timeouts, breaks, or halftime

### Visual Indicators

| Color | Meaning |
|-------|---------|
| 🟢 Green | Start button, "Next Up" player |
| 🟠 Orange | Pause button, "Next to Sub Out" player |
| 🔴 Red | Overtime (past preferred time) |
| 🟡 Yellow | Temporarily out players |
| 🔵 Blue | Substitute button, action buttons |

### Haptic Feedback

- **Medium Impact**: When a substitution occurs
- **Warning Notification**: When preferred time is reached

## Settings Tab Features

### Player Management

#### Adding Players
- Tap "Add Player"
- Enter name (supports emoji! ⚽️)
- Save

#### Editing Players
- Tap the **pencil icon** next to any player
- Modify name or status
- View statistics (current duration, total time, created date)

#### Reordering Players
- Tap "Edit" in navigation bar
- Drag players to reorder
- This affects bench queue order

#### Deleting Players
- Swipe left on player
- Tap "Delete"
- Confirmation required if player is currently active

### Configuration

**Active Players Count**:
- Use stepper to adjust
- Valid range: 1 to total number of players
- Auto-adjusts if you have fewer players than configured

**Preferred Play Time**:
- Choose from preset options (0:30 to 30:00)
- 0:30 = 30 seconds minimum
- 30:00 = 30 minutes maximum
- Most common: 3:00 (3 minutes)

### Session Management

**Session History**:
- View past games/practices
- See date, duration, substitution count, player count
- Swipe to delete old sessions

**Clear Current Session**:
- Resets all player times to zero
- Ends active session
- Use between games or practices

## Understanding the Substitution Algorithm

SubTimer ensures fair play time using these principles:

### Automatic Mode
1. **Tracks** current play duration for each active player
2. **Identifies** player with longest current duration
3. **Selects** first player in bench queue (lowest total play time)
4. **Swaps** them, moving benched player to active
5. **Accumulates** outgoing player's time to their total
6. **Resets** all active player current times to 0:00
7. **Updates** session substitution count

### Fair Play Goal
- All players should be within ±10% of average playing time
- App tracks total play time across entire session
- Visual indicators help coach see disparities

## Tips and Best Practices

### Before the Game
1. ✅ Add all players who will participate
2. ✅ Set correct active player count (4 for basketball, 11 for soccer, etc.)
3. ✅ Choose appropriate rotation time for your sport/age group
4. ✅ Test with a quick practice substitution

### During the Game
1. ✅ Start timer when play begins
2. ✅ Watch for red overtime indicator
3. ✅ Pause during official timeouts
4. ✅ Use temporary removal for injuries
5. ✅ Trust the automatic substitution for fairness

### After the Game
1. ✅ Check session history to see total stats
2. ✅ Review if any players need more time next game
3. ✅ Clear session before next game

### Common Scenarios

**Late Arrival**:
- Add player during session (in Settings)
- They'll automatically join bench queue
- Manual substitution available immediately

**Early Departure**:
- Tap player > "Mark Temporarily Out"
- Or delete from Settings if they won't return
- Rotation adjusts automatically

**Uneven Numbers**:
- App handles any player count
- If 7 players with 5 active spots = 2 on bench
- Rotates through evenly

**One Player Only**:
- Timer works but substitution disabled
- Useful for individual time tracking

**Very Long Game**:
- Timer continues beyond 99:59 (shows hours)
- No automatic limit on session duration

## Keyboard Shortcuts (Future)

Currently not implemented, planned for macOS version:
- `Space`: Start/Pause timer
- `S`: Perform substitution
- `Cmd+,`: Open Settings
- `Cmd+H`: Toggle history

## Troubleshooting

### Timer Won't Start
- ✅ Check that you have at least 1 player added
- ✅ Verify Settings > Players list is not empty

### Substitute Button Disabled
- ✅ Need both active players AND bench players
- ✅ Can't substitute if bench is empty

### Player Missing from List
- ✅ Check Settings tab to verify they're added
- ✅ Check "Temporarily Out" section
- ✅ May be filtered or deleted accidentally

### Times Not Updating
- ✅ Ensure timer is running (not paused)
- ✅ Check player is marked as "Active" status
- ✅ Try pausing and resuming

### CloudKit Sync Not Working
- ✅ Verify iCloud is signed in on device
- ✅ Check internet connection
- ✅ Sync happens automatically in background
- ✅ May take a few moments to propagate

## Advanced Features

### Multiple Sessions per Day
- Each time you tap Start, a new session begins
- Previous session ends automatically
- All sessions saved to history

### Player Statistics
- **Current Play Duration**: Time in current shift
- **Total Play Time**: Cumulative time across entire session
- View in Settings > Edit Player or player action sheet

### Session Data
- **Duration**: Total game/practice time
- **Substitution Count**: Number of swaps made
- **Player Names**: Who participated
- Stored for future analysis

## Accessibility

SubTimer is designed to be accessible:
- Large touch targets (44x44pt minimum)
- High contrast colors for outdoor use
- VoiceOver support (in progress)
- Dynamic Type support (in progress)
- Haptic feedback for non-visual alerts

## Data and Privacy

### Local Storage
- All data stored on device using SwiftData
- Automatic backup via iCloud (if enabled)
- No data sent to external servers
- You own your data

### CloudKit Sync
- Optional - works offline without iCloud
- Syncs across your devices only
- End-to-end encryption
- Standard Apple privacy policies apply

### Deleting Data
- Delete individual players in Settings
- Delete sessions in History view
- Clear current session clears times but keeps roster
- Uninstalling app removes all local data

## What's Next?

SubTimer is actively being developed. Upcoming features:

### Phase 4 (In Progress)
- 🔔 Audio alerts at preferred time
- ⚡️ Additional haptic feedback
- ✅ Comprehensive UI tests

### Phase 5 (Planned)
- ☁️ Enhanced CloudKit features
- 📊 Advanced statistics
- 📈 Play time analytics

### Phase 6 (Future)
- 📱 iPad optimization
- 💻 macOS version
- ⌚️ Apple Watch app
- 📤 Export to CSV/PDF

## Getting Help

- 📖 Check README.md for technical details
- ✅ Review IMPLEMENTATION_CHECKLIST.md for feature status
- 🐛 Report issues via GitHub Issues
- 💡 Feature requests welcome

## Contributing

Want to improve SubTimer? See IMPLEMENTATION_CHECKLIST.md for:
- Areas that need work
- Testing requirements
- Known limitations

---

**Enjoy fair and easy player rotation with SubTimer!** ⚽️🏀🏐
