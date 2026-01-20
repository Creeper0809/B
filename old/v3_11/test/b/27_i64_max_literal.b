// Test 27: i64 max literal parsing
// Expect exit code: 0
import io;
import util;

func main(argc, argv) {
    var x;
    x = 9223372036854775807;

    // If overflow/wrap happened, x may become negative.
    if (x < 0) {
        return 1;
    }

    return 0;
}
