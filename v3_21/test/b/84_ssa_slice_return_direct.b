// Expect exit code: 0
// Mode: ssa
// Opt: O1

func make_slice(p: *u8, n: i64) -> []u8 {
    return slice(p, n);
}

func get_first(s: []u8) -> u8 {
    return s[0];
}

func main() -> i64 {
    var arr: [3]u8;
    arr[0] = 42;
    arr[1] = 43;
    arr[2] = 44;

    // Test: use slice return directly in another function call
    var first: u8 = get_first(make_slice(arr, 3));
    if (first != 42) { return 1; }
    return 0;
}
