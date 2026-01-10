// v3.6 Compiler - Part 1: Utility Functions

// ============================================
// Error Handling
// ============================================

func panic() {
    emit("[PANIC] Compiler error - exiting", 32);
    emit_nl();
    // Force crash by dereferencing null
    var x;
    x = ptr64[0];
}

// Write to stderr (fd=2)
func emit_stderr(s, len) {
    sys_write(2, s, len);
}

func emit_stderr_nl() {
    var nl;
    nl = heap_alloc(1);
    ptr8[nl] = 10;
    sys_write(2, nl, 1);
}

func warn(msg, len) {
    emit_stderr("[WARN] ", 7);
    emit_stderr(msg, len);
    emit_stderr_nl();
}

// ============================================
// Type Compatibility (Phase 4: Implicit Conversion)
// ============================================

// Check if two types are compatible (lenient rules)
// Returns: 0 = exact match, 1 = compatible with warning, 2 = incompatible
func check_type_compat(from_base, from_depth, to_base, to_depth) {
    // Exact match - no warning needed
    if (from_base == to_base) {
        if (from_depth == to_depth) {
            return 0;
        }
    }
    
    // Pointer <-> Pointer: always OK (warning)
    if (from_depth > 0) {
        if (to_depth > 0) {
            return 1;
        }
    }
    
    // Integer <-> Integer: always OK (no warning for same size)
    if (from_depth == 0) {
        if (to_depth == 0) {
            // Same size integers: no warning
            var from_size;
            from_size = get_type_size(from_base, 0);
            var to_size;
            to_size = get_type_size(to_base, 0);
            if (from_size == to_size) {
                return 0;
            }
            // Different size: warning
            return 1;
        }
    }
    
    // Integer <-> Pointer: OK with warning
    if (from_depth == 0) {
        if (to_depth > 0) {
            return 1;
        }
    }
    if (from_depth > 0) {
        if (to_depth == 0) {
            return 1;
        }
    }
    
    // Default: compatible with warning
    return 1;
}

// Get type name for warning messages
func get_type_name(base_type, ptr_depth) {
    // Returns pointer to static string (no allocation)
    if (ptr_depth > 0) {
        if (base_type == TYPE_U8) { return "u8 ptr"; }
        if (base_type == TYPE_U16) { return "u16 ptr"; }
        if (base_type == TYPE_U32) { return "u32 ptr"; }
        if (base_type == TYPE_U64) { return "u64 ptr"; }
        if (base_type == TYPE_I64) { return "i64 ptr"; }
        return "ptr";
    }
    if (base_type == TYPE_U8) { return "u8"; }
    if (base_type == TYPE_U16) { return "u16"; }
    if (base_type == TYPE_U32) { return "u32"; }
    if (base_type == TYPE_U64) { return "u64"; }
    if (base_type == TYPE_I64) { return "i64"; }
    return "unknown";
}

// ============================================
// Type Size Helpers
// ============================================

func get_type_size(base_type, ptr_depth) {
    // If it's a pointer, size is always 8 (64-bit pointer)
    if (ptr_depth > 0) {
        return 8;
    }
    // Non-pointer types
    if (base_type == TYPE_U8) { return 1; }
    if (base_type == TYPE_U16) { return 2; }
    if (base_type == TYPE_U32) { return 4; }
    if (base_type == TYPE_U64) { return 8; }
    if (base_type == TYPE_I64) { return 8; }
    // Default/unknown
    return 8;
}

// Get the size of what the pointer points to
func get_pointee_size(base_type, ptr_depth) {
    // ptr_depth > 0 means it's a pointer
    if (ptr_depth > 1) {
        // Pointer to pointer -> 8 bytes
        return 8;
    }
    if (ptr_depth == 1) {
        // Pointer to base type
        if (base_type == TYPE_U8) { return 1; }
        if (base_type == TYPE_U16) { return 2; }
        if (base_type == TYPE_U32) { return 4; }
        if (base_type == TYPE_U64) { return 8; }
        if (base_type == TYPE_I64) { return 8; }
    }
    // Not a pointer or unknown
    return 8;
}

