// v1 function/program parser + codegen (stage 11 minimal)
// Roadmap: docs/roadmap.md (stage 11)
// Scope (minimal): only `func <name>(<args...>) { <stmt*> }` at top-level.
// - Uses v1 Parser (from expr.b)
// - Emits raw NASM asm for:
//   - function label `<name>:`
//   - argument spills to stack locals [rbp-off] (recursion-safe)
//   - function body by reusing stmt_parse_list
//   - `ret` via shared `RET_<name>` label

func die_func_expected_kw_func() {
	die("func: expected 'func'");
}

func die_global_var_expected_ident() {
	die("global var: expected identifier");
}

func die_global_var_expected_semi() {
	die("global var: expected ';'");
}

func die_global_var_expected_equal() {
	die("global var: expected '='");
}

func die_func_expected_ident() {
	die("func: expected identifier");
}

func die_func_expected_lparen() {
	die("func: expected '('");
}

func die_func_expected_rparen() {
	die("func: expected ')'");
}

func die_func_expected_lbrace() {
	die("func: expected '{'");
}

func die_func_expected_rbrace() {
	die("func: expected '}'");
}

func die_func_expected_comma() {
	die("func: expected ','");
}

func die_func_too_many_args() {
	die("func: too many args (max 6)");
}

func slice_eq_cstr(p, n, cstr_ptr, cstr_len) {
	// Returns rax=1 if (p,n)==(cstr_ptr,cstr_len) else 0.
	// Convention: rdi=p, rsi=n, rdx=cstr_ptr, rcx=cstr_len
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"mov r12, rdi\n"
		"mov r13, rsi\n"
		"mov r14, rdx\n"
		"mov r15, rcx\n"
		"mov rdi, r12\n"
		"mov rsi, r13\n"
		"mov rdx, r14\n"
		"mov rcx, r15\n"
		"call slice_eq_parts\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func parser_is_ident_kw(p, kw_ptr, kw_len) {
	// Current token must be IDENT and equal to keyword text.
	// Convention: rdi=Parser*, rsi=kw_ptr, rdx=kw_len
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"mov r12, rdi\n"      // p
		"mov r13, rsi\n"      // kw_ptr
		"mov r14, rdx\n"      // kw_len
		"mov rax, [r12+8]\n"  // kind
		"cmp rax, 1\n"        // TOK_IDENT
		"jne .no\n"
		"mov rdi, [r12+16]\n" // tok_ptr
		"mov rsi, [r12+24]\n" // tok_len
		"mov rdx, r13\n"
		"mov rcx, r14\n"
		"call slice_eq_cstr\n"
		"jmp .done\n"
		".no:\n"
		"xor eax, eax\n"
		".done:\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func die_func_expected_kw_enum() {
	die("top-level: expected 'enum'");
}

func die_enum_expected_lbrace() {
	die("enum: expected '{'");
}

func die_enum_expected_rbrace() {
	die("enum: expected '}'");
}

func die_enum_expected_colon_or_comma_or_rbrace() {
	die("enum: expected ',' or '}'");
}

func die_enum_expected_equal() {
	die("enum: expected '='");
}

func die_struct_expected_ident() {
	die("struct: expected identifier");
}

func die_struct_expected_lbrace() {
	die("struct: expected '{'");
}

func die_struct_expected_rbrace() {
	die("struct: expected '}'");
}

func die_struct_expected_semi() {
	die("struct: expected ';'");
}

func die_import_expected_ident_toplevel() {
	die("import: expected identifier");
}

func die_import_expected_semi_toplevel() {
	die("import: expected ';'");
}

