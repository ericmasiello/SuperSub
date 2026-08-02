# Pre-commit hook is a plain checked-in script, not a hook-manager dependency

`scripts/git-hooks/pre-commit` is a plain shell script the contributor symlinks into `.git/hooks/pre-commit` by hand (see README), rather than something installed automatically via a hook-manager dependency (e.g. Husky, Lefthook).

This repo has no other JS/Node tooling that would make a JS-based hook manager a natural fit, and a single SwiftLint-on-staged-files check doesn't need the multi-hook orchestration those tools exist for. The tradeoff is manual, one-time activation per clone instead of automatic installation via a package-manager postinstall step — acceptable since local enforcement is a convenience layer on top of the GitHub Actions CI check (ADR-0005), which is the enforcement that can't be skipped.