// ============================================
// Vec (Dynamic Array)
// Structure: [buf_ptr, len, cap]
// ============================================

func vec_new(cap) {
    var v;
    v = heap_alloc(24);
    var buf;
    buf = heap_alloc(cap * 8);
    ptr64[v] = buf;
    ptr64[v + 8] = 0;
    ptr64[v + 16] = cap;
    return v;
}

func vec_len(v) {
    return ptr64[v + 8];
}

func vec_cap(v) {
    return ptr64[v + 16];
}

func vec_push(v, item) {
    var len;
    len = ptr64[v + 8];
    var cap;
    cap = ptr64[v + 16];
    
    // Grow if needed
    if (len >= cap) {
        var new_cap;
        new_cap = cap * 2;
        var new_buf;
        new_buf = heap_alloc(new_cap * 8);
        var old_buf;
        old_buf = ptr64[v];
        // Copy old data
        var i;
        i = 0;
        while (i < len) {
            ptr64[new_buf + i * 8] = ptr64[old_buf + i * 8];
            i = i + 1;
        }
        ptr64[v] = new_buf;
        ptr64[v + 16] = new_cap;
    }
    
    var buf;
    buf = ptr64[v];
    ptr64[buf + len * 8] = item;
    ptr64[v + 8] = len + 1;
}

func vec_get(v, i) {
    var buf;
    buf = ptr64[v];
    return ptr64[buf + i * 8];
}

func vec_set(v, i, val) {
    var buf;
    buf = ptr64[v];
    ptr64[buf + i * 8] = val;
}

// ============================================
// String Utilities
// ============================================

func str_eq(s1, len1, s2, len2) {
    if (len1 != len2) { return 0; }
    var i;
    i = 0;
    while (i < len1) {
        if (ptr8[s1 + i] != ptr8[s2 + i]) { return 0; }
        i = i + 1;
    }
    return 1;
}

func str_copy(dst, src, len) {
    var i;
    i = 0;
    while (i < len) {
        ptr8[dst + i] = ptr8[src + i];
        i = i + 1;
    }
}

// ============================================
// Output Utilities
// ============================================

func emit(s, len) {
    sys_write(1, s, len);
}

func emit_char(c) {
    var buf;
    buf = heap_alloc(1);
    ptr8[buf] = c;
    sys_write(1, buf, 1);
}

func emit_u64(n) {
    if (n == 0) {
        emit("0", 1);
        return;
    }
    var buf;
    buf = heap_alloc(32);
    var i;
    i = 0;
    var t;
    t = n;
    while (t > 0) {
        ptr8[buf + i] = 48 + (t % 10);
        t = t / 10;
        i = i + 1;
    }
    var j;
    j = i - 1;
    while (j >= 0) {
        sys_write(1, buf + j, 1);
        j = j - 1;
    }
}

func emit_i64(n) {
    if (n < 0) {
        emit("-", 1);
        emit_u64(0 - n);
    } else {
        emit_u64(n);
    }
}

func emit_nl() {
    var nl;
    nl = heap_alloc(1);
    ptr8[nl] = 10;  // ASCII newline
    sys_write(1, nl, 1);
}

// ============================================
// Extended String Utilities
// ============================================

// Get string length (null-terminated)
func str_len(s) {
    var i;
    i = 0;
    while (ptr8[s + i] != 0) {
        i = i + 1;
    }
    return i;
}

