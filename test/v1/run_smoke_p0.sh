#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

src="$root_dir/test/v1/smoke/p0_syscall_ok.b"
out_dir="$root_dir/build"
asm="$out_dir/p0_syscall_ok.asm"
obj="$out_dir/p0_syscall_ok.o"
bin="$out_dir/p0_syscall_ok"

mkdir -p "$out_dir"

basm "$src" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

if ! cmp -s <(printf 'OK\n') <($bin); then
  echo 'FAIL: unexpected output' >&2
  echo 'Expected bytes: 4f 4b 0a' >&2
  echo 'Actual bytes:' >&2
  $bin | od -An -t x1 >&2
  exit 1
fi

echo "PASS: P0 smoke"
