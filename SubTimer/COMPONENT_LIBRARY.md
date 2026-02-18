# Component Library Documentation

**Project**: SubTimer  
**Last Updated**: February 17, 2026  
**Total Components**: 21  
**Total Preview States**: 105  

---

## Overview

This document provides a comprehensive reference for all reusable components in the SubTimer application. Components are organized by functional area and follow consistent architectural patterns.

---

## Architecture Principles

### Component Design
- **Single Responsibility**: Each component handles one specific UI concern
- **Props-Based Interface**: Data flows down via properties, events flow up via closures
- **Preview-Driven Development**: All components have multiple preview states
- **Size Target**: Components aim for <150 lines (some exceptions for complex previews)

### Naming Conventions
- Descriptive names indicating purpose (e.g., `ActivePlayerRowView`, `TimerControlsView`)
- "View" suffix for all SwiftUI components
- Context prefix when needed (e.g., `SettingsPlayerRowView` vs `ActivePlayerRowView`)

### File Organization
```
Views/
  Components/
    Timer/          (5 components - timer-specific UI)
    Players/        (6 components - player display components)
    Settings/       (10 components - settings-specific UI)
    Shared/         (future: cross-cutting components)
```

---

## Component Catalog

### Timer Components (5)

#### 1. TimerControlsView
**File**: `Views/Components/Timer/TimerControlsView.swift` (55 lines)  
**Purpose**: Play/pause timer button  
**Preview States**: 2

```swift
struct TimerControlsView: View {
  let isRunning: Bool
  let onToggle: () -> Void
}
```

**Usage**:
```swift
TimerControlsView(
  isRunning: timerViewModel?.isRunning ?? false,
  onToggle: toggleTimer
)
```

---

#### 2. PreferredTimeDisplayView
**File**: `Views/Components/Timer/PreferredTimeDisplayView.swift` (112 lines)  
**Purpose**: Display current play time with overtime indicator  
**Preview States**: 5

```swift
struct PreferredTimeDisplayView: View {
  let currentPlayDuration: TimeInterval
  let preferredPlayTimeSeconds: Int
}
```

**Features**:
- Large time display with `TimeFormatter`
- Overtime detection (red color when exceeded)
- Warning icon when over preferred time
- Dynamic sizing based on content

**Usage**:
```swift
PreferredTimeDisplayView(
  currentPlayDuration: currentDuration,
  preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds
)
```

---

#### 3. SubstitutionButtonView
**File**: `Views/Components/Timer/SubstitutionButtonView.swift` (80 lines)  
**Purpose**: Main substitute button  
**Preview States**: 4

```swift
struct SubstitutionButtonView: View {
  let canPerformSubstitution: Bool
  let onSubstitute: () -> Void
}
```

**Features**:
- Enabled/disabled states
- Visual feedback (blue when enabled, gray when disabled)
- Icon + text layout

**Usage**:
```swift
SubstitutionButtonView(
  canPerformSubstitution: !activePlayers.isEmpty && !benchedPlayers.isEmpty,
  onSubstitute: performAutomaticSubstitution
)
```

---

#### 4. ManualSubstitutionSheetView
**File**: `Views/Components/Timer/ManualSubstitutionSheetView.swift` (97 lines)  
**Purpose**: Sheet for selecting which bench player to substitute in  
**Preview States**: 4

```swift
struct ManualSubstitutionSheetView: View {
  let playerToSubOut: Player
  let benchPlayers: [Player]
  let onSubstitute: (Player) -> Void
  let onCancel: () -> Void
}
```

**Features**:
- List of available bench players
- Shows total play time for each player
- Cancel/substitute actions

**Usage**:
```swift
ManualSubstitutionSheetView(
  playerToSubOut: selectedPlayer,
  benchPlayers: benchedPlayers,
  onSubstitute: { benchPlayer in performManualSubstitution(subOut: selectedPlayer, subIn: benchPlayer) },
  onCancel: { showingManualSubstitution = false }
)
```

---

#### 5. PlayerActionsSheetView
**File**: `Views/Components/Timer/PlayerActionsSheetView.swift` (207 lines)  
**Purpose**: Context-sensitive player actions sheet  
**Preview States**: 5

```swift
struct PlayerActionsSheetView: View {
  let player: Player
  let canActivate: Bool
  let onSubstituteOut: () -> Void
  let onActivatePlayer: () -> Void
  let onMarkTemporarilyOut: () -> Void
  let onReturnToBench: () -> Void
  let onClose: () -> Void
}
```

