# shellcheck shell=bash
# Lefthook-compatible TDD order enforcer for bats.
# Verifies implementation commits include corresponding bats specs.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ "${LEFTHOOK_TDD_ALLOW_GAP:-0}" = "1" ]; then
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
IFS=':' read -ra exclude_patterns <<<"${LEFTHOOK_TDD_EXCLUDE:-}"

failed=0
for c in "${commits[@]}"; do
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        skip=0
        for pattern in "${exclude_patterns[@]}"; do
            [ -z "$pattern" ] && continue
            # shellcheck disable=SC2254
            case "$f" in
                $pattern)
                    skip=1
                    break
                    ;;
            esac
        done
        [ "$skip" -eq 1 ] && continue
        raw_stem="$(basename "$f")"
        raw_stem="${raw_stem%.sh}"
        norm_stem="${raw_stem//_/-}"
        case "$f" in
            scripts/*)
                dir="$(echo "$f" | sed 's|^scripts/||; s|/[^/]*$||')"
                candidates=("tests/${dir}/${norm_stem}.bats")
                [ "$raw_stem" != "$norm_stem" ] &&
                    candidates+=("tests/${dir}/${raw_stem}.bats")
                ;;
            *)
                dir="$(dirname "$f")"
                candidates=("tests/${dir}/${norm_stem}.bats")
                [ "$raw_stem" != "$norm_stem" ] &&
                    candidates+=("tests/${dir}/${raw_stem}.bats")
                ;;
        esac
        found=0
        for spec in "${candidates[@]}"; do
            if git cat-file -e "$c:$spec" 2>/dev/null; then
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
        echo "ERROR: spec gap(s) detected. Add missing spec in"
        echo "       same commit, or split spec into earlier commit."
        echo "       Bypass: LEFTHOOK_TDD_ALLOW_GAP=1"
    } >&2
    exit 1
fi
