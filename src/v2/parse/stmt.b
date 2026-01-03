// v1 statements
// Roadmap: docs/roadmap.md (stage 10)
// Planned:
// - stmt_if()
// - stmt_while()
// - stmt_assign()
// - stmt_break(num)
// - stmt_continue(num)
// - stmt_return()
// - stmt_expr()

func die_stmt_expected_semi() {
	die("stmt: expected ';'");
}

func die_stmt_expected_lparen() {
	die("stmt: expected '('");
}

func die_stmt_expected_rparen() {
	die("stmt: expected ')'");
}

func die_stmt_expected_lbrace() {
	die("stmt: expected '{'");
}

func die_stmt_expected_rbrace() {
	die("stmt: expected '}'");
}

func die_stmt_expected_lbrack() {
	die("stmt: expected '['");
}

func die_stmt_expected_rbrack() {
	die("stmt: expected ']'");
}

func die_stmt_expected_eq() {
	die("stmt: expected '='");
}

func die_stmt_expected_ident() {
	die("stmt: expected identifier");
}

func die_stmt_expected_int() {
	die("stmt: expected int");
}

func die_stmt_var_array_init() {
	die("stmt: var array initializer not supported");
}

func die_stmt_struct_init_too_many() {
	die("stmt: too many struct initializers");
}

func die_stmt_struct_init_needs_brace() {
	die("stmt: struct initializer must be '{ ... }'");
}

func die_stmt_expected_colon() {
	die("stmt: expected ':'");
}

func die_stmt_bad_alias_reg() {
	die("stmt: bad alias register (expected rdi/rsi/rdx/rcx/r8/r9/r10/r11)");
}

func die_stmt_assign_to_const() {
	die("stmt: cannot assign to const");
}

func die_stmt_unexpected_eof() {
	die("stmt: unexpected EOF");
}

func die_stmt_unexpected_token() {
	die("stmt: unexpected token");
}

func die_stmt_break_outside_loop() {
	die("stmt: break outside loop");
}

func die_stmt_continue_outside_loop() {
	die("stmt: continue outside loop");
}

func die_stmt_continue_in_switch() {
	die("stmt: continue in switch");
}

func die_stmt_bad_loop_depth() {
	die("stmt: bad loop depth");
}

func die_stmt_undefined_ident() {
	die("stmt: undefined identifier");
}

func die_stmt_expected_kw_var() {
	die("stmt: expected 'var'");
}

func die_stmt_expected_kw_in() {
	die("stmt: expected 'in'");
}

func emit_label_def(sl) {
	// Emit: <label>:\n
	// Convention: rdi=Slice*
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

func emit_jmp(sl) {
	// Emit:   jmp <label>\n
	// Convention: rdi=Slice*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		"lea rdi, [rel .s_jmp]\n"
		"call emit_cstr\n"
		"mov rdi, r12\n"
		"call slice_parts\n" // rax=ptr, rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"

		"pop r12\n"
		"jmp near .exit\n"
		".s_jmp: db '  jmp ', 0\n"
		".s_nl:  db 10, 0\n"
		".exit:\n"
	};
}

func stmt_try_switch(p, loop_starts, loop_ends, ret_target) {
	// If current token is IDENT "switch", parse switch stmt and return 1.
	// Else return 0 and consume nothing.
	// Convention:
	// - rdi = Parser*
	// - rsi = loop_starts
	// - rdx = loop_ends
	// - rcx = ret_target
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=p [8]=starts [16]=ends [24]=ret
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .no\n"
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"lea rdx, [rel .s_switch]\n"
		"mov rcx, 6\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .no\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_switch\n"
		"mov eax, 1\n"
		"jmp .done\n"
		".no:\n"
		"xor eax, eax\n"
		".done:\n"
		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_switch: db 'switch', 0\n"
		".exit:\n"
	};
}

func stmt_try_ident_stmt(p, loop_starts, loop_ends, ret_target) {
	// If current token is IDENT for a statement keyword, parse it and return 1.
	// Supported: switch / for / foreach
	// Else return 0 and consume nothing.
	// Convention:
	// - rdi = Parser*
	// - rsi = loop_starts
	// - rdx = loop_ends
	// - rcx = ret_target
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=p [8]=starts [16]=ends [24]=ret
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .no\n"

		// switch
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"lea rdx, [rel .s_switch]\n"
		"mov rcx, 6\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .chk_for\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_switch\n"
		"mov eax, 1\n"
		"jmp .done\n"

		".chk_for:\n"
		"mov r12, [rsp+0]\n"
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"lea rdx, [rel .s_for]\n"
		"mov rcx, 3\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .chk_foreach\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_for\n"
		"mov eax, 1\n"
		"jmp .done\n"

		".chk_foreach:\n"
		"mov r12, [rsp+0]\n"
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"lea rdx, [rel .s_foreach]\n"
		"mov rcx, 7\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .no\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_foreach\n"
		"mov eax, 1\n"
		"jmp .done\n"

		".no:\n"
		"xor eax, eax\n"
		".done:\n"
		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_switch: db 'switch', 0\n"
		".s_for: db 'for', 0\n"
		".s_foreach: db 'foreach', 0\n"
		".exit:\n"
	};
}

func stmt_parse_list(p, loop_starts, loop_ends, ret_target, end_kind) {
	// Parse statements until current token kind == end_kind.
	// Does not consume end_kind token.
	//
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts (Slice* elements)
	// - rdx = Vec* loop_ends   (Slice* elements)
	// - rcx = Slice* ret_target
	// - r8  = end_kind (u64)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 48\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=end_kind

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov [rsp+32], r8\n"

		".loop:\n"
		"mov r12, [rsp+0]\n" // p
		"mov rax, [r12+8]\n" // kind
		"cmp rax, [rsp+32]\n" // end_kind
		"je .done\n"

		// If we are parsing a block (end_kind != EOF) and hit EOF => error.
		"test rax, rax\n" // TOK_EOF
		"jne .dispatch\n"
		"cmp qword [rsp+32], 0\n"
		"je .done\n" // end_kind==EOF => done
		"call die_stmt_unexpected_eof\n"

		".dispatch:\n"
		"cmp rax, 13\n" // TOK_KW_IF
		"je .do_if\n"
		"cmp rax, 15\n" // TOK_KW_WHILE
		"je .do_while\n"
		"cmp rax, 16\n" // TOK_KW_BREAK
		"je .do_break\n"
		"cmp rax, 17\n" // TOK_KW_CONTINUE
		"je .do_continue\n"
		"cmp rax, 18\n" // TOK_KW_RETURN
		"je .do_return\n"
		"cmp rax, 12\n" // TOK_KW_ALIAS
		"je .do_alias\n"
		"cmp rax, 19\n" // TOK_ASM_RAW
		"je .do_asm_raw\n"
		"cmp rax, 11\n" // TOK_KW_VAR
		"je .do_var\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .do_block\n"

		// '*' : deref store or expr-stmt
		"cmp rax, 42\n" // TOK_STAR
		"jne .not_deref_store\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_try_deref_store\n" // rax=1 if consumed
		"test rax, rax\n"
		"jnz .loop\n"
		"jmp .do_expr\n"
		".not_deref_store:\n"

		// IDENT: assignment or expr-stmt
		"cmp rax, 1\n" // TOK_IDENT
		"jne .do_expr\n"
		// switch/for/foreach statements are encoded as IDENT text (no dedicated token)
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_try_ident_stmt\n" // rax=1 if consumed
		"test rax, rax\n"
		"jnz .loop\n"
		"mov rdi, [rsp+0]\n"
		"call parser_peek_kind\n" // rax=next kind
		"cmp rax, 50\n" // TOK_EQ
		"je .do_assign\n"
		"cmp rax, 38\n" // TOK_DOT
		"je .do_field_store_maybe\n"
		"cmp rax, 72\n" // TOK_ARROW
		"je .do_field_store_maybe\n"
		"cmp rax, 34\n" // TOK_LBRACK
		"je .do_ptr_store_maybe\n"
		"jmp .do_expr\n"

		".do_field_store_maybe:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_try_field_store\n" // rax=1 if consumed
		"test rax, rax\n"
		"jnz .loop\n"
		"jmp .do_expr\n"

		".do_ptr_store_maybe:\n"
		"mov rdi, [rsp+0]\n"
		"call stmt_ptr_width_if_ptr_ident\n" // rax=0|8|64
		"test rax, rax\n"
		"jz .do_array_store_maybe\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_ptr_store\n"
		"jmp .loop\n"

		".do_array_store_maybe:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_try_array_store\n" // rax=1 if consumed
		"test rax, rax\n"
		"jnz .loop\n"
		"jmp .do_expr\n"

		".do_assign:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_assign\n"
		"jmp .loop\n"

		".do_asm_raw:\n"
		"mov rdi, [rsp+0]\n"
		"call stmt_asm_raw\n"
		"jmp .loop\n"

		".do_var:\n"
		"mov rdi, [rsp+0]\n"
		"call stmt_var_decl\n"
		"jmp .loop\n"

		".do_block:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_block\n"
		"jmp .loop\n"

		".do_expr:\n"

		// default: expr-stmt
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_expr\n"
		"jmp .loop\n"

		".do_if:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_if\n"
		"jmp .loop\n"

		".do_while:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_while\n"
		"jmp .loop\n"

		".do_break:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_break\n"
		"jmp .loop\n"

		".do_continue:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_continue\n"
		"jmp .loop\n"

		".do_return:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_return\n"
		"jmp .loop\n"

		".do_alias:\n"
		"mov rdi, [rsp+0]\n"
		"call stmt_alias\n"
		"jmp .loop\n"

		".done:\n"
		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_alias_reg_id_from_parts(ptr, len) {
	// Return reg_id for a register name.
	// Convention: rdi=ptr, rsi=len
	// Returns: rax=reg_id, rdx=ok(1/0)
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [0]=ptr [8]=len
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// rdi
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_rdi]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_rdi\n"
		// rsi
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_rsi]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_rsi\n"
		// rdx
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_rdx]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_rdx\n"
		// rcx
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_rcx]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_rcx\n"
		// r8
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_r8]\n" "mov rcx, 2\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_r8\n"
		// r9
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_r9]\n" "mov rcx, 2\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_r9\n"
		// r10
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_r10]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_r10\n"
		// r11
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n"
		"lea rdx, [rel .s_r11]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .is_r11\n"

		"xor eax, eax\n"
		"xor edx, edx\n"
		"jmp .done\n"
		".is_rdi:\n" "mov rax, 0\n" "mov rdx, 1\n" "jmp .done\n"
		".is_rsi:\n" "mov rax, 1\n" "mov rdx, 1\n" "jmp .done\n"
		".is_rdx:\n" "mov rax, 2\n" "mov rdx, 1\n" "jmp .done\n"
		".is_rcx:\n" "mov rax, 3\n" "mov rdx, 1\n" "jmp .done\n"
		".is_r8:\n"  "mov rax, 4\n" "mov rdx, 1\n" "jmp .done\n"
		".is_r9:\n"  "mov rax, 5\n" "mov rdx, 1\n" "jmp .done\n"
		".is_r10:\n" "mov rax, 6\n" "mov rdx, 1\n" "jmp .done\n"
		".is_r11:\n" "mov rax, 7\n" "mov rdx, 1\n"
		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_rdi: db 'rdi', 0\n"
		".s_rsi: db 'rsi', 0\n"
		".s_rdx: db 'rdx', 0\n"
		".s_rcx: db 'rcx', 0\n"
		".s_r8:  db 'r8', 0\n"
		".s_r9:  db 'r9', 0\n"
		".s_r10: db 'r10', 0\n"
		".s_r11: db 'r11', 0\n"
		".exit:\n"
	};
}

