#!/usr/bin/env bash
# v3c_full이 기존 테스트를 모두 통과하는지 확인
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
V3C="$ROOT/bin/v3c_full"
OUT="$ROOT/build"

passed=0
failed=0

for test_file in "$ROOT"/test/v3h_*.b; do
    name=$(basename "$test_file" .b)
    asm="$OUT/${name}.v3c.asm"
    bin="$OUT/${name}.v3c_bin"
    
    # 컴파일
    if ! $V3C "$test_file" > "$asm" 2>&1; then
        echo "✗ $name: compile failed"
        failed=$((failed + 1))
        continue
    fi
    
    # 어셈블 + 링크
    if ! nasm -f elf64 -o "$OUT/${name}.o" "$asm" 2>/dev/null; then
        echo "✗ $name: assemble failed"
        failed=$((failed + 1))
        continue
    fi
    
    if ! ld -o "$bin" "$OUT/${name}.o" 2>/dev/null; then
        echo "✗ $name: link failed"
        failed=$((failed + 1))
        continue
    fi
    
    # 실행
    expected="$ROOT/build/${name}.stdout"
    if [[ -f "$expected" ]]; then
        actual=$("$bin" 2>&1 || true)
        expected_content=$(cat "$expected")
        if [[ "$actual" == "$expected_content" ]]; then
            echo "✓ $name"
            passed=$((passed + 1))
        else
            echo "✗ $name: output mismatch"
            failed=$((failed + 1))
        fi
    else
        # 그냥 실행만 확인
        if "$bin" >/dev/null 2>&1; then
            echo "✓ $name (no expected output)"
            passed=$((passed + 1))
        else
            echo "✗ $name: runtime error"
            failed=$((failed + 1))
        fi
    fi
done

echo ""
echo "=== Results: $passed passed, $failed failed ==="
