// 78_struct_return_nested.b - Nested struct value return
// Expect exit code: 42

struct Inner {
    a: i64;
    b: i64;
}

// Note: Outer with nested Inner would be 16 bytes, at the limit
// This tests struct return with different struct types

func Inner_new(a: i64, b: i64) -> Inner {
    var i: Inner;
    i.a = a;
    i.b = b;
    return i;
}

func get_value() -> i64 {
    var inner: Inner = Inner_new(20, 22);
    return inner.a + inner.b;
}

func main() -> i64 {
    var result = get_value();
    if (result == 42) {
        return 42;
    }
    return 1;
}
