// Expect exit code: 150
// Mode: ssa
// Opt: O1

struct LargeStruct {
    a: i64;
    b: i64;
    c: i64;
    d: i64;
}

func make_large(a: i64, b: i64, c: i64, d: i64) -> LargeStruct {
    return LargeStruct { a, b, c, d };
}

func main() -> i64 {
    var ls: LargeStruct = make_large(10, 20, 30, 90);
    return ls.a + ls.b + ls.c + ls.d;
}
