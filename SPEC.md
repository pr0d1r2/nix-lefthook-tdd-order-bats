# SPEC — nix-lefthook-tdd-order-bats

## §G Goal

Lefthook-compatible TDD order enforcer for bats. Verify every `.sh` commit has matching `.bats` in same tree. Nix flake pkg. Opensource-safe: zero credentials, zero local paths, zero private refs.

## §C Constraints

- C1: Pure bash — no Python/Ruby/etc runtime deps
- C2: Nix flake — `writeShellApplication` pkg, devShells via `nix-dev-shell-agentic`
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded local paths, no private repo refs
- C6: All config via env vars — no config files beyond baseline
- C7: Exit non-zero on spec gaps — hard enforcement, blocks commit

## §I Interfaces

- I.cli: `lefthook-tdd-order-bats` — main binary, exit 1 on spec gaps (blocks commit), exit 0 on pass
- I.env: `LEFTHOOK_TDD_ALLOW_GAP` (0/1), `LEFTHOOK_TDD_BASE_REF` (default `origin/main`), `LEFTHOOK_TDD_BASELINE` (default `.tdd-order-baseline`), `LEFTHOOK_TDD_PATHS` (space-sep pathspecs), `LEFTHOOK_TDD_EXCLUDE` (colon-sep globs), `LEFTHOOK_TDD_ORDER_TIMEOUT` (seconds)
- I.remote: `lefthook-remote.yml` — consumers add as lefthook remote
- I.flake: `packages.${system}.default` — Nix pkg output
- I.devshell: `devShells.${system}.default` + `.#ci` — dev/CI shells
- I.ci: `.github/workflows/ci.yml` — linux + macos, nix build + lefthook pre-commit + pre-push

## §V Invariants

- V1: Every `.sh` added/modified in commit range has matching `.bats` in same commit tree — exit 1 if any gap found
- V2: `scripts/*` path strips `scripts/` prefix for test lookup; all others keep full dir under `tests/`
- V3: Underscore→hyphen normalization: `my_tool.sh` matches `my-tool.bats` (both forms tried)
- V4: `LEFTHOOK_TDD_ALLOW_GAP=1` bypasses all checks — immediate exit 0
- V5: Missing/invalid base ref → silent exit 0 (no crash on fresh repos)
- V6: Baseline file skips commits at/before recorded SHA
- V7: `LEFTHOOK_TDD_EXCLUDE` patterns suppress check for matching paths
- V8: `LEFTHOOK_TDD_PATHS` overrides default `:(glob)**/*.sh` scan scope
- V9: Script exits 1 when spec gaps detected — hard requirement, blocks commit
- V10: No credentials, secrets, tokens, API keys, or private paths in any tracked file
- V11: No hardcoded local filesystem paths (enforced by `nix-lefthook-git-no-local-paths` hook)
- V12: `dev.sh` sets `BATS_LIB_PATH` and auto-installs lefthook when hooks missing
- V13: CI runs both pre-commit and pre-push on linux + macos
- V14: All linters pass: shellcheck, shfmt, nixfmt, statix, deadnix, yamllint, typos, editorconfig-checker, bats-parse, unicode-lint, trailing-whitespace, missing-final-newline, git-conflict-markers, git-no-local-paths
- V15: `LEFTHOOK_TDD_PATHS` uses space-separated pathspecs (not colon) — colon breaks `:(glob)` magic prefix

## §T Tasks

| id | status | task | cites |
|----|--------|------|-------|
| T1 | x | core enforcer script with path mapping + normalization + exit 1 on gaps | V1,V2,V3,I.cli |
| T2 | x | env var config: allow-gap, base-ref, baseline, paths, exclude | V4,V5,V6,V7,V8,I.env |
| T3 | x | Nix flake pkg (`writeShellApplication`) | C2,I.flake |
| T4 | x | devShell + CI shell via nix-dev-shell-agentic | C2,I.devshell |
| T5 | x | lefthook-remote.yml for consumers | I.remote |
| T6 | x | dev.sh — BATS_LIB_PATH + auto-install | V12 |
| T7 | x | unit tests: lefthook-tdd-order-bats.bats (12 tests, assert_failure for gaps) | V1-V9 |
| T8 | x | unit tests: dev.bats (3 tests) | V12 |
| T9 | x | GitHub Actions CI: linux + macos | V13,I.ci |
| T10 | x | linter suite via lefthook remotes | V14 |
| T11 | x | opensource audit: verify no credentials/local-paths/private-refs in git history | V10,V11,C5 |
| T12 | x | .gitignore: add `.claude/`, `.env`, and sensitive patterns | V10,C5 |
| T13 | x | change `exit 0` to `exit 1` on spec gaps in enforcer script + update tests | V9,V1,C7 |

## §B Bugs

| id | date | cause | fix |
|----|------|-------|-----|
| B1 | 2026-05-11 | `IFS=':'` split destroyed `:(glob)` pathspec prefix — enforcer never found `.sh` files | V15 |
