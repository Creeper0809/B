// hashmap.b - Hash map implementation for v3.8

import std.io;

// HashMap structure: [entries_ptr, capacity, count]
// Entry: [key_ptr, key_len, value, hash, used] = 40 bytes

func fnv1a_hash(ptr, len) {
    var hash = 0;
    for(var i = 0;i < len; i++){
        hash = hash ^ *(*u8)(ptr + i);
        hash = hash * 31;
    }
    return hash;
}

func hashmap_new(capacity) {
    var cap = 16;
    while (cap < capacity) {
        cap = cap * 2;
    }
    var map = heap_alloc(24);
    var bytes = cap * 40;
    var entries = heap_alloc(bytes);
    
    for(var i = 0; i < bytes;i++){
        *(*u8)(entries + i) = 0;
    }
    
    *(map) = entries;
    *(map + 8) = cap;
    *(map + 16) = 0;
    return map;
}

func hashmap_entry_ptr(entries, idx) {
    return entries + idx * 40;
}

func hashmap_put_internal(map, key_ptr, key_len, value) {
    var entries = *(map);
    var cap = *(map + 8);
    var hash = fnv1a_hash(key_ptr, key_len);
    var idx = hash % cap;
    
    for(var i = 0; i < cap ; i++){
        var e = hashmap_entry_ptr(entries, idx);
        var used = *(e + 32);
        
        if (used == 0) {
            *(e) = key_ptr;
            *(e + 8) = key_len;
            *(e + 16) = value;
            *(e + 24) = hash;
            *(e + 32) = 1;
            *(map + 16) = *(map + 16) + 1;
            return;
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_grow(map) {
    var old_entries = *(map);
    var old_cap = *(map + 8);
    
    var new_cap = old_cap * 2;
    var new_bytes = new_cap * 40;
    var new_entries = heap_alloc(new_bytes);
    
    for(var i = 0; i < new_bytes;i++){
        *(*u8)(new_entries + i) = 0;
    }

    *(map) = new_entries;
    *(map + 8) = new_cap;
    *(map + 16) = 0;
    
    for(var i = 0; i<old_cap;i++){
        var e = old_entries + i * 40;
        var used = *(e + 32);
        if (used != 0) {
            var kp = *(e);
            var kl = *(e + 8);
            var val = *(e + 16);
            hashmap_put_internal(map, kp, kl, val);
        }
    }
}

func hashmap_put(map, key_ptr, key_len, value) {
    var entries  = *(map);
    var cap = *(map + 8);
    var count = *(map + 16);
    
    if (count * 10 >= cap * 7) {
        hashmap_grow(map);
        entries = *(map);
        cap = *(map + 8);
    }
    
    var hash = fnv1a_hash(key_ptr, key_len);
    var idx = hash % cap;
    
    for(var i = 0; i < cap ;i++){
        var e= hashmap_entry_ptr(entries, idx);
        var used = *(e + 32);
        
        if (used == 0) {
            *(e) = key_ptr;
            *(e + 8) = key_len;
            *(e + 16) = value;
            *(e + 24) = hash;
            *(e + 32) = 1;
            *(map + 16) = *(map + 16) + 1;
            return;
        }
        
        var kp = *(e);
        var kl = *(e + 8);
        if (str_eq(kp, kl, key_ptr, key_len)) {
            *(e + 16) = value;
            return;
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_get(map, key_ptr, key_len) {
    var entries = *(map);
    var cap = *(map + 8);
    var hash = fnv1a_hash(key_ptr, key_len);
    var idx = hash % cap;
    
    for(var i = 0; i <cap ; i++){
        var e = hashmap_entry_ptr(entries, idx);
        var used = *(e + 32);
        
        if (used == 0) {
            return 0;
        }
        
        var kp = *(e);
        var kl  = *(e + 8);
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return *(e + 16);
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_has(map, key_ptr, key_len) {
    var entries = *(map);
    var cap = *(map + 8);
    var hash = fnv1a_hash(key_ptr, key_len);
    var idx = hash % cap;
    
    for(var i = 0; i < cap ; i++){
        var e = hashmap_entry_ptr(entries, idx);
        var used = *(e + 32);
        
        if (used == 0) {
            return 0;
        }
        
        var kp = *(e);
        var kl = *(e + 8);
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return 1;
        }
        
        idx = (idx + 1) % cap;
    }
    return 0;
}
