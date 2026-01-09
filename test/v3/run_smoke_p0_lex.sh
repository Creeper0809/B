#!/bin/sh
set -eu

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
std2="$root_dir/src/v1/std/std2_fileio.b"
core_slice="$root_dir/src/v1/core/slice.b"
core_vec="$root_dir/src/v1/core/vec.b"
core_label="$root_dir/src/v1/core/label_gen.b"
emit_emitter="$root_dir/src/v1/emit/emitter.b"

lex_token="$root_dir/src/v3/lex/token.b"
lex_lexer="$root_dir/src/v3/lex/lexer.b"
driver_main="$root_dir/src/v3/driver/main.b"

input_src="$root_dir/test/v3/smoke/p0_lex_input.txt"

out_dir="$root_dir/build"
merged="$out_dir/v3_p0_lex_driver.b"
drv_asm="$out_dir/v3_p0_lex_driver.asm"
drv_obj="$out_dir/v3_p0_lex_driver.o"
drv_bin="$out_dir/v3_p0_lex_driver"
out_txt="$out_dir/v3_p0_lex_tokens.txt"

mkdir -p "$out_dir"

cat "$prelude" \
  "$std0" "$std1" "$std2" \
  "$core_slice" "$core_vec" "$core_label" \
  "$emit_emitter" \
  "$lex_token" "$lex_lexer" \
  "$driver_main" > "$merged"

basm "$merged" -o "$drv_asm" >/dev/null
nasm -felf64 "$drv_asm" -o "$drv_obj"
ld -o "$drv_bin" "$drv_obj"

"$drv_bin" "$input_src" >"$out_txt"

# Basic sanity: should print at least 1 token line containing 'kind='
if ! grep -q "kind=" "$out_txt"; then
  echo "FAIL: expected token dump in $out_txt" >&2
  exit 1
fi

echo "PASS: v3 P0 lex token dump"
