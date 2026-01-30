#!/bin/bash
# B 컴파일러 빌드 → 셀프 호스팅 → 테스트 자동화 스크립트

set -e  # 에러 발생 시 즉시 중단

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# config.ini에서 버전 설정 읽기
# ============================================
if [ -f "$SCRIPT_DIR/config.ini" ]; then
    source <(grep -E '^(VERSION|PREV_VERSION)=' "$SCRIPT_DIR/config.ini")
else
    echo "Error: config.ini file not found."
    exit 1
fi
ROOT_DIR="$SCRIPT_DIR/.."
BUILD_DIR="$ROOT_DIR/build"
BIN_DIR="$ROOT_DIR/bin"

# 버전별 경로
SRC_FILE="${VERSION}/src/main.b"
TEST_SCRIPT="${VERSION}/test/run_tests.sh"
BASE_COMPILER="${VERSION}_base"

echo "========================================="
echo "${VERSION} Build & Test Automation"
echo "========================================="
echo ""

# Step 1: 베이스 컴파일러로 빌드 (또는 이전 버전 사용)
echo "[1/5] Compiling ${VERSION}..."
cd "$ROOT_DIR"

# {VERSION}_base가 있으면 사용, 없으면 이전 버전 사용
if [ -f "./bin/${BASE_COMPILER}" ]; then
    echo "   (${BASE_COMPILER} used)"
    ./bin/${BASE_COMPILER} ${SRC_FILE} > build/${VERSION}_stage0.asm
elif [ -f "./bin/${PREV_VERSION}_stage1" ]; then
    echo "   (${PREV_VERSION}_stage1 used)"
    ./bin/${PREV_VERSION}_stage1 ${SRC_FILE} > build/${VERSION}_stage0.asm
elif [ -f "./bin/${PREV_VERSION}" ]; then
    echo "   (${PREV_VERSION} used)"
    ./bin/${PREV_VERSION} ${SRC_FILE} > build/${VERSION}_stage0.asm
else
    echo "Error: Base compiler not found."
    echo "   ${BASE_COMPILER}, ${PREV_VERSION}_stage1 or ${PREV_VERSION} is required."
    exit 1
fi
nasm -felf64 build/${VERSION}_stage0.asm -o build/${VERSION}_stage0.o
ld build/${VERSION}_stage0.o -o bin/${VERSION}_stage0
echo "Stage 0 Build Completed"
echo ""

# Step 2: 셀프 호스팅 (1단계)
echo "[2/5] Self-Hosting Stage 1..."
./bin/${VERSION}_stage0 -asm ${SRC_FILE} > build/${VERSION}_stage1.asm
nasm -felf64 build/${VERSION}_stage1.asm -o build/${VERSION}_stage1.o
ld build/${VERSION}_stage1.o -o bin/${VERSION}_stage1
echo "Stage 1 Build Completed"
echo ""

# Step 3: 셀프 호스팅 (2단계)
echo "[3/5] Self-Hosting Stage 2..."
./bin/${VERSION}_stage1 -asm ${SRC_FILE} > build/${VERSION}_stage2.asm
echo "Stage 2 Build Completed"
echo ""

# Step 4: ASM 비교 (1단계 vs 2단계)
echo "[4/5] Self-Hosting Verification..."
if diff -q build/${VERSION}_stage1.asm build/${VERSION}_stage2.asm > /dev/null; then
    echo "Self-Hosting Success! (Stage 1 == Stage 2)"
    echo "   ASM: $(wc -l < build/${VERSION}_stage1.asm) lines"
else
    echo "Self-Hosting Failed! ASM is different."
    echo "   Stage 1: $(wc -l < build/${VERSION}_stage1.asm) lines"
    echo "   Stage 2: $(wc -l < build/${VERSION}_stage2.asm) lines"
    exit 1
fi
echo ""

# Step 5: 테스트 실행
echo "[5/5] Running Tests..."
bash ${TEST_SCRIPT} bin/${VERSION}_stage1 2>&1 | tail -15

# Step 6: 바이너리(.out) 생성 (기본 실행 경로)
echo ""
    echo "[6/6] Generating Executable..."
rm -f out.s out.o a.out
BASE_NAME=$(basename "${SRC_FILE}" .b)
./bin/${VERSION}_stage1 ${SRC_FILE} >/dev/null
if [ -f "${BASE_NAME}.out" ]; then
    mv "${BASE_NAME}.out" build/${VERSION}.out
fi
rm -f "${BASE_NAME}.s" "${BASE_NAME}.o"

echo ""
echo "========================================="
echo "All tasks completed!"
echo "========================================="
echo ""
echo "Generated Files:"
echo "  - bin/${VERSION}_stage0 (Base Compiler)"
echo "  - bin/${VERSION}_stage1 (Self-Hosting Stage 1)"
echo "  - build/${VERSION}_stage*.asm (ASM Output)"
echo "  - build/${VERSION}.out (Executable)"
