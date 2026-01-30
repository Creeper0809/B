// Test 56: O1 call-save liveness smoke
// Opt: O1
// Expect exit code: 0

import print_u64 from std.io;

func foo(x: u64) -> u64 {
    return x + 1;
}

func main() -> i64 {
    var a: u64 = 10;
    var b: u64 = foo(a);
    print_u64(b);
    return 0;
}
