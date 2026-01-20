// Test 30: var init + function call + pointer deref/store
// Expect exit code: 11
import io;
import util;

func main(argc, argv) {
    // Call + cast in var-init
    var mem = heap_alloc(24);
    var p = (*i64)mem;

    // Store through pointer
    *p = 7;
    *(p + 1) = 4;

    // Var-init from deref + pointer arithmetic
    var a = *p;
    var q = p + 1;
    var b = *q;

    return a + b;
}
