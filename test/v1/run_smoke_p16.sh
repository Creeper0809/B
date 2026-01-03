#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
lib_prelude="$root_dir/src/library/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
std2="$root_dir/src/v1/std/std2_fileio.b"
core_slice="$root_dir/src/v1/core/slice.b"
core_vec="$root_dir/src/v1/core/vec.b"
core_hashmap="$root_dir/src/library/v1/core/hashmap.b"
core_interner="$root_dir/src/library/v1/core/string_interner.b"

main_src="$root_dir/test/v1/smoke/p16_string_interner.b"

out_dir="$root_dir/build"
merged="$out_dir/p16_string_interner_merged.b"
asm="$out_dir/p16_string_interner.asm"
obj="$out_dir/p16_string_interner.o"
bin="$out_dir/p16_string_interner"

mkdir -p "$out_dir"
cat "$prelude" "$lib_prelude" "$std0" "$std1" "$std2" \
  "$core_slice" "$core_vec" "$core_hashmap" "$core_interner" \
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

echo "PASS: P16 string_interner"
