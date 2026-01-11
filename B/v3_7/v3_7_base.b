// v3.6 Compiler - Pointer Support
// Part 0: Header - Constants and Token/AST definitions

import io;

// ============================================
// Token Types
// ============================================
const TOKEN_EOF = 0;
const TOKEN_IDENTIFIER = 10;
const TOKEN_NUMBER = 11;
const TOKEN_STRING = 12;

// Keywords
const TOKEN_FUNC = 20;
const TOKEN_VAR = 21;
const TOKEN_CONST = 22;
const TOKEN_RETURN = 23;
const TOKEN_IF = 24;
const TOKEN_ELSE = 25;
const TOKEN_WHILE = 26;
const TOKEN_IMPORT = 27;
const TOKEN_FOR = 28;
const TOKEN_SWITCH = 29;
const TOKEN_CASE = 30;
const TOKEN_DEFAULT = 31;
const TOKEN_BREAK = 32;
const TOKEN_ASM = 33;

// Type keywords
const TOKEN_U8 = 40;
const TOKEN_U16 = 41;
const TOKEN_U32 = 42;
const TOKEN_U64 = 43;
const TOKEN_I64 = 44;

// Delimiters
const TOKEN_LPAREN = 100;
const TOKEN_RPAREN = 101;
const TOKEN_LBRACE = 102;
const TOKEN_RBRACE = 103;
const TOKEN_LBRACKET = 104;
const TOKEN_RBRACKET = 105;
const TOKEN_SEMICOLON = 106;
const TOKEN_COLON = 107;
const TOKEN_COMMA = 108;
const TOKEN_DOT = 109;
const TOKEN_ARROW = 110;

// Operators
const TOKEN_PLUS = 60;
const TOKEN_MINUS = 61;
const TOKEN_STAR = 62;
const TOKEN_SLASH = 63;
const TOKEN_PERCENT = 64;
const TOKEN_CARET = 65;
const TOKEN_AMPERSAND = 66;
const TOKEN_BANG = 67;
const TOKEN_EQ = 68;
const TOKEN_EQEQ = 69;
const TOKEN_BANGEQ = 70;
const TOKEN_LT = 71;
const TOKEN_GT = 72;
const TOKEN_LTEQ = 73;
const TOKEN_GTEQ = 74;

// ============================================
// AST Node Types
// ============================================

// Expressions
const AST_LITERAL = 100;
const AST_IDENT = 101;
const AST_BINARY = 102;
const AST_UNARY = 103;
const AST_CALL = 104;
const AST_ADDR_OF = 105;
const AST_DEREF = 106;
const AST_DEREF8 = 107;  // ptr8[expr] - byte dereference
const AST_CAST = 108;
const AST_STRING = 109;

// Statements
const AST_RETURN = 200;
const AST_VAR_DECL = 201;
const AST_CONST_DECL = 206;
const AST_ASSIGN = 202;
const AST_EXPR_STMT = 203;
const AST_IF = 204;
const AST_WHILE = 205;
const AST_FOR = 207;
const AST_SWITCH = 208;
const AST_CASE = 209;
const AST_BREAK = 211;
const AST_BLOCK = 210;
const AST_ASM = 212;

// Top-level
const AST_FUNC = 300;
const AST_PROGRAM = 301;
const AST_IMPORT = 302;

// ============================================
// Type Constants
// ============================================
const TYPE_VOID = 0;
const TYPE_U8 = 1;
const TYPE_U16 = 2;
const TYPE_U32 = 3;
const TYPE_U64 = 4;
const TYPE_I64 = 5;
const TYPE_PTR = 10;

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

// emit() is defined in io.b

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
// Simple hash function (simplified for self-hosting)
// ============================================

func fnv1a_hash(ptr, len) {
    var hash;
    hash = 0;
    var i;
    i = 0;
    while (i < len) {
        hash = hash ^ ptr8[ptr + i];
        hash = hash * 31;
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
// v3.6 Compiler - Part 2: Lexer
// Lexer structure: [src_ptr, src_len, pos, line, col]

// ============================================
// Character Classification
// ============================================

func is_digit(c) {
    if (c >= 48) {
        if (c <= 57) {
            return 1;
        }
    }
    return 0;
}

func is_alpha(c) {
    if (c >= 65) {
        if (c <= 90) { return 1; }
    }
    if (c >= 97) {
        if (c <= 122) { return 1; }
    }
    if (c == 95) { return 1; }
    return 0;
}

func is_alnum(c) {
    if (is_alpha(c)) { return 1; }
    if (is_digit(c)) { return 1; }
    return 0;
}

func is_whitespace(c) {
    if (c == 32) { return 1; }
    if (c == 9) { return 1; }
    if (c == 10) { return 1; }
    if (c == 13) { return 1; }
    return 0;
}

// ============================================
// Lexer Core
// ============================================

func lex_new(src, len) {
    var l;
    l = heap_alloc(40);
    ptr64[l] = src;
    ptr64[l + 8] = len;
    ptr64[l + 16] = 0;
    ptr64[l + 24] = 1;
    ptr64[l + 32] = 1;
    return l;
}

func lex_at_end(l) {
    var pos;
    pos = ptr64[l + 16];
    var len;
    len = ptr64[l + 8];
    if (pos >= len) { return 1; }
    return 0;
}

func lex_peek(l) {
    if (lex_at_end(l)) { return 0; }
    var src;
    src = ptr64[l];
    var pos;
    pos = ptr64[l + 16];
    return ptr8[src + pos];
}

func lex_peek_next(l) {
    var pos;
    pos = ptr64[l + 16];
    var len;
    len = ptr64[l + 8];
    if (pos + 1 >= len) { return 0; }
    var src;
    src = ptr64[l];
    return ptr8[src + pos + 1];
}

func lex_advance(l) {
    var c;
    c = lex_peek(l);
    ptr64[l + 16] = ptr64[l + 16] + 1;
    if (c == 10) {
        ptr64[l + 24] = ptr64[l + 24] + 1;
        ptr64[l + 32] = 1;
    } else {
        ptr64[l + 32] = ptr64[l + 32] + 1;
    }
    return c;
}

func lex_skip_ws(l) {
    while (!lex_at_end(l)) {
        var c;
        c = lex_peek(l);
        if (!is_whitespace(c)) { break; }
        lex_advance(l);
    }
}

func lex_skip_comment(l) {
    if (lex_peek(l) == 47) {
        if (lex_peek_next(l) == 47) {
            lex_advance(l);
            lex_advance(l);
            while (!lex_at_end(l)) {
                var c;
                c = lex_peek(l);
                if (c == 10) {
                    lex_advance(l);
                    break;
                }
                lex_advance(l);
            }
        }
    }
}

func lex_skip_ws_and_comments(l) {
    while (!lex_at_end(l)) {
        lex_skip_ws(l);
        var c;
        c = lex_peek(l);
        if (c == 47) {
            if (lex_peek_next(l) == 47) {
                lex_skip_comment(l);
            } else {
                break;
            }
        } else {
            break;
        }
    }
}

// ============================================
// Keyword Recognition
// ============================================

func lex_check_keyword(ptr, len) {
    if (str_eq(ptr, len, "func", 4)) { return TOKEN_FUNC; }
    if (str_eq(ptr, len, "var", 3)) { return TOKEN_VAR; }
    if (str_eq(ptr, len, "const", 5)) { return TOKEN_CONST; }
    if (str_eq(ptr, len, "return", 6)) { return TOKEN_RETURN; }
    if (str_eq(ptr, len, "if", 2)) { return TOKEN_IF; }
    if (str_eq(ptr, len, "else", 4)) { return TOKEN_ELSE; }
    if (str_eq(ptr, len, "while", 5)) { return TOKEN_WHILE; }
    if (str_eq(ptr, len, "for", 3)) { return TOKEN_FOR; }
    if (str_eq(ptr, len, "switch", 6)) { return TOKEN_SWITCH; }
    if (str_eq(ptr, len, "case", 4)) { return TOKEN_CASE; }
    if (str_eq(ptr, len, "default", 7)) { return TOKEN_DEFAULT; }
    if (str_eq(ptr, len, "break", 5)) { return TOKEN_BREAK; }
    if (str_eq(ptr, len, "asm", 3)) { return TOKEN_ASM; }
    if (str_eq(ptr, len, "import", 6)) { return TOKEN_IMPORT; }
    if (str_eq(ptr, len, "u8", 2)) { return TOKEN_U8; }
    if (str_eq(ptr, len, "u16", 3)) { return TOKEN_U16; }
    if (str_eq(ptr, len, "u32", 3)) { return TOKEN_U32; }
    if (str_eq(ptr, len, "u64", 3)) { return TOKEN_U64; }
    if (str_eq(ptr, len, "i64", 3)) { return TOKEN_I64; }
    return TOKEN_IDENTIFIER;
}

// ============================================
// Token Structure
// Token: [kind, ptr, len, line, col]
// ============================================

func tok_new(kind, ptr, len, line, col) {
    var t;
    t = heap_alloc(40);
    ptr64[t] = kind;
    ptr64[t + 8] = ptr;
    ptr64[t + 16] = len;
    ptr64[t + 24] = line;
    ptr64[t + 32] = col;
    return t;
}

func tok_kind(t) { return ptr64[t]; }
func tok_ptr(t) { return ptr64[t + 8]; }
func tok_len(t) { return ptr64[t + 16]; }
func tok_line(t) { return ptr64[t + 24]; }
func tok_col(t) { return ptr64[t + 32]; }

// ============================================
// Main Lexer Function
// ============================================

func lex_next(l) {
    lex_skip_ws_and_comments(l);
    
    var line;
    line = ptr64[l + 24];
    var col;
    col = ptr64[l + 32];
    
    if (lex_at_end(l)) {
        return tok_new(TOKEN_EOF, 0, 0, line, col);
    }
    
    var start;
    start = ptr64[l + 16];
    var c;
    c = lex_advance(l);
    var src;
    src = ptr64[l];
    
    // Identifier or keyword
    if (is_alpha(c)) {
        while (!lex_at_end(l)) {
            if (is_alnum(lex_peek(l))) {
                lex_advance(l);
            } else {
                break;
            }
        }
        var len;
        len = ptr64[l + 16] - start;
        var kind;
        kind = lex_check_keyword(src + start, len);
        return tok_new(kind, src + start, len, line, col);
    }
    
    // Number
    if (is_digit(c)) {
        while (!lex_at_end(l)) {
            if (is_digit(lex_peek(l))) {
                lex_advance(l);
            } else {
                break;
            }
        }
        var len;
        len = ptr64[l + 16] - start;
        return tok_new(TOKEN_NUMBER, src + start, len, line, col);
    }
    
    // String literal
    if (c == 34) {
        // c == '"'
        while (!lex_at_end(l)) {
            var ch;
            ch = lex_peek(l);
            if (ch == 34) {
                // End of string
                lex_advance(l);
                break;
            }
            if (ch == 92) {
                // Backslash - skip escape sequence
                lex_advance(l);
                if (!lex_at_end(l)) {
                    lex_advance(l);
                }
            } else {
                lex_advance(l);
            }
        }
        var len;
        len = ptr64[l + 16] - start;
        // Return token pointing to the opening quote
        return tok_new(TOKEN_STRING, src + start, len, line, col);
    }
    
    // Two-char operators
    if (c == 61) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_EQEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_EQ, src + start, 1, line, col);
    }
    if (c == 33) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_BANGEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_BANG, src + start, 1, line, col);
    }
    if (c == 60) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_LTEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_LT, src + start, 1, line, col);
    }
    if (c == 62) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_GTEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_GT, src + start, 1, line, col);
    }
    
    // Single-char tokens
    if (c == 40) { return tok_new(TOKEN_LPAREN, src + start, 1, line, col); }
    if (c == 41) { return tok_new(TOKEN_RPAREN, src + start, 1, line, col); }
    if (c == 123) { return tok_new(TOKEN_LBRACE, src + start, 1, line, col); }
    if (c == 125) { return tok_new(TOKEN_RBRACE, src + start, 1, line, col); }
    if (c == 91) { return tok_new(TOKEN_LBRACKET, src + start, 1, line, col); }
    if (c == 93) { return tok_new(TOKEN_RBRACKET, src + start, 1, line, col); }
    if (c == 59) { return tok_new(TOKEN_SEMICOLON, src + start, 1, line, col); }
    if (c == 58) { return tok_new(TOKEN_COLON, src + start, 1, line, col); }
    if (c == 44) { return tok_new(TOKEN_COMMA, src + start, 1, line, col); }
    if (c == 46) { return tok_new(TOKEN_DOT, src + start, 1, line, col); }
    if (c == 43) { return tok_new(TOKEN_PLUS, src + start, 1, line, col); }
    if (c == 45) {
        if (lex_peek(l) == 62) {
            lex_advance(l);
            return tok_new(TOKEN_ARROW, src + start, 2, line, col);
        }
        return tok_new(TOKEN_MINUS, src + start, 1, line, col);
    }
    if (c == 42) { return tok_new(TOKEN_STAR, src + start, 1, line, col); }
    if (c == 47) { return tok_new(TOKEN_SLASH, src + start, 1, line, col); }
    if (c == 37) { return tok_new(TOKEN_PERCENT, src + start, 1, line, col); }
    if (c == 94) { return tok_new(TOKEN_CARET, src + start, 1, line, col); }
    if (c == 38) { return tok_new(TOKEN_AMPERSAND, src + start, 1, line, col); }
    
    // Unknown - return EOF
    return tok_new(TOKEN_EOF, 0, 0, line, col);
}

