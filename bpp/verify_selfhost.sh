#!/usr/bin/env bash
# v3c 셀프호스팅 검증: 단일 파일 비교
# v2c와 v3c_full이 같은 어셈블리를 생성하는지 확인

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

V2C="$ROOT/bin/v2c"
V3C="$ROOT/bin/v3c_full"
OUT="$ROOT/build"

# 테스트할 파일 (v3_hosted의 각 모듈)
test_file="${1:-$ROOT/src/v3_hosted/token.b}"

echo "=== Self-hosting Verification ==="
echo "Testing: $test_file"

# v2c로 컴파일
echo "1. Compiling with v2c..."
$V2C "$test_file" 2>/dev/null
v2_asm="$OUT/$(basename "$test_file").v2_out.asm"

# v3c_full로 컴파일
echo "2. Compiling with v3c_full..."
v3_asm="$OUT/$(basename "$test_file").v3c.asm"
$V3C "$test_file" > "$v3_asm" 2>&1 || {
    echo "v3c_full failed:"
    head -20 "$v3_asm"
    exit 1
}

# 어셈블리 비교 (boilerplate 제외, 함수 본문만)
echo "3. Comparing assembly output..."
v2_funcs=$(grep -c "^[a-z_]*:" "$v2_asm" || echo 0)
v3_funcs=$(grep -c "^[a-z_]*:" "$v3_asm" || echo 0)

echo "   v2c functions: $v2_funcs"
echo "   v3c functions: $v3_funcs"

if diff -q <(grep "^\s*mov\|^\s*push\|^\s*pop\|^\s*call\|^\s*ret" "$v2_asm" | head -50) \
           <(grep "^\s*mov\|^\s*push\|^\s*pop\|^\s*call\|^\s*ret" "$v3_asm" | head -50) >/dev/null; then
    echo "✓ Assembly output matches (first 50 instructions)"
else
    echo "✗ Assembly differs"
    echo "--- v2c vs v3c (first 20 lines) ---"
    diff <(head -100 "$v2_asm") <(head -100 "$v3_asm") | head -40 || true
fi

echo ""
echo "Files:"
echo "  v2c: $v2_asm ($(wc -l < "$v2_asm") lines)"
echo "  v3c: $v3_asm ($(wc -l < "$v3_asm") lines)"
