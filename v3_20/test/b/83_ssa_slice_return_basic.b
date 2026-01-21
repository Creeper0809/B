// Covers: Slice return basic functionality
// Mode: ssa
// Opt: O1
// Expect exit code: 6

func get_slice() -> []i64 {
    var arr: [3]i64;
    arr[0] = 1;
    arr[1] = 2;
    arr[2] = 3;
    return slice(arr, 3);
}

func main() -> i64 {
    var s: []i64 = get_slice();
    return s[0] + s[1] + s[2];
}
