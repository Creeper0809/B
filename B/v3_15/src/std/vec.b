// vec.b - Dynamic array implementation for v3.8

import std.io;

// Vec structure: [buf_ptr, len, cap]

func vec_new(cap) {
    var v = heap_alloc(24);
    var buf = heap_alloc(cap * 8);
    *(v) = buf;
    *(v + 8) = 0;
    *(v + 16) = cap;
    return v;
}

func vec_len(v) {
    return *(v + 8);
}

func vec_cap(v) {
    return *(v + 16);
}

func vec_push(v, item) {
    var len = *(v + 8);
    var cap = *(v + 16);
    
    // Grow if needed
    if (len >= cap) {
        var new_cap = cap * 2;
        var new_buf = heap_alloc(new_cap * 8);
        var old_buf = *(v);
        // Copy old data
        var i = 0;
        while (i < len) {
            *(new_buf + i * 8) = *(old_buf + i * 8);
            i = i + 1;
        }
        *(v) = new_buf;
        *(v + 16) = new_cap;
    }
    
    var buf = *(v);
    *(buf + len * 8) = item;
    *(v + 8) = len + 1;
}

func vec_get(v, i) {
    var buf = *(v);
    return *(buf + i * 8);
}

func vec_set(v, i, val) {
    var buf = *(v);
    *(buf + i * 8) = val;
}
