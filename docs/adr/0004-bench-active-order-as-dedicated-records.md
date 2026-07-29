# Bench and Active order live in dedicated records, not a field on Player

`Player` already carries a `sortOrder` used to order the roster list in Settings. The Bench queue order (who's Next Up) and the Active order (who subs out next) are each tracked separately in their own singleton-per-context SwiftData model — `BenchManager.playerOrder` and `ActiveManager.playerOrder`, both `[UUID]` — rather than as additional fields on `Player`.

A single `sortOrder` field can't represent two independent orderings that both need to survive a player moving between Active / Benched / Temporarily Out. `TimerView` re-syncs both managers against current player statuses on every appear (`syncBenchManager()`, `syncActiveManager()`) to add players missing from the order and drop ones that changed status — logic that only makes sense because the order lives outside `Player` itself.
