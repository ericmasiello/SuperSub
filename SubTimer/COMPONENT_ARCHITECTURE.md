# Component Architecture Documentation

## Overview

This document describes the component architecture after the refactoring of TimerView and SettingsView.

---

## Component Hierarchy

```
SubTimer App
├── MainTabView
│   ├── TimerView (Orchestrator)
│   │   ├── Components/Timer/
│   │   │   ├── TimerControlsView
│   │   │   ├── PreferredTimeDisplayView
│   │   │   └── SubstitutionButtonView
│   │   ├── Components/Players/
│   │   │   ├── ActivePlayersSectionView
│   │   │   │   └── ActivePlayerRowView
│   │   │   ├── BenchSectionView
│   │   │   │   └── BenchPlayerRowView
│   │   │   └── TemporarilyOutSectionView
│   │   │       └── TemporarilyOutPlayerRowView
│   │   └── Components/Shared/
│   │       ├── EmptyStateView
│   │       ├── TimeDisplayView
│   │       └── SectionHeaderView
│   │
│   └── SettingsView (Orchestrator)
│       ├── Components/Settings/
│       │   ├── PlayerListSectionView
│       │   │   └── PlayerRowView
│       │   ├── ConfigurationSectionView
│       │   │   ├── ActivePlayersStepperView
│       │   │   └── PreferredTimePickerView
│       │   ├── SessionManagementSectionView
│       │   └── SessionHistoryView
│       │       └── SessionRowView
│       └── Components/Shared/
│           ├── EmptyStateView
│           ├── PlayerStatusBadge
│           └── SectionHeaderView
│
├── Models/
│   ├── Player
│   ├── AppConfiguration
│   └── Session
│
├── ViewModels/
│   └── TimerViewModel
│
└── Utilities/
    └── TimeFormatter
```

---

## Component Responsibilities

### Timer Components

#### TimerControlsView
**Purpose**: Start/pause timer button  
**Props**:
- `isRunning: Bool` - Current timer state
- `onToggle: () -> Void` - Toggle callback

**Responsibilities**:
- Display play or pause button based on state
- Handle button styling (green for start, orange for pause)
- Provide haptic feedback

---

#### PreferredTimeDisplayView
**Purpose**: Display current play time with overtime indicator  
**Props**:
- `currentPlayDuration: TimeInterval` - Current time
- `preferredPlayTimeSeconds: Int` - Target time

**Responsibilities**:
- Display formatted time prominently
- Show overtime warning when exceeded
- Color code: normal (primary) vs overtime (red)
- Display preferred time reference

---

#### SubstitutionButtonView
**Purpose**: Trigger automatic substitution  
**Props**:
- `canPerformSubstitution: Bool` - Enable state
- `onSubstitute: () -> Void` - Action callback

**Responsibilities**:
- Display substitute button
- Enable/disable based on player availability
- Visual feedback for enabled state

---

### Player Components

#### ActivePlayerRowView
**Purpose**: Display single active player  
**Props**:
- `player: Player` - Player data
- `isNextToSubOut: Bool` - Highlight flag
- `onTap: () -> Void` - Selection callback

**Responsibilities**:
- Show player name and current play time
- Highlight next-to-sub-out player
- Display action indicator
- Format time display

---

#### BenchPlayerRowView
**Purpose**: Display single benched player  
**Props**:
- `player: Player` - Player data
- `isNextUp: Bool` - Highlight flag
- `canActivate: Bool` - Show activate button
- `onTap: () -> Void` - Selection callback
- `onActivate: () -> Void` - Activation callback

**Responsibilities**:
- Show player name and total play time
- Highlight next-up player
- Display activate button when slots available
- Show next-up indicator

---

#### TemporarilyOutPlayerRowView
**Purpose**: Display temporarily out player  
**Props**:
- `player: Player` - Player data
- `onReturnToBench: () -> Void` - Return callback

**Responsibilities**:
- Show player name and total time
- Display return-to-bench button
- Warning color scheme (yellow)

---

