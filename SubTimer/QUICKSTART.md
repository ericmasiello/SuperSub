# Refactoring Quick Start Guide

## Overview

This guide helps you get started with the incremental refactoring of TimerView and SettingsView into smaller, testable components.

## Current State

- **TimerView.swift**: 634 lines - Controls, displays, player management, substitution logic
- **SettingsView.swift**: 425 lines - Player management, configuration, session management

## Goal

Break down into focused components (<150 lines each) with full test coverage.

## Getting Started

### Step 1: Read the PRD

Review `REFACTORING_PRD.md` for the complete plan. Key sections:
- Phase 1: TimerView refactoring (6 sub-phases)
- Phase 2: SettingsView refactoring (4 sub-phases)
- Phase 3: Shared components library

### Step 2: Set Up Your Environment

1. Create the component directories:
   ```
   mkdir -p SubTimer/Views/Components/Timer
   mkdir -p SubTimer/Views/Components/Players
   mkdir -p SubTimer/Views/Components/Settings
   mkdir -p SubTimer/Views/Components/Shared
   ```

2. Ensure tests are running:
   ```
   # Run existing tests
   cmd+U in Xcode
   ```

### Step 3: Start with Phase 1.1 (Recommended)

**Goal**: Extract timer controls into a standalone component

**What to do**:
1. Create `SubTimer/Views/Components/Timer/TimerControlsView.swift`
2. Move timer button UI code from TimerView
3. Add SwiftUI previews
4. Update TimerView to use the new component
5. Verify everything works

**Code to extract** (from TimerView.swift lines 98-120):
- The play/pause button
- State-based styling
- Icon switching logic

**New component interface**:
```swift
struct TimerControlsView: View {
    let isRunning: Bool
    let onToggle: () -> Void
    
    var body: some View {
        // Button UI here
    }
}
```

**Testing**:
- Add `#Preview` for running state
- Add `#Preview` for paused state
- Manually test in app

### Step 4: Validate Before Moving On

Before starting the next phase, check:
- [ ] App builds without errors
- [ ] Timer still works (start/pause)
- [ ] Visual appearance unchanged
- [ ] All existing tests pass
- [ ] New component has previews
- [ ] Code committed to git

### Step 5: Continue to Next Phase

Repeat the process for each phase in order:
- Phase 1.2: Time Display
- Phase 1.3: Player Rows
- Phase 1.4: Player Sections
- Phase 1.5: Substitution Components
- Phase 1.6: Consolidate TimerView

## Component Template

Use this template for each new component:

```swift
//
//  ComponentNameView.swift
//  SubTimer
//
//  Created by SubTimer on [Date].
//

import SwiftUI

/// Description of component responsibility
struct ComponentNameView: View {
    // MARK: - Properties
    
    let someData: String
    let onAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        // Implementation
    }
}

// MARK: - Preview

#Preview("Default") {
    ComponentNameView(
        someData: "Example",
        onAction: {}
    )
}

#Preview("Alternative State") {
    ComponentNameView(
        someData: "Different",
        onAction: {}
    )
}
```

## Best Practices

### Do's ✅
- Keep components under 150 lines
- Use clear, descriptive names
- Add multiple preview states
- Test after each change
- Commit after each successful phase
- Document component purpose
- Use closure props for actions

### Don'ts ❌
- Don't skip validation steps
- Don't move to next phase with failing tests
- Don't mix multiple phases in one commit
- Don't remove old code until new code works
- Don't add business logic to components (keep them presentational)

## Quick Reference: Phases

| Phase | Component | Lines | Priority |
|-------|-----------|-------|----------|
| 1.1 | TimerControlsView | ~30 | Start Here ⭐ |
| 1.2 | PreferredTimeDisplayView | ~50 | High |
| 1.3 | Player Row Views (3) | ~40 each | High |
| 1.4 | Section Views (3) | ~60 each | Medium |
| 1.5 | Substitution Views (3) | ~50 each | Medium |
| 1.6 | Consolidate TimerView | ~180 | High |
| 2.1 | Player Management (4) | ~50 each | Medium |
| 2.2 | Configuration Views (3) | ~40 each | Low |
| 2.3 | Session Views (3) | ~50 each | Low |
| 2.4 | Consolidate SettingsView | ~130 | Medium |
| 3.0 | Shared Components | ~30 each | Low |

## Testing Strategy

### For Each Component:
1. **Preview Tests**: Add 2-3 `#Preview` blocks showing different states
2. **Manual Tests**: Run app and interact with the feature
3. **Regression Tests**: Ensure existing functionality unchanged

### When to Add Unit Tests:
- Utility functions (like TimeFormatter)
- View models (if extracted)
- Business logic helpers
- Validation functions

## Troubleshooting

### "Preview doesn't show"
- Check that all dependencies are mockable
- Use example data in preview
- Verify import statements

### "Tests fail after refactor"
- Ensure model layer unchanged
- Check data flow through new components
- Verify callbacks are connected

### "Code getting complex"
- Break component down further
- Extract helper functions
- Consider view model for logic

## Next Steps After Completion

1. **Documentation**: Update README with component structure
2. **Optimization**: Profile performance
3. **Enhancement**: Add new features using component patterns
4. **Maintenance**: Keep components focused and small

## Getting Help

- Review `REFACTORING_PRD.md` for detailed specs
- Check existing tests in `SubTimerTests/` for patterns
- Look at current SwiftUI previews in existing files

## Timeline

- **Phase 1 (TimerView)**: 10-18 days
- **Phase 2 (SettingsView)**: 5-8 days  
- **Phase 3 (Shared)**: 1-2 days
- **Total**: 3-5 weeks

Remember: This is incremental. Each phase stands alone. You can pause between phases if needed.

---

**Start with Phase 1.1 and validate thoroughly before proceeding!** ⭐