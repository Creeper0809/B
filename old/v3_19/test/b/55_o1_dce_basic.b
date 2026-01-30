// Test 55: O1 dead code elimination
// Opt: O1
// Expect exit code: 0

func main() -> i64 {
    var a: u64 = 10;
    var b: u64 = a + 20; // should be removable if unused
    var c: u64 = 0;      // should be removable if unused
    return 0;
}