// ============================================
// Tokenize entire source
// ============================================

func lex_all(src, len) {
    var l;
    l = lex_new(src, len);
    var tokens;
    tokens = vec_new(256);
    while (1) {
        var tok;
        tok = lex_next(l);
        vec_push(tokens, tok);
        if (tok_kind(tok) == TOKEN_EOF) { break; }
    }
    return tokens;
}

// v3.6 Compiler - Part 3: AST Node Constructors
// All AST nodes use heap-allocated arrays

// ============================================
// Expression Nodes
// ============================================

// AST_LITERAL: [kind, value]
func ast_literal(val) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_LITERAL;
    ptr64[n + 8] = val;
    return n;
}

// AST_IDENT: [kind, name_ptr, name_len]
func ast_ident(name_ptr, name_len) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_IDENT;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    return n;
}

// AST_STRING: [kind, str_ptr, str_len]
// str_ptr points to the opening quote, str_len includes quotes
func ast_string(str_ptr, str_len) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_STRING;
    ptr64[n + 8] = str_ptr;
    ptr64[n + 16] = str_len;
    return n;
}

// AST_BINARY: [kind, op, left, right]
func ast_binary(op, left, right) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_BINARY;
    ptr64[n + 8] = op;
    ptr64[n + 16] = left;
    ptr64[n + 24] = right;
    return n;
}

// AST_UNARY: [kind, op, operand]
func ast_unary(op, operand) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_UNARY;
    ptr64[n + 8] = op;
    ptr64[n + 16] = operand;
    return n;
}

// AST_CALL: [kind, name_ptr, name_len, args_vec]
func ast_call(name_ptr, name_len, args) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CALL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = args;
    return n;
}

// AST_ADDR_OF: [kind, operand]
func ast_addr_of(operand) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_ADDR_OF;
    ptr64[n + 8] = operand;
    return n;
}

// AST_DEREF: [kind, operand]
func ast_deref(operand) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_DEREF;
    ptr64[n + 8] = operand;
    return n;
}

// AST_DEREF8: [kind, operand] - byte dereference
func ast_deref8(operand) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_DEREF8;
    ptr64[n + 8] = operand;
    return n;
}

// ast_index removed - use *ptr dereference instead

// AST_CAST: [kind, expr, target_type, target_ptr_depth]
func ast_cast(expr, target_type, ptr_depth) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CAST;
    ptr64[n + 8] = expr;
    ptr64[n + 16] = target_type;
    ptr64[n + 24] = ptr_depth;
    return n;
}

// ============================================
// Statement Nodes
// ============================================

// AST_RETURN: [kind, expr]
func ast_return(expr) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_RETURN;
    ptr64[n + 8] = expr;
    return n;
}

// AST_VAR_DECL: [kind, name_ptr, name_len, type_kind, ptr_depth, init_expr]
func ast_var_decl(name_ptr, name_len, type_kind, ptr_depth, init) {
    var n;
    n = heap_alloc(48);
    ptr64[n] = AST_VAR_DECL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = type_kind;
    ptr64[n + 32] = ptr_depth;
    ptr64[n + 40] = init;
    return n;
}

// AST_CONST_DECL: [kind, name_ptr, name_len, value]
func ast_const_decl(name_ptr, name_len, value) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CONST_DECL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = value;
    return n;
}

// AST_ASSIGN: [kind, target, value]
func ast_assign(target, value) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_ASSIGN;
    ptr64[n + 8] = target;
    ptr64[n + 16] = value;
    return n;
}

// AST_EXPR_STMT: [kind, expr]
func ast_expr_stmt(expr) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_EXPR_STMT;
    ptr64[n + 8] = expr;
    return n;
}

// AST_IF: [kind, cond, then_block, else_block]
func ast_if(cond, then_blk, else_blk) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_IF;
    ptr64[n + 8] = cond;
    ptr64[n + 16] = then_blk;
    ptr64[n + 24] = else_blk;
    return n;
}

// AST_WHILE: [kind, cond, body]
func ast_while(cond, body) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_WHILE;
    ptr64[n + 8] = cond;
    ptr64[n + 16] = body;
    return n;
}

// AST_FOR: [kind, init, cond, update, body]
func ast_for(init, cond, update, body) {
    var n;
    n = heap_alloc(40);
    ptr64[n] = AST_FOR;
    ptr64[n + 8] = init;
    ptr64[n + 16] = cond;
    ptr64[n + 24] = update;
    ptr64[n + 32] = body;
    return n;
}

// AST_SWITCH: [kind, expr, cases_vec]
func ast_switch(expr, cases) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_SWITCH;
    ptr64[n + 8] = expr;
    ptr64[n + 16] = cases;
    return n;
}

// AST_CASE: [kind, value, body, is_default]
func ast_case(value, body, is_default) {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CASE;
    ptr64[n + 8] = value;
    ptr64[n + 16] = body;
    ptr64[n + 24] = is_default;
    return n;
}

// AST_BREAK: [kind]
func ast_break() {
    var n;
    n = heap_alloc(8);
    ptr64[n] = AST_BREAK;
    return n;
}

// AST_ASM: [kind, text_vec]
func ast_asm(text_vec) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_ASM;
    ptr64[n + 8] = text_vec;
    return n;
}

// AST_BLOCK: [kind, stmts_vec]
func ast_block(stmts) {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_BLOCK;
    ptr64[n + 8] = stmts;
    return n;
}

// ============================================
// Top-level Nodes
// ============================================

// AST_FUNC: [kind, name_ptr, name_len, params_vec, ret_type, body]
func ast_func(name_ptr, name_len, params, ret_type, body) {
    var n;
    n = heap_alloc(48);
    ptr64[n] = AST_FUNC;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = params;
    ptr64[n + 32] = ret_type;
    ptr64[n + 40] = body;
    return n;
}

// AST_PROGRAM: [kind, funcs_vec, consts_vec, imports_vec, globals_vec]
func ast_program(funcs, consts, imports) {
    var n;
    n = heap_alloc(40);
    ptr64[n] = AST_PROGRAM;
    ptr64[n + 8] = funcs;
    ptr64[n + 16] = consts;
    ptr64[n + 24] = imports;
    ptr64[n + 32] = 0;  // globals (set by caller if needed)
    return n;
}

// AST_IMPORT: [kind, path_ptr, path_len]
// path is like "io" or "std/io"
func ast_import(path_ptr, path_len) {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_IMPORT;
    ptr64[n + 8] = path_ptr;
    ptr64[n + 16] = path_len;
    return n;
}

// ============================================
// AST Accessors
// ============================================

func ast_kind(n) { return ptr64[n]; }

// v3.6 Compiler - Part 4: Parser
// Parser structure: [tokens_vec, cur]

// ============================================
// Parser Core
// ============================================

func parse_new(tokens) {
    var p;
    p = heap_alloc(16);
    ptr64[p] = tokens;
    ptr64[p + 8] = 0;
    return p;
}

