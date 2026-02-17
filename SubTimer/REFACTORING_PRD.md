# Product Requirements Document: View Component Refactoring

## Executive Summary

This document outlines a phased approach to refactor `TimerView.swift` (~634 lines) and `SettingsView.swift` (~425 lines) into smaller, more maintainable, and testable SwiftUI components. Each phase will be incremental, validated with tests, and verified before proceeding to the next phase.

## Goals

1. **Improve Maintainability**: Break down large view files into focused, single-responsibility components
2. **Enhance Testability**: Create components that can be tested in isolation with SwiftUI previews and unit tests
3. **Maintain Functionality**: Ensure no regression in existing features
4. **Establish Patterns**: Create reusable component patterns for future development
5. **Incremental Delivery**: Each phase should be independently shippable and validated

## Success Criteria

- Each new component is under 150 lines of code
- All components have SwiftUI preview support for light mode and dark mode (if possible)
- Test coverage maintained or improved (currently focused on models)
- No breaking changes to existing functionality
- Code passes all existing tests after each phase

---

## Phase 1: TimerView Refactoring

### Current State Analysis

**File**: `TimerView.swift` (634 lines)

**Responsibilities**:
- Timer controls (start/pause)
- Time display and formatting
- Active players list management
- Bench players list management
- Temporarily out players list
- Substitution logic (automatic and manual)
- Player action sheets
- Session management
- Player state management

**Key Issues**:
- Too many responsibilities in a single view
- Business logic mixed with presentation logic
- Difficult to test individual components
- Hard to modify without affecting other areas

### Phase 1.1: Extract Timer Controls Component

**Timeline**: 1-2 days

**Deliverables**:
- `TimerControlsView.swift` - Standalone component for play/pause controls
- `TimerControlsView_Tests.swift` - Preview and snapshot tests
- Updated `TimerView.swift` using the new component

**Component Interface**:
```swift
struct TimerControlsView: View {
    let isRunning: Bool
    let onToggle: () -> Void
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests showing both running and paused states
- Verify button appearance changes based on state
- Verify accessibility labels

**Validation Criteria**:
- App builds and runs
- Timer still starts/pauses correctly
- Visual appearance unchanged
- All existing tests pass

---

### Phase 1.2: Extract Time Display Component

**Timeline**: 1-2 days

**Deliverables**:
- `PreferredTimeDisplayView.swift` - Component for showing current play time
- `TimeFormatter.swift` - Utility for consistent time formatting
- `PreferredTimeDisplayView_Tests.swift` - Tests
- Updated `TimerView.swift`

**Component Interface**:
```swift
struct PreferredTimeDisplayView: View {
    let currentPlayDuration: TimeInterval
    let preferredPlayTimeSeconds: Int
    
    var body: some View { ... }
}

struct TimeFormatter {
    static func format(_ timeInterval: TimeInterval) -> String
}
```

**Tests**:
- Preview tests for normal time, overtime, zero time
- Unit tests for TimeFormatter edge cases (0s, 59s, 60s, 3600s, etc.)
- Verify overtime warning displays correctly
- Color changes verified

**Validation Criteria**:
- Time displays correctly in all states
- Overtime indicator appears at correct threshold
- Color coding works (normal/overtime)
- Time formatting consistent across app

---

### Phase 1.3: Extract Player Row Components

**Timeline**: 2-3 days

**Deliverables**:
- `ActivePlayerRowView.swift` - Individual active player row
- `BenchPlayerRowView.swift` - Individual bench player row
- `TemporarilyOutPlayerRowView.swift` - Temporarily out player row
- Tests for each component
- Updated `TimerView.swift`

**Component Interfaces**:
```swift
struct ActivePlayerRowView: View {
    let player: Player
    let isNextToSubOut: Bool
    let onTap: () -> Void
    
    var body: some View { ... }
}

struct BenchPlayerRowView: View {
    let player: Player
    let isNextUp: Bool
    let canActivate: Bool
    let onTap: () -> Void
    let onActivate: () -> Void
    
    var body: some View { ... }
}

