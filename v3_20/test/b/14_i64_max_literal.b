// Test 14: i64 max literal parsing
// Expect exit code: 0
// Mode: ssa
// Opt: O1
import std.io;
import std.emit;

func main(argc, argv) {
    var x;
    x = 9223372036854775807;

    // If overflow/wrap happened, x may become negative.
    if (x < 0) {
        return 1;
    }

    return 0;
}
