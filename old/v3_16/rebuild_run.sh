#!/bin/bash
# B 컴파일러 재빌드 후 테스트 파일 실행 스크립트

set -e  # 에러 발생 시 즉시 중단

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: ./rebuild_run.sh <file.b>"
    exit 1
fi

# config.ini에서 버전 설정 읽기
if [ -f "$SCRIPT_DIR/config.ini" ]; then
    source <(grep -E '^(VERSION|PREV_VERSION|STAGE)=' "$SCRIPT_DIR/config.ini")
else
    echo "❌ 에러: config.ini 파일을 찾을 수 없습니다."
    exit 1
fi

ROOT_DIR="$SCRIPT_DIR/../.."
BUILD_DIR="$ROOT_DIR/build"
BIN_DIR="$ROOT_DIR/bin"

SOURCE_FILE="$1"
BASE_NAME=$(basename "$SOURCE_FILE" .b)

echo "========================================="
echo "${VERSION} 재빌드 & 실행"
echo "========================================="
echo ""

# Step 1: 컴파일러 재빌드
echo "[1/2] ${VERSION} 재빌드 중..."
cd "$ROOT_DIR"

# 이전 버전으로 현재 버전 빌드
if [ -f "./bin/${PREV_VERSION}" ]; then
    echo "   (${PREV_VERSION} 사용)"
    ./bin/${PREV_VERSION} B/${VERSION}/src/main.b > build/${VERSION}.asm 2>/dev/null
else
    echo "❌ 에러: ${PREV_VERSION} 컴파일러를 찾을 수 없습니다."
    exit 1
fi

nasm -felf64 build/${VERSION}.asm -o build/${VERSION}.o
ld build/${VERSION}.o -o bin/${VERSION}_${STAGE}
echo "✅ ${VERSION}_${STAGE} 빌드 완료"
echo ""

# Step 2: 테스트 파일 실행
echo "[2/2] ${SOURCE_FILE} 실행 중..."

ASM_FILE="$BUILD_DIR/${BASE_NAME}.asm"
OBJ_FILE="$BUILD_DIR/${BASE_NAME}.o"
EXE_FILE="$BUILD_DIR/${BASE_NAME}"

# Convert source file to absolute path if relative
if [[ "$SOURCE_FILE" != /* ]]; then
    SOURCE_FILE="$PWD/$SOURCE_FILE"
fi

# Compile
echo "Compiling ${SOURCE_FILE}..."
./bin/${VERSION}_${STAGE} "$SOURCE_FILE" > "$ASM_FILE" 2>/dev/null
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
echo "Running ${EXE_FILE}..."
"$EXE_FILE"
EXIT_CODE=$?
echo ""
echo "Exit code: $EXIT_CODE"
