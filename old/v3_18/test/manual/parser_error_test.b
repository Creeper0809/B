// parser_error_test.b - 파서 에러를 강제로 발생시켜 스택 트레이스 확인

func main() {
    var x: u64 = 10
    // 세미콜론 누락 -> parse_consume에서 panic 발생할 것
    return 0;
}
