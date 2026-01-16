// vec.b - Dynamic array implementation for v3.8

import std.io;

// Vec structure: [buf_ptr, len, cap]
import types; // Import types.b to use the Vec struct

func vec_new(cap: u64) -> u64 {
    var v: u64 = heap_alloc(24);
    var vec: *Vec = (*Vec)v;
    vec->data_ptr = heap_alloc(cap * 8);
    vec->length = 0;
    vec->capacity = cap;
    return v;
}

func vec_len(v: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    return vec->length;
}

func vec_cap(v: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    return vec->capacity;
}

func vec_push(v: u64, item: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    
    // Grow if needed
    if (vec->length >= vec->capacity) {
        var new_cap: u64 = vec->capacity * 2;
        var new_buf: u64 = heap_alloc(new_cap * 8);
        var old_buf: u64 = vec->data_ptr;
        // Copy old data
        var i: u64 = 0;
        while (i < vec->length) {
            *(new_buf + i * 8) = *(old_buf + i * 8);
            i = i + 1;
        }
        vec->data_ptr = new_buf;
        vec->capacity = new_cap;
    }
    
    *(vec->data_ptr + vec->length * 8) = item;
    vec->length = vec->length + 1;
}

func vec_get(v: u64, i: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    return *(vec->data_ptr + i * 8);
}

func vec_set(v: u64, i: u64, val: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    *(vec->data_ptr + i * 8) = val;
}

func vec_pop(v: u64) -> u64 {
    var vec: *Vec = (*Vec)v;
    if (vec->length == 0) {
        // Optionally, panic or return an error indicator
        return 0; // Return 0 for now to indicate an empty vector
    }
    vec->length = vec->length - 1;
    return *(vec->data_ptr + vec->length * 8);
}

