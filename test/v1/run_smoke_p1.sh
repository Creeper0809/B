#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
core_slice="$root_dir/src/v1/core/slice.b"
core_vec="$root_dir/src/v1/core/vec.b"
core_label="$root_dir/src/v1/core/label_gen.b"
main_src="$root_dir/test/v1/smoke/p1_core_ok.b"

out_dir="$root_dir/build"
merged="$out_dir/p1_core_ok.b"
asm="$out_dir/p1_core_ok.asm"
obj="$out_dir/p1_core_ok.o"
bin="$out_dir/p1_core_ok"

mkdir -p "$out_dir"
cat "$std0" "$std1" "$core_slice" "$core_vec" "$core_label" "$main_src" > "$merged"

basm "$merged" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

if ! cmp -s <(printf 'OK\n') <($bin); then
  echo 'FAIL: unexpected output' >&2
  echo 'Expected bytes: 4f 4b 0a' >&2
  echo 'Actual bytes:' >&2
  $bin | od -An -t x1 >&2
  exit 1
fi

echo "PASS: P1 smoke"
