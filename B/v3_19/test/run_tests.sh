#!/bin/bash
# B Test Runner
# Runs all tests

set -e

# Load version from config.ini
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.ini"

# 프로젝트 루트로 이동 (B/<VERSION>/test -> B 루트)
ROOT_DIR="$SCRIPT_DIR/../../.."
cd "$ROOT_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.ini not found at $CONFIG_FILE"
    exit 1
fi

# Parse config.ini (simple key=value format)
source <(grep -E '^(VERSION|PREV_VERSION)=' "$CONFIG_FILE")

if [ -z "$VERSION" ]; then
    echo "Error: VERSION not set in config.ini"
    exit 1
fi

COMPILER="./bin/${VERSION}_stage1"
TEST_DIR="B/${VERSION}/test/b"
IR_TEST_DIR="B/${VERSION}/test/ir"
BUILD_DIR="build/${VERSION}_tests"
RESULTS_DIR="build/test_results"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$RESULTS_DIR"

# Counters
TOTAL=0
PASSED=0
FAILED=0

echo "========================================"
echo "${VERSION} Compiler Test Suite"
echo "========================================"
echo ""

# Find all test files (exclude module files)
TEST_FILES=$(ls $TEST_DIR/*.b 2>/dev/null | grep -E '/[0-9]+_' | sort -V)

if [ -z "$TEST_FILES" ]; then
    echo "No test files found in $TEST_DIR"
    exit 1
fi

for TEST_FILE in $TEST_FILES; do
    TOTAL=$((TOTAL + 1))
    TEST_NAME=$(basename "$TEST_FILE" .b)
    
    echo -n "[$TOTAL] Testing $TEST_NAME... "

    EXPECTED=$(grep -m1 -E '^// Expect exit code:' "$TEST_FILE" | sed -E 's/.*: *([0-9]+).*/\1/' || true)
    if [ -z "${EXPECTED}" ]; then
        EXPECTED=0
    fi
    
    ASM_FILE="$BUILD_DIR/${TEST_NAME}.asm"
    OBJ_FILE="$BUILD_DIR/${TEST_NAME}.o"
    BIN_FILE="$BUILD_DIR/${TEST_NAME}"
    OUT_FILE="$RESULTS_DIR/${TEST_NAME}.out"
    ERR_FILE="$RESULTS_DIR/${TEST_NAME}.err"
    
    IR_FLAG=""
    if grep -q -m1 -E '^// Mode: ssa' "$TEST_FILE"; then
        IR_FLAG="-dump-ssa"
    fi
    OPT_FLAG=""
    if grep -q -m1 -E '^// Opt: O1' "$TEST_FILE"; then
        OPT_FLAG="-O1"
    fi
    if ! $COMPILER $OPT_FLAG $IR_FLAG -asm "$TEST_FILE" 2>/dev/null > "$ASM_FILE"; then
        echo -e "${RED}FAIL (compile)${NC}"
        echo "Compilation failed" > "$ERR_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Assemble
    if ! nasm -f elf64 "$ASM_FILE" -o "$OBJ_FILE" 2>"$ERR_FILE"; then
        echo -e "${RED}FAIL (assemble)${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Link
    if ! ld "$OBJ_FILE" -o "$BIN_FILE" 2>>"$ERR_FILE"; then
        echo -e "${RED}FAIL (link)${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Run (compare exit code with expected)
    set +e
    timeout 5s "$BIN_FILE" > "$OUT_FILE" 2>&1
    EXIT_CODE=$?
    set -e

    if [ "$EXIT_CODE" -eq "$EXPECTED" ]; then
        echo -e "${GREEN}PASS${NC} (exit=$EXIT_CODE)"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (exit=$EXIT_CODE, expect=$EXPECTED)"
        FAILED=$((FAILED + 1))
    fi
done

IR_TEST_FILES=$(ls $IR_TEST_DIR/*.b 2>/dev/null | sort -V)
if [ -n "$IR_TEST_FILES" ]; then
    echo ""
    echo "========================================"
    echo "IR Dump Tests"
    echo "========================================"
    echo ""
fi

for TEST_FILE in $IR_TEST_FILES; do
    TOTAL=$((TOTAL + 1))
    TEST_NAME=$(basename "$TEST_FILE" .b)

    echo -n "[$TOTAL] IR $TEST_NAME... "

    SSA_OUT="$RESULTS_DIR/${TEST_NAME}.ssa.ir"
    ADDR_OUT="$RESULTS_DIR/${TEST_NAME}.3addr.ir"
    ERR_FILE="$RESULTS_DIR/${TEST_NAME}.ir.err"

    if ! $COMPILER -dump-ssa "$TEST_FILE" > "$SSA_OUT" 2>"$ERR_FILE"; then
        echo -e "${RED}FAIL${NC} (ssa dump)"
        FAILED=$((FAILED + 1))
        continue
    fi
    if ! grep -q "phi" "$SSA_OUT"; then
        echo -e "${RED}FAIL${NC} (ssa missing phi)"
        FAILED=$((FAILED + 1))
        continue
    fi
    if ! $COMPILER -dump-ir "$TEST_FILE" > "$ADDR_OUT" 2>>"$ERR_FILE"; then
        echo -e "${RED}FAIL${NC} (3addr dump)"
        FAILED=$((FAILED + 1))
        continue
    fi
    if grep -q "phi" "$ADDR_OUT"; then
        echo -e "${RED}FAIL${NC} (3addr has phi)"
        FAILED=$((FAILED + 1))
        continue
    fi

    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
done

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Total:  $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
