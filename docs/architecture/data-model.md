# Data model

The persisted model is mid-transition between two shapes:

- **In use:** `Player`, `Session`, `OrderManager`, `AppConfiguration` — backing
  all current app behavior. Of these, `Player` continues to exist once the
  transition is complete; `Session`, `OrderManager`, and `AppConfiguration`
  are expected to be superseded by the dormant types below.
- **Partially in use:** `Team`, `RosterMembership`, `Game`, `Stint` —
  `TimerView`'s activate/mark-temporarily-out/return-to-bench/substitution
  actions, its Active/Bench/Temporarily-Out section rendering, and its Live
  Activity feed all read/write these via `GameManager` (#60/#61);
  `RosterMembership` remains unread/unwritten by app UI until a later
  ticket rewires `SettingsView` onto `TeamManager`/`Team`.

```mermaid
classDiagram
    class Player {
        <<in use>>
    }
    class Session {
        <<in use>>
    }
    class OrderManager {
        <<in use>>
    }
    class AppConfiguration {
        <<in use>>
    }

    class Team {
        <<dormant>>
        +String name
        +String sport
        +Int preferredPlayTimeSeconds
        +Int activePlayersCount
    }
    class RosterMembership {
        <<dormant>>
        +String? position
    }
    class Game {
        <<dormant>>
        +Date startDate
        +Date? endDate
        +TimeInterval duration
        +Int substitutionCount
        +Int preferredPlayTimeSeconds
        +Int activePlayersCount
        +UUID[] activeOrder
        +UUID[] benchOrder
        +UUID[] temporarilyOut
    }
    class Stint {
        <<dormant>>
        +Date startDate
        +Date? endDate
        +String? position
    }

    Team "1" o-- "0..*" RosterMembership : optional relationship
    Player "1" o-- "0..*" RosterMembership : optional relationship
    Team "1" o-- "0..*" Game : optional relationship
    Game "1" o-- "0..*" Stint : optional relationship
    Player "1" o-- "0..*" Stint : optional relationship
```

## Notes

- Every relationship is optional, no type uses `@Attribute(.unique)`, and
  ordered/unordered ID collections (`activeOrder`, `benchOrder`,
  `temporarilyOut`) are plain value attributes rather than `@Relationship`
  arrays. These are CloudKit sync constraints, not stylistic choices — see
  [ADR-0001](../adr/0001-local-only-persistence-no-cloudkit.md).
- The app's shipped `ModelConfiguration` remains local-only
  (`cloudKitDatabase: .none`) per ADR-0001, even though the schema above is
  already shaped to be CloudKit-compatible.

## GameManager and TeamManager (#58)

`GameManager` and `TeamManager` are the only code allowed to mutate
`Game`/`Stint`/`RosterMembership` — the models themselves stay anemic (no
methods). Both are plain (non-`@Model`) classes, fully unit-tested against
in-memory `ModelContainer`s; the dormant models above are still not read or
written by any app UI, only by these managers' tests.

```mermaid
classDiagram
    class GameManager {
        +transition(playerId: UUID, to: RotationBucket, in: Game)
        +automaticSubstitution(game: Game)
        +manualSubstitution(outgoing: UUID, incoming: UUID, game: Game)
        +addAdHocPlayer(player: Player, to: Game)
        +currentPlayDuration(playerId: UUID, in: Game) TimeInterval
        +totalPlayTime(playerId: UUID, in: Game) TimeInterval
    }
    class TeamManager {
        +addToRoster(player: Player, team: Team) RosterMembership
        +removeFromRoster(player: Player, team: Team)
        +updatePreferredPosition(membership: RosterMembership, position: String?)
        +updateDefaults(team: Team, preferredPlayTimeSeconds: Int, activePlayersCount: Int)
    }
    class RotationBucket {
        <<enumeration>>
        active
        benched
        temporarilyOut
    }
    class Game {
        <<anemic>>
    }
    class Stint {
        <<anemic>>
    }
    class Team {
        <<anemic>>
    }
    class RosterMembership {
        <<anemic>>
    }

    GameManager ..> RotationBucket : uses
    GameManager --> Game : sole mutator of activeOrder/benchOrder/temporarilyOut
    GameManager --> Stint : sole opener/closer
    TeamManager --> RosterMembership : sole creator/deleter, enforces (Player,Team) uniqueness
    TeamManager --> Team : reads/updates defaults
```

`transition` stays a single gateway that updates bucket membership and the
open/closed `Stint` together, so the two facts can never drift apart:

```mermaid
sequenceDiagram
    participant Caller
    participant GameManager
    participant Game
    participant Stint

    Caller->>GameManager: transition(playerId, to: .active, in: game)
    GameManager->>Game: purge playerId from benchOrder/temporarilyOut
    GameManager->>Game: append playerId to activeOrder
    GameManager->>Stint: open new Stint(player, game, startDate: now)
    GameManager-->>Caller: bucket membership + Stint updated atomically, in one call
```

## Legacy data migration (#59)

A one-time, idempotent transform, driven by `SubTimerMigrationPlan`
(`SchemaV1` → `SchemaV2`) on `ModelContainer` open, that populates the
dormant `Team`/`RosterMembership`/`Game` rows from the in-use
`Player`/`Session`/`AppConfiguration` data. No `GameManager`/`TeamManager`
involvement — this only produces correct rows for later tickets to wire up.

`SchemaV1` gives `Player` its own frozen, relationship-free snapshot rather
than reusing the real `Player` class: the real class already carries #57's
`rosterMemberships`/`stints` relationships, and reusing it as-is would pull
`RosterMembership`/`Stint`/`Team` into `SchemaV1`'s compiled model too,
making it indistinguishable from `SchemaV2`. `AppConfiguration`/`Session`/
`OrderManager` have no such relationships, so `SchemaV2` reuses them —
and the real `Player`/`Team`/`RosterMembership`/`Game`/`Stint` — directly.

`Game` gained a `duration: TimeInterval` field as part of this ticket: it
has no other way to preserve an in-progress `Session`'s elapsed time (`Session.endDate`
is `nil` while active, so `duration` can't be re-derived from
`startDate`/`endDate` alone), mirroring `Session`'s own two-field shape.

