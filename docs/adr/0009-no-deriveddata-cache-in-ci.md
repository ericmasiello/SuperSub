# CI does not cache DerivedData across runs

`build-for-testing` in `.github/workflows/ci.yml` always builds cold - no `actions/cache` step for `~/Library/Developer/Xcode/DerivedData` or the workspace-relative `DerivedData` it actually uses.

A cache was tried during #72. Its key only hashed `SubTimer.xcodeproj/project.pbxproj`, so it never invalidated on an ordinary source-file edit - once it started actually hitting (a separate bug had it silently caching the wrong, unused directory before that), `PlayerComponentsUITests.testPlayerRowStatusTransitionFlow` started failing reproducibly, 3 real PR runs in a row, on the same assertion. That's consistent with Xcode's incremental build getting confused by a restored `DerivedData` whose file mtimes don't reflect real edit history - a generally known-flaky pattern for caching `DerivedData` across CI runs, not just something this specific cache key could have been fixed to avoid.

Cold builds are already fast enough to not need it: `build-for-testing` measured ~1-2 minutes on #72's real PR runs. That's a small enough share of total PR-blocking wall time that the risk of intermittent, hard-to-diagnose test failures from a stale incremental build isn't worth chasing back.
