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
