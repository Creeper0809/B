// parse_decl.b - Declaration parsing
//
// Parses top-level declarations:
// - const declarations
// - import declarations
// - function declarations (parameters, return types, body)
// - struct definitions
// - enum definitions
// - impl blocks
// - parse_program (entry point)

import std.io;
import std.vec;
import std.util;
import std.str;
import types;
import lexer;
import ast;
import compiler;
import parser.util;
import parser.type;
import parser.expr;
import parser.stmt;

// ============================================
// Const Declaration
// ============================================

func parse_const_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_CONST);
    
    var name_tok: u64 = parse_peek(p);
    var name_ptr: u64 = ((*Token)name_tok)->ptr;
    var name_len: u64 = ((*Token)name_tok)->len;

    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_EQ);
    
    var value: u64 = 0;
    var neg: u64 = 0;
    
    // Handle negative numbers
    if (parse_match(p, TOKEN_MINUS)) {
        neg = 1;
    }
    
    if (parse_peek_kind(p) == TOKEN_NUMBER) {
        var val_tok: u64 = parse_peek(p);
        value = parse_num_val(val_tok);
        parse_consume(p, TOKEN_NUMBER);
    } else if (parse_peek_kind(p) == TOKEN_CHAR) {
        var char_tok: u64 = parse_peek(p);
        var char_ptr: u64 = ((*Token)char_tok)->ptr;
        value = *(*u8)(char_ptr + 1);
        // Handle escape sequences
        if (*(*u8)(char_ptr + 1) == 92) {
            var escape_char: u64 = *(*u8)(char_ptr + 2);
            if (escape_char == 110) { value = 10; }       // \n
            else if (escape_char == 116) { value = 9; }   // \t
            else if (escape_char == 114) { value = 13; }  // \r
            else if (escape_char == 48) { value = 0; }    // \0
            else if (escape_char == 92) { value = 92; }   // \\
            else if (escape_char == 39) { value = 39; }   // \'
            else { value = escape_char; }
        }
        parse_consume(p, TOKEN_CHAR);
    } else {
        emit_stderr("[ERROR] Expected number or char in const\n", 42);
        panic("Parse error");
    }
    
    if (neg) { value = 0 - value; }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_const_decl(name_ptr, name_len, value);
}

// ============================================
// Import Declaration
// ============================================

func parse_import_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_IMPORT);
    
    var first_tok: u64 = parse_peek(p);
    var first_kind: u64 = parse_peek_kind(p);
    if (first_kind != TOKEN_IDENTIFIER && first_kind != TOKEN_CHAR) {
        emit_stderr("[ERROR] Expected module identifier in import\n", 45);
        panic("Parse error");
    }
    parse_adv(p);

    // Selective import: import <symbol> [as <alias>] from <module>
    if (parse_peek_kind(p) == TOKEN_AS || parse_peek_kind(p) == TOKEN_FROM) {
        var symbol_ptr: u64 = ((*Token)first_tok)->ptr;
        var symbol_len: u64 = ((*Token)first_tok)->len;
        var alias_ptr: u64 = symbol_ptr;
        var alias_len: u64 = symbol_len;

        if (parse_match(p, TOKEN_AS)) {
            var alias_tok: u64 = parse_peek(p);
            if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
                emit_stderr("[ERROR] Expected alias identifier in import\n", 47);
                panic("Parse error");
            }
            alias_ptr = ((*Token)alias_tok)->ptr;
            alias_len = ((*Token)alias_tok)->len;
            parse_consume(p, TOKEN_IDENTIFIER);
        }

        parse_consume(p, TOKEN_FROM);

        var mod_tok: u64 = parse_peek(p);
        var mod_kind: u64 = parse_peek_kind(p);
        if (mod_kind != TOKEN_IDENTIFIER && mod_kind != TOKEN_CHAR) {
            emit_stderr("[ERROR] Expected module identifier in import\n", 45);
            panic("Parse error");
        }
        parse_adv(p);

        var path_ptr: u64 = ((*Token)mod_tok)->ptr;
        var path_len: u64 = ((*Token)mod_tok)->len;

        while (parse_match(p, TOKEN_DOT)) {
            var next_tok: u64 = parse_peek(p);
            var next_kind: u64 = parse_peek_kind(p);
            if (next_kind != TOKEN_IDENTIFIER && next_kind != TOKEN_CHAR) {
                emit_stderr("[ERROR] Expected module identifier in import\n", 45);
                panic("Parse error");
            }
            parse_adv(p);

            var slash: u64 = heap_alloc(sizeof(u8));
            *(*u8)slash = 47;

            var joined_path: u64 = str_concat(path_ptr, path_len, slash, 1);
            path_ptr = str_concat(joined_path, path_len + 1, ((*Token)next_tok)->ptr, ((*Token)next_tok)->len);
            path_len = path_len + 1 + ((*Token)next_tok)->len;
        }

        parse_consume(p, TOKEN_SEMICOLON);

        return ast_import(path_ptr, path_len, symbol_ptr, symbol_len, alias_ptr, alias_len);
    }

    // Import module: import <module>;
    var path_ptr: u64  = ((*Token)first_tok)->ptr;
    var path_len: u64 = ((*Token)first_tok)->len;
    
    while (parse_match(p, TOKEN_DOT)) {
        var next_tok: u64 = parse_peek(p);
        var next_kind: u64 = parse_peek_kind(p);
        if (next_kind != TOKEN_IDENTIFIER && next_kind != TOKEN_CHAR) {
            emit_stderr("[ERROR] Expected module identifier in import\n", 45);
            panic("Parse error");
        }
        parse_adv(p);
        
        var slash2: u64 = heap_alloc(sizeof(u8));
        *(*u8)slash2 = 47;
        
        var joined_path2: u64 = str_concat(path_ptr, path_len, slash2, 1);
        path_ptr = str_concat(joined_path2, path_len + 1, ((*Token)next_tok)->ptr, ((*Token)next_tok)->len);
        path_len = path_len + 1 + ((*Token)next_tok)->len;
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_import(path_ptr, path_len, 0, 0, 0, 0);
}

