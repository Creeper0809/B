cmake_minimum_required(VERSION 3.16)
project(B_Compiler C CXX)

# 프로젝트 정보
set(PROJECT_VERSION "3.0.0")
set(CMAKE_C_STANDARD 11)

# 빌드 타입 설정
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build." FORCE)
endif()

# 플랫폼 감지
if(WIN32)
    set(TARGET_OS "windows")
    set(EXECUTABLE_SUFFIX ".exe")
else()
    set(TARGET_OS "linux")
    set(EXECUTABLE_SUFFIX "")
endif()

message(STATUS "Building for ${TARGET_OS}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# v2 컴파일러 경로 (기존 바이너리)
set(V2C_COMPILER "${CMAKE_SOURCE_DIR}/bin/v2c${EXECUTABLE_SUFFIX}")

# v3 소스 파일 목록
set(V3_SOURCES
    src/v3_hosted/main.b
    src/v3_hosted/lexer.b
    src/v3_hosted/parser.b
    src/v3_hosted/token.b
    src/v3_hosted/ast.b
    src/v3_hosted/typecheck.b
    src/v3_hosted/ir.b
    src/v3_hosted/lowering.b
    src/v3_hosted/codegen.b
    src/v3_hosted/driver.b
)

# 빌드 디렉토리
set(BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
file(MAKE_DIRECTORY ${BUILD_DIR})

# 커스텀 타겟: v3 컴파일러 빌드 (v2c 사용)
# 주의: v2c는 .b 파일을 어셈블리로 변환 후 바이너리 생성
add_custom_target(v3_compiler ALL
    COMMENT "Building v3 compiler with v2c"
    DEPENDS ${V3_SOURCES}
)

# v2c로 v3 main.b 컴파일
add_custom_command(
    TARGET v3_compiler
    COMMAND ${V2C_COMPILER} ${CMAKE_SOURCE_DIR}/src/v3_hosted/main.b
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Compiling v3 with v2c..."
    VERBATIM
)

# 생성된 바이너리를 bin/v3c로 복사
add_custom_command(
    TARGET v3_compiler POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        ${BUILD_DIR}/main.b.v2_out_bin${EXECUTABLE_SUFFIX}
        ${CMAKE_SOURCE_DIR}/bin/v3c${EXECUTABLE_SUFFIX}
    COMMENT "Installing v3c to bin/"
    VERBATIM
)

# 설치 타겟
install(PROGRAMS ${CMAKE_SOURCE_DIR}/bin/v3c${EXECUTABLE_SUFFIX}
        DESTINATION bin)

# 테스트 타겟 (선택 사항)
enable_testing()

# Golden test 실행
add_test(NAME lexer_golden
    COMMAND bash ${CMAKE_SOURCE_DIR}/test/v3_hosted/run_lexer_golden.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

add_test(NAME parser_golden
    COMMAND bash ${CMAKE_SOURCE_DIR}/test/v3_hosted/run_parser_golden.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

add_test(NAME codegen_golden
    COMMAND bash ${CMAKE_SOURCE_DIR}/test/v3_hosted/run_codegen_golden.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# 정보 출력
message(STATUS "")
message(STATUS "B Compiler Build Configuration")
message(STATUS "================================")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Target OS: ${TARGET_OS}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "V2C compiler: ${V2C_COMPILER}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
message(STATUS "Build commands:")
message(STATUS "  cmake -B build")
message(STATUS "  cmake --build build")
message(STATUS "  cmake --build build --target test")
message(STATUS "")
