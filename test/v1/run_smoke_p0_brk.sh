#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
main_src="$root_dir/test/v1/smoke/p0_brk_ok_main.b"
out_dir="$root_dir/build"
merged="$out_dir/p0_brk_ok.b"
asm="$out_dir/p0_brk_ok.asm"
obj="$out_dir/p0_brk_ok.o"
bin="$out_dir/p0_brk_ok"

mkdir -p "$out_dir"
cat "$prelude" "$std0" "$main_src" > "$merged"

basm "$merged" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

mapfile -t lines < <($bin)

if [[ ${#lines[@]} -lt 2 ]]; then
  echo "FAIL: expected at least 2 output lines" >&2
  printf '%s\n' "${lines[@]-}" >&2
  exit 1
fi

if ! [[ "${lines[0]}" =~ ^[0-9]+$ ]]; then
  echo "FAIL: first line not a decimal number" >&2
  printf '%s\n' "${lines[0]}" >&2
  exit 1
fi

if ! [[ "${lines[1]}" =~ ^[0-9]+$ ]]; then
  echo "FAIL: second line not a decimal number" >&2
  printf '%s\n' "${lines[1]}" >&2
  exit 1
fi

echo "PASS: P0 brk smoke"
