# Data model

The persisted model is mid-transition between two shapes:

- **In use:** `Player`, `Session`, `OrderManager`, `AppConfiguration` — backing
  all current app behavior. Of these, `Player` continues to exist once the
  transition is complete; `Session`, `OrderManager`, and `AppConfiguration`
  are expected to be superseded by the dormant types below.
- **Present but dormant:** `Team`, `RosterMembership`, `Game`, `Stint` —
  declared in the schema; no app code reads or writes them yet.

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
