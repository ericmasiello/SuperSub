# Refactoring Code Snippets & Commands

Quick reference for common patterns and commands during the refactoring process.

---

## Xcode Commands

### Running Tests
```bash
# Run all tests
⌘ + U

# Run specific test file
Right-click test file → Run tests

# Run single test
Click diamond next to test function
```

### Building
```bash
# Build project
⌘ + B

# Clean build folder
⌘ + Shift + K

# Clean build folder and rebuild
⌘ + Shift + K, then ⌘ + B
```

### Previews
```bash
# Show/hide preview
⌘ + Option + Return

# Refresh preview
⌘ + Option + P

# Pin preview
Click pin icon in preview
```

---

## Component Templates

### Basic View Component
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
    
    let data: String
    let onAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text(data)
            Button("Action", action: onAction)
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    ComponentNameView(
        data: "Example",
        onAction: {}
    )
}
```

### Section Component
```swift
struct SectionNameView: View {
    // MARK: - Properties
    
    let items: [SomeType]
    let onItemTap: (SomeType) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Section Title", systemImage: "icon.name")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(items.count)")
                    .foregroundStyle(.secondary)
            }
            
            // Content
            if items.isEmpty {
                emptyStateView
            } else {
                ForEach(items) { item in
                    ItemRowView(item: item, onTap: { onItemTap(item) })
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        Text("No items")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
    }
}
```

### Row Component
```swift
struct RowNameView: View {
    // MARK: - Properties
    
    let item: SomeType
    let isHighlighted: Bool
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        if isHighlighted {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                isHighlighted 
                    ? Color.blue.opacity(0.1) 
                    : Color(uiColor: .secondarySystemBackground)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
```

### Sheet Component
```swift
struct SheetNameView: View {
    // MARK: - Properties
    
    @State private var inputText = ""
    
    let initialValue: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    // MARK: - Initialization
    
    init(initialValue: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.initialValue = initialValue
        self.onSave = onSave
        self.onCancel = onCancel
        _inputText = State(initialValue: initialValue)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Placeholder", text: $inputText)
                }
            }
            .navigationTitle("Sheet Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(inputText)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
```

---

## Common Patterns

### Time Formatting
```swift
// Use the TimeFormatter utility
import Foundation

struct TimeFormatter {
    static func format(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// Usage
Text(TimeFormatter.format(player.currentPlayDuration))
    .monospacedDigit()
```

### Empty State
```swift
// Use EmptyStateView component
EmptyStateView(
    title: "No Items",
    systemImage: "tray",
    description: "Add items to get started"
)
```

### Conditional Section Display
```swift
// Only show section if items exist
if !items.isEmpty {
    SectionView(items: items)
}
```

### Section Headers
```swift
// Consistent header pattern
HStack {
    Label("Section Title", systemImage: "icon.name")
        .font(.title3)
        .bold()
    Spacer()
    Text("\(items.count)")
        .foregroundStyle(.secondary)
}
```

### Player Status Badge
```swift
// Display player status
func statusText(for status: PlayerStatus) -> String {
    switch status {
    case .active:
        return "Currently Playing"
    case .benched:
        return "On Bench"
    case .temporarilyOut:
        return "Temporarily Out"
    }
}

// Color coding
func statusColor(for status: PlayerStatus) -> Color {
    switch status {
    case .active:
        return .green
    case .benched:
        return .blue
    case .temporarilyOut:
        return .orange
    }
}
```

---

## SwiftUI Preview Patterns

### Basic Preview
```swift
#Preview {
    ComponentNameView(
        data: "Example",
        onAction: {}
    )
}
```

### Multiple Preview States
```swift
#Preview("Empty State") {
    SectionView(items: [], onItemTap: { _ in })
}

#Preview("With Items") {
    SectionView(
        items: [
            Item(name: "Item 1"),
            Item(name: "Item 2"),
            Item(name: "Item 3")
        ],
        onItemTap: { _ in }
    )
}

#Preview("Single Item") {
    SectionView(items: [Item(name: "Single")], onItemTap: { _ in })
}
```

### Preview with Model Container (for SwiftData)
```swift
#Preview {
    ComponentNameView()
        .modelContainer(for: [Player.self, AppConfiguration.self], inMemory: true)
}
```

### Preview with Environment
```swift
#Preview {
    NavigationStack {
        ComponentNameView()
    }
    .preferredColorScheme(.dark)
}
```

---

## Migration Patterns

### Before (Inline View)
```swift
// In TimerView.swift
var timerControlsSection: some View {
    HStack(spacing: 20) {
        Button {
            toggleTimer()
        } label: {
            HStack {
                Image(systemName: timerViewModel?.isRunning ?? false ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 30))
                Text(timerViewModel?.isRunning ?? false ? "Pause" : "Start")
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(timerViewModel?.isRunning ?? false ? Color.orange : Color.green)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }
}
```

### After (Component)
```swift
// TimerControlsView.swift
struct TimerControlsView: View {
    let isRunning: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 30))
                Text(isRunning ? "Pause" : "Start")
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunning ? Color.orange : Color.green)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }
}