func parse_peek(p) {
    var vec;
    vec = ptr64[p];
    var cur;
    cur = ptr64[p + 8];
    if (cur >= vec_len(vec)) { return 0; }
    return vec_get(vec, cur);
}

func parse_peek_kind(p) {
    var tok;
    tok = parse_peek(p);
    if (tok == 0) { return TOKEN_EOF; }
    return tok_kind(tok);
}

func parse_adv(p) {
    ptr64[p + 8] = ptr64[p + 8] + 1;
}

func parse_prev(p) {
    var vec;
    vec = ptr64[p];
    var cur;
    cur = ptr64[p + 8];
    if (cur == 0) { return 0; }
    return vec_get(vec, cur - 1);
}

func parse_match(p, kind) {
    if (parse_peek_kind(p) == kind) {
        parse_adv(p);
        return 1;
    }
    return 0;
}

func parse_consume(p, kind) {
    if (!parse_match(p, kind)) {
        emit_stderr("[ERROR] Expected token kind ", 29);
        emit_u64(kind);
        emit(" but got ", 9);
        emit_u64(parse_peek_kind(p));
        emit_nl();
        panic();
    }
}

// ============================================
// Type Parsing
// ============================================

func parse_base_type(p) {
    var k;
    k = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); return TYPE_U8; }
    if (k == TOKEN_U16) { parse_adv(p); return TYPE_U16; }
    if (k == TOKEN_U32) { parse_adv(p); return TYPE_U32; }
    if (k == TOKEN_U64) { parse_adv(p); return TYPE_U64; }
    if (k == TOKEN_I64) { parse_adv(p); return TYPE_I64; }
    return TYPE_VOID;
}

// Parse type with pointers: *u8, **i64, etc.
// Returns [base_type, ptr_depth]
func parse_type(p) {
    var depth;
    depth = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }
    var base;
    base = parse_base_type(p);
    var result;
    result = heap_alloc(16);
    ptr64[result] = base;
    ptr64[result + 8] = depth;
    return result;
}

// ============================================
// Expression Parsing
// ============================================

func parse_num_val(tok) {
    var ptr;
    ptr = tok_ptr(tok);
    var len;
    len = tok_len(tok);
    var val;
    val = 0;
    var i;
    i = 0;
    while (i < len) {
        var c;
        c = ptr8[ptr + i];
        val = val * 10 + (c - 48);
        i = i + 1;
    }
    return val;
}

// primary := NUMBER | STRING | IDENT | '(' expr ')' | '&' IDENT | '*' unary
func parse_primary(p) {
    var k;
    k = parse_peek_kind(p);
    
    // Number literal
    if (k == TOKEN_NUMBER) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        return ast_literal(parse_num_val(tok));
    }
    
    // String literal
    if (k == TOKEN_STRING) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        return ast_string(tok_ptr(tok), tok_len(tok));
    }
    
    // Address-of: &ident
    if (k == TOKEN_AMPERSAND) {
        parse_adv(p);
        var tok;
        tok = parse_peek(p);
        if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
            emit_stderr("[ERROR] Expected identifier after &\n", 37);
            return 0;
        }
        parse_adv(p);
        var ident;
        ident = ast_ident(tok_ptr(tok), tok_len(tok));
        return ast_addr_of(ident);
    }
    
    // Dereference: *expr
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_deref(operand);
    }
    
    // Parenthesized expression or cast: (type)expr or (expr)
    if (k == TOKEN_LPAREN) {
        parse_adv(p);
        
        // Check if next token is a type (cast) or * (pointer type cast)
        var next_k;
        next_k = parse_peek_kind(p);
        if (next_k == TOKEN_STAR) {
            // Pointer type cast: (*i64)expr, (**u8)expr
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U8) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U16) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U32) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U64) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_I64) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        
        // Regular parenthesized expression
        var expr;
        expr = parse_expr(p);
        parse_consume(p, TOKEN_RPAREN);
        return expr;
    }
    
    // Check for ptr64[expr] or ptr8[expr] special syntax first
    if (k == TOKEN_IDENTIFIER) {
        var tok;
        tok = parse_peek(p);
        var ptr_kind;
        ptr_kind = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
        if (ptr_kind > 0) {
            var result;
            result = parse_ptr_access(p);
            if (result != 0) {
                return result;
            }
        }
    }
    
    // Identifier or function call
    if (k == TOKEN_IDENTIFIER) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        
        // Check for function call
        if (parse_peek_kind(p) == TOKEN_LPAREN) {
            parse_adv(p);
            var args;
            args = vec_new(8);
            if (parse_peek_kind(p) != TOKEN_RPAREN) {
                vec_push(args, parse_expr(p));
                while (parse_match(p, TOKEN_COMMA)) {
                    vec_push(args, parse_expr(p));
                }
            }
            parse_consume(p, TOKEN_RPAREN);
            return ast_call(tok_ptr(tok), tok_len(tok), args);
        }
        
        return ast_ident(tok_ptr(tok), tok_len(tok));
    }
    
    return 0;
}

// postfix := primary ('[' expr ']')*
func parse_postfix(p) {
    var left;
    left = parse_primary(p);
    
    // Handle arr[expr] index syntax - treat as *(arr + expr)
    while (parse_peek_kind(p) == TOKEN_LBRACKET) {
        parse_adv(p);  // consume '['
        var idx;
        idx = parse_expr(p);
        parse_consume(p, TOKEN_RBRACKET);
        // Treat as *(left + idx) - dereference at (base + index)
        left = ast_deref(ast_binary(TOKEN_PLUS, left, idx));
    }
    
    return left;
}

// Check if identifier is ptr64 or ptr8 special syntax
func is_ptr_keyword(ptr, len) {
    if (len == 5) {
        if (ptr8[ptr] == 112) {     // 'p'
            if (ptr8[ptr+1] == 116) { // 't'
                if (ptr8[ptr+2] == 114) { // 'r'
                    if (ptr8[ptr+3] == 54) { // '6'
                        if (ptr8[ptr+4] == 52) { // '4'
                            return 64;
                        }
                    }
                }
            }
        }
    }
    if (len == 4) {
        if (ptr8[ptr] == 112) {     // 'p'
            if (ptr8[ptr+1] == 116) { // 't'
                if (ptr8[ptr+2] == 114) { // 'r'
                    if (ptr8[ptr+3] == 56) { // '8'
                        return 8;
                    }
                }
            }
        }
    }
    return 0;
}

// Parse ptr64[expr] or ptr8[expr] as special syntax
func parse_ptr_access(p) {
    var tok;
    tok = parse_peek(p);
    var ptr_kind;
    ptr_kind = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
    
    if (ptr_kind > 0) {
        // Check if next token is [
        var next;
        parse_adv(p);  // consume ptr64/ptr8
        if (parse_peek_kind(p) == TOKEN_LBRACKET) {
            parse_adv(p);  // consume '['
            var idx;
            idx = parse_expr(p);
            parse_consume(p, TOKEN_RBRACKET);
            // For ptr64[x], treat as *(x) - deref at x
            // For ptr8[x], use AST_DEREF8
            if (ptr_kind == 64) {
                return ast_deref(idx);
            } else {
                // ptr8[x] - byte dereference
                return ast_deref8(idx);
            }
        } else {
            // Not followed by [, treat as regular identifier
            return ast_ident(tok_ptr(tok), tok_len(tok));
        }
    }
    return 0;  // Not a ptr keyword
}

// unary := ('*' | '&' | '-' | '!') unary | postfix
func parse_unary(p) {
    var k;
    k = parse_peek_kind(p);
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_deref(operand);
    }
    
    if (k == TOKEN_MINUS) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_unary(TOKEN_MINUS, operand);
    }
    
    if (k == TOKEN_BANG) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_unary(TOKEN_BANG, operand);
    }
    
    return parse_postfix(p);
}

// mul := unary (('*' | '/') unary)*
func parse_mul(p) {
    var left;
    left = parse_unary(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_STAR) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_STAR, left, right);
        } else if (k == TOKEN_SLASH) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_SLASH, left, right);
        } else if (k == TOKEN_PERCENT) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_PERCENT, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// add := mul (('+' | '-') mul)*