// Concatenate two strings, returns new heap-allocated string
func str_concat(s1, len1, s2, len2) {
    var result;
    result = heap_alloc(len1 + len2 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    ptr8[result + len1 + len2] = 0;
    return result;
}

// Concatenate 3 strings
func str_concat3(s1, len1, s2, len2, s3, len3) {
    var result;
    result = heap_alloc(len1 + len2 + len3 + 1);
    str_copy(result, s1, len1);
    str_copy(result + len1, s2, len2);
    str_copy(result + len1 + len2, s3, len3);
    ptr8[result + len1 + len2 + len3] = 0;
    return result;
}

// ============================================
// Path Utilities
// ============================================

// Get directory part of path (returns new string)
// "/foo/bar/baz.b" -> "/foo/bar"
func path_dirname(path, path_len) {
    var last_slash;
    last_slash = 0 - 1;
    var i;
    i = 0;
    while (i < path_len) {
        if (ptr8[path + i] == 47) {  // '/'
            last_slash = i;
        }
        i = i + 1;
    }
    
    if (last_slash < 0) {
        // No slash, return "."
        var result;
        result = heap_alloc(2);
        ptr8[result] = 46;  // '.'
        ptr8[result + 1] = 0;
        return result;
    }
    
    var result;
    result = heap_alloc(last_slash + 2);
    str_copy(result, path, last_slash);
    ptr8[result + last_slash] = 0;
    return result;
}

// Join directory and filename: dir + "/" + name
func path_join(dir, dir_len, name, name_len) {
    var slash;
    slash = heap_alloc(1);
    ptr8[slash] = 47;  // '/'
    return str_concat3(dir, dir_len, slash, 1, name, name_len);
}

// Convert module name to path: "io" -> "io.b"
func module_to_path(name, name_len) {
    var ext;
    ext = heap_alloc(2);
    ptr8[ext] = 46;      // '.'
    ptr8[ext + 1] = 98;  // 'b'
    return str_concat(name, name_len, ext, 2);
}

// ============================================
// HashMap (for module tracking)
// Entry: [key_ptr, key_len, value, hash, used]
// Each entry is 40 bytes
// ============================================

func fnv1a_hash(ptr, len) {
    var hash;
    hash = 14695981039346656037;
    var i;
    i = 0;
    while (i < len) {
        hash = hash ^ ptr8[ptr + i];
        hash = hash * 1099511628211;
        i = i + 1;
    }
    return hash;
}

func hashmap_new(capacity) {
    var cap;
    cap = 16;
    while (cap < capacity) {
        cap = cap * 2;
    }
    var map;
    map = heap_alloc(24);
    var bytes;
    bytes = cap * 40;
    var entries;
    entries = heap_alloc(bytes);
    
    // Zero out entries
    var i;
    i = 0;
    while (i < bytes) {
        ptr8[entries + i] = 0;
        i = i + 1;
    }
    
    ptr64[map] = entries;
    ptr64[map + 8] = cap;
    ptr64[map + 16] = 0;
    return map;
}

func hashmap_entry_ptr(entries, idx) {
    return entries + idx * 40;
}

// Grow hashmap to double capacity
func hashmap_grow(map) {
    var old_entries;
    old_entries = ptr64[map];
    var old_cap;
    old_cap = ptr64[map + 8];
    
    var new_cap;
    new_cap = old_cap * 2;
    var new_bytes;
    new_bytes = new_cap * 40;
    var new_entries;
    new_entries = heap_alloc(new_bytes);
    
    // Zero out new entries
    var i;
    i = 0;
    while (i < new_bytes) {
        ptr8[new_entries + i] = 0;
        i = i + 1;
    }
    
    // Update map with new storage
    ptr64[map] = new_entries;
    ptr64[map + 8] = new_cap;
    ptr64[map + 16] = 0;
    
    // Rehash all old entries
    i = 0;
    while (i < old_cap) {
        var e;
        e = old_entries + i * 40;
        var used;
        used = ptr64[e + 32];
        if (used != 0) {
            var kp;
            kp = ptr64[e];
            var kl;
            kl = ptr64[e + 8];
            var val;
            val = ptr64[e + 16];
            hashmap_put_internal(map, kp, kl, val);
        }
        i = i + 1;
    }
}

// Internal put without grow check (for rehashing)
func hashmap_put_internal(map, key_ptr, key_len, value) {
    var entries;
    entries = ptr64[map];
    var cap;
    cap = ptr64[map + 8];
    var hash;
    hash = fnv1a_hash(key_ptr, key_len);
    var idx;
    idx = hash % cap;
    
    var i;
    i = 0;
    while (i < cap) {
        var e;
        e = hashmap_entry_ptr(entries, idx);
        var used;
        used = ptr64[e + 32];
        
        if (used == 0) {
            ptr64[e] = key_ptr;
            ptr64[e + 8] = key_len;
            ptr64[e + 16] = value;
            ptr64[e + 24] = hash;
            ptr64[e + 32] = 1;
            ptr64[map + 16] = ptr64[map + 16] + 1;
            return;
        }
        
        idx = (idx + 1) % cap;
        i = i + 1;
    }
}

func hashmap_put(map, key_ptr, key_len, value) {
    var entries;
    entries = ptr64[map];
    var cap;
    cap = ptr64[map + 8];
    var count;
    count = ptr64[map + 16];
    
    // Grow if load factor > 70%
    if (count * 10 >= cap * 7) {
        hashmap_grow(map);
        entries = ptr64[map];
        cap = ptr64[map + 8];
    }
    
    var hash;
    hash = fnv1a_hash(key_ptr, key_len);
    var idx;
    idx = hash % cap;
    
    var i;
    i = 0;
    while (i < cap) {
        var e;
        e = hashmap_entry_ptr(entries, idx);
        var used;
        used = ptr64[e + 32];
        
        if (used == 0) {
            ptr64[e] = key_ptr;
            ptr64[e + 8] = key_len;
            ptr64[e + 16] = value;
            ptr64[e + 24] = hash;
            ptr64[e + 32] = 1;
            ptr64[map + 16] = ptr64[map + 16] + 1;
            return;
        }
        
        var kp;
        kp = ptr64[e];
        var kl;
        kl = ptr64[e + 8];
        if (str_eq(kp, kl, key_ptr, key_len)) {
            ptr64[e + 16] = value;
            return;
        }
        
        idx = (idx + 1) % cap;
        i = i + 1;
    }
}

func hashmap_get(map, key_ptr, key_len) {
    var entries;
    entries = ptr64[map];
    var cap;
    cap = ptr64[map + 8];
    var hash;
    hash = fnv1a_hash(key_ptr, key_len);
    var idx;
    idx = hash % cap;
    
    var i;
    i = 0;
    while (i < cap) {
        var e;
        e = hashmap_entry_ptr(entries, idx);
        var used;
        used = ptr64[e + 32];
        
        if (used == 0) {
            return 0;
        }
        
        var kp;
        kp = ptr64[e];
        var kl;
        kl = ptr64[e + 8];
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return ptr64[e + 16];
        }
        
        idx = (idx + 1) % cap;
        i = i + 1;
    }
    return 0;
}

func hashmap_has(map, key_ptr, key_len) {
    var entries;
    entries = ptr64[map];
    var cap;
    cap = ptr64[map + 8];
    var hash;
    hash = fnv1a_hash(key_ptr, key_len);
    var idx;
    idx = hash % cap;
    
    var i;
    i = 0;
    while (i < cap) {
        var e;
        e = hashmap_entry_ptr(entries, idx);
        var used;
        used = ptr64[e + 32];
        
        if (used == 0) {
            return 0;
        }
        
        var kp;
        kp = ptr64[e];
        var kl;
        kl = ptr64[e + 8];
        if (str_eq(kp, kl, key_ptr, key_len)) {
            return 1;
        }
        
        idx = (idx + 1) % cap;
        i = i + 1;
    }
    return 0;
}
