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

func die_stmt_bad_loop_depth() {
	die("stmt: bad loop depth");
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
		"jmp .exit\n"
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
		"jmp .exit\n"
		".s_jmp: db '  jmp ', 0\n"
		".s_nl:  db 10, 0\n"
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

		// IDENT: assignment or expr-stmt
		"cmp rax, 1\n" // TOK_IDENT
		"jne .do_expr\n"
		"mov rdi, [rsp+0]\n"
		"call parser_peek_kind\n" // rax=next kind
		"cmp rax, 50\n" // TOK_EQ
		"je .do_assign\n"
		"cmp rax, 34\n" // TOK_LBRACK
		"je .do_ptr_store_maybe\n"
		"jmp .do_expr\n"

		".do_ptr_store_maybe:\n"
		"mov rdi, [rsp+0]\n"
		"call stmt_ptr_width_if_ptr_ident\n" // rax=0|8|64
		"test rax, rax\n"
		"jz .do_expr\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"mov rcx, [rsp+24]\n"
		"call stmt_ptr_store\n"
		"jmp .loop\n"

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
		"jmp .exit\n"
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
		"jmp .exit\n"
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
		"sub rsp, 48\n" // [0]=p [8]=name_ptr [16]=name_len [24]=is_alias [32]=reg_or_off

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

		// if name is an alias, store into reg; else if const => error; else store into stack local.
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call aliases_get\n" // rax=reg_id, rdx=found
		"test rdx, rdx\n"
		"jz .not_alias\n"
		"mov qword [rsp+24], 1\n" // is_alias
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
		"mov qword [rsp+24], 0\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call locals_get_or_alloc\n" // rax=off, rdx=is_new
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

		// store: pop rax; mov (alias reg or [rbp-off]), rax
		"lea rdi, [rel .s_pop]\n"
		"call emit_cstr\n"
		"mov rax, [rsp+24]\n"
		"test rax, rax\n"
		"jnz .store_alias\n"
		"lea rdi, [rel .s_mov0]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+32]\n" // off
		"call emit_u64\n"
		"lea rdi, [rel .s_mov1]\n"
		"call emit_cstr\n"
		"jmp .store_done\n"
		".store_alias:\n"
		"mov rdi, [rsp+32]\n" // reg_id
		"call emit_mov_reg_from_rax\n"
		".store_done:\n"

		"add rsp, 48\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp .exit\n"
		".s_pop:  db '  pop rax', 10, 0\n"
		".s_mov0: db '  mov qword [rbp-', 0\n"
		".s_mov1: db '], rax', 10, 0\n"
		".exit:\n"
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
		"jmp .exit\n"
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
		"jmp .exit\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_store8:   db '  mov byte [rbx], al', 10, 0\n"
		".s_store64:  db '  mov qword [rbx], rax', 10, 0\n"
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
		"jmp .exit\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}

func stmt_asm_raw(p) {
	// asm { ... }
	// Lexer provides TOK_ASM_RAW (kind=19) whose slice includes the whole block.
	// This statement emits the bytes between '{' and the matching final '}' verbatim.
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
		"jmp .exit\n"

		".bad:\n"
		"lea rdi, [rel .s_bad_asm]\n"
		"call die\n"
		"jmp .exit\n"

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
		"jmp .exit\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".exit:\n"
	};
}