func parse_add(p) {
    var left;
    left = parse_mul(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_PLUS) {
            parse_adv(p);
            var right;
            right = parse_mul(p);
            left = ast_binary(TOKEN_PLUS, left, right);
        } else if (k == TOKEN_MINUS) {
            parse_adv(p);
            var right;
            right = parse_mul(p);
            left = ast_binary(TOKEN_MINUS, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// bitxor := add (('^') add)*
func parse_bitxor(p) {
    var left;
    left = parse_add(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_CARET) {
            parse_adv(p);
            var right;
            right = parse_add(p);
            left = ast_binary(TOKEN_CARET, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// rel := bitxor (('<' | '>' | '<=' | '>=') bitxor)*
func parse_rel(p) {
    var left;
    left = parse_bitxor(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_LT) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_LT, left, right);
        } else if (k == TOKEN_GT) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_GT, left, right);
        } else if (k == TOKEN_LTEQ) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_LTEQ, left, right);
        } else if (k == TOKEN_GTEQ) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_GTEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// eq := rel (('==' | '!=') rel)*
func parse_eq(p) {
    var left;
    left = parse_rel(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_EQEQ) {
            parse_adv(p);
            var right;
            right = parse_rel(p);
            left = ast_binary(TOKEN_EQEQ, left, right);
        } else if (k == TOKEN_BANGEQ) {
            parse_adv(p);
            var right;
            right = parse_rel(p);
            left = ast_binary(TOKEN_BANGEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_expr(p) {
    return parse_eq(p);
}

// ============================================
// Statement Parsing
// ============================================

// var_decl := 'var' IDENT (':' type)? ('=' expr)? ';'
func parse_var_decl(p) {
    parse_consume(p, TOKEN_VAR);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind;
    type_kind = TYPE_I64;
    var ptr_depth;
    ptr_depth = 0;
    
    // Optional type annotation
    if (parse_match(p, TOKEN_COLON)) {
        var ty;
        ty = parse_type(p);
        type_kind = ptr64[ty];
        ptr_depth = ptr64[ty + 8];
    }
    
    var init;
    init = 0;
    
    // Optional initializer
    if (parse_match(p, TOKEN_EQ)) {
        init = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_var_decl(tok_ptr(name_tok), tok_len(name_tok), type_kind, ptr_depth, init);
}

// assign_or_expr := expr ('=' expr)? ';'
func parse_assign_or_expr(p) {
    var expr;
    expr = parse_expr(p);
    
    if (parse_match(p, TOKEN_EQ)) {
        var val;
        val = parse_expr(p);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, val);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_expr_stmt(expr);
}

// if_stmt := 'if' '(' expr ')' block ('else' (block | if_stmt))?
func parse_if_stmt(p) {
    parse_consume(p, TOKEN_IF);
    parse_consume(p, TOKEN_LPAREN);
    var cond;
    cond = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var then_blk;
    then_blk = parse_block(p);
    
    var else_blk;
    else_blk = 0;
    if (parse_match(p, TOKEN_ELSE)) {
        // Support `else if (...) { ... }` by parsing the nested if-statement and
        // wrapping it into a single-statement block.
        if (parse_peek_kind(p) == TOKEN_IF) {
            var else_stmt;
            else_stmt = parse_if_stmt(p);
            var stmts;
            stmts = vec_new(1);
            vec_push(stmts, else_stmt);
            else_blk = ast_block(stmts);
        } else {
            else_blk = parse_block(p);
        }
    }
    
    return ast_if(cond, then_blk, else_blk);
}

// while_stmt := 'while' '(' expr ')' block
func parse_while_stmt(p) {
    parse_consume(p, TOKEN_WHILE);
    parse_consume(p, TOKEN_LPAREN);
    var cond;
    cond = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var body;
    body = parse_block(p);
    
    return ast_while(cond, body);
}

// for_stmt := 'for' '(' init? ';' cond? ';' update? ')' block
func parse_for_stmt(p) {
    parse_consume(p, TOKEN_FOR);
    parse_consume(p, TOKEN_LPAREN);
    
    var init;
    init = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        if (parse_peek_kind(p) == TOKEN_VAR) {
            init = parse_var_decl(p);
            // parse_var_decl already consumed semicolon
        } else {
            // Parse assignment or expression
            var lhs;
            lhs = parse_expr(p);
            if (parse_match(p, TOKEN_EQ)) {
                var rhs;
                rhs = parse_expr(p);
                init = ast_assign(lhs, rhs);
            } else {
                init = lhs;
            }
            parse_consume(p, TOKEN_SEMICOLON);
        }
    } else {
        parse_consume(p, TOKEN_SEMICOLON);
    }
    
    var cond;
    cond = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        cond = parse_expr(p);
    }
    parse_consume(p, TOKEN_SEMICOLON);
    
    var update;
    update = 0;
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        var upd_lhs;
        upd_lhs = parse_expr(p);
        if (parse_match(p, TOKEN_EQ)) {
            var upd_rhs;
            upd_rhs = parse_expr(p);
            update = ast_assign(upd_lhs, upd_rhs);
        } else {
            update = upd_lhs;
        }
    }
    parse_consume(p, TOKEN_RPAREN);
    
    var body;
    body = parse_block(p);
    
    return ast_for(init, cond, update, body);
}

// switch_stmt := 'switch' '(' expr ')' '{' case* '}'
// case := ('case' NUMBER ':' stmt*) | ('default' ':' stmt*)
func parse_switch_stmt(p) {
    parse_consume(p, TOKEN_SWITCH);
    parse_consume(p, TOKEN_LPAREN);
    var expr;
    expr = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    parse_consume(p, TOKEN_LBRACE);
    
    var cases;
    cases = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        var is_default;
        is_default = 0;
        var value;
        value = 0;
        
        if (parse_peek_kind(p) == TOKEN_CASE) {
            parse_consume(p, TOKEN_CASE);
            value = parse_expr(p);
        } else {
            if (parse_peek_kind(p) == TOKEN_DEFAULT) {
                parse_consume(p, TOKEN_DEFAULT);
                is_default = 1;
            } else {
                break;
            }
        }
        
        parse_consume(p, TOKEN_COLON);
        
        var stmts;
        stmts = vec_new(8);
        while (parse_peek_kind(p) != TOKEN_CASE) {
            if (parse_peek_kind(p) == TOKEN_DEFAULT) { break; }
            if (parse_peek_kind(p) == TOKEN_RBRACE) { break; }
            if (parse_peek_kind(p) == TOKEN_EOF) { break; }
            vec_push(stmts, parse_stmt(p));
        }
        
        var case_body;
        case_body = ast_block(stmts);
        vec_push(cases, ast_case(value, case_body, is_default));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    return ast_switch(expr, cases);
}

// break_stmt := 'break' ';'
func parse_break_stmt(p) {
    parse_consume(p, TOKEN_BREAK);
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_break();
}

// asm_stmt := 'asm' '{' ... '}'
// Parses inline assembly block and stores raw assembly text with newlines
func parse_asm_stmt(p) {
    parse_consume(p, TOKEN_ASM);
    parse_consume(p, TOKEN_LBRACE);
    
    // Collect all tokens until closing brace as raw text
    var asm_text;
    asm_text = vec_new(256);
    
    var prev_line;
    prev_line = -1;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) {
            emit_stderr("[ERROR] Unexpected EOF in asm block\n", 38);
            panic();
        }
        
        var tok;
        tok = parse_peek(p);
        var cur_line;
        cur_line = tok_line(tok);
        
        // Add newline if we moved to a new line
        if (prev_line >= 0) {
            if (cur_line > prev_line) {
                vec_push(asm_text, 10);  // newline
            } else {
                vec_push(asm_text, 32);  // space
            }
        }
        prev_line = cur_line;
        
        // Add token text
        var ptr;
        ptr = tok_ptr(tok);
        var len;
        len = tok_len(tok);
        var i;
        i = 0;
        while (i < len) {
            vec_push(asm_text, ptr8[ptr + i]);
            i = i + 1;
        }
        
        parse_adv(p);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return ast_asm(asm_text);
}

// return_stmt := 'return' expr? ';'
func parse_return_stmt(p) {
    parse_consume(p, TOKEN_RETURN);
    
    var expr;
    expr = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        expr = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_return(expr);
}

// const_decl := 'const' IDENT '=' NUMBER ';'
func parse_const_decl(p) {
    parse_consume(p, TOKEN_CONST);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_EQ);
    
    var val_tok;
    val_tok = parse_peek(p);
    parse_consume(p, TOKEN_NUMBER);
    
    var value;
    value = parse_num_val(val_tok);
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_const_decl(tok_ptr(name_tok), tok_len(name_tok), value);
}

// import_decl := 'import' IDENT ('.' IDENT)* ';'
// Returns AST_IMPORT with path like "io" or "std/io"
func parse_import_decl(p) {
    parse_consume(p, TOKEN_IMPORT);
    
    // First identifier
    var first_tok;
    first_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var path_ptr;
    path_ptr = tok_ptr(first_tok);
    var path_len;
    path_len = tok_len(first_tok);
    
    // Handle dotted path: io.file -> io/file
    while (parse_match(p, TOKEN_DOT)) {
        var next_tok;
        next_tok = parse_peek(p);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        // Concatenate: path + "/" + next
        var slash;
        slash = heap_alloc(1);
        ptr8[slash] = 47;  // '/'
        
        var tmp;
        tmp = str_concat(path_ptr, path_len, slash, 1);
        path_ptr = str_concat(tmp, path_len + 1, tok_ptr(next_tok), tok_len(next_tok));
        path_len = path_len + 1 + tok_len(next_tok);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_import(path_ptr, path_len);
}

func parse_stmt(p) {
    var k;
    k = parse_peek_kind(p);
    
    if (k == TOKEN_VAR) { return parse_var_decl(p); }
    if (k == TOKEN_IF) { return parse_if_stmt(p); }
    if (k == TOKEN_WHILE) { return parse_while_stmt(p); }
    if (k == TOKEN_FOR) { return parse_for_stmt(p); }
    if (k == TOKEN_SWITCH) { return parse_switch_stmt(p); }
    if (k == TOKEN_BREAK) { return parse_break_stmt(p); }
    if (k == TOKEN_ASM) { return parse_asm_stmt(p); }
    if (k == TOKEN_RETURN) { return parse_return_stmt(p); }
    
    return parse_assign_or_expr(p);
}

func parse_block(p) {
    parse_consume(p, TOKEN_LBRACE);
    
    var stmts;
    stmts = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        vec_push(stmts, parse_stmt(p));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    return ast_block(stmts);
}

// ============================================
// Function Parsing
// ============================================

// param := IDENT (':' type)?
func parse_param(p) {
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind;
    var ptr_depth;
    type_kind = 0;  // default: i64
    ptr_depth = 0;
    
    // Type annotation is optional
    if (parse_match(p, TOKEN_COLON)) {
        var ty;
        ty = parse_type(p);
        type_kind = ptr64[ty];
        ptr_depth = ptr64[ty + 8];
    }
    
    // Return: [name_ptr, name_len, type_kind, ptr_depth]
    var param;
    param = heap_alloc(32);
    ptr64[param] = tok_ptr(name_tok);
    ptr64[param + 8] = tok_len(name_tok);
    ptr64[param + 16] = type_kind;
    ptr64[param + 24] = ptr_depth;
    return param;
}

// func := 'func' IDENT '(' params? ')' ('->' type)? block
func parse_func_decl(p) {
    parse_consume(p, TOKEN_FUNC);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LPAREN);
    
    var params;
    params = vec_new(8);
    
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        vec_push(params, parse_param(p));
        while (parse_match(p, TOKEN_COMMA)) {
            vec_push(params, parse_param(p));
        }
    }
    
    parse_consume(p, TOKEN_RPAREN);
    
    // Optional return type: -> type
    var ret_type;
    var ret_ptr_depth;
    ret_type = TYPE_VOID;
    ret_ptr_depth = 0;
    
    if (parse_match(p, TOKEN_ARROW)) {
        var ty;
        ty = parse_type(p);
        ret_type = ptr64[ty];
        ret_ptr_depth = ptr64[ty + 8];
    }
    
    var body;
    body = parse_block(p);
    
    return ast_func(tok_ptr(name_tok), tok_len(name_tok), params, ret_type, body);
}

