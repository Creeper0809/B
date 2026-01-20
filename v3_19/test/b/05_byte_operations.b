// Test 05: Byte/String Operations
// Expect exit code: 0

import std.io;
import std.str;

func main(argc, argv) {
    var buf;
    var i;

    buf = heap_alloc(10);
    i = 0;
    while (i < 10) {
        *(*u8)(buf + i) = 65 + i;  // 'A'..'J'
        i = i + 1;
    }

    var sum = 0;
    i = 0;
    while (i < 10) {
        sum = sum + *(*u8)(buf + i);
        i = i + 1;
    }
    if (sum != 695) { return 1; } // 65..74 합

    var s1 = "Hello";
    var s2 = " World!";
    var len1 = str_len(s1);
    var len2 = str_len(s2);
    if (len1 != 5) { return 2; }
    if (len2 != 7) { return 3; }

    var s3 = str_concat(s1, len1, s2, len2);
    if (!str_eq(s3, 12, "Hello World!", 12)) { return 4; }
    if (!str_eq(s1, len1, "Hello", 5)) { return 5; }
    if (str_eq(s1, len1, "World", 5)) { return 6; }

    return 0;
}
