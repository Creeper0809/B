// Test 38: SSA global load/store
// Mode: ssa
// Expect exit code: 0

var g;
var h;

func inc(n: i64) -> i64 {
    g = g + n;
    return g;
}

func bump_h(n: i64) -> i64 {
    h = h + n;
    return h;
}

func main(argc, argv) {
    g = 0;
    h = 1;
    var a: i64 = inc(5);
    if (a != 5) { return 1; }
    var b: i64 = inc(3);
    if (b != 8) { return 1; }
    var c: i64 = bump_h(4);
    if (c != 5) { return 1; }
    return 0;
}