**Features**:
- Different actions based on player status (active/benched/temporarily out)
- Player statistics display (current duration, total play time)
- Uses `TimeFormatter` utility

**Usage**:
```swift
PlayerActionsSheetView(
  player: selectedPlayer,
  canActivate: activePlayers.count < configuration.activePlayersCount,
  onSubstituteOut: { /* ... */ },
  onActivatePlayer: { /* ... */ },
  onMarkTemporarilyOut: { /* ... */ },
  onReturnToBench: { /* ... */ },
  onClose: { showingPlayerActions = nil }
)
```

---

### Player Components (6)

#### 6. ActivePlayerRowView
**File**: `Views/Components/Players/ActivePlayerRowView.swift` (91 lines)  
**Purpose**: Display single active player  
**Preview States**: 4

```swift
struct ActivePlayerRowView: View {
  let player: Player
  let isNextToSubOut: Bool
  let onTap: () -> Void
}
```

**Features**:
- Player name and current play duration
- "Next to sub out" indicator (orange)
- Uses `TimeFormatter`

---

#### 7. BenchPlayerRowView
**File**: `Views/Components/Players/BenchPlayerRowView.swift` (104 lines)  
**Purpose**: Display single benched player  
**Preview States**: 5

```swift
struct BenchPlayerRowView: View {
  let player: Player
  let isNextUp: Bool
  let canActivate: Bool
  let onTap: () -> Void
  let onActivatePlayer: () -> Void
}
```

**Features**:
- Player name and total play time
- "Next up" indicator (green)
- Optional activate button

---

#### 8. TemporarilyOutPlayerRowView
**File**: `Views/Components/Players/TemporarilyOutPlayerRowView.swift` (69 lines)  
**Purpose**: Display temporarily out player  
**Preview States**: 4

```swift
struct TemporarilyOutPlayerRowView: View {
  let player: Player
  let onReturnToBench: () -> Void
}
```

**Features**:
- Player name and total play time
- Return to bench button
- Warning color scheme

---

#### 9. ActivePlayersSectionView
**File**: `Views/Components/Players/ActivePlayersSectionView.swift` (132 lines)  
**Purpose**: Complete active players section  
**Preview States**: 5

```swift
struct ActivePlayersSectionView: View {
  let players: [Player]
  let maxActiveCount: Int
  let onPlayerTap: (Player) -> Void
}
```

**Features**:
- Section header with player count
- Iteration over players using `ActivePlayerRowView`
- Empty state handling
- Next-to-sub-out logic

---

#### 10. BenchSectionView
**File**: `Views/Components/Players/BenchSectionView.swift` (131 lines)  
**Purpose**: Complete bench section  
**Preview States**: 5

```swift
struct BenchSectionView: View {
  let players: [Player]
  let activePlayersCount: Int
  let maxActiveCount: Int
  let onPlayerTap: (Player) -> Void
  let onActivatePlayer: (Player) -> Void
}
```

**Features**:
- Section header with player count
- Iteration using `BenchPlayerRowView`
- Empty state
- Next-up logic

---

#### 11. TemporarilyOutSectionView
**File**: `Views/Components/Players/TemporarilyOutSectionView.swift` (80 lines)  
**Purpose**: Temporarily out players section  
**Preview States**: 4

```swift
struct TemporarilyOutSectionView: View {
  let players: [Player]
  let onReturnToBench: (Player) -> Void
}
```

**Features**:
- Section header
- Iteration using `TemporarilyOutPlayerRowView`
- Warning styling

---

### Settings Components (10)

#### 12. SettingsPlayerRowView
**File**: `Views/Components/Settings/SettingsPlayerRowView.swift` (99 lines)  
**Purpose**: Individual player row in settings  
**Preview States**: 4

```swift
struct SettingsPlayerRowView: View {
  let player: Player
  let onEdit: () -> Void
}
```

**Features**:
- Player name and status text
- Edit button
- Status helper method

---

#### 13. PlayerListSectionView
**File**: `Views/Components/Settings/PlayerListSectionView.swift` (109 lines)  
**Purpose**: Player list section with CRUD operations  
**Preview States**: 4

```swift
struct PlayerListSectionView: View {
  let players: [Player]
  let onEdit: (Player) -> Void
  let onDelete: (IndexSet) -> Void
  let onMove: (IndexSet, Int) -> Void
  let onAdd: () -> Void
}
```

**Features**:
- ForEach with delete/move support
- Add player button
- Section header/footer with count

---

#### 14. AddPlayerSheetView
**File**: `Views/Components/Settings/AddPlayerSheetView.swift` (83 lines)  
**Purpose**: Sheet for adding new players  
**Preview States**: 4

