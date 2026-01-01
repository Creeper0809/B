#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
main_src="$root_dir/test/v1/smoke/p0_panic_ok_main.b"
out_dir="$root_dir/build"
merged="$out_dir/p0_panic_ok.b"
asm="$out_dir/p0_panic_ok.asm"
obj="$out_dir/p0_panic_ok.o"
bin="$out_dir/p0_panic_ok"

mkdir -p "$out_dir"
cat "$prelude" "$std0" "$main_src" > "$merged"

basm "$merged" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

set +e
output="$($bin 2>&1)"
status=$?
set -e

if [[ $status -ne 1 ]]; then
  echo "FAIL: expected exit code 1, got $status" >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

# bash strips trailing newlines in $(...), so compare prefix text.
if [[ "$output" != "panic: boom"* ]]; then
  echo "FAIL: unexpected output" >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

echo "PASS: P0 panic smoke"