// ============================================
// Function Parsing
// ============================================

// Skip a block without parsing its contents
func parse_skip_block(p: u64) -> u64 {
    parse_consume(p, TOKEN_LBRACE);
    var depth: u64 = 1;
    while (depth > 0) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_EOF:
                emit_stderr("[ERROR] Unexpected EOF while skipping block\n", 46);
                panic("Parse error");
                break;
            case TOKEN_LBRACE:
                depth = depth + 1;
                break;
            case TOKEN_RBRACE:
                depth = depth - 1;
                break;
            default:
                break;
        }
        parse_adv(p);
    }
    return 0;
}

func parse_param(p: u64) -> u64 {
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind: u64 = 0;
    var ptr_depth: u64 = 0;
    var is_tagged: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;
    var tag_layout_ptr: u64 = 0;
    var tag_layout_len: u64 = 0;
    var elem_type_kind: u64 = 0;
    var elem_ptr_depth: u64 = 0;
    var array_len: u64 = 0;
    
    if (parse_match(p, TOKEN_COLON)) {
        var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        type_kind = ty->type_kind;
        ptr_depth = ty->ptr_depth;
        is_tagged = ty->is_tagged;
        struct_name_ptr = ty->struct_name_ptr;
        struct_name_len = ty->struct_name_len;
        tag_layout_ptr = ty->tag_layout_ptr;
        tag_layout_len = ty->tag_layout_len;
        elem_type_kind = ty->elem_type_kind;
        elem_ptr_depth = ty->elem_ptr_depth;
        array_len = ty->array_len;
        if (type_kind == TYPE_ARRAY) {
            // Array parameter decays to pointer to first element
            type_kind = elem_type_kind;
            ptr_depth = elem_ptr_depth + 1;
            is_tagged = 0;
            tag_layout_ptr = 0;
            tag_layout_len = 0;
        }
    }
    
    var param: *Param = (*Param)heap_alloc(sizeof(Param));
    param->name_ptr = ((*Token)name_tok)->ptr;
    param->name_len = ((*Token)name_tok)->len;
    param->type_kind = type_kind;
    param->ptr_depth = ptr_depth;
    param->is_tagged = is_tagged;
    param->struct_name_ptr = struct_name_ptr;
    param->struct_name_len = struct_name_len;
    param->tag_layout_ptr = tag_layout_ptr;
    param->tag_layout_len = tag_layout_len;
    param->elem_type_kind = elem_type_kind;
    param->elem_ptr_depth = elem_ptr_depth;
    param->array_len = array_len;
    return param;
}

