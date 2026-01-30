// Test 04: Pointer Suite (basics/arithmetic/var-init)
// Expect exit code: 0

import std.io;

func main(argc, argv) {
    var x;
    var ptr;

    x = 42;
    ptr = &x;
    if (*ptr != 42) { return 1; }

    *ptr = 100;
    if (x != 100) { return 2; }

    // Pointer arithmetic (byte offset)
    var mem = heap_alloc(40);
    var arr = mem;
    var i = 0;
    while (i < 5) {
        *(arr + i * 8) = (i + 1) * 10;
        i = i + 1;
    }

    var sum = 0;
    i = 0;
    while (i < 5) {
        sum = sum + *(arr + i * 8);
        i = i + 1;
    }
    if (sum != 150) { return 3; }

    // var init + pointer deref
    var mem2 = heap_alloc(16);
    var p = mem2;
    *p = 3;
    *(p + 8) = 5;
    var a = *p;
    var b = *(p + 8);
    if (a + b != 8) { return 4; }

    // var init + call + pointer deref
    var mem3 = heap_alloc(24);
    var q = mem3;
    *q = 7;
    *(q + 8) = 4;
    var c = *q;
    var r = q + 8;
    var d = *r;
    if (c + d != 11) { return 5; }

    return 0;
}
