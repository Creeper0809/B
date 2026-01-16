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
import types;
import lexer;
import ast;
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
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var path_ptr: u64  = ((*Token)first_tok)->ptr;
    var path_len: u64 = ((*Token)first_tok)->len;
    
    while (parse_match(p, TOKEN_DOT)) {
        var next_tok: u64 = parse_peek(p);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        var slash: u64 = heap_alloc(1);
        *(*u8)slash = 47;
        
        var tmp: u64 = str_concat(path_ptr, path_len, slash, 1);
        path_ptr = str_concat(tmp, path_len + 1, ((*Token)next_tok)->ptr, ((*Token)next_tok)->len);
        path_len = path_len + 1 + ((*Token)next_tok)->len;
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_import(path_ptr, path_len);
}

// ============================================
// Function Parsing
// ============================================

func parse_param(p: u64) -> u64 {
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind: u64 = 0;
    var ptr_depth: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;
    
    if (parse_match(p, TOKEN_COLON)) {
        var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        type_kind = ty->type_kind;
        ptr_depth = ty->ptr_depth;
        struct_name_ptr = ty->struct_name_ptr;
        struct_name_len = ty->struct_name_len;
    }
    
    var param: *Param = (*Param)heap_alloc(48);
    param->name_ptr = ((*Token)name_tok)->ptr;
    param->name_len = ((*Token)name_tok)->len;
    param->type_kind = type_kind;
    param->ptr_depth = ptr_depth;
    param->struct_name_ptr = struct_name_ptr;
    param->struct_name_len = struct_name_len;
    return param;
}

func parse_func_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_FUNC);
    
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
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
    var ret_struct_name_ptr: u64 = 0;
    var ret_struct_name_len: u64 = 0;
    
    if (parse_match(p, TOKEN_ARROW)) {
        var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        ret_type = ty->type_kind;
        ret_ptr_depth = ty->ptr_depth;
        ret_struct_name_ptr = ty->struct_name_ptr;
        ret_struct_name_len = ty->struct_name_len;
    }
    
    var body: u64 = parse_block(p);
    
    return ast_func_ex(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, params, ret_type, ret_ptr_depth, ret_struct_name_ptr, ret_struct_name_len, body);
}

// ============================================
// Struct Parsing
// ============================================

func parse_struct_def(p: u64) -> u64 {
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
        
        var field_type: *TypeInfo = (*TypeInfo)parse_type(p);
        
        // If the field is a struct type, capture the struct name
        var field_struct_name_ptr: u64 = 0;
        var field_struct_name_len: u64 = 0;
        if ( field_type->type_kind == TYPE_STRUCT) {
            var parser: *Parser = (*Parser)p;
            var prev_idx: u64 = parser->cur - 1;
            if (prev_idx >= 0 && prev_idx < vec_len(parser->tokens_vec)) {
                var prev_tok: u64 = vec_get(parser->tokens_vec, prev_idx);
                field_struct_name_ptr = ((*Token)prev_tok)->ptr;
                field_struct_name_len = ((*Token)prev_tok)->len;
            }
        }
        
        parse_consume(p, TOKEN_SEMICOLON);
        
        var field_desc: *FieldDesc = (*FieldDesc)heap_alloc(48);
        field_desc->name_ptr = field_name_ptr;
        field_desc->name_len = field_name_len;
        field_desc->type_kind =  field_type->type_kind;
        field_desc->struct_name_ptr = field_struct_name_ptr;
        field_desc->struct_name_len = field_struct_name_len;
        field_desc->ptr_depth = field_type->ptr_depth;
        
        vec_push(fields, field_desc);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    var struct_def: u64 = ast_struct_def(name_ptr, name_len, fields);
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
        var full_name_ptr: u64 = heap_alloc(full_name_len);
        var full_name_buf: u64 = *(full_name);  // vec buf_ptr (array of i64)
        for (var i: u64 = 0; i < full_name_len; i++) {
            var ch: u64 = vec_get(full_name, i);  // Get i64 value
            *(*u8)(full_name_ptr + i) = ch;  // Store as u8
        }
        
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
            var new_name_ptr: u64 = heap_alloc(new_name_len);
            for (var i: u64 = 0; i < new_name_len; i++) {
                var ch: u64 = vec_get(new_name, i);
                *(*u8)(new_name_ptr + i) = ch;
            }
            
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

// ============================================
// Program Parsing (Entry Point)
// ============================================

func parse_program(p: u64) -> u64 {
    var funcs: u64 = vec_new(16);
    var consts: u64 = vec_new(64);
    var imports: u64 = vec_new(16);
    var globals: u64 = vec_new(32);
    var structs: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_FUNC) {
            vec_push(funcs, parse_func_decl(p));
        } else if (k == TOKEN_CONST) {
            vec_push(consts, parse_const_decl(p));
        } else if (k == TOKEN_ENUM) {
            // Enum을 여러 const로 변환
            var enum_consts: u64 = parse_enum_def(p);
            var num_enum_consts: u64 = vec_len(enum_consts);
            for (var i: u64 = 0; i < num_enum_consts; i++) {
                vec_push(consts, vec_get(enum_consts, i));
            }
        } else if (k == TOKEN_STRUCT) {
            var struct_def: u64 = parse_struct_def(p);
            vec_push(structs, struct_def);
            register_struct_type(struct_def);  // Register immediately for type checking
        } else if (k == TOKEN_IMPL) {
            // impl 블록: 내부 함수들을 StructName_methodName으로 변환
            var impl_funcs: u64 = parse_impl_block(p);
            var num_impl_funcs: u64 = vec_len(impl_funcs);
            for (var i: u64 = 0; i < num_impl_funcs; i++) {
                vec_push(funcs, vec_get(impl_funcs, i));
            }
        } else if (k == TOKEN_VAR) {
            parse_consume(p, TOKEN_VAR);
            var tok: u64 = parse_peek(p);
            
            parse_consume(p, TOKEN_IDENTIFIER);
            parse_consume(p, TOKEN_SEMICOLON);
            var ginfo: *GlobalInfo = (*GlobalInfo)heap_alloc(16);
            ginfo->name_ptr = ((*Token)tok)->ptr;
            ginfo->name_len = ((*Token)tok)->len;
            vec_push(globals, ginfo);
        } else if (k == TOKEN_IMPORT) {
            vec_push(imports, parse_import_decl(p));
        } else {
            emit_stderr("[ERROR] Expected function, const, or import\n", 45);
            break;
        }
    }
    
    var prog: *AstProgram = (*AstProgram)ast_program(funcs, consts, imports);
    prog->globals_vec = globals;
    prog->structs_vec = structs;
    return (u64)prog;
}
