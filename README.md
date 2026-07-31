# SubTimer

## Linting

Swift source is linted with [SwiftLint](https://github.com/realm/SwiftLint),
configured in [`.swiftlint.yml`](./.swiftlint.yml) at the repo root. It
covers `SubTimer/`, `SubTimerTests/`, `SubTimerUITests/`, and `ActiveBench/`.

### Install

```bash
brew install swiftlint
```

### Run

From the repo root:

```bash
swiftlint lint --strict
```

`--strict` treats warnings as failures, matching what CI enforces.

To auto-fix what's mechanically correctable (spacing, trailing commas,
`isEmpty` vs. `count == 0`, etc.) before addressing anything left by hand:

```bash
swiftlint --fix
```

## Running tests from the command line

This is an Xcode project, so tests run via `xcodebuild test` rather than a
package-manager script.

### Targets

- `SubTimerTests` — unit tests
- `SubTimerUITests` — UI tests

Both are exercised through the shared `SubTimer` scheme.

### Run all tests (unit + UI) on a simulator

```bash
xcodebuild test \
  -project SubTimer.xcodeproj \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Run only the unit tests

Skips the (slower) UI test target:

```bash
xcodebuild test \
  -project SubTimer.xcodeproj \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerTests
```

### Run a single test

```bash
xcodebuild test \
  -project SubTimer.xcodeproj \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SubTimerTests/YourTestClass/testYourMethod
```

### Run on macOS instead of a simulator

Faster since there's no simulator boot time:

```bash
xcodebuild test \
  -project SubTimer.xcodeproj \
  -scheme SubTimer \
  -destination 'platform=macOS'
```

### Listing available simulators

Swap `name=iPhone 17` for any simulator installed on your machine:

```bash
xcodebuild -showdestinations -project SubTimer.xcodeproj -scheme SubTimer
```

### Prettier output (optional)

If you have [`xcbeautify`](https://github.com/cpisciotta/xcbeautify) or
`xcpretty` installed, pipe the output through it:

```bash
xcodebuild test \
  -project SubTimer.xcodeproj \
  -scheme SubTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  | xcbeautify
```

### Test plan

Tests for the `SubTimer` scheme are driven by an explicit test plan,
[`SubTimer.xctestplan`](./SubTimer.xctestplan), which lists `SubTimerTests`
and `SubTimerUITests` as test targets. The scheme's `TestAction` references
this file directly (`<TestPlans><TestPlanReference reference="container:SubTimer.xctestplan" .../></TestPlans>`)
instead of relying on Xcode's "autocreated" test plan.

This matters because `shouldAutocreateTestPlan="YES"` (the default) manages
tests through an **in-memory** plan that Xcode regenerates whenever it opens
or edits the scheme — any test targets added by hand via
**Edit Scheme… ▸ Test** or by editing `<Testables>` directly in the
`.xcscheme` XML get silently dropped the next time Xcode touches the file.
Using a real, version-controlled `.xctestplan` avoids that.

### Troubleshooting

**`xcodebuild: error: Scheme SubTimer is not currently configured for the test action.`**

This means the scheme's `TestAction` has lost its test plan reference (or an
autocreated plan with 0 test targets got substituted in). Check
`SubTimer.xcodeproj/xcshareddata/xcschemes/SubTimer.xcscheme`:

- If `<TestAction>` has `shouldAutocreateTestPlan="YES"` and no `<TestPlans>`
  block, Xcode is relying on its fragile autocreated plan again.
- Fix it by pointing `TestAction` at `SubTimer.xctestplan` instead:

  ```xml
  <TestAction ... >
     <TestPlans>
        <TestPlanReference
           reference = "container:SubTimer.xctestplan"
           default = "YES">
        </TestPlanReference>
     </TestPlans>
  </TestAction>
  ```

- In Xcode's UI this is equivalent to **Edit Scheme… ▸ Test**, confirming
  `SubTimer.xctestplan` is listed under **Test Plans** and marked
  **Default**, rather than an entry labeled "(Autocreated)".
- Commit the updated `.xcscheme` and the `.xctestplan` file so the fix
  survives future edits made through Xcode's UI.