func parse_func_decl(p: u64) -> u64 {
    push_trace("parse_func_decl", "parser/decl.b", __LINE__);
    
    parse_consume(p, TOKEN_FUNC);
    
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    // Set parsing context for better error messages
    set_parsing_context(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, ((*Token)name_tok)->line);
    
    parse_consume(p, TOKEN_LPAREN);
    
    var params: u64 = vec_new(8);
    
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        vec_push(params, parse_param(p));
        while (parse_match(p, TOKEN_COMMA)) {
            vec_push(params, parse_param(p));
        }
    }
    
    parse_consume(p, TOKEN_RPAREN);
    
    var ret_type: u64 = TYPE_VOID;
    var ret_ptr_depth: u64 = 0;
    var ret_is_tagged: u64 = 0;
    var ret_struct_name_ptr: u64 = 0;
    var ret_struct_name_len: u64 = 0;
    var ret_tag_layout_ptr: u64 = 0;
    var ret_tag_layout_len: u64 = 0;
    
    if (parse_match(p, TOKEN_ARROW)) {
        var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        ret_type = ty->type_kind;
        ret_ptr_depth = ty->ptr_depth;
        ret_is_tagged = ty->is_tagged;
        ret_struct_name_ptr = ty->struct_name_ptr;
        ret_struct_name_len = ty->struct_name_len;
        ret_tag_layout_ptr = ty->tag_layout_ptr;
        ret_tag_layout_len = ty->tag_layout_len;
        if (ret_type == TYPE_ARRAY) {
            // Array return decays to pointer to first element
            ret_type = ty->elem_type_kind;
            ret_ptr_depth = ty->elem_ptr_depth + 1;
            ret_is_tagged = 0;
            ret_struct_name_ptr = ty->struct_name_ptr;
            ret_struct_name_len = ty->struct_name_len;
            ret_tag_layout_ptr = 0;
            ret_tag_layout_len = 0;
        }
    }
    
    var body: u64 = parse_block(p);
    
    pop_trace();
    return ast_func_ex(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, params, ret_type, ret_ptr_depth, ret_is_tagged, ret_struct_name_ptr, ret_struct_name_len, ret_tag_layout_ptr, ret_tag_layout_len, body);
}

// Parse function signature only (skip body)
func parse_func_decl_signature(p: u64) -> u64 {
    push_trace("parse_func_decl_signature", "parser/decl.b", __LINE__);

    parse_consume(p, TOKEN_FUNC);

    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);

    set_parsing_context(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, ((*Token)name_tok)->line);

    parse_consume(p, TOKEN_LPAREN);

    var params: u64 = vec_new(8);
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        vec_push(params, parse_param(p));
        while (parse_match(p, TOKEN_COMMA)) {
            vec_push(params, parse_param(p));
        }
    }
    parse_consume(p, TOKEN_RPAREN);

    var ret_type: u64 = TYPE_VOID;
    var ret_ptr_depth: u64 = 0;
    var ret_is_tagged: u64 = 0;
    var ret_struct_name_ptr: u64 = 0;
    var ret_struct_name_len: u64 = 0;
    var ret_tag_layout_ptr: u64 = 0;
    var ret_tag_layout_len: u64 = 0;

    if (parse_match(p, TOKEN_ARROW)) {
        var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        ret_type = ty->type_kind;
        ret_ptr_depth = ty->ptr_depth;
        ret_is_tagged = ty->is_tagged;
        ret_struct_name_ptr = ty->struct_name_ptr;
        ret_struct_name_len = ty->struct_name_len;
        ret_tag_layout_ptr = ty->tag_layout_ptr;
        ret_tag_layout_len = ty->tag_layout_len;
        if (ret_type == TYPE_ARRAY) {
            ret_type = ty->elem_type_kind;
            ret_ptr_depth = ty->elem_ptr_depth + 1;
            ret_is_tagged = 0;
            ret_struct_name_ptr = ty->struct_name_ptr;
            ret_struct_name_len = ty->struct_name_len;
            ret_tag_layout_ptr = 0;
            ret_tag_layout_len = 0;
        }
    }

    // Skip function body
    parse_skip_block(p);

    pop_trace();
    return ast_func_ex(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, params, ret_type, ret_ptr_depth, ret_is_tagged, ret_struct_name_ptr, ret_struct_name_len, ret_tag_layout_ptr, ret_tag_layout_len, 0);
}

