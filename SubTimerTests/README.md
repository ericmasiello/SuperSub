# SubTimerTests

This directory contains unit tests for the SubTimer application using Swift Testing framework.

## Test Files

- `PlayerTests.swift` - Tests for Player model functionality
- `PlayerStatusTests.swift` - Tests for player status management
- `SessionTests.swift` - Tests for Session model and tracking
- `TimeFormattingTests.swift` - Tests for time formatting utilities
- `AppConfigurationTests.swift` - Tests for app configuration validation

## Running Tests from Command Line

### Run All Unit Tests

Run all tests in the SubTimerTests target:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests
```

### Run Tests in a Specific File

Run all tests in `PlayerTests.swift`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests/PlayerTests
```

Run all tests in `SessionTests.swift`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests/SessionTests
```

### Run a Specific Test

Run a single test method (e.g., `testPlayerInitialization` in `PlayerTests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests/PlayerTests/testPlayerInitialization
```

Run another specific test (e.g., `testSessionInitialization` in `SessionTests`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests/SessionTests/testSessionInitialization
```

### Run Tests with Different Destinations

For iOS Simulator:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerTests
```

For a specific macOS architecture:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:SubTimerTests
```

### Run Multiple Specific Tests

Run multiple test files:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests/PlayerTests \
  -only-testing:SubTimerTests/SessionTests
```

### Exclude Specific Tests

Run all tests except those in `PlayerTests`:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests \
  -skip-testing:SubTimerTests/PlayerTests
```

### Verbose Output

Add `-verbose` flag for detailed output:

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests \
  -verbose
```

### Pretty Output

For more readable output, pipe through `xcpretty` (requires installation: `gem install xcpretty`):

```bash
xcodebuild test \
  -scheme SubTimer \
  -destination 'platform=macOS' \
  -only-testing:SubTimerTests \
  | xcpretty
```

## Running Tests in Xcode

1. Open `SubTimer.xcodeproj` in Xcode
2. Press `⌘+U` to run all tests
3. Or use the Test Navigator (`⌘+6`) to run individual tests

## Test Framework

These tests use Swift Testing framework (`import Testing`) with the following syntax:
- `@Test` attribute marks test functions
- `#expect()` for assertions
- `@testable import SubTimer` to access internal types

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