func parse_struct_decl(p) {
	// Parse: struct IDENT '{' field* '}'
	// field := IDENT [ ':' ['*'] IDENT ] ';'
	// Convention: rdi = Parser* (current token must be IDENT 'struct')
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 80\n" // [0]=p [8]=name_ptr [16]=name_len [24]=def [32]=cur_off [40]=type_ptr [48]=type_len [56]=type_is_ptr [64]=field_ptr [72]=field_len

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		// consume 'struct'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// struct name
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .name_ok\n" "call die_struct_expected_ident\n"
		".name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"
		// def = structs_add(name)
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+16]\n" "call structs_add\n"
		"mov [rsp+24], rax\n"
		"mov r12, [rsp+0]\n"
		// consume name
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect '{'
		"mov rax, [r12+8]\n" "cmp rax, 32\n" "je .lb_ok\n" "call die_struct_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '{'
		"mov r12, [rsp+0]\n"
		"mov qword [rsp+32], 0\n" // cur_off

		".field_loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" "je .done_fields\n" // '}'
		// field ident
		"cmp rax, 1\n" "je .fid_ok\n" "call die_struct_expected_ident\n"
		".fid_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+64], rax\n" // field_ptr
		"mov rax, [r12+24]\n" "mov [rsp+72], rax\n" // field_len
		"mov rdi, r12\n" "call parser_next\n" // consume field ident
		"mov r12, [rsp+0]\n"

		// default type: none
		"mov qword [rsp+40], 0\n" // type_ptr
		"mov qword [rsp+48], 0\n" // type_len
		"mov qword [rsp+56], 0\n" // type_is_ptr
		// optional ':' type
		"mov rax, [r12+8]\n" "cmp rax, 39\n" "jne .type_done\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 42\n" "jne .type_no_star\n"
		"mov qword [rsp+56], 1\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '*'
		"mov r12, [rsp+0]\n"
		".type_no_star:\n"
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .tid_ok\n" "call die_struct_expected_ident\n"
		".tid_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+40], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+48], rax\n"
		"mov rdi, r12\n" "call parser_next\n" // consume type ident
		"mov r12, [rsp+0]\n"
		".type_done:\n"

		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .semi_ok\n" "call die_struct_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"

		// field_size = 8 by default
		"mov rbx, 8\n"
		"mov rax, [rsp+40]\n" "test rax, rax\n" "jz .have_fsz\n"
		"mov rax, [rsp+56]\n" "test rax, rax\n" "jnz .have_fsz\n" // pointer => 8
		// by-value struct type must be complete and not recursive
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n"
		"mov rdx, [rsp+8]\n"  "mov rcx, [rsp+16]\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jz .bv_not_self\n"
		"call die_struct_by_value_recursive\n"
		".bv_not_self:\n"
		// primitive by-value field types
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "lea rdx, [rel .s_u8]\n"  "mov rcx, 2\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .fsz_u8\n"
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "lea rdx, [rel .s_u16]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .fsz_u16\n"
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "lea rdx, [rel .s_u32]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .fsz_u32\n"
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "lea rdx, [rel .s_u64]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .fsz_u64\n"
		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "lea rdx, [rel .s_i64]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .fsz_u64\n"

		"mov rdi, [rsp+40]\n" "mov rsi, [rsp+48]\n" "call structs_get\n"
		"test rdx, rdx\n" "jnz .bv_found\n"
		"call die_struct_by_value_incomplete\n"
		".bv_found:\n"
		"mov r14, rax\n" // def*
		"mov rax, [r14+32]\n" "test rax, rax\n" "jz .bv_complete\n"
		"call die_struct_by_value_recursive\n"
		".bv_complete:\n"
		"mov rbx, [r14+24]\n" // size
		".have_fsz:\n"
		"jmp .have_fsz_done\n"

		".fsz_u8:\n"  "mov rbx, 1\n" "jmp .have_fsz\n"
		".fsz_u16:\n" "mov rbx, 2\n" "jmp .have_fsz\n"
		".fsz_u32:\n" "mov rbx, 4\n" "jmp .have_fsz\n"
		".fsz_u64:\n" "mov rbx, 8\n" "jmp .have_fsz\n"

		".have_fsz_done:\n"

		// allocate Field {name_ptr,name_len,off,size,type_ptr,type_len,type_is_ptr}
		"mov rdi, 56\n" "call heap_alloc\n" // rax=Field*
		"mov r13, rax\n"
		"mov rax, [rsp+64]\n" "mov [r13+0], rax\n"
		"mov rax, [rsp+72]\n" "mov [r13+8], rax\n"
		"mov rax, [rsp+32]\n" "mov [r13+16], rax\n" // off
		"mov [r13+24], rbx\n" // size
		"mov rax, [rsp+40]\n" "mov [r13+32], rax\n"
		"mov rax, [rsp+48]\n" "mov [r13+40], rax\n"
		"mov rax, [rsp+56]\n" "mov [r13+48], rax\n"
		// push field
		"mov r15, [rsp+24]\n" // def*
		"mov rdi, [r15+16]\n" "mov rsi, r13\n" "call vec_push\n"
		"mov r12, [rsp+0]\n"
		// cur_off += field_size
		"mov rax, [rsp+32]\n" "add rax, rbx\n" "mov [rsp+32], rax\n"
		"jmp .field_loop\n"

		".done_fields:\n"
		// consume '}'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// def->size = align8(cur_off), def->in_progress=0
		"mov r15, [rsp+24]\n"
		"mov rax, [rsp+32]\n" "add rax, 7\n" "and rax, -8\n"
		"mov [r15+24], rax\n"
		"mov qword [r15+32], 0\n"

		// optional ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "jne .no_semi\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		".no_semi:\n"

		"add rsp, 80\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_u8:  db 'u8', 0\n"
		".s_u16: db 'u16', 0\n"
		".s_u32: db 'u32', 0\n"
		".s_u64: db 'u64', 0\n"
		".s_i64: db 'i64', 0\n"
		".exit:\n"
	};
}

func die_const_expected_equal() {
	die("const: expected '='");
}

func die_const_expected_semi() {
	die("const: expected ';'");
}

func die_enum_expected_semi() {
	die("enum: expected ';'");
}

