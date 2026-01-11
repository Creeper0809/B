// str.b - String utilities for v3.8

import std.io;

func str_eq(s1, len1, s2, len2) {
    if (len1 != len2) { return 0; }
    var i;
    i = 0;
    while (i < len1) {
        if (*(*u8)(s1 + i) != *(*u8)(s2 + i)) { return 0; }
        i = i + 1;
    }
    return 1;
}

func str_copy(dst, src, len) {
    var i;
    i = 0;
    while (i < len) {
        *(*u8)(dst + i) = *(*u8)(src + i);
        i = i + 1;
    }
}

func str_len(s) {
    var i;
    i = 0;
    while (*(*u8)(s + i) != 0) {
        i = i + 1;
    }
    return i;
}

func str_concat(s1, len1, s2, len2) {
    var result;
    result = heap_alloc(len1 + len2 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    *(*u8)(result + len1 + len2) = 0;
    return result;
}

func str_concat3(s1, len1, s2, len2, s3, len3) {
    var result;
    result = heap_alloc(len1 + len2 + len3 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    str_copy(result + len1 + len2, s3, len3);
    *(*u8)(result + len1 + len2 + len3) = 0;
    return result;
}