// In TimerView.swift
TimerControlsView(
    isRunning: timerViewModel?.isRunning ?? false,
    onToggle: toggleTimer
)
```

---

## Testing Snippets

### Component Preview Test
```swift
// Verify component renders in different states
#Preview("Active Player - Normal") {
    ActivePlayerRowView(
        player: Player(name: "John Doe", currentPlayDuration: 120),
        isNextToSubOut: false,
        onTap: {}
    )
}

#Preview("Active Player - Next to Sub Out") {
    ActivePlayerRowView(
        player: Player(name: "Jane Smith", currentPlayDuration: 180),
        isNextToSubOut: true,
        onTap: {}
    )
}
```

### Manual Test Checklist
```markdown
## Component: TimerControlsView

- [ ] Button displays correctly
- [ ] Play icon shows when not running
- [ ] Pause icon shows when running
- [ ] Background color changes (green/orange)
- [ ] Button is tappable
- [ ] Callback fires on tap
- [ ] Accessibility label present
- [ ] Works in light mode
- [ ] Works in dark mode
```

---

## Git Workflow

### Commit Messages
```bash
# Phase completion
git commit -m "Phase 1.1: Extract TimerControlsView component

- Created TimerControlsView.swift with play/pause UI
- Added previews for running and paused states
- Updated TimerView to use new component
- All tests passing
- Visual appearance unchanged"

# Bug fix during refactor
git commit -m "Fix: Correct timer button state binding

- Fixed isRunning state not updating
- Verified timer controls work correctly"

# Component creation
git commit -m "Add BenchPlayerRowView component

- Extracted bench player row from TimerView
- Added previews for different states
- Supports next-up indicator
- Includes activate button when applicable"
```

### Branch Strategy (Optional)
```bash
# Create feature branch for each phase
git checkout -b refactor/phase-1.1-timer-controls
# ... make changes ...
git commit -m "Phase 1.1 complete"
git checkout main
git merge refactor/phase-1.1-timer-controls

# Or work directly on main with careful commits
```

---

## Validation Commands

### Check File Line Count
```bash
# Count lines in a file
wc -l SubTimer/Views/TimerView.swift

# Count lines excluding empty lines and comments
grep -v '^\s*$\|^\s*\/\/' SubTimer/Views/TimerView.swift | wc -l
```

### Find All Views
```bash
# List all Swift files in Views directory
find SubTimer/Views -name "*.swift"

# List with line counts
find SubTimer/Views -name "*.swift" -exec wc -l {} \;
```

### Search for TODOs
```bash
# Find TODO comments
grep -r "TODO" SubTimer/Views/

# Find FIXME comments
grep -r "FIXME" SubTimer/Views/
```

---

## Common Issues & Solutions

### Preview Not Updating
```swift
// Solution: Pin the preview or refresh
⌘ + Option + P  // Refresh preview

// Or restart preview canvas
⌘ + Option + Return  // Toggle preview
```

### Binding Not Working
```swift
// Problem: Passing @State directly
var configuration: AppConfiguration
SomeView(value: configuration.someValue)  // Won't update

// Solution: Use Binding
SomeView(value: Binding(
    get: { configuration.someValue },
    set: { configuration.someValue = $0 }
))
```

### Component Not Rerendering
```swift
// Problem: Using class/reference type
class SomeData {  // SwiftUI won't detect changes
    var value: String
}

// Solution: Use struct/value type
struct SomeData {  // SwiftUI detects changes
    var value: String
}
```

### Preview Crashes
```swift
// Problem: Missing model container
#Preview {
    ViewWithSwiftData()  // Crashes if needs SwiftData
}

// Solution: Provide model container
#Preview {
    ViewWithSwiftData()
        .modelContainer(for: [Player.self], inMemory: true)
}
```

---

## Keyboard Shortcuts Reference

| Action | Shortcut |
|--------|----------|
| Build | ⌘ + B |
| Run | ⌘ + R |
| Test | ⌘ + U |
| Clean Build | ⌘ + Shift + K |
| Show Preview | ⌘ + Option + Return |
| Refresh Preview | ⌘ + Option + P |
| Jump to Definition | ⌘ + Click |
| Find in Project | ⌘ + Shift + F |
| Open Quickly | ⌘ + Shift + O |
| Show Document Items | ⌘ + Control + J |
| Re-indent | Control + I |
| Comment/Uncomment | ⌘ + / |

---

## Quick Checklist Template

Copy this for each component:

```markdown
## Component: [Name]

### Creation
- [ ] File created in correct directory
- [ ] Component interface defined
- [ ] Body implemented
- [ ] Documentation added

### Preview
- [ ] Default preview added
- [ ] Edge case previews added
- [ ] Preview renders correctly

### Integration
- [ ] Parent view updated
- [ ] Props connected
- [ ] Callbacks wired
- [ ] Old code removed

### Testing
- [ ] App builds
- [ ] Feature works
- [ ] No visual regressions
- [ ] All tests pass

### Completion
- [ ] Code reviewed
- [ ] Git committed
- [ ] Checklist updated
```

---

## Resources

- SwiftUI Documentation: https://developer.apple.com/documentation/swiftui
- SwiftData Documentation: https://developer.apple.com/documentation/swiftdata
- Testing Documentation: https://developer.apple.com/documentation/testing

---

**Remember**: Take it one component at a time. Validate thoroughly before moving on!