// ============================================
// Program Parsing
// ============================================

func parse_program(p) {
    var funcs;
    funcs = vec_new(16);
    var consts;
    consts = vec_new(64);
    var imports;
    imports = vec_new(16);
    var globals;
    globals = vec_new(32);
    
    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_FUNC) {
            vec_push(funcs, parse_func_decl(p));
        } else if (k == TOKEN_CONST) {
            vec_push(consts, parse_const_decl(p));
        } else if (k == TOKEN_VAR) {
            // Parse global var declaration
            parse_consume(p, TOKEN_VAR);
            var tok;
            tok = parse_peek(p);
            var name_ptr;
            name_ptr = tok_ptr(tok);
            var name_len;
            name_len = tok_len(tok);
            parse_consume(p, TOKEN_IDENTIFIER);
            parse_consume(p, TOKEN_SEMICOLON);
            // Store global var info: [name_ptr, name_len]
            var ginfo;
            ginfo = heap_alloc(16);
            ptr64[ginfo] = name_ptr;
            ptr64[ginfo + 8] = name_len;
            vec_push(globals, ginfo);
        } else if (k == TOKEN_IMPORT) {
            vec_push(imports, parse_import_decl(p));
        } else {
            emit_stderr("[ERROR] Expected function, const, or import\n", 45);
            break;
        }
    }
    
    var prog;
    prog = ast_program(funcs, consts, imports);
    ptr64[prog + 32] = globals;
    return prog;
}

// v3.6 Compiler - Part 5: Code Generator
// Generates x86-64 NASM assembly

// ============================================
// Symbol Table
// Structure: [names_vec, offsets_vec, types_vec, count, stack_offset]
// ============================================

var g_symtab;
var g_label_counter;
var g_consts;  // Global constants table: Vec of [name_ptr, name_len, value]
var g_strings; // String literals table: Vec of [str_ptr, str_len, label_id]
var g_loop_labels; // Stack of loop end labels for break statements
var g_globals; // Global variables: Vec of [name_ptr, name_len]

func symtab_new() {
    var s;
    s = heap_alloc(40);
    ptr64[s] = vec_new(64);       // names (ptr to name structs)
    ptr64[s + 8] = vec_new(64);   // stack offsets
    ptr64[s + 16] = vec_new(64);  // types
    ptr64[s + 24] = 0;            // count
    ptr64[s + 32] = 0;            // current stack offset
    return s;
}

func symtab_clear(s) {
    // Reset count and stack offset
    ptr64[s + 24] = 0;
    ptr64[s + 32] = 0;
    
    // Reset Vec lengths to 0 (crucial for correct indexing)
    var names;
    names = ptr64[s];
    ptr64[names + 8] = 0;  // names.len = 0
    
    var offsets;
    offsets = ptr64[s + 8];
    ptr64[offsets + 8] = 0;  // offsets.len = 0
    
    var types;
    types = ptr64[s + 16];
    ptr64[types + 8] = 0;  // types.len = 0
}

// Add symbol, returns stack offset
func symtab_add(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names;
    names = ptr64[s];
    var offsets;
    offsets = ptr64[s + 8];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    // Calculate size based on type
    var size;
    size = 8;  // Default to 8 bytes
    if (ptr_depth > 0) {
        size = 8;  // Pointers are 8 bytes
    } else if (type_kind == TYPE_U8) {
        size = 8;  // Still allocate 8 for alignment
    }
    
    // Update stack offset (grows downward)
    var offset;
    offset = ptr64[s + 32] - size;
    ptr64[s + 32] = offset;
    
    // Store name info
    var name_info;
    name_info = heap_alloc(16);
    ptr64[name_info] = name_ptr;
    ptr64[name_info + 8] = name_len;
    vec_push(names, name_info);
    
    // Store offset and type
    vec_push(offsets, offset);
    
    var type_info;
    type_info = heap_alloc(16);
    ptr64[type_info] = type_kind;
    ptr64[type_info + 8] = ptr_depth;
    vec_push(types, type_info);
    
    ptr64[s + 24] = count + 1;
    
    return offset;
}

// Update type of existing symbol (used during assignment)
func symtab_update_type(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names;
    names = ptr64[s];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info;
            type_info = vec_get(types, i);
            ptr64[type_info] = type_kind;
            ptr64[type_info + 8] = ptr_depth;
            return;
        }
        i = i + 1;
    }
}

// Find symbol, returns stack offset or 0 if not found
func symtab_find(s, name_ptr, name_len) {
    var names;
    names = ptr64[s];
    var offsets;
    offsets = ptr64[s + 8];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }
        i = i + 1;
    }
    
    return 0;  // Not found
}

// Check if a name is a global variable
// Returns 1 if global, 0 if not
func is_global_var(name_ptr, name_len) {
    var len;
    len = vec_len(g_globals);
    var i;
    i = 0;
    while (i < len) {
        var ginfo;
        ginfo = vec_get(g_globals, i);
        var g_ptr;
        g_ptr = ptr64[ginfo];
        var g_len;
        g_len = ptr64[ginfo + 8];
        if (str_eq(g_ptr, g_len, name_ptr, name_len)) {
            return 1;
        }
        i = i + 1;
    }
    return 0;
}

func symtab_get_type(s, name_ptr, name_len) {
    var names;
    names = ptr64[s];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(types, i);
        }
        i = i + 1;
    }
    
    return 0;
}

// ============================================
// String Literals Table
// ============================================

// Initialize string table
func string_table_init() {
    g_strings = vec_new(32);
}

// Find or add string, returns label ID
func string_get_label(str_ptr, str_len) {
    // Search existing strings
    var i;
    i = 0;
    var count;
    count = vec_len(g_strings);
    
    while (i < count) {
        var entry;
        entry = vec_get(g_strings, i);
        var e_ptr;
        e_ptr = ptr64[entry];
        var e_len;
        e_len = ptr64[entry + 8];
        
        if (str_eq(e_ptr, e_len, str_ptr, str_len)) {
            return ptr64[entry + 16];  // Return existing label_id
        }
        i = i + 1;
    }
    
    // Not found - add new entry
    var label_id;
    label_id = g_label_counter;
    g_label_counter = g_label_counter + 1;
    
    var entry;
    entry = heap_alloc(24);
    ptr64[entry] = str_ptr;
    ptr64[entry + 8] = str_len;
    ptr64[entry + 16] = label_id;
    vec_push(g_strings, entry);
    
    return label_id;
}

// Emit .data section with all strings
func string_emit_data() {
    var count;
    count = vec_len(g_strings);
    
    if (count == 0) {
        return;
    }
    
    emit("\nsection .data\n", 15);
    
    var i;
    i = 0;
    while (i < count) {
        var entry;
        entry = vec_get(g_strings, i);
        var str_ptr;
        str_ptr = ptr64[entry];
        var str_len;
        str_len = ptr64[entry + 8];
        var label_id;
        label_id = ptr64[entry + 16];
        
        emit("_str", 4);
        emit_u64(label_id);
        emit(": db ", 5);
        
        // Emit string contents (skip opening/closing quotes)
        var j;
        j = 1;  // Skip opening quote
        while (j < str_len - 1) {
            var c;
            c = ptr8[str_ptr + j];
            
            if (c == 92) {
                // Backslash escape
                j = j + 1;
                if (j < str_len - 1) {
                    var ec;
                    ec = ptr8[str_ptr + j];
                    if (ec == 110) {
                        // \n -> 10
                        emit("10", 2);
                    } else if (ec == 116) {
                        // \t -> 9
                        emit("9", 1);
                    } else if (ec == 48) {
                        // \0 -> 0
                        emit("0", 1);
                    } else if (ec == 92) {
                        // \\ -> 92
                        emit("92", 2);
                    } else if (ec == 34) {
                        // \" -> 34
                        emit("34", 2);
                    } else {
                        // Unknown escape, emit as-is
                        emit_u64(ec);
                    }
                }
            } else {
                emit_u64(c);
            }
            
            j = j + 1;
            if (j < str_len - 1) {
                emit(",", 1);
            }
        }
        
        emit(",0\n", 3);  // Null terminator
        i = i + 1;
    }
}

// Emit .bss section with global variables
func globals_emit_bss() {
    var count;
    count = vec_len(g_globals);
    
    if (count == 0) {
        return;
    }
    
    emit("\nsection .bss\n", 14);
    
    var i;
    i = 0;
    while (i < count) {
        var ginfo;
        ginfo = vec_get(g_globals, i);
        var name_ptr;
        name_ptr = ptr64[ginfo];
        var name_len;
        name_len = ptr64[ginfo + 8];
        
        emit("_gvar_", 6);
        emit(name_ptr, name_len);
        emit(": resq 1\n", 9);
        
        i = i + 1;
    }
}

