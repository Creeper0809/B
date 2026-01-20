// Test 24: Short-circuit (&&, ||)
// Expect exit code: 1
import std.io;
import std.emit;

func bump(p) {
    *p = *p + 1;
    return 1;
}

func main(argc, argv) {
    var x;
    x = 0;

    // RHS must NOT run
    if (0 && bump(&x)) {
        // unreachable
        x = 99;
    }

    // RHS must NOT run
    if (1 || bump(&x)) {
        // should still enter, but without bump
    }

    // RHS must run once
    if (0 || bump(&x)) {
        // bump executed
    }

    // Now x should be exactly 1.
    // Return it as exit code.
    return x;
}