// ============================================
// Struct Parsing
// ============================================

func parse_uwidth_from_ident(ptr: u64, len: u64) -> u64 {
    if (len < 2) { return 0; }
    var first: u64 = *(*u8)ptr;
    if (first != 117) { return 0; }
    var value: u64 = 0;
    for (var i: u64 = 1; i < len; i++) {
        var c: u64 = *(*u8)(ptr + i);
        if (c < 48 || c > 57) { return 0; }
        value = value * 10 + (c - 48);
    }
    return value;
}

func parse_struct_def(p: u64) -> u64 {
    var is_packed: u64 = 0;
    if (parse_match(p, TOKEN_PACKED)) {
        is_packed = 1;
    }
    parse_consume(p, TOKEN_STRUCT);
    
    var name_tok: u64 = parse_peek(p);
    var name_ptr: u64 = ((*Token)name_tok)->ptr;
    var name_len: u64 = ((*Token)name_tok)->len;
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var fields: u64 = vec_new(8);
    
    // Parse fields: field_name : type ;
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        var field_name_tok: u64 = parse_peek(p);
        var field_name_ptr: u64 = ((*Token)field_name_tok)->ptr;
        var field_name_len: u64 = ((*Token)field_name_tok)->len;
        parse_consume(p, TOKEN_IDENTIFIER);
        
        parse_consume(p, TOKEN_COLON);
        
        var field_type_kind: u64 = 0;
        var field_ptr_depth: u64 = 0;
        var field_struct_name_ptr: u64 = 0;
        var field_struct_name_len: u64 = 0;
        var field_tag_layout_ptr: u64 = 0;
        var field_tag_layout_len: u64 = 0;
        var field_elem_type_kind: u64 = 0;
        var field_elem_ptr_depth: u64 = 0;
        var field_array_len: u64 = 0;
        var field_is_tagged: u64 = 0;
        var field_bit_width: u64 = 0;

        if (is_packed == 1) {
            var k: u64 = parse_peek_kind(p);
            switch (k) {
                case TOKEN_U8:
                    parse_adv(p);
                    field_type_kind = TYPE_U8;
                    field_bit_width = 8;
                    break;
                case TOKEN_U16:
                    parse_adv(p);
                    field_type_kind = TYPE_U16;
                    field_bit_width = 16;
                    break;
                case TOKEN_U32:
                    parse_adv(p);
                    field_type_kind = TYPE_U32;
                    field_bit_width = 32;
                    break;
                case TOKEN_U64:
                    parse_adv(p);
                    field_type_kind = TYPE_U64;
                    field_bit_width = 64;
                    break;
                case TOKEN_IDENTIFIER:
                    var bw_tok: u64 = parse_peek(p);
                    var bw_ptr: u64 = ((*Token)bw_tok)->ptr;
                    var bw_len: u64 = ((*Token)bw_tok)->len;
                    parse_adv(p);
                    var bw: u64 = parse_uwidth_from_ident(bw_ptr, bw_len);
                    if (bw == 0 || bw > 64) {
                        emit_stderr("[ERROR] packed field must be u1..u64\n", 43);
                        panic("Parse error");
                    }
                    field_type_kind = TYPE_U64;
                    field_bit_width = bw;
                    break;
                default:
                    emit_stderr("[ERROR] packed field must be u1..u64\n", 43);
                    panic("Parse error");
            }
        } else {
            var field_type: *TypeInfo = (*TypeInfo)parse_type_ex(p);
            field_type_kind = field_type->type_kind;
            field_struct_name_ptr = field_type->struct_name_ptr;
            field_struct_name_len = field_type->struct_name_len;
            field_tag_layout_ptr = field_type->tag_layout_ptr;
            field_tag_layout_len = field_type->tag_layout_len;
            field_ptr_depth = field_type->ptr_depth;
            field_is_tagged = field_type->is_tagged;
            field_elem_type_kind = field_type->elem_type_kind;
            field_elem_ptr_depth = field_type->elem_ptr_depth;
            field_array_len = field_type->array_len;
        }
        
        parse_consume(p, TOKEN_SEMICOLON);
        
        var field_desc: *FieldDesc = (*FieldDesc)heap_alloc(sizeof(FieldDesc));
        field_desc->name_ptr = field_name_ptr;
        field_desc->name_len = field_name_len;
        field_desc->type_kind =  field_type_kind;
        field_desc->struct_name_ptr = field_struct_name_ptr;
        field_desc->struct_name_len = field_struct_name_len;
        field_desc->ptr_depth = field_ptr_depth;
        field_desc->is_tagged = field_is_tagged;
        field_desc->tag_layout_ptr = field_tag_layout_ptr;
        field_desc->tag_layout_len = field_tag_layout_len;
        field_desc->bit_width = field_bit_width;
        field_desc->elem_type_kind = field_elem_type_kind;
        field_desc->elem_ptr_depth = field_elem_ptr_depth;
        field_desc->array_len = field_array_len;
        
        vec_push(fields, field_desc);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    var struct_def: u64 = ast_struct_def(name_ptr, name_len, fields, is_packed);
    return struct_def;
}

