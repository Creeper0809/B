// Expect exit code: 0
// Covers: array/char/slice/array param/return/tagged pointer/packed bitfields

import std.io;

struct Holder {
    arr: [3]i64;
    s: []i64;
}

packed struct TaggedPtrBits {
    tag: u16;
}

packed struct Bits {
    ver: u4;
    id: u12;
}

func test_array_basic() -> i64 {
    var arr: [5]i64;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    var sum = arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
    if (sum != 150) { return 1; }

    arr[2] = 100;
    if (arr[2] != 100) { return 2; }

    return 0;
}

func test_char_type() -> i64 {
    var a: char = 65;
    var b: char = 66;

    if (a != 65) { return 10; }
    if (b != 66) { return 11; }

    var sum: i64 = a + b;
    if (sum != 131) { return 12; }

    return 0;
}

func test_char_array() -> i64 {
    var str: [6]char;

    str[0] = 72;
    str[1] = 101;
    str[2] = 108;
    str[3] = 108;
    str[4] = 111;
    str[5] = 0;

    if (str[0] != 72) { return 20; }
    if (str[4] != 111) { return 21; }

    var sum: i64 = 0;
    var i = 0;
    for (i = 0; i < 5; i = i + 1) {
        sum = sum + str[i];
    }
    if (sum != 500) { return 22; }

    return 0;
}

func test_multidim_simulation() -> i64 {
    var matrix: [9]i64;

    var val = 1;
    var i = 0;
    for (i = 0; i < 9; i = i + 1) {
        matrix[i] = val;
        val = val + 1;
    }

    if (matrix[5] != 6) { return 30; }

    var diag_sum = matrix[0] + matrix[4] + matrix[8];
    if (diag_sum != 15) { return 31; }

    return 0;
}

func test_nested_array_access() -> i64 {
    var arr: [10]i64;

    var i = 0;
    for (i = 0; i < 10; i = i + 1) {
        arr[i] = i * 10;
    }

    var idx = 5;
    if (arr[idx] != 50) { return 40; }

    arr[0] = 3;
    var nested_idx = arr[0];
    if (arr[nested_idx] != 30) { return 41; }

    return 0;
}

func test_slice_basic() -> i64 {
    var arr: [5]i64;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    var p: *i64 = arr;
    var s: []i64 = slice(p, 5);

    if (s[0] != 10) { return 50; }
    if (s[4] != 50) { return 51; }

    var sum = 0;
    var i = 0;
    for (i = 0; i < 5; i = i + 1) {
        sum = sum + s[i];
    }
    if (sum != 150) { return 52; }

    return 0;
}

func sum_slice(s: []i64, n: i64) -> i64 {
    var sum = 0;
    var i = 0;
    for (i = 0; i < n; i = i + 1) {
        sum = sum + s[i];
    }
    return sum;
}

func make_slice(p: *i64, n: i64) -> []i64 {
    return slice(p, n);
}

func test_slice_struct_fields() -> i64 {
    var h: Holder;

    h.arr[0] = 1;
    h.arr[1] = 2;
    h.arr[2] = 3;

    var base: [3]i64;
    base[0] = 10;
    base[1] = 20;
    base[2] = 30;

    var p: *i64 = base;
    h.s = slice(p, 3);

    if (h.arr[1] != 2) { return 60; }
    if (h.s[2] != 30) { return 61; }

    var s2: []i64 = make_slice(p, 3);
    var total = sum_slice(s2, 3);
    if (total != 60) { return 62; }

    return 0;
}

func sum_arr(a: [3]i64) -> i64 {
    return a[0] + a[1] + a[2];
}

func pass_arr(a: [3]i64) -> [3]i64 {
    return a;
}

func test_array_param_return() -> i64 {
    var arr: [3]i64;
    arr[0] = 7;
    arr[1] = 8;
    arr[2] = 9;

    var total = sum_arr(arr);
    if (total != 24) { return 70; }

    var p: *i64 = pass_arr(arr);
    if (p[1] != 8) { return 71; }

    return 0;
}

func test_tagged_ptr_basic() -> i64 {
    var mem = heap_alloc(8);
    var raw: u64 = (u64)mem;
    var tag: u64 = 4660;
    var tagged_val: u64 = (raw & 281474976710655) | (tag << 48);

    var tptr: *tagged u8 = (*tagged u8)tagged_val;
    *tptr = 55;

    var v = *tptr;
    if (v != 55) { return 80; }

    return 0;
}

func test_tagged_layout_packed_struct() -> i64 {
    var mem = heap_alloc(8);
    var raw: u64 = (u64)mem;
    var p: *tagged(TaggedPtrBits) u8 = (*tagged(TaggedPtrBits) u8)raw;
    p.tag = 1;
    *p = 77;

    if (p.tag != 1) { return 90; }
    if (*p != 77) { return 91; }

    return 0;
}

func test_packed_bitfield_access() -> i64 {
    var b: Bits;
    b.ver = 3;
    b.id = 4095;

    if (b.ver != 3) { return 100; }
    if (b.id != 4095) { return 101; }

    return 0;
}

func main() -> i64 {
    var r = 0;

    r = test_array_basic();
    if (r != 0) { return r; }

    r = test_char_type();
    if (r != 0) { return r; }

    r = test_char_array();
    if (r != 0) { return r; }

    r = test_multidim_simulation();
    if (r != 0) { return r; }

    r = test_nested_array_access();
    if (r != 0) { return r; }

    r = test_slice_basic();
    if (r != 0) { return r; }

    r = test_slice_struct_fields();
    if (r != 0) { return r; }

    r = test_array_param_return();
    if (r != 0) { return r; }

    r = test_tagged_ptr_basic();
    if (r != 0) { return r; }

    r = test_tagged_layout_packed_struct();
    if (r != 0) { return r; }

    r = test_packed_bitfield_access();
    if (r != 0) { return r; }

    return 0;
}
