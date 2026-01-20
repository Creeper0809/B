// Test 26: Short-circuit must prevent crashy RHS
// Expect exit code: 0
import io;
import util;

func crash() {
    // If this runs, the process should segfault.
    *(*i64)0 = 123;
    return 1;
}

func main(argc, argv) {
    // Must NOT evaluate crash()
    if (false && crash()) {
        return 1;
    }

    // Must NOT evaluate crash()
    if (true || crash()) {
        // ok
    }

    return 0;
}