// ============================================
// Enum Parsing
// ============================================

func parse_enum_def(p: u64) -> u64 {
    parse_consume(p, TOKEN_ENUM);
    
    var enum_name_tok: u64 = parse_peek(p);
    var enum_name_ptr: u64 = ((*Token)enum_name_tok)->ptr;
    var enum_name_len: u64 = ((*Token)enum_name_tok)->len;
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var consts: u64 = vec_new(16);
    var current_value: u64 = 0;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        var member_tok: u64 = parse_peek(p);
        var member_ptr: u64 = ((*Token)member_tok)->ptr;
        var member_len: u64 = ((*Token)member_tok)->len;
        parse_consume(p, TOKEN_IDENTIFIER);
        
        // Check for explicit value
        if (parse_match(p, TOKEN_EQ)) {
            var val_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_NUMBER);
            current_value = parse_num_val(val_tok);
        }
        
        // Create EnumName_MemberName
        var full_name: u64 = vec_new(64);
        for (var i: u64 = 0; i < enum_name_len; i++) {
            vec_push(full_name, *(*u8)(enum_name_ptr + i));
        }
        vec_push(full_name, 95);  // '_'
        for (var i: u64 = 0; i < member_len; i++) {
            vec_push(full_name, *(*u8)(member_ptr + i));
        }
        
        // Copy to permanent heap storage
        var full_name_len: u64 = vec_len(full_name);
        var full_name_ptr: u64 = heap_alloc((full_name_len + 1) * sizeof(u8));
        var full_name_buf: u64 = *(full_name);  // vec buf_ptr (array of i64)
        for (var i: u64 = 0; i < full_name_len; i++) {
            var ch: u64 = vec_get(full_name, i);  // Get i64 value
            *(*u8)(full_name_ptr + i) = ch;  // Store as u8
        }
        *(*u8)(full_name_ptr + full_name_len) = 0;
        
        var const_node: u64 = ast_const_decl(full_name_ptr, full_name_len, current_value);
        vec_push(consts, const_node);
        
        current_value = current_value + 1;
        
        // Optional comma
        if (parse_peek_kind(p) == TOKEN_COMMA) {
            parse_consume(p, TOKEN_COMMA);
        }
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return consts;
}

// ============================================
// Impl Block Parsing
// ============================================

