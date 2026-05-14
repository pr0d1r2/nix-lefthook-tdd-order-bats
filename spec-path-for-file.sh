# shellcheck shell=bash
# Maps a .sh file path to its candidate .bats spec paths.
# Usage: bash spec-path-for-file.sh <file-path>
# Prints candidate paths (one per line) to stdout.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

f="$1"
raw_stem="$(basename "$f")"
raw_stem="${raw_stem%.sh}"
norm_stem="${raw_stem//_/-}"

spec_dir="${LEFTHOOK_TDD_SPEC_DIR:-tests}"
strip_prefix="${LEFTHOOK_TDD_SRC_STRIP-scripts}"

if [ -n "$strip_prefix" ]; then
    case "$f" in
        "${strip_prefix}"/*)
            dir="$(echo "$f" | sed "s|^${strip_prefix}/||; s|/[^/]*\$||")"
            ;;
        *)
            dir="$(dirname "$f")"
            ;;
    esac
else
    dir="$(dirname "$f")"
fi

if [ "$dir" = "." ]; then
    echo "${spec_dir}/${norm_stem}.bats"
    [ "$raw_stem" != "$norm_stem" ] && echo "${spec_dir}/${raw_stem}.bats" || true
else
    echo "${spec_dir}/${dir}/${norm_stem}.bats"
    [ "$raw_stem" != "$norm_stem" ] && echo "${spec_dir}/${dir}/${raw_stem}.bats" || true
fi
