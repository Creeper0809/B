// mem.b - Memory utilities for v3.16

func memset(dst, value, len) {
    var v = value & 255;
    for (var i = 0; i < len; i++) {
        *(*u8)(dst + i) = v;
    }
    return dst;
}
