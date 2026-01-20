// Test 29: var init + pointer arithmetic scaling
// Expect exit code: 8
import io;
import util;

func main(argc, argv) {
    var mem = heap_alloc(16);
    var p = (*i64)mem;

    *p = 3;
    *(p + 1) = 5;

    var a = *p;
    var b = *(p + 1);
    return a + b;
}