func parse_impl_block(p: u64) -> u64 {
    parse_consume(p, TOKEN_IMPL);
    
    // Get struct name
    var struct_name_tok: u64 = parse_peek(p);
    var struct_name_ptr: u64 = ((*Token)struct_name_tok)->ptr;
    var struct_name_len: u64 = ((*Token)struct_name_tok)->len;
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var funcs: u64 = vec_new(8);
    
    // Parse all functions in impl block
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        // Check for static keyword
        var is_static: u64 = 0;
        if (parse_peek_kind(p) == TOKEN_STATIC) {
            is_static = 1;
            parse_adv(p);  // consume 'static'
        }
        
        if (parse_peek_kind(p) == TOKEN_FUNC) {
            var func_node: *AstFunc = (*AstFunc)parse_func_decl(p);
            
            // Rename function: methodName -> StructName_methodName
            var original_name_ptr: u64 = func_node->name_ptr;
            var original_name_len: u64 = func_node->name_len;
            
            // Create new name: StructName_methodName
            var new_name: u64 = vec_new(64);
            for (var i: u64 = 0; i < struct_name_len; i++) {
                vec_push(new_name, *(*u8)(struct_name_ptr + i));
            }
            vec_push(new_name, 95);  // '_'
            for (var i: u64 = 0; i < original_name_len; i++) {
                vec_push(new_name, *(*u8)(original_name_ptr + i));
            }
            
            // Copy to permanent heap storage
            var new_name_len: u64 = vec_len(new_name);
            var new_name_ptr: u64 = heap_alloc((new_name_len + 1) * sizeof(u8));
            for (var i: u64 = 0; i < new_name_len; i++) {
                var ch: u64 = vec_get(new_name, i);
                *(*u8)(new_name_ptr + i) = ch;
            }
            *(*u8)(new_name_ptr + new_name_len) = 0;
            
            // Update function name
            func_node->name_ptr = new_name_ptr;
            func_node->name_len = new_name_len;
            
            vec_push(funcs, (u64)func_node);
        } else {
            emit_stderr("[ERROR] impl block can only contain functions\n", 48);
            break;
        }
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return funcs;
}

// Impl block parsing for signature-only pass
func parse_impl_block_signature(p: u64) -> u64 {
    parse_consume(p, TOKEN_IMPL);

    var struct_name_tok: u64 = parse_peek(p);
    var struct_name_ptr: u64 = ((*Token)struct_name_tok)->ptr;
    var struct_name_len: u64 = ((*Token)struct_name_tok)->len;
    parse_consume(p, TOKEN_IDENTIFIER);

    parse_consume(p, TOKEN_LBRACE);

    var funcs: u64 = vec_new(8);

    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }

        var is_static: u64 = 0;
        if (parse_peek_kind(p) == TOKEN_STATIC) {
            is_static = 1;
            parse_adv(p);
        }

        if (parse_peek_kind(p) == TOKEN_FUNC) {
            var func_node: *AstFunc = (*AstFunc)parse_func_decl_signature(p);

            var original_name_ptr: u64 = func_node->name_ptr;
            var original_name_len: u64 = func_node->name_len;

            var new_name: u64 = vec_new(64);
            for (var i: u64 = 0; i < struct_name_len; i++) {
                vec_push(new_name, *(*u8)(struct_name_ptr + i));
            }
            vec_push(new_name, 95);
            for (var i: u64 = 0; i < original_name_len; i++) {
                vec_push(new_name, *(*u8)(original_name_ptr + i));
            }

            var new_name_len: u64 = vec_len(new_name);
            var new_name_ptr: u64 = heap_alloc((new_name_len + 1) * sizeof(u8));
            for (var i: u64 = 0; i < new_name_len; i++) {
                var ch: u64 = vec_get(new_name, i);
                *(*u8)(new_name_ptr + i) = ch;
            }
            *(*u8)(new_name_ptr + new_name_len) = 0;

            func_node->name_ptr = new_name_ptr;
            func_node->name_len = new_name_len;

            vec_push(funcs, (u64)func_node);
        } else {
            emit_stderr("[ERROR] impl block can only contain functions\n", 48);
            break;
        }
    }

    parse_consume(p, TOKEN_RBRACE);

    return funcs;
}

// ============================================
// Program Parsing (Entry Point)
// ============================================

