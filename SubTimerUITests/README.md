# SubTimerUITests

This directory contains UI tests for the SubTimer application using XCTest UI testing framework.

## Test Files

- `SubTimerUITests.swift` - Basic launch and performance tests
- `TimerViewUITests.swift` - Timer screen tests (20+ tests)
- `SettingsViewUITests.swift` - Settings screen tests (25+ tests)
- `PlayerComponentsUITests.swift` - Player component tests (20+ tests)
- `SubTimerUITestsLaunchTests.swift` - Launch tests

**Total UI Test Coverage: 65+ tests**

## Running Tests from Command Line

### Run All UI Tests

Run all tests in the SubTimerUITests target:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests
```

### Run Tests in a Specific File

Run all tests in `TimerViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/TimerViewUITests
```

Run all tests in `SettingsViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/SettingsViewUITests
```

Run all tests in `PlayerComponentsUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/PlayerComponentsUITests
```

### Run a Specific Test

Run a single test method (e.g., `testTimerStartAndStop` in `TimerViewUITests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/TimerViewUITests/testTimerStartAndStop
```

Run another specific test (e.g., `testNavigationToSettings` in `TimerViewUITests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/TimerViewUITests/testNavigationToSettings
```

Run a performance test:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/SubTimerUITests/testLaunchPerformance
```

### Run Tests with Different Destinations

For iOS Simulator:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests
```

For a specific macOS architecture:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:SubTimerUITests
```

### Run Multiple Specific Tests

Run multiple test files:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/TimerViewUITests \
  -only-testing:SubTimerUITests/SettingsViewUITests
```

Run specific tests across different files:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests/TimerViewUITests/testTimerStartAndStop \
  -only-testing:SubTimerUITests/PlayerComponentsUITests/testPlayerRowsDisplayed
```

### Exclude Specific Tests

Run all UI tests except those in `TimerViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests \
  -skip-testing:SubTimerUITests/TimerViewUITests
```

Run all tests except performance tests:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests \
  -skip-testing:SubTimerUITests/SubTimerUITests/testLaunchPerformance
```

### Verbose Output

Add `-verbose` flag for detailed output:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests \
  -verbose
```

### Pretty Output

For more readable output, pipe through `xcpretty` (requires installation: `gem install xcpretty`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests \
  | xcpretty
```

### Test Results

Save test results to a specific directory:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerUITests \
  -resultBundlePath ./TestResults
```

## Running Tests in Xcode

1. Open `SubTimer.xcodeproj` in Xcode
2. Press `⌘+U` to run all tests
3. Or use the Test Navigator (`⌘+6`) to run individual tests
4. Click the diamond icon next to any test to run it individually

## Test Framework

These tests use XCTest UI testing framework with the following components:
- `XCTestCase` base class for test suites
- `XCUIApplication` to launch and interact with the app
- `XCUIElement` to find and interact with UI elements
- Accessibility identifiers for reliable element selection

## UI Testing Tips

### Prerequisites
- Ensure accessibility identifiers are added to UI elements (see `QUICK_START.md`)
- UI tests launch the full application, so they take longer than unit tests
- Tests run in isolation with a clean app state each time

### Common Issues
- **Slow tests**: UI tests are inherently slower; consider running specific tests during development
- **Flaky tests**: Add explicit waits for elements using `waitForExistence(timeout:)`
- **Element not found**: Verify accessibility identifiers match between code and tests

### Debugging UI Tests
1. Set breakpoints in test methods
2. Use `print(app.debugDescription)` to see the entire view hierarchy
3. Use Xcode's UI Recording feature to generate element queries

## Available Test Destinations

List all available simulators and devices:

```bash
xcrun simctl list devices available
```

List all available destinations for the scheme:

```bash
xcodebuild test \
  -scheme SubTimer \
  -showdestinations
```

## Running Both Unit and UI Tests

Run all tests (both SubTimerTests and SubTimerUITests):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS'
```

Run only unit tests (exclude UI tests):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -skip-testing:SubTimerUITests
```
