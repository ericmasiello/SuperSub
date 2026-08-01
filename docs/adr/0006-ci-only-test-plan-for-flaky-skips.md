# A second, CI-only test plan holds the flaky-test skip list

`SubTimerCI.xctestplan` is attached to the `SubTimer` scheme as a non-default `TestPlanReference` alongside the existing default `SubTimer.xctestplan` (see ADR-0003). It lists the same two test targets as the default plan, and CI passes it explicitly via `xcodebuild test -testPlan SubTimerCI`.

The only reason it's a separate file rather than reusing the default plan is so an individually-flaky UI test can be skipped in CI — by adding it to the `SubTimerUITests` entry's `skippedTests` array — without touching the workflow YAML and without skipping it for local runs, which still use the default plan. `skippedTests` starts empty; it gets populated reactively, only once a specific test actually proves flaky under CI, not speculatively.
