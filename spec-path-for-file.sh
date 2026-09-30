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
explicit_spec_dir=0
[ "${LEFTHOOK_TDD_SPEC_DIR+x}" = x ] && explicit_spec_dir=1
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
  relative_path="${norm_stem}.bats"
  raw_relative_path="${raw_stem}.bats"
else
  relative_path="${dir}/${norm_stem}.bats"
  raw_relative_path="${dir}/${raw_stem}.bats"
fi

echo "${spec_dir}/${relative_path}"
[ "$raw_stem" != "$norm_stem" ] && echo "${spec_dir}/${raw_relative_path}" || true

if [ "$explicit_spec_dir" -eq 0 ]; then
  echo "${spec_dir}/unit/${relative_path}"
  [ "$raw_stem" != "$norm_stem" ] && echo "${spec_dir}/unit/${raw_relative_path}" || true
fi
