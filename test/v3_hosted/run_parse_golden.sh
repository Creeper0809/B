#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

./bin/v2c examples/v3_hosted/p1_parse_smoke.b >/dev/null
DRIVER="$ROOT/build/p1_parse_smoke.b.v2_out_bin"

fail=0
for f in "$ROOT"/test/v3_hosted/parse_golden/*.b; do
	base="${f%.b}"
	expected_out="$base.out"
	expected_status="$base.status"

	if [[ ! -f "$expected_out" ]]; then
		echo "missing expected output: $expected_out" >&2
		fail=1
		continue
	fi
	if [[ ! -f "$expected_status" ]]; then
		echo "missing expected status: $expected_status" >&2
		fail=1
		continue
	fi

	want_status="$(tr -d '\n\r ' < "$expected_status")"
	if [[ -z "$want_status" ]]; then
		want_status=0
	fi

	tmp_out="$(mktemp)"
	set +e
	"$DRIVER" "$f" >"$tmp_out"
	got_status=$?
	set -e

	if [[ "$got_status" != "$want_status" ]]; then
		echo "status mismatch for $f: got=$got_status want=$want_status" >&2
		fail=1
	fi

	if ! diff -u "$expected_out" "$tmp_out"; then
		echo "output mismatch for $f" >&2
		fail=1
	fi

	rm -f "$tmp_out"
done

exit "$fail"
