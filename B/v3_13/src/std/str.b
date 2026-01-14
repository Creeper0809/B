// str.b - String utilities for v3.8

import std.io;

func str_eq(s1: *u64, len1: u64, s2: *u64, len2: u64) -> u64 {
    if (len1 != len2) { return 0; }
    for (var i: u64 = 0; i<len1;i++){
         if (*(*u8)(s1 + i) != *(*u8)(s2 + i)) { return 0; }
    }
    return 1;
}

func str_copy(dst: *u64, src: *u64, len: u64) -> *u64 {
    for (var i: u64 = 0; i < len; i++){
        *(*u8)(dst + i) = *(*u8)(src + i);
    }
}

func str_len(s: *u64) -> u64 {
    var i: u64 = 0;
    while (*(*u8)(s + i) != 0) {
        i = i + 1;
    }
    return i;
}

func str_concat(s1: *u64, len1: u64, s2: *u64, len2: u64) -> *u64 {
    var result: *u64 = heap_alloc(len1 + len2 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    *(*u8)(result + len1 + len2) = 0;
    return result;
}

func str_concat3(s1: *u64, len1: u64, s2: *u64, len2: u64, s3: *u64, len3: u64) -> *u64 {
    var result: *u64 = heap_alloc(len1 + len2 + len3 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    str_copy(result + len1 + len2, s3, len3);
    *(*u8)(result + len1 + len2 + len3) = 0;
    return result;
}
