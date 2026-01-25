// Test 89: SSA pointer arithmetic scaling
// Mode: ssa
// Expect exit code: 0

func main(argc, argv) {
    var arr: [3]i64;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;

    var p: *i64 = arr;
    var q: *i64 = p + 1;
    if (*q != 20) { return 1; }

    var r: *i64 = p + 2;
    if (*r != 30) { return 2; }

    return 0;
}