```mermaid
sequenceDiagram
    participant App as App launch
    participant Plan as SchemaMigrationPlan
    participant Legacy as V1 store (Player, Session, AppConfiguration)
    participant New as V2 store (Team, RosterMembership, Game)

    App->>Plan: open ModelContainer
    Plan->>New: check for existing migrated Team
    alt already migrated
        Plan-->>App: no-op, reuse existing Team/RosterMembership/Game rows
    else not yet migrated
        Plan->>Legacy: read AppConfiguration singleton
        Plan->>New: create Team (preferredPlayTimeSeconds/activePlayersCount seeded from AppConfiguration)
        Plan->>Legacy: read every Player
        Plan->>New: create one RosterMembership(player, team) per Player, position = nil
        Plan->>Legacy: read every Session
        Plan->>New: create one Game(team) per Session, copying startDate/endDate/duration/substitutionCount
        Plan-->>App: migration complete
    end
```

## TimerView rewired onto GameManager (#60)

`TimerView`'s activate, mark-temporarily-out, and return-to-bench actions —
plus Active/Bench/Temporarily-Out section rendering — now go through
`GameManager` against an open `Game`, instead of `Player.status`/
`OrderManager`. Two additions to `GameManager` support this:
`status(playerId:in:) -> RotationBucket` (defaults to `.benched` when a
player is in none of the three buckets, matching `Player.defaultStatus`) and
`setOrder(_:for:in:)` (drag-to-reorder, replacing a bucket's order without
changing membership — `.temporarilyOut` is a no-op, since it's an unordered
`Set`).

