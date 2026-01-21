// Covers: Slice return function chaining
// Mode: ssa
// Opt: O1
// Expect exit code: 6

func get_slice() -> []i64 {
    var arr: [2]i64;
    arr[0] = 1;
    arr[1] = 2;
    return slice(arr, 2);
}

func pass_slice(s: []i64) -> []i64 {
    return s;
}

func main() -> i64 {
    var s1: []i64 = get_slice();
    var s2: []i64 = pass_slice(s1);
    return s2[0] + s2[1] + s2[0] + s2[1];
}