func stmt_alias(p) {
	// alias <reg> ':' <name> [ '=' expr ] ';'
	// Convention: rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 40\n" // [0]=p [8]=reg_id [16]=name_ptr [24]=name_len
		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		// expect 'alias'
		"mov rax, [r12+8]\n"
		"cmp rax, 12\n" // TOK_KW_ALIAS
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// expect reg ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .reg_ok\n"
		"call die_stmt_expected_ident\n"
		".reg_ok:\n"
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"call stmt_alias_reg_id_from_parts\n" // rax=reg_id, rdx=ok
		"test rdx, rdx\n"
		"jnz .reg_good\n"
		"call die_stmt_bad_alias_reg\n"
		".reg_good:\n"
		"mov [rsp+8], rax\n" // reg_id
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n" "call parser_next\n" // consume reg

		// expect ':'
		"mov rax, [r12+8]\n"
		"cmp rax, 39\n" // TOK_COLON
		"je .colon_ok\n"
		"call die_stmt_expected_colon\n"
		".colon_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// expect alias name ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .name_ok\n"
		"call die_stmt_expected_ident\n"
		".name_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+16], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+24], rax\n"
		"mov rdi, r12\n" "call parser_next\n" // consume alias name
		"mov r12, [rsp+0]\n"

		// aliases_set(name_ptr,name_len,reg_id)
		"mov rdi, [rsp+16]\n"
		"mov rsi, [rsp+24]\n"
		"mov rdx, [rsp+8]\n"
		"call aliases_set\n"
		"mov r12, [rsp+0]\n"

		// optional init
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"jne .no_init\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov rdi, r12\n" "call expr_parse_bor_emit\n" // leaves value on stack
		"lea rdi, [rel .s_pop]\n" "call emit_cstr\n"
		"mov rdi, [rsp+8]\n" "call emit_mov_reg_from_rax\n"
		"mov r12, [rsp+0]\n"
		".no_init:\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		"add rsp, 40\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_assign(p, loop_starts, loop_ends, ret_target) {
	// ident '=' expr ';'
	// Convention:
	// - rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 64\n" // [0]=p [8]=name_ptr [16]=name_len [24]=kind(0=local,1=alias,2=global) [32]=reg_or_off [40]=label_sl

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		// expect ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .id_ok\n"
		"call die_stmt_unexpected_token\n"
		".id_ok:\n"
		"mov rax, [r12+16]\n" // ptr
		"mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" // len
		"mov [rsp+16], rax\n"

		// if name is an alias, store into reg; else if const => error; else store into stack local or global.
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call aliases_get\n" // rax=reg_id, rdx=found
		"test rdx, rdx\n"
		"jz .not_alias\n"
		"mov qword [rsp+24], 1\n" // kind=alias
		"mov [rsp+32], rax\n"      // reg_id
		"jmp .after_target\n"
		".not_alias:\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call consts_get\n" // rdx=found
		"test rdx, rdx\n"
		"jz .not_const\n"
		"call die_stmt_assign_to_const\n"
		".not_const:\n"
		"mov qword [rsp+24], 0\n" // kind=local by default
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call locals_get\n" // rax=off, rdx=found
		"test rdx, rdx\n"
		"jnz .have_local\n"
		// Fall back to global var slot v_<ident>
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"call var_label_from_ident\n" // rax=Slice*
		"mov [rsp+40], rax\n" // label_sl
		"mov rdi, rax\n"
		"call vars_define_if_needed\n"
		"mov qword [rsp+24], 2\n" // kind=global
		"jmp .after_target\n"
		".have_local:\n"
		"mov [rsp+32], rax\n"       // off
		".after_target:\n"
		"mov r12, [rsp+0]\n" // reload p

		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '='
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"je .eq_ok\n"
		"call die_stmt_expected_eq\n"
		".eq_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// rhs expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// store: pop rax; mov (alias reg or [rbp-off] or [rel label]), rax
		"lea rdi, [rel .s_pop]\n"
		"call emit_cstr\n"
		"mov rax, [rsp+24]\n" // kind
		"cmp rax, 1\n"
		"je .store_alias\n"
		"cmp rax, 2\n"
		"je .store_global\n"
		"lea rdi, [rel .s_mov0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+32]\n" // off
		"call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n"
		"call emit_cstr\n"
		"jmp .store_done\n"
		".store_global:\n"
		"lea rdi, [rel .s_movg0]\n"
		"call emit_cstr\n"
		"mov rbx, [rsp+40]\n" // label_sl
		"mov rdi, [rbx+0]\n"
		"mov rsi, [rbx+8]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_movg1]\n"
		"call emit_cstr\n"
		"jmp .store_done\n"
		".store_alias:\n"
		"mov rdi, [rsp+32]\n" // reg_id
		"call emit_mov_reg_from_rax\n"
		".store_done:\n"

		"add rsp, 64\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"mov rsp, rbp\n"
		"pop rbp\n"
		"ret\n"
		".s_pop:  db '  pop rax', 10, 0\n"
		".s_mov0: db '  mov qword [rbp-', 0\n"
		".s_mov1: db '], rax', 10, 0\n"
		".s_movg0: db '  mov qword [rel ', 0\n"
		".s_movg1: db '], rax', 10, 0\n"
	};
}

func stmt_assign_no_semi(p) {
	// ident '=' expr   (no trailing ';')
	// Convention:
	// - rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 64\n" // [0]=p [8]=name_ptr [16]=name_len [24]=kind(0=local,1=alias,2=global) [32]=reg_or_off [40]=label_sl

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		// expect ident
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .id_ok\n"
		"call die_stmt_unexpected_token\n"
		".id_ok:\n"
		"mov rax, [r12+16]\n" // ptr
		"mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" // len
		"mov [rsp+16], rax\n"

		// resolve target (alias vs local vs global)
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call aliases_get\n" // rax=reg_id, rdx=found
		"test rdx, rdx\n"
		"jz .not_alias\n"
		"mov qword [rsp+24], 1\n" // kind=alias
		"mov [rsp+32], rax\n"      // reg_id
		"jmp .after_target\n"
		".not_alias:\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call consts_get\n" // rdx=found
		"test rdx, rdx\n"
		"jz .not_const\n"
		"call die_stmt_assign_to_const\n"
		".not_const:\n"
		"mov qword [rsp+24], 0\n" // kind=local by default
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call locals_get\n" // rax=off, rdx=found
		"test rdx, rdx\n"
		"jnz .have_local\n"
		// Fall back to global var slot v_<ident>
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"call var_label_from_ident\n" // rax=Slice*
		"mov [rsp+40], rax\n" // label_sl
		"mov rdi, rax\n"
		"call vars_define_if_needed\n"
		"mov qword [rsp+24], 2\n" // kind=global
		"jmp .after_target\n"
		".have_local:\n"
		"mov [rsp+32], rax\n"       // off
		".after_target:\n"
		"mov r12, [rsp+0]\n" // reload p

		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '='
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"je .eq_ok\n"
		"call die_stmt_expected_eq\n"
		".eq_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// rhs expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		// store: pop rax; mov (alias reg or [rbp-off] or [rel label]), rax
		"lea rdi, [rel .s_pop]\n"
		"call emit_cstr\n"
		"mov rax, [rsp+24]\n" // kind
		"cmp rax, 1\n"
		"je .store_alias\n"
		"cmp rax, 2\n"
		"je .store_global\n"
		"lea rdi, [rel .s_mov0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+32]\n" // off
		"call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n"
		"call emit_cstr\n"
		"jmp .store_done\n"
		".store_global:\n"
		"lea rdi, [rel .s_movg0]\n"
		"call emit_cstr\n"
		"mov rbx, [rsp+40]\n" // label_sl
		"mov rdi, [rbx+0]\n"
		"mov rsi, [rbx+8]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_movg1]\n"
		"call emit_cstr\n"
		"jmp .store_done\n"
		".store_alias:\n"
		"mov rdi, [rsp+32]\n" // reg_id
		"call emit_mov_reg_from_rax\n"
		".store_done:\n"

		"add rsp, 64\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"mov rsp, rbp\n"
		"pop rbp\n"
		"ret\n"
		".s_pop:  db '  pop rax', 10, 0\n"
		".s_mov0: db '  mov qword [rbp-', 0\n"
		".s_mov1: db '], rax', 10, 0\n"
		".s_movg0: db '  mov qword [rel ', 0\n"
		".s_movg1: db '], rax', 10, 0\n"
	};
}