`TimerView` resolves-or-creates its `Game` eagerly, on `.onAppear`. A fresh
`Game` is only created when no open one exists for the app's `Team` — for a
real upgrading user, migration (#59) only produces closed, historical
`Game`s, so a fresh `Game` is bootstrapped once from each player's current
`Player.status`/`activatedAtDate`, carrying an in-progress rotation into the
new model without resetting it (#61 dropped this bootstrap's use of
`OrderManager` to preserve a prior custom order, in step with removing
`OrderManager` from the rest of the view — see below).

```mermaid
sequenceDiagram
    participant Coach
    participant TimerView
    participant GameManager
    participant Game
    participant Stint
    participant Section as Active/Bench/TempOut SectionView

    Coach->>TimerView: tap Activate / Mark Temporarily Out / Return to Bench
    TimerView->>GameManager: transition(playerId, to: bucket, in: game)
    GameManager->>Game: purge playerId from old bucket, insert into new bucket
    GameManager->>Stint: close open Stint (leaving Active) or open new Stint (entering Active)
    GameManager-->>TimerView: updated Game/Stint state

    TimerView->>GameManager: status(playerId, in: game), currentPlayDuration/totalPlayTime(playerId, in: game)
    GameManager-->>TimerView: resolved status + duration
    TimerView->>Section: pass resolved status/duration as parameters
    Section-->>Coach: renders - identical to today, no direct player.status/currentPlayDuration reads
```

As of #60, Substitution still kept its own `Player.status`/`OrderManager`
writes in parallel with a `GameManager.manualSubstitution` mirror call — see
below for #61, the follow-on ticket that removed that legacy path.

## Substitution and Live Activity rewired onto GameManager (#61)

Automatic and Manual Substitution now run through `GameManager` exclusively:
both variants resolve an outgoing/incoming pair, then make a single
`GameManager.manualSubstitution(outgoing:incoming:game:)` call — there's no
separate need for `GameManager.automaticSubstitution`'s own pairing logic in
`TimerView`, since it already resolves the specific pair itself before
either flow reaches this call. `activatePlayer`/`markPlayerTemporarilyOut`/
`returnPlayerToBench`/`performSubstitution`/`autoActivateInitialPlayersIfNeeded`
no longer write `Player.status`/`currentPlayDuration`/`totalPlayTime`, and
`OrderManager` is gone from `TimerView` entirely — every rotation read and
write in the view now goes through `GameManager` against `Game`.

`TimerView`'s Live Activity start/update call sites
(`startLiveActivity`/`updateLiveActivity`/`scheduleOvertimeUpdate`) now read
`preferredPlayTimeSeconds` from the open `Game` instead of
`AppConfiguration`; the player counts/names they pass
(`activePlayers.count`/`benchedPlayers.count`/`.first?.name`) were already
`Game`-derived as of #60's `activePlayers`/`benchedPlayers` computed
properties, so no further change was needed there.

One reference to `Player.status` remains in `TimerView`, in
`resolveOrCreateGame()`'s one-time legacy-bootstrap read (see #60 above) —
it's the historical migration bridge, not an ongoing mirror, and both the
`--uitesting` fixture (`SubTimerApp.setupTestData`) and `TimerViewUITests`
depend on it seeding bucket membership correctly on a brand-new `Game`.

Because `SettingsView` is unrewired until a later ticket and still reads/
writes `Player.status`/`currentPlayDuration`/`totalPlayTime` directly, a
player changed through `TimerView` now shows stale values on the Settings
screen until that ticket lands — an accepted, temporary consequence of
migrating screen-by-screen. The same applies to `preferredPlayTimeSeconds`:
`Game`'s copy is a snapshot taken at creation time, so a mid-session change
in `SettingsView` (still `AppConfiguration`-backed) won't reach the Live
Activity until `SettingsView` is rewired onto `Team`.

```mermaid
sequenceDiagram
    participant Coach
    participant TimerView
    participant GameManager
    participant Stint
    participant Game
    participant LiveActivityManager
    participant ActivityKit as ActivityKit / Dynamic Island

    alt Automatic Substitution
        Coach->>TimerView: tap Substitute
        TimerView->>GameManager: resolve longest-serving Active + Next Up Bench player
    else Manual Substitution
        Coach->>TimerView: pick outgoing + incoming players
        TimerView->>GameManager: manualSubstitution(outgoing, incoming, game)
    end

    GameManager->>GameManager: transition(outgoing, to: .benched, in: game)
    GameManager->>Stint: close outgoing's Stint, add duration to total
    GameManager->>GameManager: transition(incoming, to: .active, in: game)
    GameManager->>Stint: open new Stint for incoming, starting at zero
    GameManager->>Game: substitutionCount += 1
    GameManager-->>TimerView: updated Game/Stint state

    TimerView->>LiveActivityManager: update(team: Team, game: Game)
    LiveActivityManager->>ActivityKit: push ContentState (shape unchanged)
    ActivityKit-->>Coach: lock screen / Dynamic Island reflects the swap
```

After this ticket, `TimerView` has no remaining ongoing references to
`Player.status`/`currentPlayDuration`/`totalPlayTime`/`OrderManager` —
every rotation read and write in that view goes through `GameManager`, and
every Live Activity read goes through `Game`.
