// Expect exit code: 0
// Covers: struct copy, nested copy, ptr copy, deep nested, mixed scenarios

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

struct Data {
    value: i64;
}

struct Container {
    ptr: *Data;
    multiplier: i64;
}

struct Container2 {
    ptr: *Data;
    offset: i64;
}

struct Level3 {
    val: i64;
}

struct Level2 {
    l3: Level3;
    offset: i64;
}

struct Level1 {
    l2: Level2;
    multiplier: i64;
}

struct PointRef {
    ref: *Point;
}

struct Wrapper {
    data: Data;
    ptr: *Data;
    multiplier: i64;
}

func main(argc, argv) {
    var p1: Point = Point { 10, 32 };
    var p2: Point;
    p2 = p1;
    if (p2.x + p2.y != 42) { return 1; }

    var inner1: Inner = Inner { 10, 20 };
    var outer: Outer;
    outer.inner = inner1;
    outer.c = 12;
    if (outer.inner.a + outer.inner.b + outer.c != 42) { return 2; }

    var p3: Point = Point { 5, 10 };
    var p4: Point;
    var p5: Point;
    p4 = p3;
    p5 = p4;
    p5.x = 20;
    p5.y = 22;
    if (p3.x + p3.y != 15) { return 3; }
    if (p5.x + p5.y != 42) { return 4; }

    var l1: Large = Large { 5, 10, 7, 15, 5 };
    var l2: Large;
    l2 = l1;
    if (l2.a + l2.b + l2.c + l2.d + l2.e != 42) { return 5; }

    var o1: Outer;
    o1.inner.a = 10;
    o1.inner.b = 20;
    o1.c = 12;
    var o2: Outer;
    o2 = o1;
    o2.inner.a = 100;
    o2.inner.b = 200;
    o2.c = 120;
    if (o1.inner.a + o1.inner.b + o1.c != 42) { return 6; }

    var p6: Point = Point { 10, 32 };
    var p7: Point;
    var ptr1: *Point = &p6;
    var ptr2: *Point = &p7;
    *ptr2 = *ptr1;
    if (p7.x + p7.y != 42) { return 7; }

    var d: Data;
    d.value = 21;
    var c: Container;
    c.ptr = &d;
    c.multiplier = 2;
    if (c.ptr->value * c.multiplier != 42) { return 8; }

    var d2: Data;
    d2.value = 30;
    var c1: Container2;
    c1.ptr = &d2;
    c1.offset = 12;
    var c2: Container2;
    c2 = c1;
    if (c2.ptr->value + c2.offset != 42) { return 9; }

    var s: Level1;
    s.l2.l3.val = 7;
    s.l2.offset = 8;
    s.multiplier = 3;
    var s2: Level1;
    s2 = s;
    s2.l2.l3.val = 100;
    if ((s.l2.l3.val + s.l2.offset) * s.multiplier - 3 != 42) { return 10; }

    var p8: Point = Point { 5, 10 };
    var r1: PointRef;
    r1.ref = &p8;
    var r2: PointRef;
    r2 = r1;
    r2.ref->x = 20;
    r2.ref->y = 22;
    if (p8.x + p8.y != 42) { return 11; }

    var d3: Data = Data { 5 };
    var d4: Data = Data { 10 };
    var w: Wrapper;
    w.data = d3;
    w.ptr = &d4;
    w.multiplier = 2;
    var result: i64 = w.data.value * w.multiplier + w.ptr->value * w.multiplier;
    if (result + 12 != 42) { return 12; }

    return 0;
}
