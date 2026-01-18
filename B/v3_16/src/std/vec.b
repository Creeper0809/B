// vec.b - Dynamic array implementation (impl-based)

import std.io;

// Vec structure: [data_ptr, length, capacity] (24 bytes)
struct Vec {
    data_ptr: u64;
    length: u64;
    capacity: u64;
}

impl Vec {
    func new(cap: u64) -> u64 {
        var v = (*Vec)heap_alloc(24);
        var buf = heap_alloc(cap * 8);
        v->data_ptr = buf;
        v->length = 0;
        v->capacity = cap;
        return (u64)v;
    }
    
    func len(self: *Vec) -> u64 {
        return self->length;
    }
    
    func cap(self: *Vec) -> u64 {
        return self->capacity;
    }
    
    func push(self: *Vec, item: u64) {
        var len = self->length;
        var cap = self->capacity;
        
        // Grow if needed
        if (len >= cap) {
            var new_cap = cap * 2;
            if (new_cap < 4) { new_cap = 4; }
            var new_buf = heap_alloc(new_cap * 8);
            var old_buf = self->data_ptr;
            // Copy old data
            var i = 0;
            while (i < len) {
                *(new_buf + i * 8) = *(old_buf + i * 8);
                i = i + 1;
            }
            self->data_ptr = new_buf;
            self->capacity = new_cap;
        }
        
        var buf = self->data_ptr;
        *(buf + len * 8) = item;
        self->length = len + 1;
    }
    
    func get(self: *Vec, i: u64) -> u64 {
        var buf = self->data_ptr;
        return *(buf + i * 8);
    }
    
    func set(self: *Vec, i: u64, val: u64) {
        var buf = self->data_ptr;
        *(buf + i * 8) = val;
    }
    
    func pop(self: *Vec) -> u64 {
        var len = self->length;
        if (len == 0) {
            return 0;
        }
        self->length = len - 1;
        var buf = self->data_ptr;
        return *(buf + (len - 1) * 8);
    }
}

// ============================================
// Legacy C-style API (for backward compatibility)
// ============================================

func vec_new(cap) {
    return Vec_new(cap);
}

func vec_len(v) {
    return Vec_len((*Vec)v);
}

func vec_cap(v) {
    return Vec_cap((*Vec)v);
}

func vec_push(v, item) {
    Vec_push((*Vec)v, item);
}

func vec_get(v, i) {
    return Vec_get((*Vec)v, i);
}

func vec_set(v, i, val) {
    Vec_set((*Vec)v, i, val);
}

func vec_pop(v) {
    return Vec_pop((*Vec)v);
}

