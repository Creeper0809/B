#!/bin/bash
# v3.6 Compiler Test Runner

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
V36="$ROOT_DIR/bin/v3_6"
TEST_DIR="$ROOT_DIR/test/v3_6"
BUILD_DIR="$ROOT_DIR/build"

echo "=== v3.6 Compiler Tests ==="
echo ""

run_test() {
    local name="$1"
    local expected="$2"
    local src="$TEST_DIR/${name}.b36"
    local asm="$BUILD_DIR/${name}.asm"
    local obj="$BUILD_DIR/${name}.o"
    local bin="$BUILD_DIR/${name}"
    
    echo -n "Testing $name... "
    
    # Compile (stdout only to asm, stderr to terminal)
    "$V36" "$src" > "$asm"
    
    # Assemble and link
    nasm -f elf64 "$asm" -o "$obj"
    ld "$obj" -o "$bin"
    
    # Run and check result
    set +e
    "$bin"
    local result=$?
    set -e
    
    if [ "$result" -eq "$expected" ]; then
        echo "PASS (got $result)"
    else
        echo "FAIL (expected $expected, got $result)"
        return 1
    fi
}

# Run tests
run_test "sum" 55
run_test "pointer" 42
run_test "factorial" 120
run_test "funcs" 14

echo ""
echo "=== All tests passed! ==="