```swift
struct AddPlayerSheetView: View {
  @Binding var playerName: String
  let onCancel: () -> Void
  let onAdd: () -> Void
}
```

**Features**:
- Text field with validation
- Whitespace trimming
- Cancel/Add toolbar buttons

---

#### 15. EditPlayerSheetView
**File**: `Views/Components/Settings/EditPlayerSheetView.swift` (167 lines)  
**Purpose**: Sheet for editing player details  
**Preview States**: 4

```swift
struct EditPlayerSheetView: View {
  let player: Player
  let onSave: (String, PlayerStatus) -> Void
  let onCancel: () -> Void
  
  @State private var editedName: String
  @State private var editedStatus: PlayerStatus
}
```

**Features**:
- Three sections: Information, Status, Statistics
- Name editing with validation
- Status picker (inline style)
- Read-only statistics display
- Uses `TimeFormatter`

---

#### 16. ActivePlayersStepperView
**File**: `Views/Components/Settings/ActivePlayersStepperView.swift` (91 lines)  
**Purpose**: Stepper for active player count  
**Preview States**: 5

```swift
struct ActivePlayersStepperView: View {
  let activePlayersCount: Int
  let maxPlayers: Int
  let onChange: (Int) -> Void
}
```

**Features**:
- Automatic bounds adjustment
- Current value display
- Min/max validation

---

#### 17. PreferredTimePickerView
**File**: `Views/Components/Settings/PreferredTimePickerView.swift` (91 lines)  
**Purpose**: Picker for preferred play time  
**Preview States**: 5

```swift
struct PreferredTimePickerView: View {
  let preferredTimeSeconds: Int
  let onChange: (Int) -> Void
}
```

**Features**:
- 15 time options (30 seconds to 30 minutes)
- Standard picker styling

**Time Options**:
- 0:30, 1:00, 1:30, 2:00, 2:30, 3:00, 3:30, 4:00, 4:30, 5:00
- 7:30, 10:00, 15:00, 20:00, 30:00

---

#### 18. ConfigurationSectionView
**File**: `Views/Components/Settings/ConfigurationSectionView.swift` (107 lines)  
**Purpose**: Complete configuration section  
**Preview States**: 5

```swift
struct ConfigurationSectionView: View {
  let activePlayersCount: Int
  let maxPlayers: Int
  let preferredTimeSeconds: Int
  let onActivePlayersChange: (Int) -> Void
  let onPreferredTimeChange: (Int) -> Void
}
```

**Features**:
- Combines `ActivePlayersStepperView` and `PreferredTimePickerView`
- Warning footer for player count mismatch
- Section header

---

#### 19. SessionRowView
**File**: `Views/Components/Settings/SessionRowView.swift` (121 lines)  
**Purpose**: Individual session row display  
**Preview States**: 5

```swift
struct SessionRowView: View {
  let session: Session
}
```

**Features**:
- Session date/time
- Duration, substitution count, player count
- Icons for each metric

---

#### 20. SessionHistoryView
**File**: `Views/Components/Settings/SessionHistoryView.swift` (120 lines)  
**Purpose**: Session history list  
**Preview States**: 4

```swift
struct SessionHistoryView: View {
  let sessions: [Session]
  let onDelete: (IndexSet) -> Void
}
```

**Features**:
- List with delete support
- Empty state (ContentUnavailableView)
- Navigation title

---

#### 21. SessionManagementSectionView
**File**: `Views/Components/Settings/SessionManagementSectionView.swift` (75 lines)  
**Purpose**: Session management section  
**Preview States**: 3

```swift
struct SessionManagementSectionView: View {
  let onViewHistory: () -> Void
  let onClearSession: () -> Void
}
```

**Features**:
- View history button
- Clear session button (destructive)
- Section header

---

## Utilities

### TimeFormatter
**File**: `Utilities/TimeFormatter.swift` (138 lines)

**Purpose**: Centralized time formatting utility

**Key Methods**:
- `format(_ timeInterval: TimeInterval) -> String` - M:SS or H:MM:SS format
- Various formatting options
- Extensions for TimeInterval and Int

**Usage**:
```swift
Text(TimeFormatter.format(player.currentPlayDuration))
```

---

## Component Statistics

### By Category
- **Timer Components**: 5 (551 lines, 20 preview states)
- **Player Components**: 6 (607 lines, 27 preview states)
- **Settings Components**: 10 (1063 lines, 43 preview states)
- **Utilities**: 1 (138 lines)

