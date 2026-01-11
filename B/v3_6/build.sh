#!/bin/bash
# v3.6 Compiler Build Script
# Merges parts and compiles with v2c

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PARTS_DIR="$SCRIPT_DIR/parts"
BUILD_DIR="$ROOT_DIR/build"

echo "=== Building v3.6 Compiler ==="

# Merge all parts
MERGED="$BUILD_DIR/v3_6_merged.b"
cat "$PARTS_DIR"/*.b > "$MERGED"
echo "Merged $(wc -l < "$MERGED") lines into $MERGED"

# Compile with v2c
echo "Compiling with v2c..."
"$ROOT_DIR/bin/v2c" "$MERGED"

# Assemble
ASM_FILE="$BUILD_DIR/v3_6_merged.b.v2_out.asm"
OBJ_FILE="$BUILD_DIR/v3_6.o"
BIN_FILE="$ROOT_DIR/bin/v3_6"

echo "Assembling..."
nasm -f elf64 "$ASM_FILE" -o "$OBJ_FILE"

echo "Linking..."
ld "$OBJ_FILE" -o "$BIN_FILE"

echo "=== v3.6 Compiler built: $BIN_FILE ==="
echo ""
echo "Usage: $BIN_FILE <source.b36> > output.asm"
