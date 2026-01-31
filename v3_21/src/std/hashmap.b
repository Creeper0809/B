// hashmap.b - Hash map implementation for v3.8

import std.io;
import std.str;

// HashMap structure: [entries_ptr, capacity, count]
// Entry: [key_ptr, key_len, value, hash, used]

struct HashMap {
    entries_ptr: u64;
    capacity: u64;
    count: u64;
}

struct HashEntry {
    key_ptr: u64;
    key_len: u64;
    value: u64;
    hash: u64;
    used: u64;
}

func fnv1a_hash(ptr, len) {
    var hash: u64 = 0;
    for (var i: u64 = 0; i < len; i++) {
        hash = hash ^ *(*u8)(ptr + i);
        hash = hash * 31;
    }
    return hash;
}

func hashmap_new(capacity) {
    var cap: u64 = 16;
    for (; cap < capacity; cap = cap * 2) {
    }
    var map: *HashMap = (*HashMap)heap_alloc(sizeof(HashMap));
    var bytes: u64 = cap * sizeof(HashEntry);
    var entries: u64 = heap_alloc(cap * sizeof(HashEntry));
    
    for (var i: u64 = 0; i < bytes; i++) {
        *(*u8)(entries + i) = 0;
    }
    
    map->entries_ptr = entries;
    map->capacity = cap;
    map->count = 0;
    return (u64)map;
}

func hashmap_entry_ptr(entries, idx) {
    return (*HashEntry)(entries + idx * sizeof(HashEntry));
}

func hashmap_put_internal(map, key_ptr, key_len, value) {
    var map_ptr: *HashMap = (*HashMap)map;
    var entries: u64 = map_ptr->entries_ptr;
    var cap: u64 = map_ptr->capacity;
    var hash: u64 = fnv1a_hash(key_ptr, key_len);
    var idx: u64 = hash % cap;
    
    for (var i: u64 = 0; i < cap; i++) {
        var entry: *HashEntry = hashmap_entry_ptr(entries, idx);
        var used: u64 = entry->used;
        
        if (used == 0) {
            entry->key_ptr = key_ptr;
            entry->key_len = key_len;
            entry->value = value;
            entry->hash = hash;
            entry->used = 1;
            map_ptr->count = map_ptr->count + 1;
            return;
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_grow(map) {
    var map_ptr: *HashMap = (*HashMap)map;
    var old_entries: u64 = map_ptr->entries_ptr;
    var old_cap: u64 = map_ptr->capacity;

    var new_cap: u64 = old_cap * 2;
    var new_bytes: u64 = new_cap * sizeof(HashEntry);
    var new_entries: u64 = heap_alloc(new_cap * sizeof(HashEntry));

    for (var i: u64 = 0; i < new_bytes; i++) {
        *(*u8)(new_entries + i) = 0;
    }

    map_ptr->entries_ptr = new_entries;
    map_ptr->capacity = new_cap;
    map_ptr->count = 0;

    for (var i: u64 = 0; i < old_cap; i++) {
        var entry: *HashEntry = hashmap_entry_ptr(old_entries, i);
        var used: u64 = entry->used;
        if (used != 0) {
            var kp: u64 = entry->key_ptr;
            var kl: u64 = entry->key_len;
            var val: u64 = entry->value;
            hashmap_put_internal(map, kp, kl, val);
        }
    }
}

func hashmap_put(map, key_ptr, key_len, value) {
    var map_ptr: *HashMap = (*HashMap)map;
    var entries: u64 = map_ptr->entries_ptr;
    var cap: u64 = map_ptr->capacity;
    var count: u64 = map_ptr->count;
    
    if (count * 10 >= cap * 7) {
        hashmap_grow(map);
        entries = map_ptr->entries_ptr;
        cap = map_ptr->capacity;
    }
    
    var hash: u64 = fnv1a_hash(key_ptr, key_len);
    var idx: u64 = hash % cap;
    
    for (var i: u64 = 0; i < cap; i++) {
        var entry: *HashEntry = hashmap_entry_ptr(entries, idx);
        var used: u64 = entry->used;
        
        if (used == 0) {
            entry->key_ptr = key_ptr;
            entry->key_len = key_len;
            entry->value = value;
            entry->hash = hash;
            entry->used = 1;
            map_ptr->count = map_ptr->count + 1;
            return;
        }
        
        var kp: u64 = entry->key_ptr;
        var kl: u64 = entry->key_len;
        if (str_eq(kp, kl, key_ptr, key_len)) {
            entry->value = value;
            return;
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_get(map, key_ptr, key_len) {
    var map_ptr: *HashMap = (*HashMap)map;
    var entries: u64 = map_ptr->entries_ptr;
    var cap: u64 = map_ptr->capacity;
    var hash: u64 = fnv1a_hash(key_ptr, key_len);
    var idx: u64 = hash % cap;
    
    for (var i: u64 = 0; i < cap; i++) {
        var entry: *HashEntry = hashmap_entry_ptr(entries, idx);
        var used: u64 = entry->used;
        
        if (used == 0) {
            return 0;
        }
        
        var kp: u64 = entry->key_ptr;
        var kl: u64 = entry->key_len;
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return entry->value;
        }
        
        idx = (idx + 1) % cap;
    }
}

func hashmap_has(map, key_ptr, key_len) {
    var map_ptr: *HashMap = (*HashMap)map;
    var entries: u64 = map_ptr->entries_ptr;
    var cap: u64 = map_ptr->capacity;
    var hash: u64 = fnv1a_hash(key_ptr, key_len);
    var idx: u64 = hash % cap;
    
    for (var i: u64 = 0; i < cap; i++) {
        var entry: *HashEntry = hashmap_entry_ptr(entries, idx);
        var used: u64 = entry->used;
        
        if (used == 0) {
            return 0;
        }
        
        var kp: u64 = entry->key_ptr;
        var kl: u64 = entry->key_len;
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return 1;
        }
        
        idx = (idx + 1) % cap;
    }
    return 0;
}