func stmt_var_decl(p) {
	// 'var' IDENT ( '=' expr )? ';'
	// Convention: rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 88\n" // [0]=p [8]=name_ptr [16]=name_len [24]=off [32]=has_init [40]=is_array [48]=elems [56]=type_ptr [64]=type_len [72]=type_is_ptr [80]=alloc_size

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		// expect 'var'
		"mov rax, [r12+8]\n"
		"cmp rax, 11\n" // TOK_KW_VAR
		"je .kw_ok\n"
		"call die_stmt_expected_kw_var\n"
		".kw_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume 'var'
		"mov r12, [rsp+0]\n"

		// expect IDENT
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .id_ok\n"
		"call die_stmt_expected_ident\n"
		".id_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"
		"mov qword [rsp+40], 0\n" // is_array
		"mov qword [rsp+48], 0\n" // elems
		"mov qword [rsp+56], 0\n" // type_ptr
		"mov qword [rsp+64], 0\n" // type_len
		"mov qword [rsp+72], 0\n" // type_is_ptr
		"mov qword [rsp+80], 8\n" // alloc_size (default)

		// consume IDENT
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// optional array: '[' INT ']'
		"mov rax, [r12+8]\n"
		"cmp rax, 34\n" // TOK_LBRACK
		"jne .after_array\n"
		"mov qword [rsp+40], 1\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '['
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 2\n" "je .arr_int_ok\n" "call die_stmt_expected_int\n"
		".arr_int_ok:\n"
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n" "call atoi_u64_or_panic\n"
		"mov [rsp+48], rax\n" // elems
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n" "call parser_next\n" // consume INT
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 35\n" "je .arr_rb_ok\n" "call die_stmt_expected_rbrack\n"
		".arr_rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ']'
		"mov r12, [rsp+0]\n"
		".after_array:\n"

		// optional type hint: ':' ['*'] <ident>
		"mov rax, [r12+8]\n"
		"cmp rax, 39\n" // TOK_COLON
		"jne .after_type\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 42\n" "jne .ty_no_star\n"
		"mov qword [rsp+72], 1\n" // type_is_ptr
		"mov rdi, r12\n" "call parser_next\n" // consume '*'
		"mov r12, [rsp+0]\n"
		".ty_no_star:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .after_type\n"
		"mov rax, [r12+16]\n" "mov [rsp+56], rax\n" // type_ptr
		"mov rax, [r12+24]\n" "mov [rsp+64], rax\n" // type_len
		"mov rdi, r12\n" "call parser_next\n" // consume type ident
		"mov r12, [rsp+0]\n"
		".after_type:\n"

		// if typed as by-value struct, set alloc_size = StructDef.size
		"mov rax, [rsp+56]\n" "test rax, rax\n" "jz .type_size_done\n"
		"mov rax, [rsp+72]\n" "test rax, rax\n" "jnz .type_size_done\n" // pointer => 8
		"mov rdi, [rsp+56]\n" "mov rsi, [rsp+64]\n" "call structs_get\n"
		"test rdx, rdx\n" "jz .type_size_done\n" // non-struct primitive => keep 8
		"mov rax, [rax+24]\n" "mov [rsp+80], rax\n"
		".type_size_done:\n"

		// allocate local slot(s)
		"mov rax, [rsp+40]\n" // is_array
		"test rax, rax\n"
		"jz .alloc_scalar\n"
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"mov rdx, [rsp+48]\n" // elems
		"call locals_alloc_array\n" // rax=base_off
		"mov [rsp+24], rax\n"
		"jmp .alloc_done\n"
		".alloc_scalar:\n"
		// struct-by-value alloc: use locals_alloc_ex(size)
		"mov rax, [rsp+80]\n" "cmp rax, 8\n" "je .alloc_scalar8\n"
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"mov rdx, [rsp+80]\n" // size
		"mov rcx, [rsp+56]\n" // type_ptr
		"mov r8,  [rsp+64]\n" // type_len
		"mov r9,  [rsp+72]\n" // type_is_ptr
		"call locals_alloc_ex\n"
		"mov [rsp+24], rax\n"
		"jmp .init_zero_struct\n"
		".alloc_scalar8:\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call locals_alloc\n" // rax=off
		"mov [rsp+24], rax\n"
		// default init: mov qword [rbp-off], 0
		"lea rdi, [rel .s_mov0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+24]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n" "call emit_cstr\n"
		"jmp .alloc_done\n"

		".init_zero_struct:\n"
		// zero-init struct slots: for i=0; i<size; i+=8 => mov [rbp-(off+i)],0
		"xor ebx, ebx\n" // i
		".zs_loop:\n"
		"mov rax, rbx\n" "cmp rax, [rsp+80]\n" "jae .zs_done\n"
		"lea rdi, [rel .s_mov0]\n" "call emit_cstr\n"
		"mov rax, [rsp+24]\n" "add rax, rbx\n" "mov rdi, rax\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n" "call emit_cstr\n"
		"add rbx, 8\n"
		"jmp .zs_loop\n"
		".zs_done:\n"
		".alloc_done:\n"

		// If scalar and typed, store metadata into latest Local entry.
		"mov rax, [rsp+40]\n" "test rax, rax\n" "jnz .meta_done\n" // skip arrays
		"mov rax, [rsp+56]\n" "test rax, rax\n" "jz .meta_done\n"
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+16]\n" "call locals_get_entry\n" // rax=Local*
		"test rdx, rdx\n" "jz .meta_done\n"
		"mov r13, rax\n"
		"mov rax, [rsp+80]\n" "mov [r13+24], rax\n" // size
		"mov rax, [rsp+56]\n" "mov [r13+32], rax\n" // type_ptr
		"mov rax, [rsp+64]\n" "mov [r13+40], rax\n" // type_len
		"mov rax, [rsp+72]\n" "mov [r13+48], rax\n" // type_is_ptr
		".meta_done:\n"

		// optional '= expr' OR (struct-by-value only) '= { expr (, expr)* }'
		"mov qword [rsp+32], 0\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"jne .no_init\n"
		// arrays: init not supported (MVP)
		"mov rax, [rsp+40]\n" // is_array
		"test rax, rax\n"
		"jz .init_scalar_ok\n"
		"call die_stmt_var_array_init\n"
		".init_scalar_ok:\n"
		// consume '='
		"mov qword [rsp+32], 1\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"
		// If struct-by-value (alloc_size != 8): only allow brace-init list.
		"mov rax, [rsp+80]\n" "cmp rax, 8\n" "je .init_scalar_expr\n"
		"mov rax, [r12+8]\n" "cmp rax, 32\n" "je .init_struct_brace\n" // TOK_LBRACE
		"call die_stmt_struct_init_needs_brace\n"

		".init_scalar_expr:\n"
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		// store expr into local: pop rax; mov [rbp-off], rax
		"lea rdi, [rel .s_pop]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_mov0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+24]\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_mov2]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .no_init\n"

		".init_struct_brace:\n"
		// Expect typed by-value struct local (non-pointer).
		"mov rax, [rsp+56]\n" "test rax, rax\n" "jnz .is_has_type\n" "call die_stmt_struct_init_needs_brace\n"
		".is_has_type:\n"
		"mov rax, [rsp+72]\n" "test rax, rax\n" "jz .is_not_ptr\n" "call die_stmt_struct_init_needs_brace\n"
		".is_not_ptr:\n"
		// Load StructDef and fields vec.
		"mov rdi, [rsp+56]\n" "mov rsi, [rsp+64]\n" "call structs_get\n" // rax=StructDef*, rdx=found
		"test rdx, rdx\n" "jnz .is_def_ok\n" "call die_stmt_struct_init_needs_brace\n"
		".is_def_ok:\n"
		"mov r13, rax\n" // StructDef*
		"mov r14, [r13+16]\n" // fields_vec
		// consume '{'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// idx = 0
		"xor ebx, ebx\n"
		// allow empty initializer: '{ }'
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .is_close\n" // TOK_RBRACE
		".is_loop:\n"
		// bounds check: idx < nfields
		"mov rdi, r14\n" "call vec_len\n" // rax=nfields
		"cmp rbx, rax\n" "jb .is_idx_ok\n" "call die_stmt_struct_init_too_many\n"
		".is_idx_ok:\n"
		// parse element expr (push result)
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop]\n" "call emit_cstr\n" // pop rax
		// field = vec_get(fields_vec, idx)
		"mov rdi, r14\n" "mov rsi, rbx\n" "call vec_get\n" // rax=Field*
		"mov r12, [rsp+0]\n"
		"mov rdx, rax\n" // Field*
		// total_off = (off + struct_size - 8) - field_off
		"mov rax, [rsp+24]\n" // off (top qword)
		"mov rcx, [rsp+80]\n" // struct_size
		"add rax, rcx\n"
		"sub rax, 8\n"
		"mov rcx, [rdx+16]\n" // field_off
		"sub rax, rcx\n"
		"mov [rsp+32], rax\n" // total_off (reuse has_init slot as temp)
		// store sized into [rbp-total_off]
		"mov rcx, [rdx+24]\n" // field_size
		"cmp rcx, 1\n" "je .is_store1\n"
		"cmp rcx, 2\n" "je .is_store2\n"
		"cmp rcx, 4\n" "je .is_store4\n"
		"cmp rcx, 8\n" "je .is_store8\n"
		"call die_struct_field_not_qword\n"
		".is_store1:\n"
		"lea rdi, [rel .s_movb0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movb1]\n" "call emit_cstr\n"
		"jmp .is_store_done\n"
		".is_store2:\n"
		"lea rdi, [rel .s_movw0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movw1]\n" "call emit_cstr\n"
		"jmp .is_store_done\n"
		".is_store4:\n"
		"lea rdi, [rel .s_movd0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movd1]\n" "call emit_cstr\n"
		"jmp .is_store_done\n"
		".is_store8:\n"
		"lea rdi, [rel .s_movq0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movq1]\n" "call emit_cstr\n"
		".is_store_done:\n"
		// idx++
		"inc rbx\n"
		// optional comma
		"mov rax, [r12+8]\n" "cmp rax, 37\n" "jne .is_close_check\n" // TOK_COMMA
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .is_loop\n"
		".is_close_check:\n"
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .is_close\n" // TOK_RBRACE
		"jmp .is_close\n"
		".is_close:\n"
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .is_rb_ok\n" "call die_stmt_expected_rbrace\n"
		".is_rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '}'
		"mov r12, [rsp+0]\n"
		".no_init:\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume ';'

		"add rsp, 88\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop:  db '  pop rax', 10, 0\n"
		".s_mov0: db '  mov qword [rbp-', 0\n"
		".s_mov1: db '], 0', 10, 0\n"
		".s_mov2: db '], rax', 10, 0\n"
		// struct initializer stores
		".s_movb0: db '  mov byte [rbp-', 0\n"
		".s_movb1: db '], al', 10, 0\n"
		".s_movw0: db '  mov word [rbp-', 0\n"
		".s_movw1: db '], ax', 10, 0\n"
		".s_movd0: db '  mov dword [rbp-', 0\n"
		".s_movd1: db '], eax', 10, 0\n"
		".s_movq0: db '  mov qword [rbp-', 0\n"
		".s_movq1: db '], rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_block(p, loop_starts, loop_ends, ret_target) {
	// '{' stmt* '}' with lexical scope
	// Convention:
	// - rdi = Parser*
	// - rsi = loop_starts
	// - rdx = loop_ends
	// - rcx = ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 40\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=saved_len
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"

		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .lb_ok\n"
		"call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume '{'
		"mov r12, [rsp+0]\n"

		// saved_len = vec_len(locals_emitted)
		"mov r13, [rel locals_emitted]\n"
		"mov rdi, r13\n"
		"call vec_len\n"
		"mov [rsp+32], rax\n"

		// parse inner list until '}'
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"
		"mov r12, [rsp+0]\n"

		// expect '}'
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .rb_ok\n"
		"call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume '}'

		// restore locals_emitted len
		"mov r13, [rel locals_emitted]\n"
		"mov rax, [rsp+32]\n"
		"mov [r13+8], rax\n"

		"add rsp, 40\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_ptr_width_if_ptr_ident(p) {
	// If current token is IDENT "ptr8" or "ptr64", return 8 or 64; else 0.
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .no\n"

		// compare token text
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"lea rdx, [rel .s_ptr8]\n"
		"mov rcx, 4\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .is8\n"
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"lea rdx, [rel .s_ptr64]\n"
		"mov rcx, 5\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .is64\n"
		"jmp .no\n"

		".is8:\n"
		"mov rax, 8\n"
		"jmp .done\n"
		".is64:\n"
		"mov rax, 64\n"
		"jmp .done\n"
		".no:\n"
		"xor eax, eax\n"
		".done:\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_ptr8:  db 'ptr8', 0\n"
		".s_ptr64: db 'ptr64', 0\n"
		".exit:\n"
	};
}

