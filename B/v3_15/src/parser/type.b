// parse_type.b - Type parsing
//
// Functions for parsing type declarations:
// - parse_base_type: primitive types and struct names
// - parse_type: simple type with pointer depth
// - parse_type_ex: extended type info with struct name

import std.io;
import std.vec;
import std.util;
import types;
import lexer;
import parser.util;

// ============================================
// Type Parsing
// ============================================

func parse_base_type(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); return TYPE_U8; }
    if (k == TOKEN_U16) { parse_adv(p); return TYPE_U16; }
    if (k == TOKEN_U32) { parse_adv(p); return TYPE_U32; }
    if (k == TOKEN_U64) { parse_adv(p); return TYPE_U64; }
    if (k == TOKEN_I64) { parse_adv(p); return TYPE_I64; }
    
    // Check for struct type name
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        var name_ptr: u64 = ((*Token)tok)->ptr;
        var name_len: u64 = ((*Token)tok)->len;
        
        // Call is_struct_type (defined in main.b)
        if (is_struct_type(name_ptr, name_len) != 0) {
            parse_adv(p);
            return TYPE_STRUCT;
        }
    }
    
    return TYPE_VOID;
}

func parse_type(p: u64) -> u64 {
    var depth: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }
    var base: u64 = parse_base_type(p);
    var result: *TypeInfo = (*TypeInfo)heap_alloc(32);
    result->type_kind = base;
    result->ptr_depth = depth;
    result->struct_name_ptr = 0;
    result->struct_name_len = 0;
    return (u64)result;
}

// Extended type parsing that also captures struct type name.
// Layout: [base:8][ptr_depth:8][struct_name_ptr:8][struct_name_len:8]
func parse_type_ex(p: u64) -> u64 {
    var depth: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }

    var base: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;

    var k: u64 = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); base = TYPE_U8; }
    else if (k == TOKEN_U16) { parse_adv(p); base = TYPE_U16; }
    else if (k == TOKEN_U32) { parse_adv(p); base = TYPE_U32; }
    else if (k == TOKEN_U64) { parse_adv(p); base = TYPE_U64; }
    else if (k == TOKEN_I64) { parse_adv(p); base = TYPE_I64; }
    else if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        var name_ptr: u64 = ((*Token)tok)->ptr;
        var name_len: u64 = ((*Token)tok)->len;
        if (is_struct_type(name_ptr, name_len) != 0) {
            parse_adv(p);
            base = TYPE_STRUCT;
            struct_name_ptr = name_ptr;
            struct_name_len = name_len;
        }
    }

    var result: *TypeInfo = (*TypeInfo)heap_alloc(32);
    result->type_kind = base;
    result->ptr_depth = depth;
    result->struct_name_ptr = struct_name_ptr;
    result->struct_name_len = struct_name_len;
    return (u64)result;
}
