// vec.b - Dynamic array implementation for v3.8

import std.io;

// Vec structure: [buf_ptr, len, cap]

func vec_new(cap: u64) -> *u64 {
    var v: *u64 = heap_alloc(24);
    var buf: *u64 = heap_alloc(cap * 8);
    *(v) = buf;
    *(v + 8) = 0;
    *(v + 16) = cap;
    return v;
}

func vec_len(v: *u64) -> u64 {
    return *(v + 8);
}

func vec_cap(v: *u64) -> u64 {
    return *(v + 16);
}

func vec_push(v: *u64, item: *u64) -> *u64 {
    var len: u64 = *(v + 8);
    var cap: u64 = *(v + 16);
    
    // Grow if needed
    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        var new_buf: *u64 = heap_alloc(new_cap * 8);
        var old_buf: *u64 = *(v);
        // Copy old data
        var i: u64 = 0;
        while (i < len) {
            *(new_buf + i * 8) = *(old_buf + i * 8);
            i = i + 1;
        }
        *(v) = new_buf;
        *(v + 16) = new_cap;
    }
    
    var buf: *u64 = *(v);
    *(buf + len * 8) = item;
    *(v + 8) = len + 1;
}

func vec_get(v: *u64, i: u64) -> *u64 {
    var buf: *u64 = *(v);
    return *(buf + i * 8);
}

func vec_set(v: *u64, i: u64, val: *u64) -> *u64 {
    var buf: *u64 = *(v);
    *(buf + i * 8) = val;
}

func vec_data(v: *u64) -> *u64 {
    return *(v);
}
