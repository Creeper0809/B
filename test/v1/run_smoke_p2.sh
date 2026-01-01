#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
std2="$root_dir/src/v1/std/std2_fileio.b"
emit="$root_dir/src/v1/emit/emitter.b"
main_src="$root_dir/test/v1/smoke/p2_io_ok.b"

out_dir="$root_dir/build"
merged="$out_dir/p2_io_ok.b"
asm="$out_dir/p2_io_ok.asm"
obj="$out_dir/p2_io_ok.o"
bin="$out_dir/p2_io_ok"

mkdir -p "$out_dir"
cat "$prelude" "$std0" "$std1" "$std2" "$emit" "$main_src" > "$merged"

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

echo "PASS: P2 smoke"