func const_expr_eval(p, end_kind) {
	// Evaluate a compile-time integer expression.
	// Supports: INT (including char literals lowered by lexer), const identifiers, dotted const (Name.A), parens,
	// unary +/-, and binary ops: + - * / % & | ^ << >>.
	// Stops before end_kind (does not consume it).
	// Convention: rdi=Parser*, rsi=end_kind
	// Returns: rax=value
	// NOTE: This is a small recursive-descent evaluator for P2.5.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 56\n"        // locals (+8 pad for 16B alignment)
		"mov [rbp-80], rdi\n"  // p (RSP moves during local calls)
		"mov [rbp-72], rsi\n"  // end_kind
		"xor eax, eax\n"
		"xor ebx, ebx\n"
		"; Implemented in helper functions below via local labels\n"
		"jmp .entry\n"

		".parse_primary:\n"
		"mov r12, [rbp-80]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 2\n"          // TOK_INT
		"je .prim_int\n"
		"cmp rax, 30\n"         // TOK_LPAREN
		"je .prim_paren\n"
		"cmp rax, 1\n"          // TOK_IDENT
		"je .prim_ident\n"
		"jmp .die_non_const\n"

		".prim_int:\n"
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"call atoi_u64_or_panic\n"  // rax=value
		"push rax\n"
		"mov r12, [rbp-80]\n"
		"mov rdi, r12\n"        // consume
		"call parser_next\n"
		"pop rax\n"
		"jmp .prim_done\n"

		".prim_paren:\n"
		"mov rdi, r12\n"        // consume '('
		"call parser_next\n"
		"call .parse_expr\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 31\n"         // TOK_RPAREN
		"jne .die_paren\n"
		"push rax\n"
		"mov rdi, r12\n"        // consume ')'
		"call parser_next\n"
		"pop rax\n"
		"jmp .prim_done\n"

		".prim_ident:\n"
		"; ident or dotted ident (Name.A)\n"
		"mov rax, [r12+16]\n"   // p1
		"mov [rbp-64], rax\n"
		"mov rax, [r12+24]\n"   // n1
		"mov [rbp-56], rax\n"
		"mov rdi, r12\n"
		"call parser_next\n"    // consume ident
		"mov r12, [rbp-80]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 38\n"         // TOK_DOT
		"jne .ident_single\n"
		"mov rdi, r12\n"        // consume '.'
		"call parser_next\n"
		"mov r12, [rbp-80]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n"          // TOK_IDENT
		"jne .die_non_const\n"
		"mov rax, [r12+16]\n"   // p2
		"mov [rbp-96], rax\n"
		"mov rax, [r12+24]\n"   // n2
		"mov [rbp-88], rax\n"
		"mov rdi, r12\n"        // consume second ident
		"call parser_next\n"
		"; full = concat(p1,n1, '.',1) then concat(full, p2,n2)\n"
		"lea rdi, [rel .s_dot]\n"
		"mov rsi, 1\n"
		"call slice_to_cstr\n"   // rax=dot_ptr
		"mov rdx, rax\n"         // p2=dot
		"mov rdi, [rbp-64]\n"   // p1
		"mov rsi, [rbp-56]\n"   // n1
		"mov rcx, 1\n"
		"call str_concat\n"      // rax=tmp_ptr, rdx=tmp_len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"mov rdx, [rbp-96]\n"   // p2
		"mov rcx, [rbp-88]\n"   // n2
		"call str_concat\n"      // rax=full_ptr, rdx=full_len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call consts_get\n"      // rdx=found, rax=value
		"test rdx, rdx\n"
		"jz .die_undef\n"
		"jmp .prim_done\n"

		".ident_single:\n"
		"mov rdi, [rbp-64]\n"
		"mov rsi, [rbp-56]\n"
		"call consts_get\n"
		"test rdx, rdx\n"
		"jz .die_undef\n"
		"jmp .prim_done\n"

		".prim_done:\n"
		"ret\n"

		".parse_unary:\n"
		"mov r12, [rbp-80]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 40\n"         // '+'
		"je .u_plus\n"
		"cmp rax, 41\n"         // '-'
		"je .u_minus\n"
		"call .parse_primary\n"
		"ret\n"
		".u_plus:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_unary\n"
		"ret\n"
		".u_minus:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_unary\n"
		"neg rax\n"
		"ret\n"

		".parse_mul:\n"
		"call .parse_unary\n"
		".mul_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 42\n"         // '*'
		"je .do_mul\n"
		"cmp rdx, 43\n"         // '/'
		"je .do_div\n"
		"cmp rdx, 44\n"         // '%'
		"je .do_mod\n"
		"ret\n"
		".do_mul:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_unary\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"imul rax, rbx\n"
		"jmp .mul_loop\n"
		".do_div:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_unary\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"xor edx, edx\n"
		"div rbx\n"
		"jmp .mul_loop\n"
		".do_mod:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_unary\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"xor edx, edx\n"
		"div rbx\n"
		"mov rax, rdx\n"
		"jmp .mul_loop\n"

		".parse_add:\n"
		"call .parse_mul\n"
		".add_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 40\n"         // '+'
		"je .do_add\n"
		"cmp rdx, 41\n"         // '-'
		"je .do_sub\n"
		"ret\n"
		".do_add:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_mul\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"add rax, rbx\n"
		"jmp .add_loop\n"
		".do_sub:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_mul\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"sub rax, rbx\n"
		"jmp .add_loop\n"

		".parse_shift:\n"
		"call .parse_add\n"
		".sh_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 70\n"         // '<<'
		"je .do_shl\n"
		"cmp rdx, 71\n"         // '>>'
		"je .do_shr\n"
		"ret\n"
		".do_shl:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_add\n"
		"mov rcx, rax\n"
		"pop rax\n"
		"shl rax, cl\n"
		"jmp .sh_loop\n"
		".do_shr:\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_add\n"
		"mov rcx, rax\n"
		"pop rax\n"
		"shr rax, cl\n"
		"jmp .sh_loop\n"

		".parse_and:\n"
		"call .parse_shift\n"
		".and_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 60\n"         // '&'
		"jne .and_done\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_shift\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"and rax, rbx\n"
		"jmp .and_loop\n"
		".and_done:\n"
		"ret\n"

		".parse_xor:\n"
		"call .parse_and\n"
		".xor_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 62\n"         // '^'
		"jne .xor_done\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_and\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"xor rax, rbx\n"
		"jmp .xor_loop\n"
		".xor_done:\n"
		"ret\n"

		".parse_or:\n"
		"call .parse_xor\n"
		".or_loop:\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"
		"cmp rdx, 61\n"         // '|'
		"jne .or_done\n"
		"push rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"call .parse_xor\n"
		"mov rbx, rax\n"
		"pop rax\n"
		"or rax, rbx\n"
		"jmp .or_loop\n"
		".or_done:\n"
		"ret\n"

		".parse_expr:\n"
		"call .parse_or\n"
		"ret\n"

		".die_non_const:\n"
		"call die_expr_undefined_ident\n" // reuse generic error
		"hlt\n"
		".die_undef:\n"
		"call die_expr_undefined_ident\n"
		"hlt\n"
		".die_paren:\n"
		"call die_func_expected_rparen\n"
		"hlt\n"
		".s_dot: db '.', 0\n"

		".entry:\n"
		"call .parse_expr\n"
		"mov r12, [rbp-80]\n"
		"mov rdx, [r12+8]\n"   // kind
		"cmp rdx, [rbp-72]\n"  // end_kind
		"je .ok_end\n"
		"; allow commas to be handled by callers if end_kind expects it\n"
		".ok_end:\n"
		"add rsp, 56\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"; fallthrough to basm function epilogue\n"
	};
}

