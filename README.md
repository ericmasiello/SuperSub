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

### Pre-commit hook

A pre-commit hook that runs SwiftLint against your staged Swift files (using
the same `--strict` policy as CI) lives at
[`scripts/git-hooks/pre-commit`](./scripts/git-hooks/pre-commit). It isn't
installed by default — `.git/hooks` isn't version-controlled, so Git won't
run a script that just lives in the repo — activate it once per clone:

```bash
ln -s ../../scripts/git-hooks/pre-commit .git/hooks/pre-commit
```

(A symlink keeps the hook in sync if the script changes later; copying the
file to `.git/hooks/pre-commit` instead also works, but you'll need to
re-copy it after any update.)

Once installed, `git commit` is blocked whenever a staged `.swift` file has a
SwiftLint violation. If SwiftLint isn't installed locally, the hook warns and
lets the commit through rather than blocking on missing tooling.

## Continuous integration

Every pull request runs the following GitHub Actions checks, defined in
[`.github/workflows/ci.yml`](./.github/workflows/ci.yml):

- **Lint** — runs `swiftlint lint --strict` against the same scope as the
  local command above.
- **Build for testing** — builds `SubTimerTests` + `SubTimerUITests` once
  against the `SubTimerCI` test plan (see below) via
  `xcodebuild build-for-testing`, and uploads the built products +
  generated `.xctestrun` as an artifact for the shards below.
- **Test / unit, Test / ui-player-launch, Test / ui-settings, Test /
  ui-timer** — a 4-way matrix that each downloads that artifact and runs
  `xcodebuild test-without-building -only-testing:...` against its own
  slice of `SubTimerTests`/`SubTimerUITests`, instead of every job
  rebuilding from scratch. These run concurrently on separate runners, so
  build-once + sharding keeps the total PR-blocking time from being the
  serial sum of every test class on one VM. See ADR-0008 for why each
  shard runs its own classes serially rather than also parallelizing
  within itself via simulator clones.

All jobs pin the runner image, Xcode version, and (for the test jobs)
simulator OS so the pass/fail signal doesn't silently drift as GitHub
updates its macOS images. If a job starts failing only in CI, check whether
the pinned versions are still available on the runner before assuming the
code regressed.

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

A second test plan, [`SubTimerCI.xctestplan`](./SubTimerCI.xctestplan), is
attached to the same scheme as a non-default entry and is what CI passes via
`-testPlan SubTimerCI`. It lists the same two test targets as the default
plan. The only reason it exists separately is so that an individually-flaky
UI test can be added to its `SubTimerUITests` entry's `skippedTests` array
without touching the CI workflow YAML and without affecting local runs
(which use the default `SubTimer.xctestplan`, where nothing is skipped).
Leave `skippedTests` empty until a specific test actually proves flaky in
CI — don't pre-populate it speculatively.

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