### Size Distribution
- **Under 100 lines**: 11 components (52%)
- **100-150 lines**: 8 components (38%)
- **Over 150 lines**: 2 components (10%) - EditPlayerSheetView, PlayerActionsSheetView

### Preview Coverage
- **Total Preview States**: 105 across 21 components
- **Average per Component**: 5 preview states
- **Range**: 2-5 preview states per component

---

## Design Patterns

### 1. Props-Based Architecture
All components receive data via properties and communicate changes via closures:

```swift
struct ExampleView: View {
  // Input data
  let data: SomeType
  
  // Output events
  let onAction: () -> Void
}
```

### 2. Composition Over Inheritance
Sections compose row components:

```swift
// Section uses Row
struct ActivePlayersSectionView: View {
  var body: some View {
    ForEach(players) { player in
      ActivePlayerRowView(player: player, ...)
    }
  }
}
```

### 3. Empty State Handling
Components handle their own empty states:

```swift
if items.isEmpty {
  ContentUnavailableView(...)
} else {
  ForEach(items) { ... }
}
```

### 4. Callback Pattern
Consistent use of closures for events:

```swift
let onAdd: () -> Void           // Simple action
let onEdit: (Player) -> Void    // Action with parameter
let onSave: (String, PlayerStatus) -> Void  // Multiple parameters
```

---

## Testing Strategy

### Preview-Driven Development
Every component has multiple preview states covering:
- Normal state
- Empty/zero state
- Edge cases (max, min values)
- Different data variations
- Error/warning states

### Example Preview Coverage
```swift
#Preview("Normal State") { /* ... */ }
#Preview("Empty State") { /* ... */ }
#Preview("Edge Case - Maximum") { /* ... */ }
#Preview("Edge Case - Minimum") { /* ... */ }
#Preview("With Many Items") { /* ... */ }
```

---

## Integration Guidelines

### Using Components in Views

1. **Import** - Components are in the same module, no import needed
2. **Declare Properties** - Pass data from parent
3. **Handle Callbacks** - Implement action handlers
4. **State Management** - Use @State in parent for sheets/alerts

**Example**:
```swift
struct ParentView: View {
  @State private var items: [Item] = []
  @State private var showingAdd = false
  
  var body: some View {
    ItemListView(
      items: items,
      onAdd: { showingAdd = true },
      onDelete: deleteItems
    )
    .sheet(isPresented: $showingAdd) {
      AddItemSheet(...)
    }
  }
  
  func deleteItems(at offsets: IndexSet) {
    // Handle deletion
  }
}
```

---

## Future Enhancements

### Potential Shared Components
- **EmptyStateView** - Reusable empty state wrapper
- **SectionHeaderView** - Consistent section headers
- **ConfirmationAlertView** - Standard alert component
- **LoadingStateView** - Loading indicators

### Accessibility Improvements
- VoiceOver labels for all interactive elements
- Dynamic type support verification
- Color contrast validation
- Reduced motion support

### Performance Optimizations
- Identify and memoize expensive computations
- Consider lazy loading for large lists
- Profile preview performance

---

## Maintenance Notes

### Adding New Components

1. **Create File** in appropriate directory (Timer/Players/Settings/Shared)
2. **Follow Naming Convention** - `[Purpose]View.swift`
3. **Add Documentation** - Header comment explaining purpose
4. **Create Previews** - Minimum 3 preview states
5. **Update This Document** - Add component to catalog
6. **Test Build** - Ensure no compilation errors

### Updating Components

1. **Check Impact** - Identify all usages with find/grep
2. **Update Interface** - Modify properties/methods
3. **Update Previews** - Ensure previews still work
4. **Update Callers** - Update all parent views
5. **Test Thoroughly** - Manual testing in simulator

### Deprecating Components

1. **Document Reason** - Why component is deprecated
2. **Provide Alternative** - What should be used instead
3. **Migration Guide** - How to migrate existing code
4. **Grace Period** - Don't remove immediately

---

## Resources

### Related Documentation
- `REFACTORING_PRD.md` - Original refactoring plan
- `PROGRESS_LOG.md` - Detailed phase completion notes
- `REFACTORING_CHECKLIST.md` - Implementation checklist
- `SESSION_SUMMARY.md` - Session summaries

### Code Organization
```
SubTimer/
  Views/
    TimerView.swift (368 lines)
    SettingsView.swift (248 lines)
    Components/
      Timer/ (5 components)
      Players/ (6 components)
      Settings/ (10 components)
  Utilities/
    TimeFormatter.swift
```

---

**Last Updated**: February 17, 2026  
**Status**: Component library complete  
**Next Steps**: Continue maintaining and expanding as needed