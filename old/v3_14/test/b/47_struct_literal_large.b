// 47_struct_literal_large.b - 큰 구조체 리터럴
// Expect exit code: 42

struct Large {
    a: i64;
    b: i64;
    c: i64;
    d: i64;
    e: i64;
}

func main(argc, argv) {
    var l: Large = Large { 5, 10, 7, 15, 5 };
    
    // a + b + c + d + e = 5 + 10 + 7 + 15 + 5 = 42
    return l.a + l.b + l.c + l.d + l.e;
}
