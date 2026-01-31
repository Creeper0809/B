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

// Local layout mirror for sizeof during bootstrap.
struct TypeInfoLocal {
    type_kind: u64;
    ptr_depth: u64;
    is_tagged: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    struct_def: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}

// ============================================
// Type Parsing
// ============================================

func parse_base_type(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    switch (k) {
        case TOKEN_U8: parse_adv(p); return TYPE_U8;
        case TOKEN_CHAR: parse_adv(p); return TYPE_U8;
        case TOKEN_U16: parse_adv(p); return TYPE_U16;
        case TOKEN_U32: parse_adv(p); return TYPE_U32;
        case TOKEN_U64: parse_adv(p); return TYPE_U64;
        case TOKEN_I64: parse_adv(p); return TYPE_I64;
        case TOKEN_IDENTIFIER:
            // Check for struct type name (allow any identifier in type position)
            parse_adv(p);
            return TYPE_STRUCT;
        default:
            return TYPE_VOID;
    }
}

func parse_type(p: u64) -> u64 {
    var depth: u64 = 0;
    var is_tagged: u64 = 0;
    var tag_layout_ptr: u64 = 0;
    var tag_layout_len: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
        if (parse_match(p, TOKEN_TAGGED)) {
            if (is_tagged == 1) {
                emit_stderr("[ERROR] Multiple tagged modifiers are not allowed\n", 53);
                panic("Parse error");
            }
            if (parse_match(p, TOKEN_LPAREN)) {
                if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
                    emit_stderr("[ERROR] tagged layout must be an identifier\n", 52);
                    panic("Parse error");
                }
                var layout_tok: u64 = parse_peek(p);
                tag_layout_ptr = ((*Token)layout_tok)->ptr;
                tag_layout_len = ((*Token)layout_tok)->len;
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_consume(p, TOKEN_RPAREN);
            }
            if (parse_peek_kind(p) == TOKEN_STAR) {
                emit_stderr("[ERROR] tagged must apply to the outermost pointer\n", 59);
                panic("Parse error");
            }
            is_tagged = 1;
        }
    }
    var base: u64 = parse_base_type(p);
    if (base == TYPE_STRUCT && tag_layout_ptr != 0) {
        emit_stderr("[ERROR] tagged layout on struct pointers is not supported\n", 63);
        panic("Parse error");
    }
    var result: *TypeInfo = (*TypeInfo)heap_alloc(sizeof(TypeInfoLocal));
    result->type_kind = base;
    result->ptr_depth = depth;
    result->is_tagged = is_tagged;
    if (is_tagged == 1 && tag_layout_ptr != 0) {
        result->struct_name_ptr = 0;
        result->struct_name_len = 0;
        result->tag_layout_ptr = tag_layout_ptr;
        result->tag_layout_len = tag_layout_len;
    } else {
        result->struct_name_ptr = 0;
        result->struct_name_len = 0;
        result->tag_layout_ptr = 0;
        result->tag_layout_len = 0;
    }
    result->struct_def = 0;
    result->elem_type_kind = 0;
    result->elem_ptr_depth = 0;
    result->array_len = 0;
    return (u64)result;
}

