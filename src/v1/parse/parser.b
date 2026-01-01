// v1 parser (declarations / function skeleton)
// Roadmap: docs/roadmap.md (stage 7)
// Depends on: lexer, symbol, emitter, ABI rules
// Planned:
// - parse_program()
// - parse_var_decl(), parse_var_array_decl()
// - parse_alias_decl()
// - parse_func_decl()
// - scope reset at function end

func die_parse_expected_kw_func() {
	die("parse: expected 'func'");
}

func die_parse_expected_ident() {
	die("parse: expected identifier");
}

func die_parse_expected_lparen() {
	die("parse: expected '('");
}

func die_parse_expected_rparen() {
	die("parse: expected ')'");
}

func die_parse_expected_lbrace() {
	die("parse: expected '{'");
}

func die_parse_expected_rbrace() {
	die("parse: expected '}'");
}

func die_parse_expected_eof() {
	die("parse: expected EOF");
}

func die_parse_expected_kw_var() {
	die("parse: expected 'var'");
}

func die_parse_expected_semi() {
	die("parse: expected ';'");
}

func die_parse_unexpected_toplevel() {
	die("parse: unexpected token at toplevel");
}

func die_parse_unexpected_in_func() {
	die("parse: unexpected token in func body");
}

func parse_program(lex) {
	// P4 skeleton program parser.
	// Accepts a sequence of:
	// - var <ident>;
	// - func <ident>() { (var <ident>;)* }
	// Returns: rax = symtab Vec*
	// NOTE: implemented with asm-local labels to avoid Stage1 global label collisions.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 64\n"

		// r12 = lex
		"mov r12, rdi\n"

		// r13 = symtab
		"call symtab_new\n"
		"mov r13, rax\n"

		".loop:\n"
		"mov rdi, r12\n"
		"call lexer_next\n"
		"mov r14, rax\n" // kind
		"test r14, r14\n"
		"je .done\n"

		// toplevel: var | func
		"cmp r14, 11\n" // TOK_KW_VAR
		"je .top_var\n"
		"cmp r14, 10\n" // TOK_KW_FUNC
		"je .top_func\n"
		"call die_parse_unexpected_toplevel\n"

		".top_var:\n"
		// ident
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .top_var_ident_ok\n"
		"call die_parse_expected_ident\n"
		".top_var_ident_ok:\n"
		// save (name_ptr, name_len)
		"mov [rsp+0], rdx\n"
		"mov [rsp+8], rcx\n"
		// ';'
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .top_var_semi_ok\n"
		"call die_parse_expected_semi\n"
		".top_var_semi_ok:\n"
		// symtab_put(tab, SYM_VAR, name_ptr, name_len, 0)
		"mov rdi, r13\n"
		"mov rsi, 1\n"  // SYM_VAR
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"xor r8, r8\n"
		"call symtab_put\n"
		"jmp .loop\n"

		".top_func:\n"
		// func name ident
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .func_ident_ok\n"
		"call die_parse_expected_ident\n"
		".func_ident_ok:\n"
		// '('
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .func_lparen_ok\n"
		"call die_parse_expected_lparen\n"
		".func_lparen_ok:\n"
		// ')'
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .func_rparen_ok\n"
		"call die_parse_expected_rparen\n"
		".func_rparen_ok:\n"
		// '{'
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .func_lbrace_ok\n"
		"call die_parse_expected_lbrace\n"
		".func_lbrace_ok:\n"

		// scope mark: saved_len = vec_len(tab)
		"mov rdi, r13\n"
		"call vec_len\n"
		"mov r15, rax\n"

		// body: (var <ident>;)* then '}'
		".body_loop:\n"
		"mov rdi, r12\n"
		"call lexer_next\n"
		"mov r14, rax\n"
		"cmp r14, 33\n" // TOK_RBRACE
		"je .func_end\n"
		"cmp r14, 11\n" // TOK_KW_VAR
		"je .body_var\n"
		"call die_parse_unexpected_in_func\n"

		".body_var:\n"
		// ident
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .body_var_ident_ok\n"
		"call die_parse_expected_ident\n"
		".body_var_ident_ok:\n"
		"mov [rsp+0], rdx\n"
		"mov [rsp+8], rcx\n"
		// ';'
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .body_var_semi_ok\n"
		"call die_parse_expected_semi\n"
		".body_var_semi_ok:\n"
		// symtab_put(tab, SYM_VAR, name_ptr, name_len, 0)
		"mov rdi, r13\n"
		"mov rsi, 1\n"  // SYM_VAR
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"xor r8, r8\n"
		"call symtab_put\n"
		"jmp .body_loop\n"

		".func_end:\n"
		// scope reset: tab->len = saved_len
		"mov [r13+8], r15\n"
		"jmp .loop\n"

		".done:\n"
		"mov rax, r13\n"
		"add rsp, 64\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func parse_p4_minimal_program(lex) {
	// Minimal parser for P4 smoke.
	// Accepts exactly: func <ident>() { }
	// Convention: rdi = Lexer*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		// func
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 10\n" // TOK_KW_FUNC
		"je .ok_func\n"
		"call die_parse_expected_kw_func\n"
		".ok_func:\n"

		// ident
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .ok_ident\n"
		"call die_parse_expected_ident\n"
		".ok_ident:\n"

		// (
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"je .ok_lparen\n"
		"call die_parse_expected_lparen\n"
		".ok_lparen:\n"

		// )
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .ok_rparen\n"
		"call die_parse_expected_rparen\n"
		".ok_rparen:\n"

		// {
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 32\n" // TOK_LBRACE
		"je .ok_lbrace\n"
		"call die_parse_expected_lbrace\n"
		".ok_lbrace:\n"

		// }
		"mov rdi, r12\n"
		"call lexer_next\n"
		"cmp rax, 33\n" // TOK_RBRACE
		"je .ok_rbrace\n"
		"call die_parse_expected_rbrace\n"
		".ok_rbrace:\n"

		// EOF
		"mov rdi, r12\n"
		"call lexer_next\n"
		"test rax, rax\n" // TOK_EOF
		"je .ok_eof\n"
		"call die_parse_expected_eof\n"
		".ok_eof:\n"

		"pop r12\n"
	};
}
