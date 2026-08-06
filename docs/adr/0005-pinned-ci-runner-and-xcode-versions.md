# CI pins the macOS runner, Xcode version, and simulator OS

Every GitHub Actions job in `.github/workflows/ci.yml` (`lint`, `build-for-testing`, and each shard of `test`; see ADR-0008) runs on `runs-on: macos-26` with an explicit `xcode-version` (via `maxim-lobanov/setup-xcode`) and, for the jobs that build or run tests, an explicit simulator `OS=` in the `-destination` string — never an unpinned `macos-latest`, `latest-stable`, or a bare device name with no OS.

GitHub periodically rotates what its "latest" runner image and default Xcode/simulator resolve to. On an unpinned workflow that can flip a green check red — or, worse, silently change what's actually being tested — with no code change on this repo's side. Pinning trades that drift for an explicit, one-line version bump (`XCODE_VERSION` / `SIMULATOR_DESTINATION` in the workflow) whenever this repo deliberately adopts a new Xcode release.