#### ActivePlayersSectionView
**Purpose**: Manage active players list  
**Props**:
- `players: [Player]` - Active players
- `maxActiveCount: Int` - Configuration
- `onPlayerTap: (Player) -> Void` - Selection callback

**Responsibilities**:
- Display section header with count
- Show empty state when no active players
- Render list of active player rows
- Calculate next-to-sub-out player

---

#### BenchSectionView
**Purpose**: Manage bench players list  
**Props**:
- `players: [Player]` - Benched players
- `activePlayersCount: Int` - Current active count
- `maxActiveCount: Int` - Configuration
- `onPlayerTap: (Player) -> Void` - Selection callback
- `onActivatePlayer: (Player) -> Void` - Activation callback

**Responsibilities**:
- Display section header with count
- Show empty state when no benched players
- Render list of bench player rows
- Determine if activation is allowed

---

#### TemporarilyOutSectionView
**Purpose**: Manage temporarily out players list  
**Props**:
- `players: [Player]` - Temporarily out players
- `onReturnToBench: (Player) -> Void` - Return callback

**Responsibilities**:
- Display section header
- Render list of temporarily out player rows
- Conditional rendering (only if players exist)

---

### Settings Components

#### PlayerListSectionView
**Purpose**: Display and manage player roster  
**Props**:
- `players: [Player]` - All players
- `onAdd: () -> Void` - Add callback
- `onEdit: (Player) -> Void` - Edit callback
- `onDelete: (IndexSet) -> Void` - Delete callback
- `onMove: (IndexSet, Int) -> Void` - Reorder callback

**Responsibilities**:
- Display all players with status
- Support add/edit/delete/reorder
- Show player count
- Display status for each player

---

#### PlayerRowView
**Purpose**: Individual player in settings  
**Props**:
- `player: Player` - Player data
- `onEdit: () -> Void` - Edit callback

**Responsibilities**:
- Show player name and status
- Display edit button
- Format status text

---

#### AddPlayerSheetView
**Purpose**: Add new player modal  
**Props**:
- `isPresented: Binding<Bool>` - Visibility
- `onAdd: (String) -> Void` - Add callback

**Responsibilities**:
- Text input for player name
- Input validation
- Cancel/confirm actions

---

#### EditPlayerSheetView
**Purpose**: Edit existing player modal  
**Props**:
- `player: Player` - Player to edit
- `onDismiss: () -> Void` - Dismiss callback
- `onSave: (String, PlayerStatus) -> Void` - Save callback

**Responsibilities**:
- Edit player name
- Change player status
- Display statistics
- Save/cancel actions

---

#### ConfigurationSectionView
**Purpose**: App configuration settings  
**Props**:
- `activePlayersCount: Binding<Int>` - Active count
- `preferredPlayTimeSeconds: Binding<Int>` - Preferred time
- `totalPlayerCount: Int` - Total players

**Responsibilities**:
- Display active players stepper
- Display preferred time picker
- Show validation warnings
- Auto-adjust for player count

---

#### ActivePlayersStepperView
**Purpose**: Active players count control  
**Props**:
- `value: Binding<Int>` - Current value
- `maxPlayers: Int` - Maximum allowed

**Responsibilities**:
- Increment/decrement control
- Enforce bounds (1 to maxPlayers)
- Display current value

---

#### PreferredTimePickerView
**Purpose**: Preferred play time selection  
**Props**:
- `seconds: Binding<Int>` - Selected time in seconds

**Responsibilities**:
- Display time options (0:30 to 30:00)
- Format display labels
- Handle selection

---

#### SessionManagementSectionView
**Purpose**: Session controls  
**Props**:
- `onViewHistory: () -> Void` - View history callback
- `onClearSession: () -> Void` - Clear callback

**Responsibilities**:
- Navigate to session history
- Clear current session with confirmation
- Section organization

---

#### SessionHistoryView
**Purpose**: Display past sessions  
**Props**:
- `sessions: [Session]` - Session data
- `onDelete: (IndexSet) -> Void` - Delete callback

**Responsibilities**:
- Display session list
- Show empty state
- Support deletion
- Format session details

