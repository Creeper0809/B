// Expect exit code: 0
// Mode: ssa
// Opt: O1
// Covers: struct return (basic, nested, chain, conditional, multi-type, complex, stress)

struct Point {
    x: i64;
    y: i64;
}

struct Inner {
    a: i64;
    b: i64;
}

struct Vec2 {
    x: i64;
    y: i64;
}

struct Color {
    r: i64;
    g: i64;
}

struct Pair {
    first: i64;
    second: i64;
}

struct Data {
    x: i64;
    y: i64;
}

func Point_new(x: i64, y: i64) -> Point {
    var p: Point;
    p.x = x;
    p.y = y;
    return p;
}

func Point_sum(p: *Point) -> i64 {
    return p->x + p->y;
}

func Point_add(a: *Point, b: *Point) -> Point {
    var result: Point;
    result.x = a->x + b->x;
    result.y = a->y + b->y;
    return result;
}

func Point_scale(p: *Point, factor: i64) -> Point {
    var result: Point;
    result.x = p->x * factor;
    result.y = p->y * factor;
    return result;
}

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

func Vec2_new(x: i64, y: i64) -> Vec2 {
    var v: Vec2;
    v.x = x;
    v.y = y;
    return v;
}

func get_vec(choice: i64) -> Vec2 {
    if (choice == 1) {
        return Vec2_new(10, 20);
    } else if (choice == 2) {
        return Vec2_new(30, 40);
    }
    return Vec2_new(5, 7);
}

func Color_new(r: i64, g: i64) -> Color {
    var c: Color;
    c.r = r;
    c.g = g;
    return c;
}

func compute(p: *Point, c: *Color) -> i64 {
    return p->x + p->y + c->r + c->g;
}

func Pair_new(a: i64, b: i64) -> Pair {
    var p: Pair;
    p.first = a;
    p.second = b;
    return p;
}

func Pair_swap(p: *Pair) -> Pair {
    return Pair_new(p->second, p->first);
}

func fibonacci_pair(n: i64) -> Pair {
    if (n == 0) { return Pair_new(0, 1); }
    if (n == 1) { return Pair_new(1, 1); }
    var prev: Pair = fibonacci_pair(n - 1);
    return Pair_new(prev.second, prev.first + prev.second);
}

func Data_new(x: i64, y: i64) -> Data {
    var d: Data;
    d.x = x;
    d.y = y;
    return d;
}

func Data_transform(d: *Data, op: i64) -> Data {
    if (op == 1) { return Data_new(d->x + 1, d->y + 1); }
    if (op == 2) { return Data_new(d->x * 2, d->y * 2); }
    if (op == 3) { return Data_new(d->x - d->y, d->y - d->x); }
    return Data_new(d->x, d->y);
}

func main() -> i64 {
    var p1: Point = Point_new(10, 20);
    if (Point_sum(&p1) != 30) { return 1; }

    if (get_value() != 42) { return 2; }

    var a: Point = Point_new(5, 10);
    var b: Point = Point_new(3, 7);
    var sum: Point = Point_add(&a, &b);  // (8, 17)
    var scaled: Point = Point_scale(&sum, 2); // (16, 34)
    if (scaled.x + scaled.y != 50) { return 3; }

    var v1: Vec2 = get_vec(1);
    var v2: Vec2 = get_vec(2);
    var v3: Vec2 = get_vec(3);
    var v_sum = v1.x + v1.y + v2.x + v2.y + v3.x + v3.y;
    if (v_sum != 112) { return 4; }

    var c1: Color = Color_new(100, 200);
    var c2: Color = Color_new(50, 75);
    var total = compute(&a, &c1) + compute(&b, &c2);
    if (total != 450) { return 5; }

    var p2: Pair = Pair_new(10, 20);
    var p3: Pair = Pair_swap(&p2);
    if (p3.first != 20 || p3.second != 10) { return 6; }

    var fib: Pair = fibonacci_pair(5);
    if (fib.first != 5) { return 7; }

    var data: Data = Data_new(5, 3);
    var sum_all = 0;
    for (var i = 0; i < 10; i = i + 1) {
        var op = (i % 3) + 1;
        data = Data_transform(&data, op);
        sum_all = sum_all + data.x + data.y;
    }
    if (sum_all == 0) { return 8; }

    return 0;
}
