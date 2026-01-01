#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prelude="$root_dir/src/v1/prelude.b"
std0="$root_dir/src/v1/std/std0_sys.b"
std1="$root_dir/src/v1/std/std1_memstrnum.b"
std2="$root_dir/src/v1/std/std2_fileio.b"
core_slice="$root_dir/src/v1/core/slice.b"
core_vec="$root_dir/src/v1/core/vec.b"
emit_emitter="$root_dir/src/v1/emit/emitter.b"
lex_token="$root_dir/src/v1/lex/token.b"
lex_lexer="$root_dir/src/v1/lex/lexer.b"
parse_symbol="$root_dir/src/v1/parse/symbol.b"
parse_parser="$root_dir/src/v1/parse/parser.b"
main_src="$root_dir/test/v1/smoke/p4_parse_ok.b"

out_dir="$root_dir/build"
merged="$out_dir/p4_parse_ok.b"
asm="$out_dir/p4_parse_ok.asm"
obj="$out_dir/p4_parse_ok.o"
bin="$out_dir/p4_parse_ok"

mkdir -p "$out_dir"
cat "$prelude" "$std0" "$std1" "$std2" "$core_slice" "$core_vec" "$emit_emitter" "$lex_token" "$lex_lexer" "$parse_symbol" "$parse_parser" "$main_src" > "$merged"

basm "$merged" -o "$asm" >/dev/null
nasm -felf64 "$asm" -o "$obj"
ld -o "$bin" "$obj"

# ensure output file from the test is clean
rm -f "$out_dir/p4_out.asm"

if ! cmp -s <(printf 'OK\n') <($bin); then
  echo 'FAIL: unexpected output' >&2
  echo 'Expected bytes: 4f 4b 0a' >&2
  echo 'Actual bytes:' >&2
  $bin | od -An -t x1 >&2
  exit 1
fi

if [[ ! -f "$out_dir/p4_out.asm" ]]; then
  echo 'FAIL: expected build/p4_out.asm to be created' >&2
  exit 1
fi

if ! head -n 1 "$out_dir/p4_out.asm" | grep -q '^global _start$'; then
  echo 'FAIL: build/p4_out.asm missing expected header' >&2
  echo 'First line:' >&2
  head -n 1 "$out_dir/p4_out.asm" >&2 || true
  exit 1
fi

echo "PASS: P4 smoke"