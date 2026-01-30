// Expect exit code: 0
// Mode: ssa
// Opt: O1
// Covers: struct member/ptr/nested/multiple/function/loop/linked list/large struct

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

struct Color {
    r: i64;
    g: i64;
    b: i64;
}

struct Data {
    value: i64;
    flag: i64;
}

struct Node {
    value: i64;
    next: *Node;
}

struct BigData {
    f0: i64;
    f1: i64;
    f2: i64;
    f3: i64;
    f4: i64;
    f5: i64;
    f6: i64;
    f7: i64;
    f8: i64;
    f9: i64;
}

func set_point(p: *Point, x_val: i64, y_val: i64) {
    p->x = x_val;
    p->y = y_val;
}

func get_sum(p: *Point) -> i64 {
    return p->x + p->y;
}

func main(argc, argv) {
    var p: Point;
    p.x = 10;
    p.y = 32;
    if (p.x + p.y != 42) { return 1; }

    var ptr: *Point;
    ptr = &p;
    ptr->x = 20;
    ptr->y = 22;
    if (ptr->x + ptr->y != 42) { return 2; }

    var outer: Outer;
    outer.inner.a = 10;
    outer.inner.b = 15;
    outer.c = 17;
    if (outer.inner.a + outer.inner.b + outer.c != 42) { return 3; }

    var p2: Point;
    var c: Color;
    p2.x = 10;
    p2.y = 12;
    c.r = 5;
    c.g = 7;
    c.b = 8;
    if (p2.x + p2.y + c.r + c.g + c.b != 42) { return 4; }

    var p3: Point;
    var p3_ptr: *Point;
    p3_ptr = &p3;
    set_point(p3_ptr, 20, 22);
    if (get_sum(p3_ptr) != 42) { return 5; }

    var p0: Point;
    var p1: Point;
    var p4: Point;
    p0.x = 5;  p0.y = 7;
    p1.x = 10; p1.y = 12;
    p4.x = 3;  p4.y = 5;
    if (p0.x + p0.y + p1.x + p1.y + p4.x + p4.y != 42) { return 6; }

    var d1: Data;
    var d2: Data;
    var d3: Data;
    d1.value = 0; d1.flag = 1;
    d2.value = 0; d2.flag = 1;
    d3.value = 0; d3.flag = 1;

    for (var i = 0; i < 10; i = i + 1) {
        if (d1.flag) { d1.value = d1.value + 1; }
    }
    for (var i = 0; i < 15; i = i + 1) {
        if (d2.flag) { d2.value = d2.value + 1; }
    }
    for (var i = 0; i < 17; i = i + 1) {
        if (d3.flag) { d3.value = d3.value + 1; }
    }
    if (d1.value + d2.value + d3.value != 42) { return 7; }

    var n1: Node;
    var n2: Node;
    var n3: Node;
    n1.value = 10;
    n2.value = 15;
    n3.value = 17;
    n1.next = &n2;
    n2.next = &n3;
    n3.next = 0;

    var sum: i64 = 0;
    var current: *Node = &n1;
    while (current != 0) {
        sum = sum + current->value;
        current = current->next;
    }
    if (sum != 42) { return 8; }

    var big: BigData;
    var big_ptr: *BigData = &big;
    big_ptr->f0 = 1;
    big_ptr->f1 = 2;
    big_ptr->f2 = 3;
    big_ptr->f3 = 4;
    big_ptr->f4 = 5;
    big_ptr->f5 = 6;
    big_ptr->f6 = 7;
    big_ptr->f7 = 8;
    big_ptr->f8 = 4;
    big_ptr->f9 = 2;

    var big_sum = big.f0 + big.f1 + big.f2 + big.f3 + big.f4;
    big_sum = big_sum + big.f5 + big.f6 + big.f7 + big.f8 + big.f9;
    if (big_sum != 42) { return 9; }

    return 0;
}
