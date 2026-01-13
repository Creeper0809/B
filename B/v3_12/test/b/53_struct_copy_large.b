// 53_struct_copy_large.b - 큰 구조체 값 복사
// Expect exit code: 42

struct Large {
    a: i64;
    b: i64;
    c: i64;
    d: i64;
    e: i64;
}

func main(argc, argv) {
    var l1: Large = Large { 5, 10, 7, 15, 5 };
    var l2: Large;
    
    // 큰 구조체 복사
    l2 = l1;
    
    // l2.a + l2.b + l2.c + l2.d + l2.e = 5 + 10 + 7 + 15 + 5 = 42
    return l2.a + l2.b + l2.c + l2.d + l2.e;
}
