# shellcheck shell=bash
# Maps a .sh file path to its candidate .bats spec paths.
# Usage: bash spec-path-for-file.sh <file-path>
# Prints candidate paths (one per line) to stdout.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

f="$1"
raw_stem="$(basename "$f")"
raw_stem="${raw_stem%.sh}"
norm_stem="${raw_stem//_/-}"

case "$f" in
    scripts/*)
        dir="$(echo "$f" | sed 's|^scripts/||; s|/[^/]*$||')"
        echo "tests/${dir}/${norm_stem}.bats"
        [ "$raw_stem" != "$norm_stem" ] && echo "tests/${dir}/${raw_stem}.bats" || true
        ;;
    *)
        dir="$(dirname "$f")"
        echo "tests/${dir}/${norm_stem}.bats"
        [ "$raw_stem" != "$norm_stem" ] && echo "tests/${dir}/${raw_stem}.bats" || true
        ;;
esac
