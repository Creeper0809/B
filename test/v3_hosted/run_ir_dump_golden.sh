#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="$root_dir/build"

golden_dir="$root_dir/test/v3_hosted/ir_dump_golden"

# Build the hosted v3 codegen smoke driver (v2 output binary)
(
  cd "$root_dir"
  ./bin/v2c ./examples/v3_hosted/p4_codegen_smoke_golden.b >/dev/null
)
smoke_bin="$out_dir/p4_codegen_smoke_golden.b.v2_out_bin"

if [[ ! -x "$smoke_bin" ]]; then
  echo "FAIL: missing smoke binary: $smoke_bin" >&2
  exit 1
fi

ok=0
fail=0

for input in "$golden_dir"/*.b; do
  base="$(basename "$input" .b)"
  out="$out_dir/${base}.ir.stdout"

  : >"$out"
  set +e
  timeout 5s "$smoke_bin" --dump-ir "$input" >"$out"
  status=$?
  set -e

  if [[ "$status" == "124" ]]; then
    echo "FAIL: timeout running: $base" >&2
    fail=$((fail+1))
    continue
  fi

  exp_out="$golden_dir/${base}.out"
  exp_status="$golden_dir/${base}.status"

  if ! diff -u "$exp_out" "$out" >/dev/null; then
    echo "FAIL: ir dump mismatch: $base" >&2
    diff -u "$exp_out" "$out" >&2 || true
    fail=$((fail+1))
    continue
  fi

  want_status="$(cat "$exp_status" | tr -d '\n' | tr -d '\r')"
  if [[ "$status" != "$want_status" ]]; then
    echo "FAIL: status mismatch: $base (got $status, want $want_status)" >&2
    fail=$((fail+1))
    continue
  fi

  ok=$((ok+1))
done

echo "ir_dump_golden: ok=$ok fail=$fail"
[[ $fail -eq 0 ]]
