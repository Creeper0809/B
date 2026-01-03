#!/usr/bin/env bash
set -euo pipefail

# P18 (확장): -I/--module-root + __init__.b fallback

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
std2="$root_dir/src/v1/std/std2_fileio.b"
core_slice="$root_dir/src/v1/core/slice.b"
core_vec="$root_dir/src/v1/core/vec.b"
core_label="$root_dir/src/v1/core/label_gen.b"
emit_emitter="$root_dir/src/v1/emit/emitter.b"

lex_token="$root_dir/src/v2/lex/token.b"
lex_lexer="$root_dir/src/v2/lex/lexer.b"

parse_expr="$root_dir/src/v2/parse/expr.b"
parse_cond="$root_dir/src/v2/parse/cond.b"
parse_stmt="$root_dir/src/v2/parse/stmt.b"
parse_func="$root_dir/src/v2/parse/func.b"
driver_main="$root_dir/src/v2/driver/main.b"

input_src="$root_dir/test/v2/smoke/p18_import_module_root.b"
module_root="$root_dir/test/v2/modules"

out_dir="$root_dir/build"
merged="$out_dir/v2_p18_I_driver.b"
drv_asm="$out_dir/v2_p18_I_driver.asm"
drv_obj="$out_dir/v2_p18_I_driver.o"
drv_bin="$out_dir/v2_p18_I_driver"

out_asm="$out_dir/v2_out.asm"
out_obj="$out_dir/v2_out.o"
out_bin="$out_dir/v2_out_bin"

mkdir -p "$out_dir"

cat "$prelude" \
  "$std0" "$std1" "$std2" \
  "$core_slice" "$core_vec" "$core_label" \
  "$emit_emitter" \
  "$lex_token" "$lex_lexer" \
  "$parse_expr" "$parse_cond" "$parse_stmt" "$parse_func" \
  "$driver_main" > "$merged"

basm "$merged" -o "$drv_asm" >/dev/null
nasm -felf64 "$drv_asm" -o "$drv_obj"
ld -o "$drv_bin" "$drv_obj"

rm -f "$out_asm"
"$drv_bin" -I "$module_root" "$input_src" >/dev/null

if [[ ! -f "$out_asm" ]]; then
  echo 'FAIL: expected build/v2_out.asm to be created' >&2
  exit 1
fi

nasm -felf64 "$out_asm" -o "$out_obj"
ld -o "$out_bin" "$out_obj"

set +e
"$out_bin" >/dev/null
code=$?
set -e

if [[ $code -ne 42 ]]; then
  echo 'FAIL: unexpected exit code' >&2
  echo "Expected: 42" >&2
  echo "Actual: $code" >&2
  exit 1
fi

echo "PASS: v2 P18 -I module root + __init__"
