# nix-lefthook-tdd-order-bats

[![CI](https://github.com/pr0d1r2/nix-lefthook-tdd-order-bats/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-tdd-order-bats/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible TDD order enforcer for [bats](https://github.com/bats-core/bats-core), packaged as a Nix flake.

Verifies that implementation commits include corresponding bats spec files. When a commit adds or modifies a shell script, this hook checks that the matching `.bats` test file exists in the same commit tree. Exits 0 when no gaps are found.

## Path mapping

| Implementation | Test |
|----------------|------|
| `scripts/foo/bar.sh` | `tests/foo/bar.bats` |
| `fragments/example.sh` | `tests/fragments/example.bats` |
| `pkgs/tool.sh` | `tests/pkgs/tool.bats` |

Scripts under `scripts/` have the `scripts/` prefix stripped for the test path. All other paths map directly under `tests/`. Underscores in filenames are normalized to hyphens when searching for specs (both forms are tried).

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-tdd-order-bats
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-tdd-order-bats = {
  url = "github:pr0d1r2/nix-lefthook-tdd-order-bats";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-tdd-order-bats.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    tdd-order:
      run: timeout ${LEFTHOOK_TDD_ORDER_TIMEOUT:-30} lefthook-tdd-order-bats
```

## Configuration

All configuration is via environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `LEFTHOOK_TDD_ALLOW_GAP` | `0` | Set to `1` to bypass the check |
| `LEFTHOOK_TDD_BASE_REF` | `origin/main` | Base ref for commit range |
| `LEFTHOOK_TDD_BASELINE` | `.tdd-order-baseline` | File containing baseline commit SHA |
| `LEFTHOOK_TDD_PATHS` | `:(glob)**/*.sh` | Space-separated git pathspec patterns to scan |
| `LEFTHOOK_TDD_EXCLUDE` | *(empty)* | Colon-separated glob patterns for paths to skip |
| `LEFTHOOK_TDD_ORDER_TIMEOUT` | `30` | Timeout in seconds |

### Configuring scan paths

Override which files are checked (space-separated git pathspecs):

```bash
export LEFTHOOK_TDD_PATHS=":(glob)scripts/**/*.sh :(glob)lib/**/*.sh"
```

### Excluding paths

Skip specific paths from the TDD check (colon-separated globs):

```bash
export LEFTHOOK_TDD_EXCLUDE="scripts/lefthook/*:scripts/vendor/*"
```

### Baseline file

The baseline file (default `.tdd-order-baseline`) contains a commit SHA. Commits at or before this SHA are not checked. This is useful when adopting the hook on an existing project — set the baseline to the current HEAD and only new commits are enforced.

```bash
git rev-parse HEAD > .tdd-order-baseline
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-tdd-order-bats  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
