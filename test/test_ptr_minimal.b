// 최소 포인터 역참조 테스트

func main() -> u64 {
    var val: u64 = 42;
    var p: *u64 = &val;
    *p = 100;
    return val;
}