struct TemporarilyOutPlayerRowView: View {
    let player: Player
    let onReturnToBench: () -> Void
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests for each row type with different states
- Verify next-up/next-out indicators
- Verify button states and availability
- Accessibility testing

**Validation Criteria**:
- Player rows display correctly
- Indicators appear for next up/next out players
- Tap actions trigger correctly
- Visual consistency maintained

---

### Phase 1.4: Extract Player List Sections

**Timeline**: 2-3 days

**Deliverables**:
- `ActivePlayersSectionView.swift` - Manages active players list
- `BenchSectionView.swift` - Manages bench list
- `TemporarilyOutSectionView.swift` - Manages temporarily out list
- Tests for each section
- Updated `TimerView.swift`

**Component Interfaces**:
```swift
struct ActivePlayersSectionView: View {
    let players: [Player]
    let maxActiveCount: Int
    let onPlayerTap: (Player) -> Void
    
    var body: some View { ... }
}

struct BenchSectionView: View {
    let players: [Player]
    let activePlayersCount: Int
    let maxActiveCount: Int
    let onPlayerTap: (Player) -> Void
    let onActivatePlayer: (Player) -> Void
    
    var body: some View { ... }
}

struct TemporarilyOutSectionView: View {
    let players: [Player]
    let onReturnToBench: (Player) -> Void
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests with empty states
- Preview tests with multiple players
- Verify section headers and counts
- Empty state messages

**Validation Criteria**:
- Sections render correctly
- Empty states display properly
- Player counts accurate
- Section headers formatted correctly

---

### Phase 1.5: Extract Substitution Components

**Timeline**: 2-3 days

**Deliverables**:
- `SubstitutionButtonView.swift` - Main substitute button
- `ManualSubstitutionSheetView.swift` - Manual sub selection
- `PlayerActionsSheetView.swift` - Player action menu
- Tests for each component
- Updated `TimerView.swift`

**Component Interfaces**:
```swift
struct SubstitutionButtonView: View {
    let canPerformSubstitution: Bool
    let onSubstitute: () -> Void
    
    var body: some View { ... }
}

struct ManualSubstitutionSheetView: View {
    let playerToSubOut: Player
    let benchPlayers: [Player]
    let onSubstitute: (Player) -> Void
    let onCancel: () -> Void
    
    var body: some View { ... }
}

struct PlayerActionsSheetView: View {
    let player: Player
    let configuration: AppConfiguration
    let activePlayersCount: Int
    let onSubstituteOut: () -> Void
    let onActivate: () -> Void
    let onMarkTemporarilyOut: () -> Void
    let onReturnToBench: () -> Void
    let onDismiss: () -> Void
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests for each component state
- Verify enabled/disabled states
- Test player selection
- Verify action availability based on player status

**Validation Criteria**:
- Substitution button works correctly
- Manual substitution flow functions
- Player actions appropriate for each status
- All actions trigger correctly

---

### Phase 1.6: Consolidate TimerView

**Timeline**: 1-2 days

**Deliverables**:
- Refactored `TimerView.swift` (target: <200 lines)
- Documentation for component architecture
- Integration tests

**Remaining Responsibilities**:
- Coordinate between components
- Manage state and data flow
- Handle SwiftData queries
- Manage sheet presentations
- Business logic (substitution, activation, etc.)

**Tests**:
- End-to-end integration tests
- State management verification
- Data flow testing

**Validation Criteria**:
- All timer functionality works
- Performance maintained or improved
- Code is more readable and maintainable
- Component boundaries are clear

---

## Phase 2: SettingsView Refactoring

### Current State Analysis

**File**: `SettingsView.swift` (425 lines including EditPlayerView)

**Responsibilities**:
- Player list management (add, edit, delete, reorder)
- Configuration settings (active count, preferred time)
- Session management (history, clear)
- Player editing modal
- Session history display

**Key Issues**:
- Player management and configuration mixed together
- EditPlayerView embedded in same file
- Session history view inline
- Multiple concerns in one file

### Phase 2.1: Extract Player Management Components

**Timeline**: 2-3 days

**Deliverables**:
- `PlayerListSectionView.swift` - Player roster display
- `PlayerRowView.swift` - Individual player row
- `AddPlayerSheetView.swift` - Add player modal
- `EditPlayerSheetView.swift` - Standalone edit player view
- Tests for each component
- Updated `SettingsView.swift`

**Component Interfaces**:
```swift
struct PlayerListSectionView: View {
    let players: [Player]
    let onAdd: () -> Void
    let onEdit: (Player) -> Void
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void
    
    var body: some View { ... }
}

struct PlayerRowView: View {
    let player: Player
    let onEdit: () -> Void
    
    var body: some View { ... }
}

struct AddPlayerSheetView: View {
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void
    
    var body: some View { ... }
}

struct EditPlayerSheetView: View {
    let player: Player
    let onDismiss: () -> Void
    let onSave: (String, PlayerStatus) -> Void
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests for each component
- Test player row with different statuses
- Verify add/edit forms
- Test validation logic

**Validation Criteria**:
- Player CRUD operations work
- Reordering functions correctly
- Forms validate input
- Status displays correctly

---

### Phase 2.2: Extract Configuration Components

**Timeline**: 1-2 days

**Deliverables**:
- `ConfigurationSectionView.swift` - Settings configuration
- `ActivePlayersStepperView.swift` - Active players control
- `PreferredTimePickerView.swift` - Time selection
- Tests for each component
- Updated `SettingsView.swift`

**Component Interfaces**:
```swift
struct ConfigurationSectionView: View {
    @Binding var activePlayersCount: Int
    @Binding var preferredPlayTimeSeconds: Int
    let totalPlayerCount: Int
    
