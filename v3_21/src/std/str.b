// str.b - String utilities for v3.8
import std.io;
func str_eq(s1, len1, s2, len2) {
    if (len1 != len2) { return 0; }
    for(var i = 0; i<len1;i++){
         if (*(*u8)(s1 + i) != *(*u8)(s2 + i)) { return 0; }
    }
    return 1;
}

func str_copy(dst, src, len) {
    for(var i = 0; i < len; i++){
        *(*u8)(dst + i) = *(*u8)(src + i);
    }
}

func str_len(s) {
    var i = 0;
    for (; *(*u8)(s + i) != 0; i++) {
    }
    return i;
}

func str_concat(s1, len1, s2, len2) {
    var result = heap_alloc((len1 + len2 + 1) * sizeof(u8));
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    *(*u8)(result + len1 + len2) = 0;
    return result;
}

func str_concat3(s1, len1, s2, len2, s3, len3) {
    var result = heap_alloc((len1 + len2 + len3 + 1) * sizeof(u8));
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    str_copy(result + len1 + len2, s3, len3);
    *(*u8)(result + len1 + len2 + len3) = 0;
    return result;
}