// Extended type parsing that also captures struct type name.
// Layout: [base:8][ptr_depth:8][struct_name_ptr:8][struct_name_len:8]
func parse_type_ex(p: u64) -> u64 {
    var depth: u64 = 0;
    var is_tagged: u64 = 0;
    var tag_layout_ptr: u64 = 0;
    var tag_layout_len: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
        if (parse_match(p, TOKEN_TAGGED)) {
            if (is_tagged == 1) {
                emit_stderr("[ERROR] Multiple tagged modifiers are not allowed\n", 53);
                panic("Parse error");
            }
            if (parse_match(p, TOKEN_LPAREN)) {
                if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
                    emit_stderr("[ERROR] tagged layout must be an identifier\n", 52);
                    panic("Parse error");
                }
                var layout_tok2: u64 = parse_peek(p);
                tag_layout_ptr = ((*Token)layout_tok2)->ptr;
                tag_layout_len = ((*Token)layout_tok2)->len;
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_consume(p, TOKEN_RPAREN);
            }
            if (parse_peek_kind(p) == TOKEN_STAR) {
                emit_stderr("[ERROR] tagged must apply to the outermost pointer\n", 59);
                panic("Parse error");
            }
            is_tagged = 1;
        }
    }

    // Array or slice type: [N]T or []T
    if (parse_match(p, TOKEN_LBRACKET)) {
        var is_slice: u64 = 0;
        var arr_len: u64 = 0;
        if (parse_match(p, TOKEN_RBRACKET)) {
            is_slice = 1;
        } else {
            var len_tok: u64 = parse_peek(p);
            if (parse_peek_kind(p) != TOKEN_NUMBER) {
                emit_stderr("[ERROR] Array length must be a number\n", 38);
                panic("Parse error");
            }
            arr_len = parse_num_val(len_tok);
            parse_consume(p, TOKEN_NUMBER);
            parse_consume(p, TOKEN_RBRACKET);
        }

        var elem_ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        if (elem_ty->type_kind == TYPE_ARRAY || elem_ty->type_kind == TYPE_SLICE) {
            emit_stderr("[ERROR] Nested array/slice types are not supported\n", 51);
            panic("Parse error");
        }
        if (elem_ty->type_kind == TYPE_STRUCT && elem_ty->ptr_depth == 0) {
            emit_stderr("[ERROR] Array/slice of struct value is not supported\n", 53);
            panic("Parse error");
        }

        var result_arr: *TypeInfo = (*TypeInfo)heap_alloc(sizeof(TypeInfoLocal));
        if (is_slice == 1) { result_arr->type_kind = TYPE_SLICE; }
        else { result_arr->type_kind = TYPE_ARRAY; }
        result_arr->ptr_depth = depth;
        result_arr->is_tagged = is_tagged;
        if (tag_layout_ptr != 0) {
            emit_stderr("[ERROR] tagged layout is not supported for array/slice types\n", 72);
            panic("Parse error");
        }
        result_arr->struct_name_ptr = elem_ty->struct_name_ptr;
        result_arr->struct_name_len = elem_ty->struct_name_len;
        result_arr->tag_layout_ptr = 0;
        result_arr->tag_layout_len = 0;
        result_arr->struct_def = 0;
        result_arr->elem_type_kind = elem_ty->type_kind;
        result_arr->elem_ptr_depth = elem_ty->ptr_depth;
        result_arr->array_len = arr_len;
        return (u64)result_arr;
    }

    var base: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;

    var k: u64 = parse_peek_kind(p);
    switch (k) {
        case TOKEN_U8:
            parse_adv(p);
            base = TYPE_U8;
            break;
        case TOKEN_CHAR:
            parse_adv(p);
            base = TYPE_U8;
            break;
        case TOKEN_U16:
            parse_adv(p);
            base = TYPE_U16;
            break;
        case TOKEN_U32:
            parse_adv(p);
            base = TYPE_U32;
            break;
        case TOKEN_U64:
            parse_adv(p);
            base = TYPE_U64;
            break;
        case TOKEN_I64:
            parse_adv(p);
            base = TYPE_I64;
            break;
        case TOKEN_IDENTIFIER:
            var tok: u64 = parse_peek(p);
            var name_ptr: u64 = ((*Token)tok)->ptr;
            var name_len: u64 = ((*Token)tok)->len;
            parse_adv(p);
            base = TYPE_STRUCT;
            struct_name_ptr = name_ptr;
            struct_name_len = name_len;
            break;
        default:
            base = 0;
            break;
    }

    if (base == TYPE_STRUCT && tag_layout_ptr != 0) {
        emit_stderr("[ERROR] tagged layout on struct pointers is not supported\n", 63);
        panic("Parse error");
    }

    var result: *TypeInfo = (*TypeInfo)heap_alloc(sizeof(TypeInfoLocal));
    result->type_kind = base;
    result->ptr_depth = depth;
    result->is_tagged = is_tagged;
    if (is_tagged == 1 && tag_layout_ptr != 0) {
        result->struct_name_ptr = 0;
        result->struct_name_len = 0;
        result->tag_layout_ptr = tag_layout_ptr;
        result->tag_layout_len = tag_layout_len;
    } else {
        result->struct_name_ptr = struct_name_ptr;
        result->struct_name_len = struct_name_len;
        result->tag_layout_ptr = 0;
        result->tag_layout_len = 0;
    }
    result->struct_def = 0;
    result->elem_type_kind = 0;
    result->elem_ptr_depth = 0;
    result->array_len = 0;
    return (u64)result;
}
