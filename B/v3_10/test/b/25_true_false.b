// Test 25: true/false keywords
// Expect exit code: 1
import io;
import util;

func main(argc, argv) {
    var x;
    x = 0;

    if (true) {
        x = x + 1;
    }

    if (false) {
        x = 99;
    }

    // Combined with short-circuit
    if (true && false) {
        x = 123;
    }

    if (false || true) {
        x = x + 0;
    }

    return x;
}
