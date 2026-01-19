// Test 35: SSA addr/deref/index/member
// Mode: ssa
// Expect exit code: 0

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var arr: [4]i64;
    arr[0] = 10;
    arr[1] = 20;

    var p: Point;
    p.x = arr[0];
    p.y = arr[1];

    var ptr: *i64 = &arr[1];
    var v = *ptr;

    if (p.x + p.y + v != 50) { return 1; }
    return 0;
}