func enum_define_member(enum_ptr, enum_len, mem_ptr, mem_len, value) {
	// Insert a const for "Enum.Member" with given value.
	// Convention: rdi=enum_ptr, rsi=enum_len, rdx=mem_ptr, rcx=mem_len, r8=value
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 48\n" // [0]=e_ptr [8]=e_len [16]=m_ptr [24]=m_len [32]=pad [40]=value (16B aligned)
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov [rsp+40], r8\n"

		"; tmp1 = enum + '.'\n"
		"lea rdi, [rel .s_dot]\n"
		"mov rsi, 1\n"
		"call slice_to_cstr\n" // rax=dot_ptr
		"mov r12, rax\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, r12\n"
		"mov rcx, 1\n"
		"call str_concat\n" // rax=tmp_ptr, rdx=tmp_len
		"mov r13, rax\n"
		"mov r14, rdx\n"

		"; full = tmp1 + member\n"
		"mov rdi, r13\n"
		"mov rsi, r14\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call str_concat\n" // rax=full_ptr, rdx=full_len

		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"mov rdx, [rsp+40]\n"
		"call consts_set\n"

		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_dot: db '.', 0\n"
		".exit:\n"
	};
}

func emit_store_stack_arg_to_local(off, stack_idx) {
	// Emit store of one incoming stack argument into a stack local slot.
	// stack_idx: 0 => arg7 at [rbp+16], 1 => arg8 at [rbp+24], ...
	// Convention: rdi = off (u64 for [rbp-off]), rsi = stack_idx (u64)
	asm {
		"push rbx\n"
		"push r12\n"
		"sub rsp, 16\n" // [0]=off [8]=stack_idx
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// disp = 16 + stack_idx*8
		"mov rax, [rsp+8]\n"
		"shl rax, 3\n"
		"add rax, 16\n"
		"mov [rsp+8], rax\n" // save disp across helper calls

		// mov rax, qword [rbp+disp]
		"lea rdi, [rel .s_mov_stack0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_mov_stack1]\n"
		"call emit_cstr\n"

		// mov qword [rbp-off], rax
		"lea rdi, [rel .s_mov_loc0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+0]\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_mov_loc1]\n"
		"call emit_cstr\n"

		"add rsp, 16\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_mov_stack0: db '  mov rax, qword [rbp+', 0\n"
		".s_mov_stack1: db ']', 10, 0\n"
		".s_mov_loc0:   db '  mov qword [rbp-', 0\n"
		".s_mov_loc1:   db '], rax', 10, 0\n"
		".exit:\n"
	};
}

