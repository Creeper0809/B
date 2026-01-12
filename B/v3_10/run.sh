#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: ./run.sh <file.b>"
    exit 1
fi

SOURCE_FILE="$1"
BASE_NAME=$(basename "$SOURCE_FILE" .b)

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
BUILD_DIR="$ROOT_DIR/build"

ASM_FILE="$BUILD_DIR/${BASE_NAME}.asm"
OBJ_FILE="$BUILD_DIR/${BASE_NAME}.o"
EXE_FILE="$BUILD_DIR/${BASE_NAME}"

# Create build directory if not exists
mkdir -p "$BUILD_DIR"

# Convert source file to absolute path if relative
if [[ "$SOURCE_FILE" != /* ]]; then
    SOURCE_FILE="$PWD/$SOURCE_FILE"
fi

# Change to root directory (where B/v3_10/src exists)
cd "$ROOT_DIR"

# Compile
echo "Compiling ${SOURCE_FILE}..."
./bin/v3_10_stage1 "$SOURCE_FILE" > "$ASM_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi

# Assemble
nasm -f elf64 "$ASM_FILE" -o "$OBJ_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Assembly failed"
    exit 1
fi

# Link
ld "$OBJ_FILE" -o "$EXE_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Linking failed"
    exit 1
fi

# Run
echo "Running ${BASE_NAME}..."
echo "---"
"$EXE_FILE"
EXIT_CODE=$?
echo "---"
echo "Exit code: $EXIT_CODE"
