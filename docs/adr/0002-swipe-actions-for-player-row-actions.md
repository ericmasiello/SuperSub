# Swipe actions, not long-press, open the player actions sheet

Player rows (Active, Bench, Temporarily Out) reveal the player actions sheet via `.swipeActions`, not a long-press gesture. Bench rows that are full (`canActivate == false`) also keep tap-to-open as a fallback for quick access.

## Considered Options

1. **Button wrappers around row content** — nested buttons intercepted taps meant for the row's own controls (e.g. the Bench row's activate button), so the row's primary action and the "open sheet" action fought each other.
2. **Long-press gesture** (commit `cee7713`) — resolved the nested-button conflict, but long-press conflicts with `List`'s native drag-to-reorder gesture recognizer, so it fired inconsistently inside the Active/Bench lists.
3. **Swipe actions** (commit `f638470`, current) — natively supported inside `List`, zero conflict with drag-to-reorder.

If a future change reintroduces long-press or nested buttons on these rows, it's very likely reintroducing one of the two bugs above, not just a style preference.