func emit_slice_label_def(sl) {
	// Emit: <label>:\n
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rdi, r12\n"
		"call slice_parts\n" // rax=ptr, rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_colon_nl]\n"
		"call emit_cstr\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_colon_nl: db ':', 10, 0\n"
		".exit:\n"
	};
}

func slice_from_parts(ptr, len) {
	// Allocate a Slice struct with (ptr,len).
	// Convention: rdi=ptr, rsi=len
	// Returns: rax = Slice*
	asm {
		"push rbx\n"
		"mov rbx, rdi\n"
		"push rsi\n"
		"mov rdi, 16\n"
		"call heap_alloc\n"
		"pop rsi\n"
		"mov [rax+0], rbx\n"
		"mov [rax+8], rsi\n"
		"pop rbx\n"
	};
}

func ret_label_from_func_name(name_ptr, name_len) {
	// Build Slice* for "RET_<name>".
	// Convention: rdi=name_ptr, rsi=name_len
	// Returns: rax = Slice*
	asm {
		"push rbx\n"
		"push r12\n"
		"sub rsp, 16\n" // [0]=name_ptr [8]=name_len
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"lea rdi, [rel .s_prefix]\n"
		"mov rsi, 4\n"
		"call slice_to_cstr\n" // rax=ptr
		"mov r12, rax\n"

		"mov rdi, r12\n"
		"mov rsi, 4\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call str_concat\n" // rax=ptr, rdx=len

		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call slice_from_parts\n"

		"add rsp, 16\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_prefix: db 'RET_', 0\n"
		".exit:\n"
	};
}

func emit_store_arg_to_local(off, reg_id) {
	// Emit store of one incoming argument register into a stack local slot.
	// Convention: rdi = off (u64 for [rbp-off]), rsi = reg_id (0..5)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [0]=var_sl [8]=reg_id
		"mov [rsp+0], rdi\n" // off
		"mov [rsp+8], rsi\n"

		"lea rdi, [rel .s_mov0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+0]\n"
		"call emit_u64\n"

		// select src reg
		"mov rax, [rsp+8]\n"
		"cmp rax, 0\n" "je .rdi\n"
		"cmp rax, 1\n" "je .rsi\n"
		"cmp rax, 2\n" "je .rdx\n"
		"cmp rax, 3\n" "je .rcx\n"
		"cmp rax, 4\n" "je .r8\n"
		"jmp .r9\n"
		".rdi:\n" "lea rdi, [rel .s_rdi]\n" "jmp .emit_reg\n"
		".rsi:\n" "lea rdi, [rel .s_rsi]\n" "jmp .emit_reg\n"
		".rdx:\n" "lea rdi, [rel .s_rdx]\n" "jmp .emit_reg\n"
		".rcx:\n" "lea rdi, [rel .s_rcx]\n" "jmp .emit_reg\n"
		".r8:\n"  "lea rdi, [rel .s_r8]\n"  "jmp .emit_reg\n"
		".r9:\n"  "lea rdi, [rel .s_r9]\n"  "jmp .emit_reg\n"
		".emit_reg:\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"

		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".s_mov0: db '  mov qword [rbp-', 0\n"
		".s_rdi:  db '], rdi', 0\n"
		".s_rsi:  db '], rsi', 0\n"
		".s_rdx:  db '], rdx', 0\n"
		".s_rcx:  db '], rcx', 0\n"
		".s_r8:   db '], r8', 0\n"
		".s_r9:   db '], r9', 0\n"
		".s_nl:   db 10, 0\n"
		".exit:\n"
	};
}

