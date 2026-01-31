// vec.b - Dynamic array implementation (pointer arithmetic for bootstrap)

import std.io;

// Vec structure: [data_ptr, length, capacity] (24 bytes)
struct Vec {
    data_ptr: u64;
    length: u64;
    capacity: u64;
}

func vec_new(cap) {
    var vec: *Vec = (*Vec)heap_alloc(sizeof(Vec));
    var buf: u64 = heap_alloc(cap * sizeof(u64));
    vec->data_ptr = buf;
    vec->length = 0;
    vec->capacity = cap;
    return (u64)vec;
}

func vec_len(v) {
    var vec: *Vec = (*Vec)v;
    return vec->length;
}

func vec_cap(v) {
    var vec: *Vec = (*Vec)v;
    return vec->capacity;
}

func vec_push(v, item) {
    var vec: *Vec = (*Vec)v;
    var len: u64 = vec->length;
    var cap: u64 = vec->capacity;

    // Grow if needed
    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap < 4) { new_cap = 4; }
        var new_buf: u64 = heap_alloc(new_cap * sizeof(u64));
        var old_buf: u64 = vec->data_ptr;
        // Copy old data
        for (var i: u64 = 0; i < len; i++) {
            *(new_buf + i * sizeof(u64)) = *(old_buf + i * sizeof(u64));
        }
        vec->data_ptr = new_buf;
        vec->capacity = new_cap;
    }

    var buf: u64 = vec->data_ptr;
    *(buf + len * sizeof(u64)) = item;
    vec->length = len + 1;
}

func vec_get(v, i) {
    var vec: *Vec = (*Vec)v;
    var buf: u64 = vec->data_ptr;
    return *(buf + i * sizeof(u64));
}

func vec_set(v, i, val) {
    var vec: *Vec = (*Vec)v;
    var buf: u64 = vec->data_ptr;
    *(buf + i * sizeof(u64)) = val;
}

func vec_pop(v) {
    var vec: *Vec = (*Vec)v;
    var len: u64 = vec->length;
    if (len == 0) {
        return 0;
    }
    vec->length = len - 1;
    var buf: u64 = vec->data_ptr;
    return *(buf + (len - 1) * sizeof(u64));
}

