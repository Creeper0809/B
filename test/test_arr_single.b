// Test single array assignment
func main() -> u64 {
    var arr: [3]u64;
    arr[$0] = 42;
    return arr[$0];
}