func parse_func_args(p, out_vec) {
	// Parse argument list after having consumed '('.
	// Grammar: [ ident (',' ident)* ] ')'
	// Convention: rdi=Parser*, rsi=Vec* out_vec (ArgName* elements; ArgName={ptr,len})
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [0]=p [8]=out
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rsp+0]\n"
		// empty? if next is ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .done\n"

		".loop:\n"
		// ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .id_ok\n"
		"call die_func_expected_ident\n"
		".id_ok:\n"
		// store ArgName {ptr,len} on heap and push pointer
		"mov rdi, 16\n"
		"call heap_alloc\n" // rax=ArgName*
		"mov r13, rax\n"
		"mov r8, [r12+16]\n" // ptr
		"mov r9, [r12+24]\n" // len
		"mov [r13+0], r8\n"
		"mov [r13+8], r9\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, r13\n"
		"call vec_push\n"
		"mov r12, [rsp+0]\n" // be conservative

		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// optional type hint: ':' <ident>
		"mov rax, [r12+8]\n"
		"cmp rax, 39\n" // TOK_COLON
		"jne .after_type\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .after_type\n"
		"mov rdi, r12\n" "call parser_next\n" // consume type ident
		"mov r12, [rsp+0]\n"
		".after_type:\n"
		"mov r12, [rsp+0]\n"

		// if ')' => done
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .done\n"

		// expect ','
		"cmp rax, 37\n" // TOK_COMMA
		"je .comma_ok\n"
		"call die_func_expected_comma\n"
		".comma_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .loop\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func parse_program_emit_funcs(p) {
	// Parse and emit a sequence of func declarations until EOF.
	// Convention: rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 128\n" // [0]=p [8]=name_ptr [16]=name_len [24]=name_sl [32]=ret_sl [40]=args_vec [48]=loop_s [56]=loop_e [64]=argc [72]=i [80]=frame [88]=body_ptr [96]=body_line [104]=emit_len_saved

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		".top_loop:\n"
		"mov r12, [rsp+0]\n" // reload p (helpers may clobber callee-saved regs)
		"mov rax, [r12+8]\n"
		"test rax, rax\n" // TOK_EOF
		"je .done\n"

		// top-level: const decl, enum decl, or func decl
		"cmp rax, 20\n" // TOK_KW_CONST
		"je .do_const\n"
		"cmp rax, 11\n" // TOK_KW_VAR
		"je .do_gvar\n"
		"cmp rax, 1\n"  // TOK_IDENT (maybe 'enum')
		"jne .maybe_func\n"
		"mov rdi, r12\n"
		"lea rsi, [rel .s_import]\n"
		"mov rdx, 6\n"
		"call parser_is_ident_kw\n"
		"test rax, rax\n"
		"jnz .do_import\n"
		"mov rdi, r12\n"
		"lea rsi, [rel .s_enum]\n"
		"mov rdx, 4\n"
		"call parser_is_ident_kw\n"
		"test rax, rax\n"
		"jnz .do_enum\n"
		"mov rdi, r12\n"
		"lea rsi, [rel .s_struct]\n"
		"mov rdx, 6\n"
		"call parser_is_ident_kw\n"
		"test rax, rax\n"
		"jnz .do_struct\n"
		".maybe_func:\n"
		"cmp rax, 10\n" // TOK_KW_FUNC
		"je .kw_ok\n"
		"call die_func_expected_kw_func\n"
		".kw_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// name ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .name_ok\n"
		"call die_func_expected_ident\n"
		".name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"
		// Slice* for function name
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call slice_from_parts\n"
		"mov [rsp+24], rax\n"

		// consume name
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect '('
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .lp_ok\n"
		"call die_func_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// args vec
		"mov rdi, 8\n" "call vec_new\n"
		"mov [rsp+40], rax\n"
		"mov rdi, r12\n"
		"mov rsi, [rsp+40]\n"
		"call parse_func_args\n"
		"mov r12, [rsp+0]\n"

		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rp_ok\n"
		"call die_func_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .lb_ok\n"
		"call die_func_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// save current emit_len so scan output can be discarded
		"mov rax, [rel emit_len]\n"
		"mov [rsp+104], rax\n"

		// ret label Slice*
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call ret_label_from_func_name\n"
		"mov [rsp+32], rax\n"

		// --- P1/P2: compute per-function frame size via a scan pass ---
		// Save body-start lexer state (ptr, line) for replay.
		"mov r13, [r12+0]\n"   // lex*
		"mov r14, [r12+16]\n"  // tok_ptr (start)
		"mov r15, [r12+32]\n"  // tok_line
		// stash at [rsp+88]=body_ptr, [rsp+96]=body_line
		"mov [rsp+88], r14\n"
		"mov [rsp+96], r15\n"

		// reset locals/aliases for scan
		"call locals_reset\n"
		"call aliases_reset\n"

		// allocate arg locals (no emits)
		"mov rdi, [rsp+40]\n" "call vec_len\n"
		"mov r14, rax\n" // argc
		"xor ebx, ebx\n" // i
		".arg_scan_loop:\n"
		"cmp rbx, r14\n" "jae .arg_scan_done\n"
		"mov rdi, [rsp+40]\n" "mov rsi, rbx\n" "call vec_get\n" // ArgName*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n" "mov rsi, [r13+8]\n"
		"call locals_get_or_alloc\n"
		"inc rbx\n"
		"jmp .arg_scan_loop\n"
		".arg_scan_done:\n"

		// scan stmt list until '}'
		"mov rdi, 8\n" "call vec_new\n" "mov [rsp+48], rax\n" // loop_starts
		"mov rdi, 8\n" "call vec_new\n" "mov [rsp+56], rax\n" // loop_ends
		"mov rdi, r12\n"
		"mov rsi, [rsp+48]\n"
		"mov rdx, [rsp+56]\n"
		"mov rcx, [rsp+32]\n" // ret_target
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"
		"mov r12, [rsp+0]\n"

		// frame_size = align16(locals_next_off)
		"mov rax, [rel locals_next_off]\n"
		"add rax, 15\n"
		"and rax, -16\n"
		"mov [rsp+80], rax\n" // frame_size

		// discard any scan emissions
		"mov rax, [rsp+104]\n"
		"mov [rel emit_len], rax\n"

		// replay body: restore lexer cur/line to body start, then parser_next
		"mov r13, [r12+0]\n"   // lex*
		"mov rax, [rsp+88]\n"  // body_ptr
		"mov [r13+0], rax\n"
		"mov rax, [rsp+96]\n"  // body_line
		"mov [r13+16], rax\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// reset locals/aliases for real emit pass
		"call locals_reset\n"
		"call aliases_reset\n"

		// emit function label
		"mov rdi, [rsp+24]\n"
		"call emit_slice_label_def\n"

		// prologue: push rbp; mov rbp,rsp; sub rsp, <frame_size>
		"lea rdi, [rel .s_pro0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+80]\n" "call emit_u64\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"

		// spill args to stack locals (now that offsets are fixed)
		"mov rdi, [rsp+40]\n" "call vec_len\n"
		"mov [rsp+64], rax\n" // argc
		"mov qword [rsp+72], 0\n" // i
		".spill_loop:\n"
		"mov rbx, [rsp+72]\n"
		"cmp rbx, [rsp+64]\n" "jae .spill_done\n"
		"mov rdi, [rsp+40]\n" "mov rsi, rbx\n" "call vec_get\n" // ArgName*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n" // name_ptr
		"mov rsi, [r13+8]\n" // name_len
		"call locals_get_or_alloc\n" // rax=off
		"mov rdi, rax\n" // off
		"cmp rbx, 6\n"
		"jb .spill_reg\n"
		// stack arg: spill from [rbp+16+8*(i-6)]
		"mov rsi, rbx\n"
		"sub rsi, 6\n"
		"call emit_store_stack_arg_to_local\n"
		"jmp .spill_next\n"
		".spill_reg:\n"
		"mov rsi, rbx\n" // reg_id
		"call emit_store_arg_to_local\n"
		".spill_next:\n"
		"mov rbx, [rsp+72]\n"
		"inc rbx\n"
		"mov [rsp+72], rbx\n"
		"jmp .spill_loop\n"
		".spill_done:\n"
		"mov r12, [rsp+0]\n" // reload p

		// loop stacks
		"mov rdi, 8\n" "call vec_new\n" "mov [rsp+48], rax\n"
		"mov rdi, 8\n" "call vec_new\n" "mov [rsp+56], rax\n"

		// parse stmt list until '}'
		"mov rdi, r12\n"
		"mov rsi, [rsp+48]\n"
		"mov rdx, [rsp+56]\n"
		"mov rcx, [rsp+32]\n"
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"
		"mov r12, [rsp+0]\n"

		// expect '}'
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .rb_ok\n"
		"call die_func_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// default return 0 if no explicit return
		"lea rdi, [rel .s_xor]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_slice_label_def\n"
		"lea rdi, [rel .s_ret]\n" "call emit_cstr\n"

		"jmp .top_loop\n"

		".do_gvar:\n"
		// global var decl: var IDENT [ ':' ['*'] IDENT ] [ '=' <const-expr> ] ';'
		"mov rdi, r12\n"
		"call parser_next\n" // consume 'var'
		"mov r12, [rsp+0]\n"
		// name ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .gv_name_ok\n" "call die_global_var_expected_ident\n"
		".gv_name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"
		"mov rdi, r12\n" "call parser_next\n" // consume name
		"mov r12, [rsp+0]\n"
		// optional type hint: ':' ['*'] IDENT
		"mov rax, [r12+8]\n" "cmp rax, 39\n" "jne .gv_after_type\n" // TOK_COLON
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 42\n" "jne .gv_ty_no_star\n" // '*'
		"mov rdi, r12\n" "call parser_next\n" // consume '*'
		"mov r12, [rsp+0]\n"
		".gv_ty_no_star:\n"
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .gv_ty_ok\n" "call die_global_var_expected_ident\n"
		".gv_ty_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume type ident
		"mov r12, [rsp+0]\n"
		".gv_after_type:\n"
		// optional init
		"mov qword [rsp+112], 0\n" // has_init
		"mov qword [rsp+120], 0\n" // init_value
		"mov rax, [r12+8]\n" "cmp rax, 50\n" "jne .gv_no_init\n" // TOK_EQ
		"mov qword [rsp+112], 1\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n" "mov rsi, 36\n" "call const_expr_eval\n" // end at ';'
		"mov [rsp+120], rax\n"
		"mov r12, [rsp+0]\n"
		".gv_no_init:\n"
		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .gv_semi_ok\n" "call die_global_var_expected_semi\n"
		".gv_semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"
		// label_sl = var_label_from_ident(name)
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"call var_label_from_ident\n" // rax=Slice*
		"mov r13, rax\n" // label_sl
		"mov rax, [rsp+112]\n" "test rax, rax\n" "jz .gv_emit_bss\n"
		"mov rdi, r13\n" // label
		"mov rsi, [rsp+120]\n" // init_value
		"call vars_define_data_if_needed\n"
		"jmp .gv_done\n"
		".gv_emit_bss:\n"
		"mov rdi, r13\n"
		"call vars_define_if_needed\n"
		".gv_done:\n"
		"jmp .top_loop\n"

		".do_const:\n"
		// const IDENT = <const-expr> ;
		"mov rdi, r12\n"
		"call parser_next\n" // consume 'const'
		"mov r12, [rsp+0]\n"

		// name ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .c_name_ok\n"
		"call die_func_expected_ident\n"
		".c_name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"
		"mov rdi, r12\n" "call parser_next\n" // consume name
		"mov r12, [rsp+0]\n"

		// expect '='
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"je .c_eq_ok\n"
		"call die_const_expected_equal\n"
		".c_eq_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"

		// value = const_expr_eval(p, ';')
		"mov rdi, r12\n"
		"mov rsi, 36\n" // TOK_SEMI
		"call const_expr_eval\n"
		"mov r14, rax\n" // value
		"mov r12, [rsp+0]\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .c_semi_ok\n"
		"call die_const_expected_semi\n"
		".c_semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"

		// consts_set(name, value)
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"mov rdx, r14\n"       // value
		"call consts_set\n"
		"jmp .top_loop\n"

		".do_enum:\n"
		// enum IDENT { IDENT [= const-expr] (, ...)? } [';']
		"mov rdi, r12\n" "call parser_next\n" // consume 'enum' ident
		"mov r12, [rsp+0]\n"
		// enum name
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .e_name_ok\n"
		"call die_func_expected_ident\n"
		".e_name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"   // reuse name_ptr slot
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"  // reuse name_len slot
		"mov rdi, r12\n" "call parser_next\n" // consume enum name
		"mov r12, [rsp+0]\n"
		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .e_lb_ok\n"
		"call die_enum_expected_lbrace\n"
		".e_lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '{'
		"mov r12, [rsp+0]\n"
		
		"xor r14d, r14d\n" // next_val
		".e_loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .e_rb\n"
		"cmp rax, 1\n"  // TOK_IDENT
		"je .e_mem_ok\n"
		"call die_func_expected_ident\n"
		".e_mem_ok:\n"
		"mov r13, [r12+16]\n" // mem_ptr
		"mov r15, [r12+24]\n" // mem_len
		"mov rdi, r12\n" "call parser_next\n" // consume member
		"mov r12, [rsp+0]\n"
		// optional '= expr'
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"jne .e_use_next\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n"
		"mov rsi, 37\n" // end_kind = ',' (we also allow '}' handled after)
		"call const_expr_eval\n"
		"mov r14, rax\n" // set next_val
		"mov r12, [rsp+0]\n"
		".e_use_next:\n"
		// define Enum.Member = next_val
		"mov rdi, [rsp+8]\n"   // enum_ptr
		"mov rsi, [rsp+16]\n"  // enum_len
		"mov rdx, r13\n"        // mem_ptr
		"mov rcx, r15\n"        // mem_len
		"mov r8,  r14\n"        // value
		"call enum_define_member\n"
		"inc r14\n"             // next_val++
		"mov r12, [rsp+0]\n"
		// after member: ',' or '}'
		"mov rax, [r12+8]\n"
		"cmp rax, 37\n" // ','
		"je .e_comma\n"
		"cmp rax, 33\n" // '}'
		"je .e_rb\n"
		"call die_enum_expected_colon_or_comma_or_rbrace\n"
		".e_comma:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ','
		"mov r12, [rsp+0]\n"
		"jmp .e_loop\n"
		".e_rb:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '}'
		"mov r12, [rsp+0]\n"
		// optional ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // ';'
		"jne .e_done\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		".e_done:\n"
		"jmp .top_loop\n"

		".do_struct:\n"
		"mov rdi, r12\n" "call parse_struct_decl\n"
		"mov r12, [rsp+0]\n"
		"jmp .top_loop\n"

		".do_import:\n"
		// consume 'import'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect first ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .imp_id_ok\n" "call die_import_expected_ident_toplevel\n"
		".imp_id_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ident
		"mov r12, [rsp+0]\n"
		".imp_more:\n"
		"mov rax, [r12+8]\n" "cmp rax, 38\n" "jne .imp_done_parts\n" // '.'
		"mov rdi, r12\n" "call parser_next\n" // consume '.'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .imp_next_ok\n" "call die_import_expected_ident_toplevel\n"
		".imp_next_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ident
		"mov r12, [rsp+0]\n"
		"jmp .imp_more\n"
		".imp_done_parts:\n"
		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .imp_semi_ok\n" "call die_import_expected_semi_toplevel\n"
		".imp_semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"
		"jmp .top_loop\n"

		".s_enum: db 'enum', 0\n"
		".s_struct: db 'struct', 0\n"
		".s_import: db 'import', 0\n"

		".done:\n"
		"add rsp, 128\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pro0: db '  push rbp', 10, '  mov rbp, rsp', 10, '  sub rsp, ', 0\n"
		".s_nl: db 10, 0\n"
		".s_xor: db '  xor rax, rax', 10, 0\n"
		".s_ret: db '  mov rsp, rbp', 10, '  pop rbp', 10, '  ret', 10, 0\n"
		".exit:\n"
	};
}
