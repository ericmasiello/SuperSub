# SubTimer

A single-purpose iOS app that helps a coach run fair player rotations during a practice or game: it times how long each player has been playing, tells the coach who to substitute next, and mirrors that state on the lock screen / Dynamic Island while the timer runs.

## Language

### Product identity

**SubTimer**:
The Xcode project, app target, and product name.
_Avoid_: Super Sub, SuperSub (see below — same product, different names in different places)

**Super Sub**:
The in-app display name shown as the navigation title on the Timer screen. Same product as SubTimer and SuperSub, just a different name at a different layer — don't treat it as a separate feature or mode.

**ActiveBench**:
The name of the WidgetKit extension target/bundle that hosts the Live Activity and Dynamic Island UI. Distinct from the `ActiveManager` and `BenchManager` records described below, despite the similar name.
_Avoid_: confusing with Active Manager / Bench Manager

### Roster & player status

**Player**:
A roster member tracked by the app. Has a name, a running play-time total, and exactly one status: Active, Benched, or Temporarily Out.

**Active**:
The player status meaning a player is currently on the field/court and their play clock is counting toward the Preferred Play Time.
_Avoid_: on field, playing, starting

**Bench** / **Benched**:
The player status, and the group of players, waiting to substitute in. Ordered — a player's position in the Bench determines when they come in.
_Avoid_: queue, reserves, subs pool (the original PRD used "queue"; the app and code say "Bench")

**Temporarily Out**:
A player status for a player pulled from rotation for a short absence (injury, bathroom break, etc.) without losing their place. Returns to the Bench, never directly back to Active.
_Avoid_: injured, inactive, unavailable

**Next Up**:
The Benched player at the front of the Bench order — the one an Automatic Substitution brings in next.

### Session & configuration

**Session**:
One complete timed run of the app, from the first timer start until the timer is reset or the session is cleared. Records its duration, Substitution count, and a snapshot of the roster and settings at the time it started.

**Preferred Play Time**:
The configured target duration an Active player should play before substituting out (default 3:00). Exceeding it puts that player's clock into Overtime.
_Avoid_: target time, shift length, rotation time

**Active Players Count**:
The configured number of roster spots that are simultaneously Active (default 4). Must be less than or equal to the total roster size.
_Avoid_: active spots, active count

**Overtime**:
The state where an Active player's current play duration has exceeded the Preferred Play Time. Rendered in red both in-app and in the Live Activity.

### Substitution

**Substitution**:
Swapping one Active player out for one Benched player in: the outgoing player's segment time is added to their total and they move to the back of the Bench; the incoming player becomes Active with their play clock reset to zero.

**Automatic Substitution**:
A Substitution triggered by the primary Substitute button. Always swaps the longest-serving Active player for the player Next Up on the Bench — no player selection required.
_Avoid_: auto-sub, quick sub

**Manual Substitution**:
A Substitution where the coach explicitly picks both the outgoing Active player and the incoming Benched player, via the player actions sheet and manual substitution sheet.

**Swap Recommendation**:
The suggested next Substitution pairing (who's coming out, who's coming in) surfaced in the Live Activity / Dynamic Island as "SubOut → SubIn".

### Live Activity

**Live Activity**:
The iOS ActivityKit lock-screen and Dynamic Island surface, hosted by the ActiveBench widget extension, that mirrors the running timer, the Active/Bench counts, and the current Swap Recommendation while a Session's timer is running.