func parse_program(p: u64) -> u64 {
    push_trace("parse_program", "parser/decl.b", __LINE__);
    
    var funcs: u64 = vec_new(16);
    var consts: u64 = vec_new(64);
    var imports: u64 = vec_new(16);
    var globals: u64 = vec_new(32);
    var structs: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_FUNC:
                vec_push(funcs, parse_func_decl(p));
                break;
            case TOKEN_CONST:
                vec_push(consts, parse_const_decl(p));
                break;
            case TOKEN_ENUM:
                // Enum을 여러 const로 변환
                var enum_consts: u64 = parse_enum_def(p);
                var num_enum_consts: u64 = vec_len(enum_consts);
                for (var i: u64 = 0; i < num_enum_consts; i++) {
                    vec_push(consts, vec_get(enum_consts, i));
                }
                break;
            case TOKEN_STRUCT:
            case TOKEN_PACKED:
                var struct_def: u64 = parse_struct_def(p);
                vec_push(structs, struct_def);
                register_struct_type(struct_def);  // Register immediately for type checking
                break;
            case TOKEN_IMPL:
                // impl 블록: 내부 함수들을 StructName_methodName으로 변환
                var impl_funcs: u64 = parse_impl_block(p);
                var num_impl_funcs: u64 = vec_len(impl_funcs);
                for (var i: u64 = 0; i < num_impl_funcs; i++) {
                    vec_push(funcs, vec_get(impl_funcs, i));
                }
                break;
            case TOKEN_VAR:
                parse_consume(p, TOKEN_VAR);
                var tok: u64 = parse_peek(p);

                parse_consume(p, TOKEN_IDENTIFIER);
                parse_consume(p, TOKEN_SEMICOLON);
                var ginfo: *GlobalInfo = (*GlobalInfo)heap_alloc(sizeof(GlobalInfo));
                ginfo->name_ptr = ((*Token)tok)->ptr;
                ginfo->name_len = ((*Token)tok)->len;
                vec_push(globals, ginfo);
                break;
            case TOKEN_IMPORT:
                vec_push(imports, parse_import_decl(p));
                break;
            default:
                emit_stderr("[ERROR] Expected function, const, or import\n", 45);
                break;
        }
    }
    
    var prog: *AstProgram = (*AstProgram)ast_program(funcs, consts, imports);
    prog->globals_vec = globals;
    prog->structs_vec = structs;
    
    pop_trace();
    return (u64)prog;
}

// ============================================
// Program Parsing (Signature Pass)
// ============================================

func parse_program_pass1(p: u64) -> u64 {
    push_trace("parse_program_pass1", "parser/decl.b", __LINE__);

    var funcs: u64 = vec_new(16);
    var consts: u64 = vec_new(1);
    var imports: u64 = vec_new(1);

    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_FUNC:
                vec_push(funcs, parse_func_decl_signature(p));
                break;
            case TOKEN_IMPL:
                var impl_funcs: u64 = parse_impl_block_signature(p);
                var num_impl_funcs: u64 = vec_len(impl_funcs);
                for (var i: u64 = 0; i < num_impl_funcs; i++) {
                    vec_push(funcs, vec_get(impl_funcs, i));
                }
                break;
            case TOKEN_STRUCT:
                parse_consume(p, TOKEN_STRUCT);
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_skip_block(p);
                break;
            case TOKEN_PACKED:
                parse_adv(p);
                parse_consume(p, TOKEN_STRUCT);
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_skip_block(p);
                break;
            case TOKEN_ENUM:
                parse_consume(p, TOKEN_ENUM);
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_skip_block(p);
                break;
            case TOKEN_CONST:
                // const 선언은 ; 까지 스킵
                parse_consume(p, TOKEN_CONST);
                parse_consume(p, TOKEN_IDENTIFIER);
                if (parse_match(p, TOKEN_EQ)) {
                    while (parse_peek_kind(p) != TOKEN_SEMICOLON && parse_peek_kind(p) != TOKEN_EOF) {
                        parse_adv(p);
                    }
                }
                parse_consume(p, TOKEN_SEMICOLON);
                break;
            case TOKEN_IMPORT:
                // import 선언은 ; 까지 스킵
                parse_consume(p, TOKEN_IMPORT);
                while (parse_peek_kind(p) != TOKEN_SEMICOLON && parse_peek_kind(p) != TOKEN_EOF) {
                    parse_adv(p);
                }
                parse_consume(p, TOKEN_SEMICOLON);
                break;
            case TOKEN_VAR:
                // 전역 var 선언은 ; 까지 스킵
                parse_consume(p, TOKEN_VAR);
                parse_consume(p, TOKEN_IDENTIFIER);
                parse_consume(p, TOKEN_SEMICOLON);
                break;
            default:
                emit_stderr("[ERROR] Expected function, const, or import\n", 45);
                break;
        }
    }

    var prog: *AstProgram = (*AstProgram)ast_program(funcs, consts, imports);
    pop_trace();
    return (u64)prog;
}
