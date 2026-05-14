# shellcheck shell=bash
# Checks if a file path matches any of the colon-separated exclude patterns.
# Usage: bash is-excluded-path.sh <file-path> <colon-separated-patterns>
# Exit 0 = excluded, Exit 1 = not excluded.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

f="$1"
exclude_str="${2:-}"

if [ -z "$exclude_str" ]; then
    exit 1
fi

IFS=':' read -ra patterns <<<"$exclude_str"
for pattern in "${patterns[@]}"; do
    [ -z "$pattern" ] && continue
    # shellcheck disable=SC2254
    case "$f" in
        $pattern)
            exit 0
            ;;
    esac
done

exit 1
