// Expect exit code: 0
// Covers: struct literals (simple, nested, multiple, expr, large, ptr, reassign)

struct Point {
    x: i64;
    y: i64;
}

struct Inner {
    a: i64;
    b: i64;
}

struct Outer {
    inner: Inner;
    c: i64;
}

struct Large {
    a: i64;
    b: i64;
    c: i64;
    d: i64;
    e: i64;
}

func main(argc, argv) {
    var p: Point = Point { 10, 32 };
    if (p.x + p.y != 42) { return 1; }

    var p_simple: Point;
    p_simple.x = 10;
    p_simple.y = 32;
    if (p_simple.x + p_simple.y != 42) { return 2; }

    var inner1: Inner = Inner { 10, 20 };
    var outer: Outer;
    outer.inner = inner1;
    outer.c = 12;
    if (outer.inner.a + outer.inner.b + outer.c != 42) { return 3; }

    var p1: Point = Point { 5, 10 };
    var p2: Point = Point { 15, 12 };
    if (p1.x + p1.y + p2.x + p2.y != 42) { return 4; }

    var a: i64 = 5;
    var b: i64 = 10;
    var p_expr: Point = Point { a * 2, b + 22 };
    if (p_expr.x + p_expr.y != 42) { return 5; }

    var l: Large = Large { 5, 10, 7, 15, 5 };
    if (l.a + l.b + l.c + l.d + l.e != 42) { return 6; }

    var ptr: *Point = &p;
    if (ptr->x + ptr->y != 42) { return 7; }

    var p3: Point = Point { 5, 10 };
    p3.x = 20;
    p3.y = 22;
    if (p3.x + p3.y != 42) { return 8; }

    return 0;
}
