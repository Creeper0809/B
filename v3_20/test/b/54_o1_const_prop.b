// Test 54: O1 const propagation
// Opt: O1
// Expect exit code: 0

func main() -> i64 {
    var a: u64 = 10;
    var b: u64 = a + 10 + 20;
    if (b != 40) { return 1; }
    return 0;
}
