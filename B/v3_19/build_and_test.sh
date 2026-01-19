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
    echo "❌ 에러: config.ini 파일을 찾을 수 없습니다."
    exit 1
fi
ROOT_DIR="$SCRIPT_DIR/../.."
BUILD_DIR="$ROOT_DIR/build"
BIN_DIR="$ROOT_DIR/bin"

# 버전별 경로
SRC_FILE="B/${VERSION}/src/main.b"
TEST_SCRIPT="B/${VERSION}/test/run_tests.sh"
BASE_COMPILER="${VERSION}_base"

echo "========================================="
echo "${VERSION} 빌드 & 테스트 자동화"
echo "========================================="
echo ""

# Step 1: 베이스 컴파일러로 빌드 (또는 이전 버전 사용)
echo "[1/5] ${VERSION} 컴파일 중..."
cd "$ROOT_DIR"

# {VERSION}_base가 있으면 사용, 없으면 이전 버전 사용
if [ -f "./bin/${BASE_COMPILER}" ]; then
    echo "   (${BASE_COMPILER} 사용)"
    ./bin/${BASE_COMPILER} ${SRC_FILE} > build/${VERSION}_stage0.asm
elif [ -f "./bin/${PREV_VERSION}_stage1" ]; then
    echo "   (${PREV_VERSION}_stage1 사용)"
    ./bin/${PREV_VERSION}_stage1 ${SRC_FILE} > build/${VERSION}_stage0.asm
elif [ -f "./bin/${PREV_VERSION}" ]; then
    echo "   (${PREV_VERSION} 사용)"
    ./bin/${PREV_VERSION} ${SRC_FILE} > build/${VERSION}_stage0.asm
else
    echo "❌ 에러: 베이스 컴파일러를 찾을 수 없습니다."
    echo "   ${BASE_COMPILER}, ${PREV_VERSION}_stage1 또는 ${PREV_VERSION}이 필요합니다."
    exit 1
fi
nasm -felf64 build/${VERSION}_stage0.asm -o build/${VERSION}_stage0.o
ld build/${VERSION}_stage0.o -o bin/${VERSION}_stage0
echo "✅ Stage 0 빌드 완료"
echo ""

# Step 2: 셀프 호스팅 (1단계)
echo "[2/5] 셀프 호스팅 1단계..."
./bin/${VERSION}_stage0 -asm ${SRC_FILE} > build/${VERSION}_stage1.asm
nasm -felf64 build/${VERSION}_stage1.asm -o build/${VERSION}_stage1.o
ld build/${VERSION}_stage1.o -o bin/${VERSION}_stage1
echo "✅ Stage 1 빌드 완료"
echo ""

# Step 3: 셀프 호스팅 (2단계)
echo "[3/5] 셀프 호스팅 2단계..."
./bin/${VERSION}_stage1 -asm ${SRC_FILE} > build/${VERSION}_stage2.asm
echo "✅ Stage 2 빌드 완료"
echo ""

# Step 4: ASM 비교 (1단계 vs 2단계)
echo "[4/5] 셀프 호스팅 검증 중..."
if diff -q build/${VERSION}_stage1.asm build/${VERSION}_stage2.asm > /dev/null; then
    echo "✅ 셀프 호스팅 성공! (Stage 1 == Stage 2)"
    echo "   ASM: $(wc -l < build/${VERSION}_stage1.asm) lines"
else
    echo "❌ 셀프 호스팅 실패! ASM이 다릅니다."
    echo "   Stage 1: $(wc -l < build/${VERSION}_stage1.asm) lines"
    echo "   Stage 2: $(wc -l < build/${VERSION}_stage2.asm) lines"
    exit 1
fi
echo ""

# Step 5: 테스트 실행
echo "[5/5] 테스트 실행 중..."
bash ${TEST_SCRIPT} bin/${VERSION}_stage1 2>&1 | tail -15

# Step 6: 바이너리(.out) 생성 (기본 실행 경로)
echo ""
echo "[6/6] 실행 바이너리 생성 중..."
rm -f out.s out.o a.out
BASE_NAME=$(basename "${SRC_FILE}" .b)
./bin/${VERSION}_stage1 ${SRC_FILE} >/dev/null
if [ -f "${BASE_NAME}.out" ]; then
    mv "${BASE_NAME}.out" build/${VERSION}.out
fi
rm -f "${BASE_NAME}.s" "${BASE_NAME}.o"

echo ""
echo "========================================="
echo "✅ 모든 작업 완료!"
echo "========================================="
echo ""
echo "생성된 파일:"
echo "  - bin/${VERSION}_stage0 (베이스 컴파일러로 빌드)"
echo "  - bin/${VERSION}_stage1 (셀프 호스팅 1단계)"
echo "  - build/${VERSION}_stage*.asm (ASM 출력)"
echo "  - build/${VERSION}.out (실행 바이너리)"
