# shellcheck shell=bash
# Lefthook-compatible TDD order enforcer for bats.
# Verifies implementation commits include corresponding bats specs.
# Usage: lefthook-tdd-order-bats [--staged file1 file2 ...]
#   --staged <files>: check given files for matching specs (pre-commit)
#   default:          walk commit range base..HEAD (pre-push)
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ "${LEFTHOOK_TDD_ALLOW_GAP:-0}" = "1" ]; then
  exit 0
fi

staged_mode=0
if [ "${1:-}" = "--staged" ]; then
  staged_mode=1
  shift
fi

if [ "$staged_mode" -eq 1 ]; then
  files=()
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
      *.sh) files+=("$f") ;;
    esac
  done
  if [ "${#files[@]}" -eq 0 ]; then
    exit 0
  fi

  failed=0
  for f in "${files[@]}"; do
    bash @IS_EXCLUDED_PATH@ "$f" "${LEFTHOOK_TDD_EXCLUDE:-}" && continue

    mapfile -t candidates < <(bash @SPEC_PATH_FOR_FILE@ "$f")
    [ "${#candidates[@]}" -eq 0 ] && continue

    found=0
    for spec in "${candidates[@]}"; do
      if [ -f "$spec" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      printf 'tdd-order: staged %s but %s not found\n' \
        "$f" "${candidates[0]}" >&2
      failed=1
    fi
  done

  if [ "$failed" -ne 0 ]; then
    {
      echo
      echo "ERROR: spec gap(s) detected. Add missing spec in"
      echo "       the same commit, or stage it alongside."
      echo "       Bypass: LEFTHOOK_TDD_ALLOW_GAP=1"
    } >&2
    exit 1
  fi
  exit 0
fi

base="${LEFTHOOK_TDD_BASE_REF:-origin/main}"
if ! git rev-parse --verify --quiet "$base" >/dev/null; then
  exit 0
fi

baseline_file="${LEFTHOOK_TDD_BASELINE:-.tdd-order-baseline}"

rev_args=("$base..HEAD")
if [ -f "$baseline_file" ]; then
  baseline="$(sed -n '/^[^#[:space:]]/{p;q;}' "$baseline_file" | tr -d '[:space:]')"
  if [ -n "$baseline" ] &&
    git rev-parse --verify --quiet "${baseline}^{commit}" >/dev/null 2>&1; then
    rev_args+=("^$baseline")
  fi
fi

mapfile -t commits < <(git rev-list "${rev_args[@]}")
if [ "${#commits[@]}" -eq 0 ]; then
  exit 0
fi

read -ra scan_patterns <<<"${LEFTHOOK_TDD_PATHS:-:(glob)**/*.sh}"

failed=0
for c in "${commits[@]}"; do
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    bash @IS_EXCLUDED_PATH@ "$f" "${LEFTHOOK_TDD_EXCLUDE:-}" && continue

    mapfile -t candidates < <(bash @SPEC_PATH_FOR_FILE@ "$f")
    [ "${#candidates[@]}" -eq 0 ] && continue

    found=0
    for spec in "${candidates[@]}"; do
      if git cat-file -e "$c:$spec" 2>/dev/null ||
        git cat-file -e "HEAD:$spec" 2>/dev/null; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      printf 'tdd-order: %s touches %s but %s missing in its tree\n' \
        "$(git log -1 --format=%h "$c")" "$f" "${candidates[0]}" >&2
      failed=1
    fi
  done < <(git show --no-renames --name-only --pretty=format: \
    --diff-filter=AM "$c" \
    -- "${scan_patterns[@]}" \
    2>/dev/null)
done

if [ "$failed" -ne 0 ]; then
  {
    echo
    echo "ERROR: spec gap(s) detected. Add missing spec in the"
    echo "       same commit, an earlier commit, or a later commit"
    echo "       within the unpushed range."
    echo "       Bypass: LEFTHOOK_TDD_ALLOW_GAP=1"
  } >&2
  exit 1
fi