---

#### SessionRowView
**Purpose**: Individual session display  
**Props**:
- `session: Session` - Session data

**Responsibilities**:
- Show session date/time
- Display duration
- Show substitution count
- Show player count

---

### Shared Components

#### EmptyStateView
**Purpose**: Reusable empty state display  
**Props**:
- `title: String` - Main message
- `systemImage: String` - SF Symbol name
- `description: String` - Secondary message

**Responsibilities**:
- Display empty state message
- Show appropriate icon
- Consistent styling across app

---

#### SectionHeaderView
**Purpose**: Consistent section headers  
**Props**:
- `title: String` - Header text
- `systemImage: String?` - Optional icon
- `count: Int?` - Optional count badge

**Responsibilities**:
- Display formatted header
- Show icon if provided
- Display count badge if provided

---

#### PlayerStatusBadge
**Purpose**: Player status indicator  
**Props**:
- `status: PlayerStatus` - Player status

**Responsibilities**:
- Display status badge
- Color code by status (active/benched/temp out)
- Show appropriate icon

---

#### TimeDisplayView
**Purpose**: Consistent time display  
**Props**:
- `timeInterval: TimeInterval` - Time to display
- `style: TimeDisplayStyle` - Display style

**Responsibilities**:
- Format time consistently
- Support multiple display styles
- Monospaced digit display

---

## Orchestrator Views

### TimerView (Orchestrator)
**Responsibilities**:
- Coordinate all timer components
- Manage SwiftData queries (players, config, sessions)
- Handle timer state (TimerViewModel)
- Manage sheet presentations
- Implement business logic:
  - Substitution logic (auto/manual)
  - Player activation/deactivation
  - Session management
  - Time tracking

**Props**: None (root view)  
**State**:
- `timerViewModel: TimerViewModel?`
- `showingManualSubstitution: Bool`
- `selectedPlayerToSubOut: Player?`
- `showingPlayerActions: Player?`

---

### SettingsView (Orchestrator)
**Responsibilities**:
- Coordinate all settings components
- Manage SwiftData queries (players, config, sessions)
- Handle modal presentations
- Implement business logic:
  - Player CRUD operations
  - Configuration updates
  - Session management

**Props**: None (root view)  
**State**:
- `showingAddPlayer: Bool`
- `newPlayerName: String`
- `editingPlayer: Player?`
- `showingClearSessionAlert: Bool`

---

## Utilities

### TimeFormatter
**Purpose**: Consistent time formatting across app  

**Functions**:
- `static func format(_ timeInterval: TimeInterval) -> String`

**Responsibilities**:
- Format seconds to MM:SS or H:MM:SS
- Handle zero, negative, and large values
- Consistent across all time displays

---

## Data Flow

### Timer Flow
```
User Action → TimerView (Orchestrator)
           ↓
    Update State/Data
           ↓
    SwiftData Model Update
           ↓
    Component Props Update
           ↓
    Component Re-render
```

### Settings Flow
```
User Action → SettingsView (Orchestrator)
           ↓
    Validate Input
           ↓
    SwiftData Model Update
           ↓
    Component Props Update
           ↓
    Component Re-render
```

---

## Component Communication

### Parent → Child (Props)
- Data flows down through props
- Immutable data passed to children
- Children are pure presentation components

### Child → Parent (Callbacks)
- Events flow up through callbacks
- Children call parent-provided functions
- Parent handles business logic

### Example:
```swift
// Parent (TimerView)
BenchSectionView(
    players: benchedPlayers,
    activePlayersCount: activePlayers.count,
    maxActiveCount: configuration.activePlayersCount,
    onPlayerTap: { player in
        showingPlayerActions = player
    },
    onActivatePlayer: { player in
        activatePlayer(player)
    }
)

// Child (BenchSectionView) - receives data, calls callbacks
```

---

## Testing Strategy

### Component Tests
- Each component has SwiftUI previews
- Test with different data states
- Verify visual appearance
- Test user interactions

### Integration Tests
- Test orchestrator views
- Verify data flow
- Test business logic
- Ensure components work together

