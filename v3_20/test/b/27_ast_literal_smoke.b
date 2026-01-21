// 99_ast_literal_smoke.b - ast_literal() struct refactor 회귀용
// Expect exit code: 42
// Mode: ssa
// Opt: O1

// 이 테스트는 컴파일러 내부(ast_literal) 변경이
// 기본 리터럴/연산/리턴 경로를 깨지 않는지만 확인한다.

func main(argc, argv) {
    return 40 + 2;
}