func stmt_ptr_store(p, loop_starts, loop_ends, ret_target) {
	// ptr8 '[' addr ']' '=' expr ';'
	// ptr64 '[' addr ']' '=' expr ';'
	// addr: expr (evaluated as address value)
	// Convention:
	// - rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 32\n" // [0]=p [8]=width [16]=var_label
		"mov [rsp+0], rdi\n"

		// width = stmt_ptr_width_if_ptr_ident(p)
		"mov rdi, [rsp+0]\n"
		"call stmt_ptr_width_if_ptr_ident\n"
		"mov [rsp+8], rax\n"
		"test rax, rax\n"
		"jnz .w_ok\n"
		"call die_stmt_unexpected_token\n"
		".w_ok:\n"

		"mov r12, [rsp+0]\n"
		// consume ptr8/ptr64 ident
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '['
		"mov rax, [r12+8]\n"
		"cmp rax, 34\n" // TOK_LBRACK
		"je .lb_ok\n"
		"call die_stmt_expected_lbrack\n"
		".lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume '['

		// parse address expr and leave it on stack
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"
		// expect ']'
		"mov rax, [r12+8]\n"
		"cmp rax, 35\n" // TOK_RBRACK
		"je .rb_ok\n"
		"call die_stmt_expected_rbrack\n"
		".rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume ']'

		// expect '='
		"mov rax, [r12+8]\n"
		"cmp rax, 50\n" // TOK_EQ
		"je .eq_ok\n"
		"call die_stmt_expected_eq\n"
		".eq_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume '='

		// rhs expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n" // consume ';'

		// emit store
		// stack at runtime: [addr, rhs] (rhs on top)
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"mov rax, [rsp+8]\n" // width
		"cmp rax, 8\n"
		"je .store8\n"
		"lea rdi, [rel .s_store64]\n"
		"jmp .store_emit\n"
		".store8:\n"
		"lea rdi, [rel .s_store8]\n"
		".store_emit:\n"
		"call emit_cstr\n"

		"add rsp, 32\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_store8:   db '  mov byte [r10], al', 10, 0\n"
		".s_store64:  db '  mov qword [r10], rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_try_deref_store(p, loop_starts, loop_ends, ret_target) {
	// Try parse/emit: '*' expr '=' expr ';' as a qword store through a pointer.
	// If the form doesn't match (not followed by '='), restores lexer+emit state and returns 0.
	// Returns: rax = 1 if consumed, else 0.
	// Convention: rdi=Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 40\n" // [0]=p [8]=start_ptr [16]=start_line [24]=saved_emit_len

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"
		// snapshot start token and emit_len
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"   // tok_ptr
		"mov rax, [r12+32]\n" "mov [rsp+16], rax\n"  // tok_line
		"mov rax, [rel emit_len]\n" "mov [rsp+24], rax\n"

		// must start with '*'
		"mov rax, [r12+8]\n" "cmp rax, 42\n" "je .star_ok\n" "jmp .fail\n"
		".star_ok:\n"
		// consume '*'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// parse address expr (leaves value on stack)
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		// require '=' to be an assignment; otherwise rollback
		"mov rax, [r12+8]\n" "cmp rax, 50\n" "je .eq_ok\n" "jmp .fail\n"
		".eq_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"

		// rhs expr (leaves value on stack)
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .semi_ok\n" "call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'

		// emit store
		// stack at runtime: [addr, rhs] (rhs on top)
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n" // rhs
		"lea rdi, [rel .s_pop_r10]\n" "call emit_cstr\n" // addr
		"lea rdi, [rel .s_store64]\n" "call emit_cstr\n"

		"mov rax, 1\n"
		"jmp .done\n"

		".fail:\n"
		// rollback emitted code
		"mov rax, [rsp+24]\n"
		"mov [rel emit_len], rax\n"
		// restore lexer to statement start token and re-prime
		"mov r12, [rsp+0]\n"
		"mov r13, [r12+0]\n"  // lex*
		"mov rax, [rsp+8]\n"  // start_ptr
		"mov [r13+0], rax\n"
		"mov rax, [rsp+16]\n" // start_line
		"mov [r13+16], rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"xor eax, eax\n"

		".done:\n"
		"add rsp, 40\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop_rax:   db '  pop rax', 10, 0\n"
		".s_pop_r10:   db '  pop r10', 10, 0\n"
		".s_store64:   db '  mov qword [r10], rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_try_field_store(p, loop_starts, loop_ends, ret_target) {
	// Try parse/emit: IDENT ('.'|'->') IDENT '=' expr ';'
	// If the form doesn't match (not followed by '='), restores lexer+emit state and returns 0.
	// Returns: rax = 1 if consumed, else 0.
	// Convention: rdi=Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 104\n" // [0]=p [8]=start_ptr [16]=start_line [24]=saved_emit_len [32]=name_ptr [40]=name_len [48]=op_kind [56]=field_ptr [64]=field_len [72]=local [80]=field [88]=total_off [96]=field_size

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"
		// snapshot start token and emit_len
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"   // tok_ptr
		"mov rax, [r12+32]\n" "mov [rsp+16], rax\n"  // tok_line
		"mov rax, [rel emit_len]\n" "mov [rsp+24], rax\n"

		// must start with IDENT
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .id_ok\n" "jmp .fail\n"
		".id_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+32], rax\n" // name_ptr
		"mov rax, [r12+24]\n" "mov [rsp+40], rax\n" // name_len

		// consume IDENT
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// op: '.' or '->'
		"mov rax, [r12+8]\n" "cmp rax, 38\n" "je .op_ok\n" "cmp rax, 72\n" "je .op_ok\n" "jmp .fail\n"
		".op_ok:\n"
		"mov [rsp+48], rax\n" // op_kind
		"mov rdi, r12\n" "call parser_next\n" // consume op
		"mov r12, [rsp+0]\n"

		// field ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .fid_ok\n" "call die_stmt_expected_ident\n"
		".fid_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+56], rax\n" // field_ptr
		"mov rax, [r12+24]\n" "mov [rsp+64], rax\n" // field_len
		"mov rdi, r12\n" "call parser_next\n" // consume field
		"mov r12, [rsp+0]\n"

		// require '=' to be an assignment; otherwise rollback
		"mov rax, [r12+8]\n" "cmp rax, 50\n" "je .eq_ok\n" "jmp .fail\n"
		".eq_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"

		// rhs expr (leaves value on stack)
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .semi_ok\n" "call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"

		// resolve base local and field
		"mov rdi, [rsp+32]\n" "mov rsi, [rsp+40]\n" "call locals_get_entry\n" // rax=Local*
		"test rdx, rdx\n" "jnz .have_local\n" "call die_expr_undefined_ident\n"
		".have_local:\n"
		"mov [rsp+72], rax\n" // local
		"mov r15, rax\n"
		"mov rax, [r15+32]\n" "test rax, rax\n" "jnz .have_type\n" "call die_struct_field_access_needs_type\n"
		".have_type:\n"
		"mov rdi, [r15+32]\n" "mov rsi, [r15+40]\n" // type
		"mov rdx, [rsp+56]\n" "mov rcx, [rsp+64]\n" // field
		"call structs_get_field\n"
		"test rdx, rdx\n" "jnz .have_field\n" "call die_struct_unknown_field\n"
		".have_field:\n"
		"mov [rsp+80], rax\n" // field
		"mov r14, rax\n"
		"mov rax, [r14+24]\n" "mov [rsp+96], rax\n" // field_size

		// emit store
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n" // rhs
		"mov r15, [rsp+72]\n" // Local*
		"mov rax, [rsp+48]\n" // op_kind
		"cmp rax, 38\n" "je .store_dot\n"
		"jmp .store_arrow\n"

		".store_dot:\n"
		// require non-pointer base
		"mov rax, [r15+48]\n" "test rax, rax\n" "jz .dot_ok\n" "call die_struct_field_access_needs_type\n"
		".dot_ok:\n"
		// total_off = (local_off + struct_size - 8) - field_off
		"mov rdi, [r15+32]\n" "mov rsi, [r15+40]\n" "call structs_get\n" // rax=StructDef*, rdx=found
		"test rdx, rdx\n" "jnz .dot_def_ok\n" "call die_struct_by_value_incomplete\n"
		".dot_def_ok:\n"
		"mov rdx, [rax+24]\n" // struct_size
		"mov rax, [r15+16]\n" // local_off (top qword)
		"add rax, rdx\n"
		"sub rax, 8\n"
		"mov rdx, [rsp+80]\n" "mov rdx, [rdx+16]\n" // field_off
		"sub rax, rdx\n" "mov [rsp+88], rax\n"
		"mov rax, [rsp+96]\n" // field_size
		"cmp rax, 1\n" "je .dot_store1\n"
		"cmp rax, 2\n" "je .dot_store2\n"
		"cmp rax, 4\n" "je .dot_store4\n"
		"cmp rax, 8\n" "je .dot_store8\n"
		"call die_struct_field_not_qword\n"
		".dot_store1:\n"
		"lea rdi, [rel .s_movb_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+88]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movb_rbp1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".dot_store2:\n"
		"lea rdi, [rel .s_movw_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+88]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movw_rbp1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".dot_store4:\n"
		"lea rdi, [rel .s_movd_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+88]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movd_rbp1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".dot_store8:\n"
		"lea rdi, [rel .s_mov_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+88]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_rbp1]\n" "call emit_cstr\n"
		"jmp .store_done\n"

		".store_arrow:\n"
		// require pointer base
		"mov rax, [r15+48]\n" "test rax, rax\n" "jnz .ar_ok\n" "call die_struct_field_access_needs_type\n"
		".ar_ok:\n"
		// mov r10, qword [rbp-off]
		"lea rdi, [rel .s_mov_r10_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [r15+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"mov rax, [rsp+96]\n" // field_size
		"cmp rax, 1\n" "je .ar_store1\n"
		"cmp rax, 2\n" "je .ar_store2\n"
		"cmp rax, 4\n" "je .ar_store4\n"
		"cmp rax, 8\n" "je .ar_store8\n"
		"call die_struct_field_not_qword\n"
		".ar_store1:\n"
		"lea rdi, [rel .s_movb_r10_off0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movb_r10_off1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".ar_store2:\n"
		"lea rdi, [rel .s_movw_r10_off0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movw_r10_off1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".ar_store4:\n"
		"lea rdi, [rel .s_movd_r10_off0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_movd_r10_off1]\n" "call emit_cstr\n"
		"jmp .store_done\n"
		".ar_store8:\n"
		"lea rdi, [rel .s_mov_r10_off0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_r10_off1]\n" "call emit_cstr\n"
		"jmp .store_done\n"

		".store_done:\n"
		"mov rax, 1\n"
		"jmp .done\n"

		".fail:\n"
		// rollback emitted code
		"mov rax, [rsp+24]\n" "mov [rel emit_len], rax\n"
		// restore lexer to statement start token and re-prime
		"mov r12, [rsp+0]\n"
		"mov r13, [r12+0]\n"  // lex*
		"mov rax, [rsp+8]\n"  // start_ptr
		"mov [r13+0], rax\n"
		"mov rax, [rsp+16]\n" // start_line
		"mov [r13+16], rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"xor eax, eax\n"

		".done:\n"
		"add rsp, 104\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop_rax:       db '  pop rax', 10, 0\n"
		".s_mov_rbp0:      db '  mov qword [rbp-', 0\n"
		".s_mov_rbp1:      db '], rax', 10, 0\n"
		".s_movd_rbp0:     db '  mov dword [rbp-', 0\n"
		".s_movd_rbp1:     db '], eax', 10, 0\n"
		".s_movw_rbp0:     db '  mov word [rbp-', 0\n"
		".s_movw_rbp1:     db '], ax', 10, 0\n"
		".s_movb_rbp0:     db '  mov byte [rbp-', 0\n"
		".s_movb_rbp1:     db '], al', 10, 0\n"
		".s_mov_r10_rbp0:  db '  mov r10, qword [rbp-', 0\n"
		".s_rbr:           db ']', 10, 0\n"
		".s_mov_r10_off0:  db '  mov qword [r10+', 0\n"
		".s_mov_r10_off1:  db '], rax', 10, 0\n"
		".s_movd_r10_off0: db '  mov dword [r10+', 0\n"
		".s_movd_r10_off1: db '], eax', 10, 0\n"
		".s_movw_r10_off0: db '  mov word [r10+', 0\n"
		".s_movw_r10_off1: db '], ax', 10, 0\n"
		".s_movb_r10_off0: db '  mov byte [r10+', 0\n"
		".s_movb_r10_off1: db '], al', 10, 0\n"
		".exit:\n"
	};
}

