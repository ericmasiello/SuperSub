# Local-only persistence via SwiftData (no CloudKit)

SubTimer persists `Player`, `Session`, `AppConfiguration`, `BenchManager`, and `ActiveManager` locally via SwiftData, with `ModelConfiguration(..., cloudKitDatabase: .none)` in `SubTimerApp.swift`. The original PRD (`PRD.md`, since removed from the tree but preserved in git history at `54c0634`) specified SwiftData **with CloudKit sync**, full offline support, and a last-write-wins/merge conflict strategy. No CloudKit sync has been implemented — treat this as the current, load-bearing state rather than a forgotten TODO.

Reversing it later isn't free: `ActiveManager.playerOrder` and `BenchManager.playerOrder` are ordered `[UUID]` arrays representing queue position, and CloudKit's per-record merge model doesn't resolve concurrent edits to an ordered array for you. Wiring in CloudKit sync means designing that conflict resolution explicitly, not just flipping `cloudKitDatabase` to `.automatic`.