// Get expression type info: returns [base_type, ptr_depth] or 0
// This is used for pointer arithmetic
func get_expr_type(node) {
    var kind;
    kind = ast_kind(node);
    
    // Identifier - lookup in symbol table
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var type_info;
        type_info = symtab_get_type(g_symtab, name_ptr, name_len);
        // If not found, return default i64
        if (type_info == 0) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = TYPE_I64;
            ptr64[result + 8] = 0;
            return result;
        }
        return type_info;
    }
    
    // String literal - returns *u8 type
    if (kind == AST_STRING) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = TYPE_U8;
        ptr64[result + 8] = 1;  // ptr_depth = 1 (*u8)
        return result;
    }
    
    // Cast - use target type
    if (kind == AST_CAST) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = ptr64[node + 16];      // target_type
        ptr64[result + 8] = ptr64[node + 24];  // ptr_depth
        return result;
    }
    
    // Address-of - pointer to operand's type
    if (kind == AST_ADDR_OF) {
        var operand;
        operand = ptr64[node + 8];
        var op_type;
        op_type = get_expr_type(operand);
        if (op_type != 0) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = ptr64[op_type];        // same base type
            ptr64[result + 8] = ptr64[op_type + 8] + 1;  // increase ptr_depth
            return result;
        }
    }
    
    // Deref - dereference type
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        var op_type;
        op_type = get_expr_type(operand);
        if (op_type != 0) {
            var depth;
            depth = ptr64[op_type + 8];
            if (depth > 0) {
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[op_type];       // same base type
                ptr64[result + 8] = depth - 1;        // decrease ptr_depth
                return result;
            }
        }
    }
    
    // Deref8 - byte dereference, returns u8
    if (kind == AST_DEREF8) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = TYPE_U8;
        ptr64[result + 8] = 0;  // not a pointer
        return result;
    }
    
    // Binary - for pointer arithmetic, result is same type as pointer operand
    if (kind == AST_BINARY) {
        var left;
        left = ptr64[node + 16];
        var right;
        right = ptr64[node + 24];
        
        // Check left operand type
        var left_type;
        left_type = get_expr_type(left);
        if (left_type != 0) {
            var l_depth;
            l_depth = ptr64[left_type + 8];
            if (l_depth > 0) {
                // Left is pointer - result is same pointer type
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[left_type];
                ptr64[result + 8] = l_depth;
                return result;
            }
        }
        
        // Check right operand type (for ptr - ptr case)
        var right_type;
        right_type = get_expr_type(right);
        if (right_type != 0) {
            var r_depth;
            r_depth = ptr64[right_type + 8];
            if (r_depth > 0) {
                // Right is pointer - result is same pointer type
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[right_type];
                ptr64[result + 8] = r_depth;
                return result;
            }
        }
        
        // Both are non-pointers - result is i64
    }
    
    // Literal - assume i64
    if (kind == AST_LITERAL) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = TYPE_I64;
        ptr64[result + 8] = 0;
        return result;
    }
    
    // Unknown - return default i64
    var result;
    result = heap_alloc(16);
    ptr64[result] = TYPE_I64;
    ptr64[result + 8] = 0;
    return result;
}

// ============================================
// Global Constants
// ============================================

// Find constant by name, returns [found, value]
func const_find(name_ptr, name_len) {
    var len;
    len = vec_len(g_consts);
    var i;
    i = 0;
    while (i < len) {
        var c;
        c = vec_get(g_consts, i);
        var c_ptr;
        c_ptr = ptr64[c];
        var c_len;
        c_len = ptr64[c + 8];
        if (str_eq(c_ptr, c_len, name_ptr, name_len)) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = 1;  // found
            ptr64[result + 8] = ptr64[c + 16];  // value
            return result;
        }
        i = i + 1;
    }
    var result;
    result = heap_alloc(16);
    ptr64[result] = 0;  // not found
    return result;
}

// ============================================
// Label Generation
// ============================================

func new_label() {
    var l;
    l = g_label_counter;
    g_label_counter = g_label_counter + 1;
    return l;
}

func emit_label(n) {
    emit(".L", 2);
    emit_u64(n);
}

func emit_label_def(n) {
    emit_label(n);
    emit(":", 1);
    emit_nl();
}

// ============================================
// Expression Codegen
// Result in RAX
// ============================================

func cg_expr(node) {
    var kind;
    kind = ast_kind(node);
    
    // Literal
    if (kind == AST_LITERAL) {
        emit("    mov rax, ", 13);
        emit_u64(ptr64[node + 8]);
        emit_nl();
        return;
    }
    
    // String literal - load address of string from .data section
    if (kind == AST_STRING) {
        var str_ptr;
        str_ptr = ptr64[node + 8];
        var str_len;
        str_len = ptr64[node + 16];
        
        // Find or add string to g_strings
        var label_id;
        label_id = string_get_label(str_ptr, str_len);
        
        emit("    lea rax, [rel _str", 22);
        emit_u64(label_id);
        emit("]\n", 2);
        return;
    }
    
    // Identifier - check constants first, then globals, then stack
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        
        // Check if it's a constant
        var c_result;
        c_result = const_find(name_ptr, name_len);
        if (ptr64[c_result] == 1) {
            emit("    mov rax, ", 13);
            emit_u64(ptr64[c_result + 8]);
            emit_nl();
            return;
        }
        
        // Check if it's a global variable
        if (is_global_var(name_ptr, name_len)) {
            emit("    mov rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    mov rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Binary operation
    if (kind == AST_BINARY) {
        var op;
        op = ptr64[node + 8];
        var left;
        left = ptr64[node + 16];
        var right;
        right = ptr64[node + 24];
        
        cg_expr(left);
        emit("    push rax", 12);
        emit_nl();
        cg_expr(right);
        emit("    mov rbx, rax", 16);
        emit_nl();
        emit("    pop rax", 11);
        emit_nl();
        
        // Pointer arithmetic: if left is pointer, scale index by pointee size
        var left_type;
        left_type = get_expr_type(left);
        var ptr_depth;
        ptr_depth = ptr64[left_type + 8];
        
        if (ptr_depth > 0) {
            // Left is a pointer - scale RHS for add/sub
            if (op == TOKEN_PLUS) {
                var psize;
                psize = get_pointee_size(ptr64[left_type], ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            } else if (op == TOKEN_MINUS) {
                var psize;
                psize = get_pointee_size(ptr64[left_type], ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            }
        }
        
        if (op == TOKEN_PLUS) {
            emit("    add rax, rbx", 16);
            emit_nl();
        } else if (op == TOKEN_MINUS) {
            emit("    sub rax, rbx", 16);
            emit_nl();
        } else if (op == TOKEN_STAR) {
            emit("    imul rax, rbx", 17);
            emit_nl();
        } else if (op == TOKEN_SLASH) {
            // Unsigned division: xor rdx, rdx; div rbx
            emit("    xor rdx, rdx", 16);
            emit_nl();
            emit("    div rbx", 11);
            emit_nl();
        } else if (op == TOKEN_PERCENT) {
            // Unsigned modulo: xor rdx, rdx; div rbx; mov rax, rdx
            emit("    xor rdx, rdx", 16);
            emit_nl();
            emit("    div rbx", 11);
            emit_nl();
            emit("    mov rax, rdx", 16);
            emit_nl();
        } else if (op == TOKEN_CARET) {
            emit("    xor rax, rbx", 16);
            emit_nl();
        } else if (op == TOKEN_LT) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setl al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_GT) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setg al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_LTEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setle al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_GTEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setge al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_EQEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    sete al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_BANGEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setne al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        }
        return;
    }
    
    // Unary minus and NOT
    if (kind == AST_UNARY) {
        var op;
        op = ptr64[node + 8];
        var operand;
        operand = ptr64[node + 16];
        
        cg_expr(operand);
        if (op == TOKEN_MINUS) {
            emit("    neg rax\n", 12);
        } else if (op == TOKEN_BANG) {
            emit("    test rax, rax\n", 18);
            emit("    setz al\n", 13);
            emit("    movzx rax, al\n", 18);
        }
        return;
    }
    
    // Address-of
    if (kind == AST_ADDR_OF) {
        var operand;
        operand = ptr64[node + 8];
        // operand should be AST_IDENT
        var name_ptr;
        name_ptr = ptr64[operand + 8];
        var name_len;
        name_len = ptr64[operand + 16];
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Dereference - type-aware memory read
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);
        
        // Get operand type to determine memory access size
        var op_type;
        op_type = get_expr_type(operand);
        var base_type;
        base_type = ptr64[op_type];
        var ptr_depth;
        ptr_depth = ptr64[op_type + 8];
        
        // After dereference, ptr_depth decreases by 1
        // If ptr_depth was 1, we're reading the base type
        if (ptr_depth == 1) {
            if (base_type == TYPE_U8) {
                emit("    movzx rax, byte [rax]", 25);
                emit_nl();
                return;
            }
            if (base_type == TYPE_U16) {
                emit("    movzx rax, word [rax]", 25);
                emit_nl();
                return;
            }
            if (base_type == TYPE_U32) {
                emit("    mov eax, [rax]", 18);
                emit_nl();
                return;
            }
        }
        // Default: 8-byte read (i64, u64, or pointer)
        emit("    mov rax, [rax]", 18);
        emit_nl();
        return;
    }
    
    // Byte dereference - ptr8[x] always reads 1 byte
    if (kind == AST_DEREF8) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);
        emit("    movzx rax, byte [rax]", 25);
        emit_nl();
        return;
    }
    
    // Index syntax removed - use *ptr dereference instead
    
    // Cast: (type)expr - mostly no-op in our system
    if (kind == AST_CAST) {
        var expr;
        expr = ptr64[node + 8];
        // target_type = ptr64[node + 16]
        // ptr_depth = ptr64[node + 24]
        // For now, just evaluate the expression
        // Type info will be used in Phase 3 for pointer arithmetic
        cg_expr(expr);
        return;
    }
    
    // Function call
    if (kind == AST_CALL) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var args;
        args = ptr64[node + 24];
        var nargs;
        nargs = vec_len(args);
        
        // Push args in reverse order
        var i;
        i = nargs - 1;
        while (i >= 0) {
            cg_expr(vec_get(args, i));
            emit("    push rax\n", 13);
            i = i - 1;
        }
        
        // Call
        emit("    call ", 9);
        emit(name_ptr, name_len);
        emit_nl();
        
        // Clean up stack
        if (nargs > 0) {
            emit("    add rsp, ", 13);
            emit_u64(nargs * 8);
            emit_nl();
        }
        return;
    }
}

// ============================================
// LValue Codegen (for assignment targets)
// Result: address in RAX
// ============================================

func cg_lvalue(node) {
    var kind;
    kind = ast_kind(node);
    
    // Identifier
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        
        // Check if it's a global variable
        if (is_global_var(name_ptr, name_len)) {
            emit("    lea rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Dereference: *ptr = val
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);  // Address is already the result
        return;
    }
    
    // Byte dereference: ptr8[x] = val
    if (kind == AST_DEREF8) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);  // Address is already the result
        return;
    }
    
    // Index syntax removed - use *ptr dereference instead
}

// ============================================
// Statement Codegen
// ============================================