func stmt_try_array_store(p, loop_starts, loop_ends, ret_target) {
	// Try parse/emit: IDENT '[' expr ']' '=' expr ';' as a local qword array element store.
	// If the form doesn't match (not followed by '='), restores lexer+emit state and returns 0.
	// Returns: rax = 1 if consumed, else 0.
	// Convention: rdi=Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 64\n" // [0]=p [8]=start_ptr [16]=start_line [24]=name_ptr [32]=name_len [40]=saved_emit_len [48]=off

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"
		// snapshot start token and emit_len
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"   // tok_ptr
		"mov rax, [r12+32]\n" "mov [rsp+16], rax\n"  // tok_line
		"mov rax, [rel emit_len]\n" "mov [rsp+40], rax\n"

		// must start with IDENT
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .id_ok\n" "jmp .fail\n"
		".id_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+24], rax\n" // name_ptr
		"mov rax, [r12+24]\n" "mov [rsp+32], rax\n" // name_len

		// consume IDENT
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '['
		"mov rax, [r12+8]\n" "cmp rax, 34\n" "je .lb_ok\n" "jmp .fail\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '['
		"mov r12, [rsp+0]\n"
		// parse index expr (leaves value on stack)
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"
		// expect ']'
		"mov rax, [r12+8]\n" "cmp rax, 35\n" "je .rb_ok\n" "call die_stmt_expected_rbrack\n"
		".rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ']'
		"mov r12, [rsp+0]\n"
		// require '=' to be an assignment; otherwise rollback
		"mov rax, [r12+8]\n" "cmp rax, 50\n" "je .eq_ok\n" "jmp .fail\n"
		".eq_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '='
		"mov r12, [rsp+0]\n"
		// rhs expr
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"
		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .semi_ok\n" "call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'

		// resolve array base offset (local)
		"mov rdi, [rsp+24]\n" // name_ptr
		"mov rsi, [rsp+32]\n" // name_len
		"call locals_get\n"      // rax=off, rdx=found
		"test rdx, rdx\n" "jnz .off_ok\n" "call die_expr_undefined_ident\n"
		".off_ok:\n"
		"mov [rsp+48], rax\n"

		// emit store: stack [idx, rhs]
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n" // rhs
		"lea rdi, [rel .s_pop_r10]\n" "call emit_cstr\n" // idx
		"lea rdi, [rel .s_lea_r11_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+48]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_lea_r11_idx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_store64]\n" "call emit_cstr\n"

		"mov rax, 1\n"
		"jmp .done\n"

		".fail:\n"
		// rollback emitted code
		"mov rax, [rsp+40]\n"
		"mov [rel emit_len], rax\n"
		// restore lexer to statement start token and re-prime
		"mov r12, [rsp+0]\n"
		"mov r13, [r12+0]\n"  // lex*
		"mov rax, [rsp+8]\n"  // start_ptr
		"mov [r13+0], rax\n"
		"mov rax, [rsp+16]\n" // start_line
		"mov [r13+16], rax\n"
		"mov rdi, r12\n" "call parser_next\n"
		"xor eax, eax\n"

		".done:\n"
		"add rsp, 64\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop_rax:       db '  pop rax', 10, 0\n"
		".s_pop_r10:       db '  pop r10', 10, 0\n"
		".s_lea_r11_rbp0:  db '  lea r11, [rbp-', 0\n"
		".s_rbr:           db ']', 10, 0\n"
		".s_lea_r11_idx:   db '  lea r11, [r11+r10*8]', 10, 0\n"
		".s_store64:       db '  mov qword [r11], rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_if(p, loop_starts, loop_ends, ret_target) {
	// if '(' cond ')' '{' stmt* '}' [else ( if ... | '{' stmt* '}' )]
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 64\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=else [40]=end

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 13\n" // TOK_KW_IF
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"

		// consume 'if'
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '('
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .lp_ok\n"
		"call die_stmt_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// else_label = label_next(), end_label = label_next()
		"call label_next\n"
		"mov [rsp+32], rax\n"
		"call label_next\n"
		"mov [rsp+40], rax\n"
		"mov r12, [rsp+0]\n" // label_next clobbers r12-r15

		// cond false => else_label
		"mov rdi, r12\n"
		"mov rsi, [rsp+32]\n"
		"call parse_cond_emit_jfalse\n"

		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rp_ok\n"
		"call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .lb_ok\n"
		"call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// then block stmts until '}'
		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"

		// expect '}'
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .rb_ok\n"
		"call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// if no else: emit else_label: and finish
		"mov rax, [r12+8]\n"
		"cmp rax, 14\n" // TOK_KW_ELSE
		"je .has_else\n"
		"mov rdi, [rsp+32]\n"
		"call emit_label_def\n"
		"jmp .done\n"

		".has_else:\n"
		// jump over else body
		"mov rdi, [rsp+40]\n"
		"call emit_jmp\n"
		// else_label:
		"mov rdi, [rsp+32]\n"
		"call emit_label_def\n"

		// consume 'else'
		"mov rdi, r12\n"
		"call parser_next\n"

		// else-if
		"mov rax, [r12+8]\n"
		"cmp rax, 13\n" // TOK_KW_IF
		"jne .else_block\n"
		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_if\n"
		"jmp .emit_end\n"

		".else_block:\n"
		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .elb_ok\n"
		"call die_stmt_expected_lbrace\n"
		".elb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"

		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .erb_ok\n"
		"call die_stmt_expected_rbrace\n"
		".erb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		".emit_end:\n"
		"mov rdi, [rsp+40]\n"
		"call emit_label_def\n"

		".done:\n"
		"add rsp, 64\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_while(p, loop_starts, loop_ends, ret_target) {
	// while '(' cond ')' '{' stmt* '}'
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 80\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=start [40]=end

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 15\n" // TOK_KW_WHILE
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"

		// consume 'while'
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '('
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .lp_ok\n"
		"call die_stmt_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// start/end labels
		"call label_next\n"
		"mov [rsp+32], rax\n"
		"call label_next\n"
		"mov [rsp+40], rax\n"
		"mov r12, [rsp+0]\n" // label_next clobbers r12-r15

		// start:
		"mov rdi, [rsp+32]\n"
		"call emit_label_def\n"

		// cond false => end
		"mov rdi, r12\n"
		"mov rsi, [rsp+40]\n"
		"call parse_cond_emit_jfalse\n"

		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rp_ok\n"
		"call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '{'
		"mov rax, [r12+8]\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .lb_ok\n"
		"call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// push start/end onto stacks
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+32]\n"
		"call vec_push\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, [rsp+40]\n"
		"call vec_push\n"
		"mov r12, [rsp+0]\n" // be conservative about clobbers

		// body stmts until '}'
		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"mov r8, 33\n" // TOK_RBRACE
		"call stmt_parse_list\n"

		// expect '}'
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .rb_ok\n"
		"call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// pop stacks (len--)
		"mov r13, [rsp+8]\n"  // starts
		"mov r14, [rsp+16]\n" // ends
		"mov rax, [r13+8]\n"  // len
		"dec rax\n"
		"mov [r13+8], rax\n"
		"mov rax, [r14+8]\n"
		"dec rax\n"
		"mov [r14+8], rax\n"

		// jmp start
		"mov rdi, [rsp+32]\n"
		"call emit_jmp\n"

		// end:
		"mov rdi, [rsp+40]\n"
		"call emit_label_def\n"

		"add rsp, 80\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_for(p, loop_starts, loop_ends, ret_target) {
	// for '(' init? ';' cond? ';' post? ')' '{' stmt* '}'
	// for/foreach are encoded as IDENT text (no dedicated tokens).
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 96\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=cond [40]=post [48]=body [56]=end

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"

		// consume 'for' (IDENT)
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// expect '('
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .lp_ok\n"
		"call die_stmt_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// init clause (runs once)
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // ';' => empty init
		"jne .init_nonempty\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"jmp .after_init\n"
		".init_nonempty:\n"
		"cmp rax, 11\n" // TOK_KW_VAR
		"jne .init_not_var\n"
		"mov rdi, r12\n" "call stmt_var_decl\n"
		"mov r12, [rsp+0]\n"
		"jmp .after_init\n"
		".init_not_var:\n"
		// assignment init if IDENT '='
		"cmp rax, 1\n" // IDENT
		"jne .init_expr\n"
		"mov rdi, r12\n" "call parser_peek_kind\n"
		"cmp rax, 50\n" // '='
		"jne .init_expr\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_assign\n"
		"mov r12, [rsp+0]\n"
		"jmp .after_init\n"
		".init_expr:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_expr\n"
		"mov r12, [rsp+0]\n"
		".after_init:\n"

		// labels (cond/post/body/end)
		"call label_next\n" "mov [rsp+32], rax\n"
		"call label_next\n" "mov [rsp+40], rax\n"
		"call label_next\n" "mov [rsp+48], rax\n"
		"call label_next\n" "mov [rsp+56], rax\n"
		"mov r12, [rsp+0]\n" // label_next clobbers

		// cond:
		"mov rdi, [rsp+32]\n" "call emit_label_def\n"

		// cond clause
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // ';' => empty cond (true)
		"jne .cond_nonempty\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov rdi, [rsp+48]\n" "call emit_jmp\n" // jmp body
		"jmp .after_cond\n"
		".cond_nonempty:\n"
		"mov rdi, r12\n" "mov rsi, [rsp+56]\n" "call parse_cond_emit_jfalse\n"
		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .cond_semi_ok\n" "call die_stmt_expected_semi\n"
		".cond_semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov rdi, [rsp+48]\n" "call emit_jmp\n" // jmp body
		"mov r12, [rsp+0]\n"
		".after_cond:\n"

		// post:
		"mov rdi, [rsp+40]\n" "call emit_label_def\n"
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // ')' => empty post
		"je .post_done\n"
		// assignment post if IDENT '=' else expr
		"cmp rax, 1\n" "jne .post_expr\n"
		"mov rdi, r12\n" "call parser_peek_kind\n"
		"cmp rax, 50\n" "jne .post_expr\n"
		"mov rdi, r12\n" "call stmt_assign_no_semi\n"
		"mov r12, [rsp+0]\n"
		"jmp .post_done\n"
		".post_expr:\n"
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		".post_done:\n"
		"mov rdi, [rsp+32]\n" "call emit_jmp\n" // jmp cond
		"mov r12, [rsp+0]\n"

		// expect ')'
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .rp_ok\n" "call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// expect '{'
		"mov rax, [r12+8]\n" "cmp rax, 32\n" "je .lb_ok\n" "call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// body:
		"mov rdi, [rsp+48]\n" "call emit_label_def\n"

		// push continue/break targets
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+40]\n" "call vec_push\n" // continue => post
		"mov rdi, [rsp+16]\n" "mov rsi, [rsp+56]\n" "call vec_push\n" // break => end
		"mov r12, [rsp+0]\n"

		// body stmts until '}'
		"mov rdi, r12\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "mov r8, 33\n" "call stmt_parse_list\n"

		// expect '}'
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .rb_ok\n" "call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// pop loop stacks (len--)
		"mov r13, [rsp+8]\n"  // starts
		"mov r14, [rsp+16]\n" // ends
		"mov rax, [r13+8]\n"  // len
		"dec rax\n" "mov [r13+8], rax\n"
		"mov rax, [r14+8]\n" "dec rax\n" "mov [r14+8], rax\n"

		// jmp post
		"mov rdi, [rsp+40]\n" "call emit_jmp\n"

		// end:
		"mov rdi, [rsp+56]\n" "call emit_label_def\n"

		"add rsp, 96\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_foreach(p, loop_starts, loop_ends, ret_target) {
	// foreach '(' IDENT 'in' expr ')' '{' stmt* '}'
	// MVP: expr evaluates to Slice*; iterates bytes and assigns into loop variable.
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 144\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=x_ptr [40]=x_len [48]=x_off [56]=sl_off [64]=ptr_off [72]=len_off [80]=i_off [88]=cond [96]=post [104]=body [112]=end

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"

		// consume 'foreach' (IDENT)
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .kw_ok\n" "call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// expect '('
		"mov rax, [r12+8]\n" "cmp rax, 30\n" "je .lp_ok\n" "call die_stmt_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect IDENT (loop var)
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .x_ok\n" "call die_stmt_expected_ident\n"
		".x_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+32], rax\n" // x_ptr
		"mov rax, [r12+24]\n" "mov [rsp+40], rax\n" // x_len
		"mov rdi, r12\n" "call parser_next\n" // consume x ident
		"mov r12, [rsp+0]\n"

		// expect IDENT 'in'
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .in_kind_ok\n" "call die_stmt_expected_kw_in\n"
		".in_kind_ok:\n"
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n" "lea rdx, [rel .s_in]\n" "mov rcx, 2\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .in_ok\n" "call die_stmt_expected_kw_in\n"
		".in_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume 'in'
		"mov r12, [rsp+0]\n"

		// resolve loop var offset (must exist)
		"mov rdi, [rsp+32]\n" "mov rsi, [rsp+40]\n" "call locals_get\n" // rax=off, rdx=found
		"test rdx, rdx\n" "jnz .x_have\n" "call die_stmt_undefined_ident\n"
		".x_have:\n"
		"mov [rsp+48], rax\n" // x_off
		"mov r12, [rsp+0]\n"

		// allocate temp locals: $fe_sl/$fe_ptr/$fe_len/$fe_i
		"lea rdi, [rel .s_fe_sl]\n" "mov rsi, 6\n" "call locals_alloc\n" "mov [rsp+56], rax\n"
		"lea rdi, [rel .s_fe_ptr]\n" "mov rsi, 7\n" "call locals_alloc\n" "mov [rsp+64], rax\n"
		"lea rdi, [rel .s_fe_len]\n" "mov rsi, 7\n" "call locals_alloc\n" "mov [rsp+72], rax\n"
		"lea rdi, [rel .s_fe_i]\n"  "mov rsi, 5\n" "call locals_alloc\n" "mov [rsp+80], rax\n"
		"mov r12, [rsp+0]\n"

		// init: eval expr (Slice*) and store to $fe_sl
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_mov_store0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+56]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_store1]\n" "call emit_cstr\n"

		// Inline Slice layout loads: fe_sl -> (ptr,len)
		"lea rdi, [rel .s_load_sl0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+56]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_sl1]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_load_slice_ptr]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_load_slice_len]\n" "call emit_cstr\n"
		// store ptr (rax)
		"lea rdi, [rel .s_mov_store0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+64]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_store1]\n" "call emit_cstr\n"
		// store len (rdx)
		"lea rdi, [rel .s_mov_store_rdx0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+72]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_store_rdx1]\n" "call emit_cstr\n"

		// i = 0
		"lea rdi, [rel .s_mov_store_imm0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+80]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_store_imm1]\n" "call emit_cstr\n"

		// expect ')'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .rp_ok\n" "call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// labels
		"call label_next\n" "mov [rsp+88], rax\n"
		"call label_next\n" "mov [rsp+96], rax\n"
		"call label_next\n" "mov [rsp+104], rax\n"
		"call label_next\n" "mov [rsp+112], rax\n"
		"mov r12, [rsp+0]\n"

		// cond:
		"mov rdi, [rsp+88]\n" "call emit_label_def\n"
		// load i -> r10
		"lea rdi, [rel .s_load_i0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+80]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_i1]\n" "call emit_cstr\n"
		// load len -> r11
		"lea rdi, [rel .s_load_len0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+72]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_len1]\n" "call emit_cstr\n"
		// cmp r10, r11; jge end
		"lea rdi, [rel .s_cmp_i_len]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_jge]\n" "call emit_cstr\n"
		"mov rdi, [rsp+112]\n" "call slice_parts\n" "mov rdi, rax\n" "mov rsi, rdx\n" "call emit_str\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"
		// jmp body
		"mov rdi, [rsp+104]\n" "call emit_jmp\n"

		// post:
		"mov rdi, [rsp+96]\n" "call emit_label_def\n"
		// i++
		"lea rdi, [rel .s_inc_i0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+80]\n" "call emit_u64\n"
		"lea rdi, [rel .s_inc_i1]\n" "call emit_cstr\n"
		"mov rdi, [rsp+88]\n" "call emit_jmp\n" // jmp cond

		// expect '{'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 32\n" "je .lb_ok\n" "call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// body:
		"mov rdi, [rsp+104]\n" "call emit_label_def\n"
		// load current byte into rax and store into loop var
		"lea rdi, [rel .s_load_ptr0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+64]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_ptr1]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_load_i0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+80]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_i1]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_load_byte]\n" "call emit_cstr\n"
		// store into x_off
		"lea rdi, [rel .s_mov_store0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+48]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov_store1]\n" "call emit_cstr\n"

		// push continue/break targets
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+96]\n" "call vec_push\n" // continue => post
		"mov rdi, [rsp+16]\n" "mov rsi, [rsp+112]\n" "call vec_push\n" // break => end
		"mov r12, [rsp+0]\n"

		// body stmts until '}'
		"mov rdi, r12\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "mov r8, 33\n" "call stmt_parse_list\n"

		// expect '}'
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .rb_ok\n" "call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"

		// pop loop stacks (len--)
		"mov r13, [rsp+8]\n"  // starts
		"mov r14, [rsp+16]\n" // ends
		"mov rax, [r13+8]\n"  // len
		"dec rax\n" "mov [r13+8], rax\n"
		"mov rax, [r14+8]\n" "dec rax\n" "mov [r14+8], rax\n"

		// jmp post
		"mov rdi, [rsp+96]\n" "call emit_jmp\n"

		// end:
		"mov rdi, [rsp+112]\n" "call emit_label_def\n"

		"add rsp, 144\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_in: db 'in', 0\n"
		".s_fe_sl:  db '$fe_sl', 0\n"
		".s_fe_ptr: db '$fe_ptr', 0\n"
		".s_fe_len: db '$fe_len', 0\n"
		".s_fe_i:   db '$fe_i', 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_mov_store0: db '  mov qword [rbp-', 0\n"
		".s_mov_store1: db '], rax', 10, 0\n"
		".s_mov_store_rdx0: db '  mov qword [rbp-', 0\n"
		".s_mov_store_rdx1: db '], rdx', 10, 0\n"
		".s_mov_store_imm0: db '  mov qword [rbp-', 0\n"
		".s_mov_store_imm1: db '], 0', 10, 0\n"
		".s_load_sl0: db '  mov r11, qword [rbp-', 0\n"
		".s_load_sl1: db ']', 10, 0\n"
		".s_load_slice_ptr: db '  mov rax, qword [r11]', 10, 0\n"
		".s_load_slice_len: db '  mov rdx, qword [r11+8]', 10, 0\n"
		".s_load_i0: db '  mov r10, qword [rbp-', 0\n"
		".s_load_i1: db ']', 10, 0\n"
		".s_load_len0: db '  mov r11, qword [rbp-', 0\n"
		".s_load_len1: db ']', 10, 0\n"
		".s_cmp_i_len: db '  cmp r10, r11', 10, 0\n"
		".s_jge: db '  jge ', 0\n"
		".s_nl: db 10, 0\n"
		".s_inc_i0: db '  inc qword [rbp-', 0\n"
		".s_inc_i1: db ']', 10, 0\n"
		".s_load_ptr0: db '  mov r11, qword [rbp-', 0\n"
		".s_load_ptr1: db ']', 10, 0\n"
		".s_load_byte: db '  movzx eax, byte [r11+r10]', 10, 0\n"
		".exit:\n"
	};
}

