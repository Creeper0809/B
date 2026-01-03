#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
lib_prelude="$root_dir/src/library/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"

core_sb="$root_dir/src/library/v1/core/string_builder.b"

main_src="$root_dir/test/v1/smoke/p18_string_builder.b"

out_dir="$root_dir/build"
merged="$out_dir/p18_string_builder_merged.b"
asm="$out_dir/p18_string_builder.asm"
obj="$out_dir/p18_string_builder.o"
bin="$out_dir/p18_string_builder"

mkdir -p "$out_dir"
cat "$prelude" "$lib_prelude" "$std0" "$std1" \
  "$core_sb" \
  "$main_src" > "$merged"

basm "$merged" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

set +e
"$bin" >/dev/null
code=$?
set -e

if [[ $code -ne 0 ]]; then
  echo 'FAIL: unexpected exit code' >&2
  echo "Expected: 0" >&2
  echo "Actual: $code" >&2
  exit 1
fi

echo "PASS: P18 string builder"
