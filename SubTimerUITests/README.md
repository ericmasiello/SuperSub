# SubTimerUITests

This directory contains UI tests for the SubTimer application using XCTest UI testing framework.

## Test Files

- `TimerViewUITests.swift` - Timer screen tests (7 tests)
- `SettingsViewUITests.swift` - Settings screen tests (6 tests)
- `PlayerComponentsUITests.swift` - Player component tests (7 tests, 2 of which are `measure()` performance tests)
- `SubTimerUITests.swift` - App launch performance (1 test)
- `SubTimerUITestsLaunchTests.swift` - App launch smoke test + screenshot (1 test)

**Total UI Test Coverage: 22 tests**

### Hardening results (issues #43-#47)

Issue #43 audited the original suite (82 test methods total) and catalogued 5
failing tests. Each screen's tests were then hardened in its own ticket -
fixing the catalogued failures at their root cause, replacing `sleep`/`usleep`
synchronization with real waits, and consolidating trivial single-assertion
smoke tests into broader per-flow tests:

| File | Before | After | Wall-clock |
|---|---|---|---|
| `TimerViewUITests` (#44) | 24 | 7 | ~100s (after) |
| `PlayerComponentsUITests` (#45) | 27 | 7 | 273s → 121s |
| `SettingsViewUITests` (#46) | 28 | 6 | ~265s → ~143s |
| `SubTimerUITests` (#47) | 2 | 1 | not separately timed |
| `SubTimerUITestsLaunchTests` | 1 | 1 | unchanged |

`SubTimerUITestsLaunchTests` runs once per target application UI
configuration (4 in this project), so the full target executes 25 test runs
across 22 test methods. Verified: `xcodebuild test -only-testing:SubTimerUITests`
passes 25/25 (0 failures) on `platform=iOS Simulator,name=iPhone 17` in
500.7s (~8.3 minutes) total.

**Known gap:** this suite has only been verified on the iOS Simulator
destination. The `platform=macOS` destination this README used to recommend
does not build - see "Running Tests from Command Line" below - so it hasn't
been possible to confirm 0 failures there too.

## Running Tests from Command Line

All examples below target the iOS Simulator. The `macOS` destination this
README previously recommended does not build for this app:

```
error: 'Activity' is unavailable in macOS
  --> SubTimer/Utilities/LiveActivityManager.swift:18
error: 'ActivityAttributes' is unavailable in macOS
  --> ActiveBench/ActiveBenchAttributes.swift:15
```

`LiveActivityManager` and `ActiveBenchAttributes` both `import ActivityKit`,
which macOS doesn't support - this is an app-level platform constraint
unrelated to the UI tests, and predates the test-hardening work in
issues #43-#47.

### Run All UI Tests

Run all tests in the SubTimerUITests target:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests
```

### Run Tests in a Specific File

Run all tests in `TimerViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/TimerViewUITests
```

Run all tests in `SettingsViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/SettingsViewUITests
```

Run all tests in `PlayerComponentsUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/PlayerComponentsUITests
```

### Run a Specific Test

Run a single test method (e.g., `testInitialTimerScreenState` in `TimerViewUITests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/TimerViewUITests/testInitialTimerScreenState
```

Run another specific test (e.g., `testPlayerActionSheetFlow` in `TimerViewUITests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/TimerViewUITests/testPlayerActionSheetFlow
```

### Run Tests on a Different Simulator

Swap `name=iPhone 17` for any simulator installed on your machine (see
[`SubTimer.xcodeproj -showdestinations`](../README.md#listing-available-simulators)):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SubTimerUITests
```

### Run Multiple Specific Tests

Run multiple test files:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/TimerViewUITests \
  -only-testing:SubTimerUITests/SettingsViewUITests
```

Run specific tests across different files:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests/TimerViewUITests/testInitialTimerScreenState \
  -only-testing:SubTimerUITests/PlayerComponentsUITests/testActivePlayerRowRendersContent
```

### Exclude Specific Tests

Run all UI tests except those in `TimerViewUITests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests \
  -skip-testing:SubTimerUITests/TimerViewUITests
```

### Verbose Output

Add `-verbose` flag for detailed output:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests \
  -verbose
```

### Pretty Output

For more readable output, pipe through `xcpretty` (requires installation: `gem install xcpretty`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerUITests \
  | xcpretty
```

### Test Results

Save test results to a specific directory:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
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
- Ensure accessibility identifiers are added to UI elements
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
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Run only unit tests (exclude UI tests):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skip-testing:SubTimerUITests
```