    var body: some View { ... }
}

struct ActivePlayersStepperView: View {
    @Binding var value: Int
    let maxPlayers: Int
    
    var body: some View { ... }
}

struct PreferredTimePickerView: View {
    @Binding var seconds: Int
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests for different configurations
- Test stepper bounds
- Test time picker values
- Verify warning messages

**Validation Criteria**:
- Configuration changes save correctly
- Bounds enforced properly
- Warning appears when needed
- UI updates reactively

---

### Phase 2.3: Extract Session Management Components

**Timeline**: 2-3 days

**Deliverables**:
- `SessionManagementSectionView.swift` - Session controls
- `SessionHistoryView.swift` - Standalone history view
- `SessionRowView.swift` - Individual session row
- Tests for each component
- Updated `SettingsView.swift`

**Component Interfaces**:
```swift
struct SessionManagementSectionView: View {
    let onViewHistory: () -> Void
    let onClearSession: () -> Void
    
    var body: some View { ... }
}

struct SessionHistoryView: View {
    let sessions: [Session]
    let onDelete: (IndexSet) -> Void
    
    var body: some View { ... }
}

struct SessionRowView: View {
    let session: Session
    
    var body: some View { ... }
}
```

**Tests**:
- Preview tests with empty and populated sessions
- Test session row formatting
- Verify delete functionality
- Test empty state

**Validation Criteria**:
- History displays correctly
- Sessions can be deleted
- Clear session works
- Date/time formatting correct

---

### Phase 2.4: Consolidate SettingsView

**Timeline**: 1 day

**Deliverables**:
- Refactored `SettingsView.swift` (target: <150 lines)
- Documentation
- Integration tests

**Remaining Responsibilities**:
- Coordinate sections
- Manage SwiftData queries
- Handle modal presentations
- Orchestrate data operations

**Tests**:
- End-to-end settings tests
- Data persistence verification
- Navigation testing

**Validation Criteria**:
- All settings functionality works
- Data saves correctly
- Navigation flows work
- Code is cleaner and more maintainable

---

## Phase 3: Shared Components Library

### Timeline: 1-2 days

**Deliverables**:
- `Components/` directory structure
- Shared components extracted
- Component documentation
- Storybook-style preview file

**Shared Components to Extract**:
1. `EmptyStateView.swift` - Reusable empty state
2. `SectionHeaderView.swift` - Consistent section headers
3. `PlayerStatusBadge.swift` - Status indicator
4. `TimeDisplayView.swift` - Consistent time display

**Directory Structure**:
```
Views/
  Components/
    Timer/
      TimerControlsView.swift
      PreferredTimeDisplayView.swift
      SubstitutionButtonView.swift
      ...
    Players/
      ActivePlayerRowView.swift
      BenchPlayerRowView.swift
      PlayerRowView.swift
      ...
    Settings/
      ConfigurationSectionView.swift
      SessionHistoryView.swift
      ...
    Shared/
      EmptyStateView.swift
      SectionHeaderView.swift
      PlayerStatusBadge.swift
      TimeDisplayView.swift
      ...
  TimerView.swift
  SettingsView.swift
  MainTabView.swift
```

---

## Testing Strategy

### Unit Tests
- Create `ViewModelTests.swift` for testing business logic
- Test time formatting utilities
- Test validation logic
- Test data transformations

### Component Tests
- SwiftUI Preview tests for each component
- Snapshot tests for visual regression (optional)
- Accessibility tests
- Different state variations

### Integration Tests
- End-to-end flow tests
- Data persistence tests
- Navigation tests
- State synchronization tests

### Test Structure
```
SubTimerTests/
  ViewModelTests/
    TimerViewModelTests.swift
  ComponentTests/
    TimerComponentsTests.swift
    SettingsComponentsTests.swift
    SharedComponentsTests.swift
  IntegrationTests/
    TimerFlowTests.swift
    SettingsFlowTests.swift
  Utilities/
    TimeFormatterTests.swift
```

---

## Validation Checklist (Per Phase)

Before moving to the next phase, verify:

- [ ] All new files created and properly organized
- [ ] New components have SwiftUI previews
- [ ] All existing tests still pass
- [ ] New component tests written and passing
- [ ] App builds without errors
- [ ] Manual testing completed for affected features
- [ ] No performance regressions
- [ ] Code reviewed (self or peer)
- [ ] Documentation updated
- [ ] Git commit with clear message

---

## Risk Mitigation

### Risks:
1. **Breaking existing functionality** - Mitigated by incremental changes and thorough testing
2. **Performance degradation** - Mitigated by performance testing after each phase
3. **Increased complexity** - Mitigated by clear component boundaries and documentation
4. **Time overruns** - Mitigated by phase-based approach allowing pausing between phases

### Rollback Plan:
- Each phase is a separate PR/commit
- Can revert individual phases if issues arise
- Feature flags for new components (optional)

---

## Success Metrics

### Code Quality:
- Average file size reduced by 60%+
- Function complexity reduced (max 10 lines per function)
- Test coverage increased to 80%+

### Developer Experience:
- Faster to locate specific UI code
- Easier to modify individual components
- Reusable components for future features

### Maintainability:
- Clear separation of concerns
- Single responsibility per component
- Documented component interfaces

---

## Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| 1.1 - Timer Controls | 1-2 days | TimerControlsView |
| 1.2 - Time Display | 1-2 days | PreferredTimeDisplayView, TimeFormatter |
| 1.3 - Player Rows | 2-3 days | 3 player row components |
| 1.4 - Player Sections | 2-3 days | 3 section components |
| 1.5 - Substitution | 2-3 days | 3 substitution components |
| 1.6 - Consolidate Timer | 1-2 days | Refactored TimerView |
| 2.1 - Player Management | 2-3 days | 4 player components |
| 2.2 - Configuration | 1-2 days | 3 configuration components |
| 2.3 - Session Management | 2-3 days | 3 session components |
| 2.4 - Consolidate Settings | 1 day | Refactored SettingsView |
| 3.0 - Shared Components | 1-2 days | Component library |

**Total Estimated Time**: 16-27 days (3-5 weeks)

---

## Appendix A: Component Naming Conventions

- **View Components**: End with `View` (e.g., `TimerControlsView`)
- **Section Components**: End with `SectionView` (e.g., `ConfigurationSectionView`)
- **Row Components**: End with `RowView` (e.g., `PlayerRowView`)
- **Sheet Components**: End with `SheetView` (e.g., `AddPlayerSheetView`)
- **Utilities**: Descriptive names (e.g., `TimeFormatter`)

## Appendix B: Code Review Checklist

For each component:
- [ ] Single responsibility
- [ ] Minimal dependencies
- [ ] Props-based interface (data in, events out)
- [ ] SwiftUI preview included
- [ ] Accessibility support
- [ ] Documentation comments
- [ ] No hardcoded values
- [ ] Consistent styling

## Appendix C: Example Component Template

```swift
//
//  ComponentNameView.swift
//  SubTimer
//
//  Created by [Author] on [Date].
//

import SwiftUI

/// Brief description of what this component does
struct ComponentNameView: View {
    // MARK: - Properties
    
    let someProperty: String
    let onAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        // Implementation
    }
}

// MARK: - Preview

#Preview("Default State") {
    ComponentNameView(
        someProperty: "Example",
        onAction: {}
    )
}

#Preview("Alternative State") {
    ComponentNameView(
        someProperty: "Different Example",
        onAction: {}
    )
}
```
