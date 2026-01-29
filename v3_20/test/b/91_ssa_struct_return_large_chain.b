// Covers: SSA sret return from call + ignored sret call
// Mode: ssa
// Opt: O1
// Expect exit code: 46

struct LargeStruct {
    a: i64;
    b: i64;
    c: i64;
    d: i64;
}

func make_large(a: i64, b: i64, c: i64, d: i64) -> LargeStruct {
    return LargeStruct { a, b, c, d };
}

func forward_large(x: i64) -> LargeStruct {
    var t: LargeStruct = make_large(x, x + 1, x + 2, x + 3);
    return t;
}

func main() -> i64 {
    make_large(1, 2, 3, 4);
    var ls: LargeStruct = forward_large(10);
    return ls.a + ls.b + ls.c + ls.d;
}
