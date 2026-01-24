// Covers: SysV ABI slice + stack args
// Mode: ssa
// Opt: O1
// Expect exit code: 51

func sum_mix(a: i64, b: i64, c: i64, d: i64, e: i64, s: []i64, f: i64) -> i64 {
    return a + b + c + d + e + s[0] + s[1] + f;
}

func main() -> i64 {
    var arr: [2]i64;
    arr[0] = 10;
    arr[1] = 20;
    return sum_mix(1, 2, 3, 4, 5, slice(arr, 2), 6);
}