func cg_stmt(node) {
    var kind;
    kind = ast_kind(node);
    
    // Return
    if (kind == AST_RETURN) {
        var expr;
        expr = ptr64[node + 8];
        if (expr != 0) {
            cg_expr(expr);
        } else {
            emit("    xor eax, eax\n", 17);
        }
        emit("    mov rsp, rbp\n", 17);
        emit("    pop rbp\n", 12);
        emit("    ret\n", 8);
        return;
    }
    
    // Variable declaration
    if (kind == AST_VAR_DECL) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var type_kind;
        type_kind = ptr64[node + 24];
        var ptr_depth;
        ptr_depth = ptr64[node + 32];
        var init;
        init = ptr64[node + 40];
        
        var offset;
        offset = symtab_add(g_symtab, name_ptr, name_len, type_kind, ptr_depth);
        
        // Stack space already reserved in function prologue
        
        // Initialize if provided
        if (init != 0) {
            // Type check: compare declared type with initializer type
            if (type_kind != 0) {
                var init_type;
                init_type = get_expr_type(init);
                if (init_type != 0) {
                    var it_base;
                    it_base = ptr64[init_type];
                    var it_depth;
                    it_depth = ptr64[init_type + 8];
                    
                    var compat;
                    compat = check_type_compat(it_base, it_depth, type_kind, ptr_depth);
                    if (compat == 1) {
                        warn("implicit type conversion in initialization", 43);
                    }
                }
            }
            
            cg_expr(init);
            emit("    mov [rbp", 12);
            if (offset < 0) {
                emit_i64(offset);
            } else {
                emit("+", 1);
                emit_u64(offset);
            }
            emit("], rax", 6);
            emit_nl();
        }
        return;
    }
    
    // Assignment
    if (kind == AST_ASSIGN) {
        var target;
        target = ptr64[node + 8];
        var value;
        value = ptr64[node + 16];
        
        // Type checking and propagation for identifier targets
        var target_kind;
        target_kind = ast_kind(target);
        if (target_kind == AST_IDENT) {
            var name_ptr;
            name_ptr = ptr64[target + 8];
            var name_len;
            name_len = ptr64[target + 16];
            
            // Get target type from symbol table
            var target_type;
            target_type = symtab_get_type(g_symtab, name_ptr, name_len);
            
            // Get value type
            var value_type;
            value_type = get_expr_type(value);
            
            if (target_type != 0) {
                if (value_type != 0) {
                    var tt_base;
                    tt_base = ptr64[target_type];
                    var tt_depth;
                    tt_depth = ptr64[target_type + 8];
                    var vt_base;
                    vt_base = ptr64[value_type];
                    var vt_depth;
                    vt_depth = ptr64[value_type + 8];
                    
                    // Check type compatibility
                    var compat;
                    compat = check_type_compat(vt_base, vt_depth, tt_base, tt_depth);
                    if (compat == 1) {
                        // Compatible but not exact - emit warning
                        warn("implicit type conversion in assignment", 39);
                    }
                    
                    // Type propagation: update target type if value is pointer
                    if (vt_depth > 0) {
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            } else {
                // Target has no type - propagate from value if it's a pointer
                if (value_type != 0) {
                    var vt_depth;
                    vt_depth = ptr64[value_type + 8];
                    if (vt_depth > 0) {
                        var vt_base;
                        vt_base = ptr64[value_type];
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            }
        }
        
        cg_expr(value);
        emit("    push rax", 12);
        emit_nl();
        cg_lvalue(target);
        emit("    pop rbx", 11);
        emit_nl();
        
        // Type-aware memory write for dereference targets
        if (target_kind == AST_DEREF) {
            var deref_operand;
            deref_operand = ptr64[target + 8];
            var op_type;
            op_type = get_expr_type(deref_operand);
            var base_type;
            base_type = ptr64[op_type];
            var ptr_depth;
            ptr_depth = ptr64[op_type + 8];
            
            if (ptr_depth == 1) {
                if (base_type == TYPE_U8) {
                    emit("    mov [rax], bl", 17);
                    emit_nl();
                    return;
                }
                if (base_type == TYPE_U16) {
                    emit("    mov [rax], bx", 17);
                    emit_nl();
                    return;
                }
                if (base_type == TYPE_U32) {
                    emit("    mov [rax], ebx", 18);
                    emit_nl();
                    return;
                }
            }
        }
        
        // Byte dereference write - ptr8[x] = val
        if (target_kind == AST_DEREF8) {
            emit("    mov [rax], bl", 17);
            emit_nl();
            return;
        }
        
        // Default: 8-byte write
        emit("    mov [rax], rbx", 18);
        emit_nl();
        return;
    }
    
    // Expression statement
    if (kind == AST_EXPR_STMT) {
        var expr;
        expr = ptr64[node + 8];
        cg_expr(expr);
        return;
    }
    
    // If statement
    if (kind == AST_IF) {
        var cond;
        cond = ptr64[node + 8];
        var then_blk;
        then_blk = ptr64[node + 16];
        var else_blk;
        else_blk = ptr64[node + 24];
        
        var else_label;
        else_label = new_label();
        var end_label;
        end_label = new_label();
        
        cg_expr(cond);
        emit("    test rax, rax", 17);
        emit_nl();
        emit("    jz ", 7);
        emit_label(else_label);
        emit_nl();
        
        cg_block(then_blk);
        
        if (else_blk != 0) {
            emit("    jmp ", 8);
            emit_label(end_label);
            emit_nl();
        }
        
        emit_label_def(else_label);
        
        if (else_blk != 0) {
            cg_block(else_blk);
            emit_label_def(end_label);
        }
        return;
    }
    
    // While statement
    if (kind == AST_WHILE) {
        var cond;
        cond = ptr64[node + 8];
        var body;
        body = ptr64[node + 16];
        
        var start_label;
        start_label = new_label();
        var end_label;
        end_label = new_label();
        
        emit_label_def(start_label);
        
        cg_expr(cond);
        emit("    test rax, rax", 17);
        emit_nl();
        emit("    jz ", 7);
        emit_label(end_label);
        emit_nl();
        
        // Push end_label for break statements
        vec_push(g_loop_labels, end_label);
        
        cg_block(body);
        
        // Pop end_label after body
        var len;
        len = vec_len(g_loop_labels);
        ptr64[g_loop_labels + 8] = len - 1;
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    // For statement
    if (kind == AST_FOR) {
        var init;
        init = ptr64[node + 8];
        var cond;
        cond = ptr64[node + 16];
        var update;
        update = ptr64[node + 24];
        var body;
        body = ptr64[node + 32];
        
        if (init != 0) {
            cg_stmt(init);
        }
        
        var start_label;
        start_label = new_label();
        var end_label;
        end_label = new_label();
        
        emit_label_def(start_label);
        
        if (cond != 0) {
            cg_expr(cond);
            emit("    test rax, rax", 17);
            emit_nl();
            emit("    jz ", 7);
            emit_label(end_label);
            emit_nl();
        }
        
        // Push end_label for break statements
        vec_push(g_loop_labels, end_label);
        
        cg_block(body);
        
        // Pop end_label after body
        var labels_len;
        labels_len = vec_len(g_loop_labels);
        ptr64[g_loop_labels + 8] = labels_len - 1;
        
        if (update != 0) {
            cg_stmt(update);
        }
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    // Switch statement
    if (kind == AST_SWITCH) {
        var expr;
        expr = ptr64[node + 8];
        var cases;
        cases = ptr64[node + 16];
        
        cg_expr(expr);
        emit("    push rax\n", 13);
        
        var end_label;
        end_label = new_label();
        
        var num_cases;
        num_cases = vec_len(cases);
        var i;
        i = 0;
        while (i < num_cases) {
            var case_node;
            case_node = vec_get(cases, i);
            var is_default;
            is_default = ptr64[case_node + 24];
            
            if (is_default == 0) {
                var value;
                value = ptr64[case_node + 8];
                var next_label;
                next_label = new_label();
                
                emit("    mov rax, [rsp]\n", 19);
                emit("    push rax\n", 13);
                cg_expr(value);
                emit("    mov rbx, rax\n", 17);
                emit("    pop rax\n", 12);
                emit("    cmp rax, rbx\n", 17);
                emit("    jne ", 8);
                emit_label(next_label);
                emit_nl();
                
                var body;
                body = ptr64[case_node + 16];
                cg_block(body);
                
                emit("    jmp ", 8);
                emit_label(end_label);
                emit_nl();
                
                emit_label_def(next_label);
            } else {
                var body;
                body = ptr64[case_node + 16];
                cg_block(body);
            }
            
            i = i + 1;
        }
        
        emit("    add rsp, 8", 14);
        emit_nl();
        emit_label_def(end_label);
        return;
    }
    
    // Break statement
    if (kind == AST_BREAK) {
        var len;
        len = vec_len(g_loop_labels);
        if (len == 0) {
            emit_stderr("[ERROR] break outside loop\n", 29);
            panic();
        }
        var label;
        label = vec_get(g_loop_labels, len - 1);
        emit("    jmp ", 8);
        emit_label(label);
        emit_nl();
        return;
    }
    
    // Inline assembly
    if (kind == AST_ASM) {
        var text_vec;
        text_vec = ptr64[node + 8];
        var asm_len;
        asm_len = vec_len(text_vec);
        
        // Emit asm with proper indentation
        var i;
        i = 0;
        var at_line_start;
        at_line_start = 1;
        while (i < asm_len) {
            var ch;
            ch = vec_get(text_vec, i);
            if (ch == 10) {  // newline
                emit_nl();
                at_line_start = 1;
            } else {
                if (at_line_start == 1) {
                    emit("    ", 4);
                    at_line_start = 0;
                }
                emit_char(ch);
            }
            i = i + 1;
        }
        emit_nl();
        return;
    }
    
    // Block
    if (kind == AST_BLOCK) {
        cg_block(node);
        return;
    }
}

func cg_block(node) {
    var stmts;
    stmts = ptr64[node + 8];
    var len;
    len = vec_len(stmts);
    var i;
    i = 0;
    while (i < len) {
        cg_stmt(vec_get(stmts, i));
        i = i + 1;
    }
}

// ============================================
// Function Codegen
// ============================================

func cg_func(node) {
    var name_ptr;
    name_ptr = ptr64[node + 8];
    var name_len;
    name_len = ptr64[node + 16];
    var params;
    params = ptr64[node + 24];
    var body;
    body = ptr64[node + 40];
    
    // Clear symbol table for new function
    symtab_clear(g_symtab);
    
    // Emit function label
    emit(name_ptr, name_len);
    emit(":\n", 2);
    
    // Prologue
    emit("    push rbp\n", 13);
    emit("    mov rbp, rsp\n", 17);
    emit("    sub rsp, 1024\n", 18);  // Reserve space for locals (will be optimized later)
    
    // Add parameters to symbol table (pushed by caller)
    var nparams;
    nparams = vec_len(params);
    var i;
    i = 0;
    while (i < nparams) {
        var param;
        param = vec_get(params, i);
        var pname;
        pname = ptr64[param];
        var plen;
        plen = ptr64[param + 8];
        var ptype;
        ptype = ptr64[param + 16];
        var pdepth;
        pdepth = ptr64[param + 24];
        
        // Parameters are at [rbp + 16 + i*8] (return addr at [rbp+8])
        // Just add to symbol table with positive offset
        var names;
        names = ptr64[g_symtab];
        var offsets;
        offsets = ptr64[g_symtab + 8];
        var types;
        types = ptr64[g_symtab + 16];
        
        var name_info;
        name_info = heap_alloc(16);
        ptr64[name_info] = pname;
        ptr64[name_info + 8] = plen;
        vec_push(names, name_info);
        
        vec_push(offsets, 16 + i * 8);
        
        var type_info;
        type_info = heap_alloc(16);
        ptr64[type_info] = ptype;
        ptr64[type_info + 8] = pdepth;
        vec_push(types, type_info);
        
        ptr64[g_symtab + 24] = ptr64[g_symtab + 24] + 1;
        
        i = i + 1;
    }
    
    // Generate body
    cg_block(body);
    
    // Default return if no explicit return
    emit("    xor eax, eax\n", 17);
    emit("    mov rsp, rbp\n", 17);
    emit("    pop rbp\n", 12);
    emit("    ret\n", 8);
}

// ============================================
// Program Codegen
// ============================================

func cg_program(prog) {
    var funcs;
    funcs = ptr64[prog + 8];
    var consts;
    consts = ptr64[prog + 16];
    var globals;
    globals = ptr64[prog + 32];
    
    // Initialize globals
    g_symtab = symtab_new();
    g_label_counter = 0;
    string_table_init();
    g_loop_labels = vec_new(16);  // Initialize loop label stack
    
    // Store global variables list for lookup
    if (globals == 0) {
        g_globals = vec_new(32);
    } else {
        g_globals = globals;
    }
    
    // Process constants: store in g_consts for lookup
    g_consts = vec_new(64);
    var clen;
    clen = vec_len(consts);
    var ci;
    ci = 0;
    while (ci < clen) {
        var c;
        c = vec_get(consts, ci);
        // AST_CONST_DECL: [kind, name_ptr, name_len, value]
        var cinfo;
        cinfo = heap_alloc(24);
        ptr64[cinfo] = ptr64[c + 8];       // name_ptr
        ptr64[cinfo + 8] = ptr64[c + 16];  // name_len
        ptr64[cinfo + 16] = ptr64[c + 24]; // value
        vec_push(g_consts, cinfo);
        ci = ci + 1;
    }
    
    // Emit header
    emit("default rel\n", 12);
    emit("section .text\n", 14);
    emit("global _start\n", 14);
    emit("_start:\n", 8);
    emit("    pop rdi          ; argc\n", 28);
    emit("    mov rsi, rsp     ; argv\n", 28);
    emit("    push rsi\n", 13);
    emit("    push rdi\n", 13);
    emit("    call main\n", 14);
    emit("    mov rdi, rax\n", 17);
    emit("    mov rax, 60\n", 16);
    emit("    syscall\n", 12);
    
    // Emit functions
    var len;
    len = vec_len(funcs);
    var i;
    i = 0;
    while (i < len) {
        cg_func(vec_get(funcs, i));
        i = i + 1;
    }
    
    // Emit string data section
    string_emit_data();
    
    // Emit global variables in bss section
    globals_emit_bss();
}

// v3.6 Compiler - Part 6: Main Entry Point with Module System

// ============================================
// Global Module State
// ============================================
var g_loaded_modules;    // HashMap: path -> 1 (tracks loaded files)
var g_all_funcs;         // Vec of all function ASTs from all modules
var g_all_consts;        // Vec of all const ASTs from all modules
var g_all_globals;       // Vec of all global var info [name_ptr, name_len]
var g_base_dir;          // Base directory for resolving imports
var g_base_dir_len;

var g_file_ptr;
var g_file_len;

// ============================================
// File Reading
// ============================================

func read_entire_file(path) {
    // Open file (O_RDONLY = 0)
    var fd;
    fd = sys_open(path, 0, 0);
    if (fd < 0) {
        return 0;  // Return 0 on failure
    }
    
    // Get file size using fstat
    // struct stat is 144 bytes, st_size at offset 48
    var statbuf;
    statbuf = heap_alloc(144);
    sys_fstat(fd, statbuf);
    var size;
    size = ptr64[statbuf + 48];
    
    // Allocate buffer
    var buf;
    buf = heap_alloc(size + 1);
    
    // Read file
    var total;
    total = 0;
    while (total < size) {
        var n;
        n = sys_read(fd, buf + total, size - total);
        if (n <= 0) { break; }
        total = total + n;
    }
    
    // Null terminate
    ptr8[buf + total] = 0;
    
    // Close
    sys_close(fd);
    
    // Store result in global (ptr, len)
    g_file_ptr = buf;
    g_file_len = total;
    
    return buf;
}

// ============================================
// Module Loading
// ============================================

// Resolve import path to actual file path
// "io" -> "{base_dir}/io.b"
func resolve_module_path(module_path, module_len) {
    // Add .b extension
    var ext;
    ext = heap_alloc(3);
    ptr8[ext] = 46;      // '.'
    ptr8[ext + 1] = 98;  // 'b'
    ptr8[ext + 2] = 0;
    
    var with_ext;
    with_ext = str_concat(module_path, module_len, ext, 2);
    var with_ext_len;
    with_ext_len = module_len + 2;
    
    // Join with base directory
    var slash;
    slash = heap_alloc(1);
    ptr8[slash] = 47;  // '/'
    
    var full_path;
    full_path = str_concat3(g_base_dir, g_base_dir_len, slash, 1, with_ext, with_ext_len);
    
    return full_path;
}

// Load and process a single module file
// Returns 1 on success, 0 on failure
func load_module(file_path, file_path_len) {
    // Check if already loaded (avoid circular imports)
    if (hashmap_has(g_loaded_modules, file_path, file_path_len)) {
        return 1;  // Already loaded, skip
    }
    
    // Mark as loading (before actually loading to detect cycles)
    hashmap_put(g_loaded_modules, file_path, file_path_len, 1);
    
    // Read file
    var content;
    content = read_entire_file(file_path);
    if (content == 0) {
        emit_stderr("[ERROR] Cannot open module: ", 29);
        var i;
        i = 0;
        while (i < file_path_len) {
            emit_char(ptr8[file_path + i]);
            i = i + 1;
        }
        emit_nl();
        return 0;
    }
    
    var src;
    src = g_file_ptr;
    var slen;
    slen = g_file_len;
    
    // Lex
    var tokens;
    tokens = lex_all(src, slen);
    
    // Parse
    var parser;
    parser = parse_new(tokens);
    var prog;
    prog = parse_program(parser);
    
    // Process imports first (recursive)
    var imports;
    imports = ptr64[prog + 24];
    var num_imports;
    num_imports = vec_len(imports);
    var ii;
    ii = 0;
    while (ii < num_imports) {
        var imp;
        imp = vec_get(imports, ii);
        var imp_path;
        imp_path = ptr64[imp + 8];
        var imp_len;
        imp_len = ptr64[imp + 16];
        
        // Resolve and load the imported module
        var resolved;
        resolved = resolve_module_path(imp_path, imp_len);
        var resolved_len;
        resolved_len = str_len(resolved);
        
        if (!load_module(resolved, resolved_len)) {
            return 0;  // Failed to load dependency
        }
        
        ii = ii + 1;
    }
    
    // Add this module's consts to global list
    var consts;
    consts = ptr64[prog + 16];
    var num_consts;
    num_consts = vec_len(consts);
    var ci;
    ci = 0;
    while (ci < num_consts) {
        vec_push(g_all_consts, vec_get(consts, ci));
        ci = ci + 1;
    }
    
    // Add this module's funcs to global list
    var funcs;
    funcs = ptr64[prog + 8];
    var num_funcs;
    num_funcs = vec_len(funcs);
    var fi;
    fi = 0;
    while (fi < num_funcs) {
        vec_push(g_all_funcs, vec_get(funcs, fi));
        fi = fi + 1;
    }
    
    // Add this module's globals to global list
    var globals;
    globals = ptr64[prog + 32];
    if (globals != 0) {
        var num_globals;
        num_globals = vec_len(globals);
        var gi;
        gi = 0;
        while (gi < num_globals) {
            vec_push(g_all_globals, vec_get(globals, gi));
            gi = gi + 1;
        }
    }
    
    return 1;  // Success
}

// ============================================
// Main Entry Point
// ============================================

func main(argc, argv) {
    // Check arguments
    if (argc < 2) {
        emit("Usage: v3_6 <source.b>\n", 23);
        return 1;
    }
    
    // Get filename from argv[1]
    var filename;
    filename = ptr64[argv + 8];
    var filename_len;
    filename_len = str_len(filename);
    
    // Extract base directory from filename
    g_base_dir = path_dirname(filename, filename_len);
    g_base_dir_len = str_len(g_base_dir);
    
    // Initialize global state
    g_loaded_modules = hashmap_new(64);
    g_all_funcs = vec_new(64);
    g_all_consts = vec_new(128);
    g_all_globals = vec_new(64);
    
    // Load main file and all its imports
    if (!load_module(filename, filename_len)) {
        return 1;
    }
    
    // Create merged program AST
    var dummy_imports;
    dummy_imports = vec_new(1);  // Empty imports (already processed)
    var merged_prog;
    merged_prog = ast_program(g_all_funcs, g_all_consts, dummy_imports);
    ptr64[merged_prog + 32] = g_all_globals;  // Set collected globals
    
    // Generate code for all modules
    cg_program(merged_prog);
    
    return 0;
}