### Model Tests
- Existing unit tests for models
- Test data transformations
- Validate business rules

---

## File Organization

```
SubTimer/
├── Views/
│   ├── Components/
│   │   ├── Timer/
│   │   │   ├── TimerControlsView.swift
│   │   │   ├── PreferredTimeDisplayView.swift
│   │   │   └── SubstitutionButtonView.swift
│   │   ├── Players/
│   │   │   ├── ActivePlayerRowView.swift
│   │   │   ├── BenchPlayerRowView.swift
│   │   │   ├── TemporarilyOutPlayerRowView.swift
│   │   │   ├── ActivePlayersSectionView.swift
│   │   │   ├── BenchSectionView.swift
│   │   │   └── TemporarilyOutSectionView.swift
│   │   ├── Settings/
│   │   │   ├── PlayerListSectionView.swift
│   │   │   ├── PlayerRowView.swift
│   │   │   ├── AddPlayerSheetView.swift
│   │   │   ├── EditPlayerSheetView.swift
│   │   │   ├── ConfigurationSectionView.swift
│   │   │   ├── ActivePlayersStepperView.swift
│   │   │   ├── PreferredTimePickerView.swift
│   │   │   ├── SessionManagementSectionView.swift
│   │   │   ├── SessionHistoryView.swift
│   │   │   └── SessionRowView.swift
│   │   └── Shared/
│   │       ├── EmptyStateView.swift
│   │       ├── SectionHeaderView.swift
│   │       ├── PlayerStatusBadge.swift
│   │       └── TimeDisplayView.swift
│   ├── TimerView.swift
│   ├── SettingsView.swift
│   └── MainTabView.swift
├── Models/
│   ├── Player.swift
│   ├── AppConfiguration.swift
│   └── Session.swift
├── ViewModels/
│   └── TimerViewModel.swift
└── Utilities/
    └── TimeFormatter.swift
```

---

## Best Practices

### Component Design
1. **Single Responsibility**: Each component does one thing well
2. **Props-Based**: Data flows through props
3. **Stateless When Possible**: Prefer stateless presentation components
4. **Reusable**: Design for reuse across features
5. **Testable**: Easy to preview and test in isolation

### Naming Conventions
- Views end with `View`
- Sections end with `SectionView`
- Rows end with `RowView`
- Sheets end with `SheetView`
- Clear, descriptive names

### Code Organization
- Keep components under 150 lines
- Group related components in directories
- Use `// MARK:` for section organization
- Document public interfaces

---

## Migration Guide

### From Old TimerView (634 lines)
1. Import component modules
2. Replace inline views with components
3. Pass data as props
4. Connect callbacks to existing logic
5. Remove extracted code

### From Old SettingsView (425 lines)
1. Import component modules
2. Replace sections with components
3. Pass bindings where needed
4. Connect callbacks to existing logic
5. Move EditPlayerView to separate file

---

## Future Enhancements

### Potential New Components
- `PlayerStatsView` - Detailed player statistics
- `SubstitutionHistoryView` - Substitution timeline
- `FairPlayIndicator` - Visual fairness meter
- `QuickActionsView` - Common actions toolbar

### Component Library Expansion
- Design system tokens (colors, spacing)
- Animation library
- Accessibility helpers
- Shared styles/modifiers

---

## Performance Considerations

### Optimization Strategies
1. **Lazy Loading**: Use LazyVStack for large lists
2. **Computed Properties**: Cache expensive calculations
3. **Minimal Re-renders**: Use @State and @Binding appropriately
4. **SwiftData Queries**: Optimize queries in orchestrators
5. **Preview Performance**: Keep preview data minimal

### Monitoring
- Watch for excessive re-renders
- Profile with Instruments
- Test on older devices
- Monitor memory usage

---

## Conclusion

This component architecture provides:
- ✅ Better maintainability (smaller files)
- ✅ Improved testability (isolated components)
- ✅ Enhanced reusability (shared components)
- ✅ Clearer separation of concerns
- ✅ Easier onboarding for new developers
- ✅ Foundation for future features