func stmt_break(p, loop_starts, loop_ends, ret_target) {
	// break [(num)] ';'
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 48\n" // [0]=p [8]=ends [16]=num

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rdx\n" // ends
		"mov qword [rsp+16], 1\n" // default num=1

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 16\n" // TOK_KW_BREAK
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		// consume 'break'
		"mov rdi, r12\n"
		"call parser_next\n"

		// optional (num)
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"jne .after_num\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 2\n" // TOK_INT
		"je .int_ok\n"
		"call die_stmt_unexpected_token\n"
		".int_ok:\n"
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"call atoi_u64_or_panic\n"
		"mov [rsp+16], rax\n" // num
		"mov r12, [rsp+0]\n" // atoi helpers may clobber r12-r15
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rp_ok\n"
		"call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		".after_num:\n"
		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// depth = vec_len(ends)
		"mov rdi, [rsp+8]\n"
		"call vec_len\n"
		"mov r13, rax\n" // depth
		"test r13, r13\n"
		"jnz .depth_ok\n"
		"call die_stmt_break_outside_loop\n"
		".depth_ok:\n"

		"mov r14, [rsp+16]\n" // num
		"cmp r14, 1\n"
		"jae .num_ok\n"
		"call die_stmt_bad_loop_depth\n"
		".num_ok:\n"
		"cmp r13, r14\n"
		"jae .idx_ok\n"
		"call die_stmt_bad_loop_depth\n"
		".idx_ok:\n"
		// idx = depth - num
		"mov rbx, r13\n"
		"sub rbx, r14\n"
		// target = vec_get(ends, idx)
		"mov rdi, [rsp+8]\n"
		"mov rsi, rbx\n"
		"call vec_get\n"
		"mov rdi, rax\n" // Slice*
		"call emit_jmp\n"

		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_continue(p, loop_starts, loop_ends, ret_target) {
	// continue [(num)] ';'
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 48\n" // [0]=p [8]=starts [16]=num

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n" // starts
		"mov qword [rsp+16], 1\n" // default num=1

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 17\n" // TOK_KW_CONTINUE
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		// consume 'continue'
		"mov rdi, r12\n"
		"call parser_next\n"

		// optional (num)
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"jne .after_num\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 2\n" // TOK_INT
		"je .int_ok\n"
		"call die_stmt_unexpected_token\n"
		".int_ok:\n"
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"call atoi_u64_or_panic\n"
		"mov [rsp+16], rax\n" // num
		"mov r12, [rsp+0]\n" // atoi helpers may clobber r12-r15
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rp_ok\n"
		"call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		".after_num:\n"
		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// depth = vec_len(starts)
		"mov rdi, [rsp+8]\n"
		"call vec_len\n"
		"mov r13, rax\n" // depth
		"test r13, r13\n"
		"jnz .depth_ok\n"
		"call die_stmt_continue_outside_loop\n"
		".depth_ok:\n"

		"mov r14, [rsp+16]\n" // num
		"cmp r14, 1\n"
		"jae .num_ok\n"
		"call die_stmt_bad_loop_depth\n"
		".num_ok:\n"
		"cmp r13, r14\n"
		"jae .idx_ok\n"
		"call die_stmt_bad_loop_depth\n"
		".idx_ok:\n"
		// idx = depth - num
		"mov rbx, r13\n"
		"sub rbx, r14\n"
		// target = vec_get(starts, idx)
		"mov rdi, [rsp+8]\n"
		"mov rsi, rbx\n"
		"call vec_get\n"
		// For switch, we push a NULL start label; continue is invalid there.
		"test rax, rax\n"
		"jnz .cont_ok\n"
		"call die_stmt_continue_in_switch\n"
		".cont_ok:\n"
		"mov rdi, rax\n" // Slice*
		"call emit_jmp\n"

		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func stmt_switch(p, loop_starts, loop_ends, ret_target) {
	// switch (expr) { case CONST: stmt* break; ... default: stmt* }
	// Implemented via a dispatch label + compare chain.
	// No-fallthrough: each case body ends with an implicit jump to end.
	// Convention:
	// - rdi = Parser*
	// - rsi = loop_starts
	// - rdx = loop_ends
	// - rcx = ret_target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 128\n" // [0]=p [8]=starts [16]=ends [24]=ret [32]=off [40]=dispatch [48]=end [56]=cases_vec [64]=default_lab [72]=saved_st_len [80]=saved_en_len [88]=tmp
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov r12, rdi\n"

		// consume 'switch' ident
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '('
		"mov rax, [r12+8]\n" "cmp rax, 30\n" "je .lp_ok\n" "call die_stmt_expected_lparen\n"
		".lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expr -> stack
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		// allocate temp local slot for switch value (fresh slot, included in scan frame)
		"lea rdi, [rel .s_swtmp]\n" "mov rsi, 5\n" "call locals_alloc\n"
		"mov [rsp+32], rax\n" // off
		// pop rax; mov [rbp-off], rax
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_mov0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		// expect ')'
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .rp_ok\n" "call die_stmt_expected_rparen\n"
		".rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '{'
		"mov rax, [r12+8]\n" "cmp rax, 32\n" "je .lb_ok\n" "call die_stmt_expected_lbrace\n"
		".lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// dispatch_label, end_label
		"call label_next\n" "mov [rsp+40], rax\n"
		"call label_next\n" "mov [rsp+48], rax\n"
		"mov qword [rsp+64], 0\n" // default_lab = 0
		// cases_vec
		"mov rdi, 8\n" "call vec_new\n" "mov [rsp+56], rax\n"
		"mov r12, [rsp+0]\n"

		// save loop stack lens and push switch break/continue targets
		"mov rdi, [rsp+8]\n" "call vec_len\n" "mov [rsp+72], rax\n"
		"mov rdi, [rsp+16]\n" "call vec_len\n" "mov [rsp+80], rax\n"
		// loop_starts push NULL
		"mov rdi, [rsp+8]\n" "xor rsi, rsi\n" "call vec_push\n"
		// loop_ends push end_label
		"mov rdi, [rsp+16]\n" "mov rsi, [rsp+48]\n" "call vec_push\n"
		"mov r12, [rsp+0]\n"

		// jump to dispatch to skip bodies
		"mov rdi, [rsp+40]\n" "call emit_jmp\n"

		// parse cases/default until '}'
		".case_loop:\n"
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" "je .after_cases\n" // '}'
		"cmp rax, 0\n" "jne .need_ident\n" "call die_stmt_unexpected_eof\n"
		".need_ident:\n"
		"cmp rax, 1\n" "je .kw_check\n" "call die_stmt_unexpected_token\n"
		".kw_check:\n"
		// case?
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n"
		"lea rdx, [rel .s_case]\n" "mov rcx, 4\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .do_case\n"
		// default?
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n"
		"lea rdx, [rel .s_default]\n" "mov rcx, 7\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .do_default\n"
		"call die_stmt_unexpected_token\n"

		".do_case:\n"
		// consume 'case'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// value = const_expr_eval(p, ':')
		"mov rdi, r12\n" "mov rsi, 39\n" "call const_expr_eval\n"
		"mov r14, rax\n" // case value
		"mov [rsp+88], r14\n" // preserve across helper calls
		"mov r12, [rsp+0]\n"
		// expect ':'
		"mov rax, [r12+8]\n" "cmp rax, 39\n" "je .case_col_ok\n" "call die_stmt_unexpected_token\n"
		".case_col_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		// label
		"call label_next\n" "mov r13, rax\n"
		// push CaseEntry{value,label}
		"mov rdi, 16\n" "call heap_alloc\n" "mov r15, rax\n"
		"mov r14, [rsp+88]\n" // restore case value
		"mov [r15+0], r14\n" "mov [r15+8], r13\n"
		"mov rdi, [rsp+56]\n" "mov rsi, r15\n" "call vec_push\n"
		// emit label for body
		"mov rdi, r13\n" "call emit_label_def\n"
		"mov r12, [rsp+0]\n"
		"jmp .case_body\n"

		".do_default:\n"
		// consume 'default'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ':'
		"mov rax, [r12+8]\n" "cmp rax, 39\n" "je .def_col_ok\n" "call die_stmt_unexpected_token\n"
		".def_col_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ':'
		"mov r12, [rsp+0]\n"
		// create label if first default
		"mov rax, [rsp+64]\n" "test rax, rax\n" "jnz .have_def_lab\n"
		"call label_next\n" "mov [rsp+64], rax\n"
		".have_def_lab:\n"
		"mov rdi, [rsp+64]\n" "call emit_label_def\n"
		"mov r12, [rsp+0]\n"

		".case_body:\n"
		// parse statements until next 'case'/'default'/'}'
		".body_loop:\n"
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 33\n" "je .body_done\n" // '}'
		"cmp rax, 1\n" "jne .body_dispatch\n"
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n"
		"lea rdx, [rel .s_case]\n" "mov rcx, 4\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .body_done\n"
		"mov rdi, [r12+16]\n" "mov rsi, [r12+24]\n"
		"lea rdx, [rel .s_default]\n" "mov rcx, 7\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .body_done\n"
		".body_dispatch:\n"
		// One-statement dispatch (mirrors stmt_parse_list)
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 13\n" "je .bd_if\n"
		"cmp rax, 15\n" "je .bd_while\n"
		"cmp rax, 16\n" "je .bd_break\n"
		"cmp rax, 17\n" "je .bd_continue\n"
		"cmp rax, 18\n" "je .bd_return\n"
		"cmp rax, 12\n" "je .bd_alias\n"
		"cmp rax, 19\n" "je .bd_asm\n"
		"cmp rax, 11\n" "je .bd_var\n"
		"cmp rax, 32\n" "je .bd_block\n"
		// '*' : deref store or expr-stmt
		"cmp rax, 42\n" "jne .bd_not_deref\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_try_deref_store\n"
		"test rax, rax\n" "jnz .body_loop\n"
		"jmp .bd_expr\n"
		".bd_not_deref:\n"
		"cmp rax, 1\n" "jne .bd_expr\n"
		// allow nested switch
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_try_switch\n"
		"test rax, rax\n" "jnz .body_loop\n"
		"mov rdi, [rsp+0]\n" "call parser_peek_kind\n"
		"cmp rax, 50\n" "je .bd_assign\n"
		"cmp rax, 34\n" "je .bd_ptr_store_maybe\n"
		"jmp .bd_expr\n"
		".bd_ptr_store_maybe:\n"
		"mov rdi, [rsp+0]\n" "call stmt_ptr_width_if_ptr_ident\n" "test rax, rax\n" "jz .bd_array_store_maybe\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_ptr_store\n" "jmp .body_loop\n"
		".bd_array_store_maybe:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_try_array_store\n"
		"test rax, rax\n" "jnz .body_loop\n"
		"jmp .bd_expr\n"
		".bd_assign:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_assign\n" "jmp .body_loop\n"
		".bd_asm:\n"
		"mov rdi, [rsp+0]\n" "call stmt_asm_raw\n" "jmp .body_loop\n"
		".bd_var:\n"
		"mov rdi, [rsp+0]\n" "call stmt_var_decl\n" "jmp .body_loop\n"
		".bd_block:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_block\n" "jmp .body_loop\n"
		".bd_expr:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_expr\n" "jmp .body_loop\n"
		".bd_if:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_if\n" "jmp .body_loop\n"
		".bd_while:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_while\n" "jmp .body_loop\n"
		".bd_break:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_break\n" "jmp .body_loop\n"
		".bd_continue:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_continue\n" "jmp .body_loop\n"
		".bd_return:\n"
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n" "call stmt_return\n" "jmp .body_loop\n"
		".bd_alias:\n"
		"mov rdi, [rsp+0]\n" "call stmt_alias\n" "jmp .body_loop\n"

		".body_done:\n"
		// implicit no-fallthrough
		"mov rdi, [rsp+48]\n" "call emit_jmp\n"
		"jmp .case_loop\n"

		".after_cases:\n"
		// expect '}'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 33\n" "je .rb_ok\n" "call die_stmt_expected_rbrace\n"
		".rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '}'
		"mov r12, [rsp+0]\n"

		// restore loop stack lens
		"mov r13, [rsp+8]\n" "mov rax, [rsp+72]\n" "mov [r13+8], rax\n"
		"mov r13, [rsp+16]\n" "mov rax, [rsp+80]\n" "mov [r13+8], rax\n"

		// emit dispatch at end
		"mov rdi, [rsp+40]\n" "call emit_label_def\n"
		// mov rax, [rbp-off]
		"lea rdi, [rel .s_load_sw0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+32]\n" "call emit_u64\n"
		"lea rdi, [rel .s_load_sw1]\n" "call emit_cstr\n"
		// for each case: cmp/je
		"mov rdi, [rsp+56]\n" "call vec_len\n" "mov r14, rax\n" "xor ebx, ebx\n"
		".cmp_loop:\n"
		"cmp rbx, r14\n" "jae .cmp_done\n"
		"mov rdi, [rsp+56]\n" "mov rsi, rbx\n" "call vec_get\n" // CaseEntry*
		"mov r15, rax\n"
		"lea rdi, [rel .s_cmp0]\n" "call emit_cstr\n"
		"mov rdi, [r15+0]\n" "call emit_u64\n"
		"lea rdi, [rel .s_cmp1]\n" "call emit_cstr\n"
		"mov rdi, [r15+8]\n" "call slice_parts\n" // rax=ptr rdx=len
		"mov rdi, rax\n" "mov rsi, rdx\n" "call emit_str\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"
		"inc rbx\n" "jmp .cmp_loop\n"
		".cmp_done:\n"
		// jmp default or end
		"mov rax, [rsp+64]\n" "test rax, rax\n" "jz .jmp_end\n"
		"mov rdi, rax\n" "call emit_jmp\n" "jmp .after_jmp\n"
		".jmp_end:\n"
		"mov rdi, [rsp+48]\n" "call emit_jmp\n"
		".after_jmp:\n"
		// end label
		"mov rdi, [rsp+48]\n" "call emit_label_def\n"

		"add rsp, 128\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_switch:   db 'switch', 0\n"
		".s_case:     db 'case', 0\n"
		".s_default:  db 'default', 0\n"
		".s_swtmp:    db '$sw0', 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_mov0:     db '  mov qword [rbp-', 0\n"
		".s_mov1:     db '], rax', 10, 0\n"
		".s_load_sw0: db '  mov rax, qword [rbp-', 0\n"
		".s_load_sw1: db ']', 10, 0\n"
		".s_cmp0:     db '  cmp rax, ', 0\n"
		".s_cmp1:     db 10, '  je ', 0\n"
		".s_nl:       db 10, 0\n"
		".exit:\n"
	};
}

func stmt_return(p, loop_starts, loop_ends, ret_target) {
	// return [expr] ';'
	// Convention:
	// - rdi = Parser*
	// - rsi = Vec* loop_starts
	// - rdx = Vec* loop_ends
	// - rcx = Slice* ret_target
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 32\n" // [0]=p [8]=ret

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rcx\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 18\n" // TOK_KW_RETURN
		"je .kw_ok\n"
		"call die_stmt_unexpected_token\n"
		".kw_ok:\n"
		// consume 'return'
		"mov rdi, r12\n"
		"call parser_next\n"

		// if next is ';' => no value
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .no_expr\n"

		// expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"

		".no_expr:\n"
		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		// jmp ret
		"mov rdi, [rsp+8]\n"
		"call emit_jmp\n"

		"add rsp, 32\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_asm_raw(p) {
	// asm { ... }
	// Lexer produces a single raw token (kind=19) spanning the entire `asm { ... }` block.
	// Emits the bytes between '{' and the final '}' verbatim, and ensures a trailing newline.
	// Convention:
	// - rdi = Parser*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"

		"mov r12, rdi\n" // p
		"mov rax, [r12+8]\n" // kind
		"cmp rax, 19\n" // TOK_ASM_RAW
		"je .ok\n"
		"call die_stmt_unexpected_token\n"
		".ok:\n"
		"mov rbx, [r12+16]\n" // ptr
		"mov rcx, [r12+24]\n" // len

		// find first '{'
		"xor r13, r13\n" // i
		".find_lbrace:\n"
		"cmp r13, rcx\n"
		"jae .bad\n"
		"mov al, [rbx+r13]\n"
		"cmp al, '{'\n"
		"je .found_lbrace\n"
		"inc r13\n"
		"jmp .find_lbrace\n"
		".found_lbrace:\n"
		// expect final '}'
		"test rcx, rcx\n"
		"jz .bad\n"
		"mov r9, rcx\n"
		"dec r9\n"
		"mov al, [rbx+r9]\n"
		"cmp al, '}'\n"
		"jne .bad\n"

		// inner_ptr = ptr + i + 1
		"lea r13, [rbx+r13+1]\n" // inner_ptr
		// inner_len = (ptr+len-1) - inner_ptr
		"lea r14, [rbx+rcx]\n" // end_one_past
		"sub r14, r13\n"
		"dec r14\n"              // exclude final '}'
		"js .bad\n"

		"mov rdi, r13\n"
		"mov rsi, r14\n"
		"call emit_str\n"

		// ensure newline after raw asm if not already present
		"test r14, r14\n"
		"jz .nl_done\n"
		"mov r9, r14\n"
		"dec r9\n"
		"mov al, [r13+r9]\n"
		"cmp al, 10\n"
		"je .nl_done\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		".nl_done:\n"

		// consume raw token
		"mov rdi, r12\n"
		"call parser_next\n"

		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".bad:\n"
		"lea rdi, [rel .s_bad_asm]\n"
		"call die\n"
		"jmp near .exit\n"

		".s_nl: db 10, 0\n"
		".s_bad_asm: db 'stmt: bad asm { } block', 0\n"
		".exit:\n"
	};
}

func stmt_expr(p, loop_starts, loop_ends, ret_target) {
	// expr ';' (discard result)
	// Convention:
	// - rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .semi_ok\n"
		"call die_stmt_expected_semi\n"
		".semi_ok:\n"
		// consume ';'
		"mov rdi, r12\n"
		"call parser_next\n"

		// discard expr result
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"

		"pop r12\n"
		"jmp near .exit\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}
