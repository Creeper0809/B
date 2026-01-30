// Test 57: single-symbol import smoke
// Opt: O1
// Expect exit code: 0

import print_u64 from std.io;

func main() -> i64 {
    print_u64(123);
    return 0;
}
