// v1 expression parser
// Roadmap: docs/roadmap.md (stage 8)
// Recursive descent by precedence:
// bor -> bxor -> band -> equality -> relational -> shift -> additive -> term -> unary -> factor

func die_expr_expected_factor() {
	die("expr: expected factor");
}

func die_expr_expected_rparen() {
	die("expr: expected ')'");
}

func die_expr_expected_eof() {
	die("expr: expected EOF");
}

func die_expr_expected_lparen() {
	die("expr: expected '('");
}

func die_expr_expected_lbrack() {
	die("expr: expected '['");
}

func die_expr_expected_rbrack() {
	die("expr: expected ']'");
}

func die_expr_too_many_args() {
	die("expr: too many call args (max 6)");
}

func parser_new(lex) {
	// Allocate and prime a Parser.
	// Convention: rdi = Lexer*
	// Returns: rax = Parser*
	var lex0;
	var p0;
	ptr64[lex0] = rdi;

	heap_alloc(40);
	ptr64[p0] = rax;

	alias r8 : p;
	alias r9 : addr;
	p = ptr64[p0];
	addr = p;
	rdi = ptr64[lex0];
	ptr64[addr] = rdi;

	// Prime lookahead.
	rdi = ptr64[p0];
	parser_next(rdi);

	rax = ptr64[p0];
}

func parser_next(p) {
	// Advance one token.
	// Convention: rdi = Parser*
	// Returns: rax = kind
	var p0;
	ptr64[p0] = rdi;

	asm {
		"push r12\n"
		"mov r12, rdi\n"      // p
		"mov rdi, [r12+0]\n"  // lex
		"call lexer_next\n"    // rax kind, rdx ptr, rcx len, r8 line
		"mov [r12+8], rax\n"
		"mov [r12+16], rdx\n"
		"mov [r12+24], rcx\n"
		"mov [r12+32], r8\n"
		"pop r12\n"
	};
}

func parser_peek_kind(p) {
	// Peek next token kind without consuming it.
	// Convention: rdi = Parser*
	// Returns: rax = kind
	asm {
		"push r12\n"
		"push r13\n"

		"mov r12, rdi\n"      // p
		"mov r13, [r12+0]\n"  // lex

		// save lex->cur and lex->line (end is constant)
		"mov r8,  [r13+0]\n"   // cur
		"mov r9,  [r13+16]\n"  // line
		"push r8\n"
		"push r9\n"

		"mov rdi, r13\n"
		"call lexer_next\n"    // rax=kind

		// restore
		"pop r9\n"
		"pop r8\n"
		"mov [r13+0], r8\n"
		"mov [r13+16], r9\n"

		"pop r13\n"
		"pop r12\n"
	};
}

func vars_init_if_needed() {
	// Ensure global vars_emitted is a Vec*.
	asm {
		"mov rax, [rel vars_emitted]\n"
		"test rax, rax\n"
		"jnz .ok\n"
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel vars_emitted], rax\n"
		".ok:\n"
	};
}

func locals_reset() {
	// Reset local variable table for a new function.
	asm {
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel locals_emitted], rax\n"
		"mov qword [rel locals_next_off], 8\n" // offsets start at 8
	};
}

func aliases_reset() {
	// Reset register alias table for a new function.
	asm {
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel aliases_emitted], rax\n"
	};
}

func consts_reset() {
	// Reset constant table for a new compilation unit.
	asm {
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel consts_emitted], rax\n"
	};
}

func die_const_duplicate() {
	die("const: duplicate name");
}

func consts_get(name_ptr, name_len) {
	// Look up constant value for a name.
	// Returns:
	// - rax = value (undefined if not found)
	// - rdx = found (1 if found else 0)
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=vec [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel consts_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call consts_reset\n"
		"mov r12, [rel consts_emitted]\n"
		".have_vec:\n"
		"mov [rsp+16], r12\n"

		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+24], rax\n"
		"xor ebx, ebx\n"
		".scan:\n"
		"cmp rbx, [rsp+24]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, rbx\n"
		"call vec_get\n" // rax=ConstSym*
		"mov r13, rax\n"
		"mov rdi, [r13+8]\n"  // name_ptr
		"mov rsi, [r13+16]\n" // name_len
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .found\n"
		"inc rbx\n"
		"jmp .scan\n"
		".found:\n"
		"mov rax, [r13+24]\n" // value
		"mov rdx, 1\n"
		"jmp .done\n"
		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"
		".done:\n"
		"add rsp, 32\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func consts_set(name_ptr, name_len, value) {
	// Insert a new constant name->value. Errors on duplicates.
	// Convention: rdi=name_ptr, rsi=name_len, rdx=value
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 24\n" // [0]=name_ptr [8]=name_len [16]=value
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"

		"mov r12, [rel consts_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call consts_reset\n"
		"mov r12, [rel consts_emitted]\n"
		".have_vec:\n"

		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call consts_get\n" // rdx=found
		"test rdx, rdx\n"
		"jz .insert\n"
		"call die_const_duplicate\n"
		".insert:\n"

		// allocate Symbol-like (32 bytes): kind,name_ptr,name_len,value
		"mov rdi, 32\n"
		"call heap_alloc\n"
		"mov r13, rax\n"
		"mov qword [r13+0], 3\n" // SYM_CONST
		"mov r14, [rsp+0]\n" "mov [r13+8], r14\n"
		"mov r14, [rsp+8]\n" "mov [r13+16], r14\n"
		"mov r14, [rsp+16]\n" "mov [r13+24], r14\n"
		"mov rdi, r12\n"
		"mov rsi, r13\n"
		"call vec_push\n"

		"add rsp, 24\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func aliases_get(name_ptr, name_len) {
	// Look up reg alias for a name.
	// Returns:
	// - rax = reg_id (undefined if not found)
	// - rdx = found (1 if found else 0)
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=vec [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel aliases_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call aliases_reset\n"
		"mov r12, [rel aliases_emitted]\n"
		".have_vec:\n"
		"mov [rsp+16], r12\n"

		// n = vec_len(vec)
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+24], rax\n"
		"xor ebx, ebx\n" // i=0
		".scan:\n"
		"cmp rbx, [rsp+24]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, rbx\n"
		"call vec_get\n" // rax=Alias*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .found\n"
		"inc rbx\n"
		"jmp .scan\n"
		".found:\n"
		"mov rax, [r13+16]\n" // reg_id
		"mov rdx, 1\n"
		"jmp .done\n"
		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"
		".done:\n"
		"add rsp, 32\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func aliases_set(name_ptr, name_len, reg_id) {
	// Set alias name -> reg_id, updating existing entry if present.
	// Convention: rdi=name_ptr, rsi=name_len, rdx=reg_id
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=reg_id [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"

		"mov r12, [rel aliases_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call aliases_reset\n"
		"mov r12, [rel aliases_emitted]\n"
		".have_vec:\n"

		// n = vec_len(vec)
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+24], rax\n"
		"xor ebx, ebx\n" // i=0
		".scan:\n"
		"cmp rbx, [rsp+24]\n"
		"jae .not_found\n"
		"mov rdi, r12\n"
		"mov rsi, rbx\n"
		"call vec_get\n" // rax=Alias*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .update\n"
		"inc rbx\n"
		"jmp .scan\n"
		".update:\n"
		"mov r14, [rsp+16]\n"
		"mov [r13+16], r14\n"
		"jmp .done\n"

		".not_found:\n"
		// allocate new Alias {name_ptr,name_len,reg_id}
		"mov rdi, 24\n"
		"call heap_alloc\n" // rax=Alias*
		"mov r13, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov r10, [rsp+16]\n"
		"mov [r13+0], r8\n"
		"mov [r13+8], r9\n"
		"mov [r13+16], r10\n"
		"mov rdi, r12\n"
		"mov rsi, r13\n"
		"call vec_push\n"

		".done:\n"
		"add rsp, 32\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func emit_push_reg(reg_id) {
	// Emit: push <reg>\n for supported reg ids.
	// Convention: rdi = reg_id
	asm {
		"mov rax, rdi\n"
		"cmp rax, 0\n" "je .rdi\n"
		"cmp rax, 1\n" "je .rsi\n"
		"cmp rax, 2\n" "je .rdx\n"
		"cmp rax, 3\n" "je .rcx\n"
		"cmp rax, 4\n" "je .r8\n"
		"cmp rax, 5\n" "je .r9\n"
		"cmp rax, 6\n" "je .r10\n"
		"cmp rax, 7\n" "je .r11\n"
		"call die_expr_expected_factor\n"
		".rdi:\n" "lea rdi, [rel .s_push_rdi]\n" "jmp .emit\n"
		".rsi:\n" "lea rdi, [rel .s_push_rsi]\n" "jmp .emit\n"
		".rdx:\n" "lea rdi, [rel .s_push_rdx]\n" "jmp .emit\n"
		".rcx:\n" "lea rdi, [rel .s_push_rcx]\n" "jmp .emit\n"
		".r8:\n"  "lea rdi, [rel .s_push_r8]\n"  "jmp .emit\n"
		".r9:\n"  "lea rdi, [rel .s_push_r9]\n"  "jmp .emit\n"
		".r10:\n" "lea rdi, [rel .s_push_r10]\n" "jmp .emit\n"
		".r11:\n" "lea rdi, [rel .s_push_r11]\n"
		".emit:\n"
		"call emit_cstr\n"
		"jmp .exit\n"
		".s_push_rdi: db '  push rdi', 10, 0\n"
		".s_push_rsi: db '  push rsi', 10, 0\n"
		".s_push_rdx: db '  push rdx', 10, 0\n"
		".s_push_rcx: db '  push rcx', 10, 0\n"
		".s_push_r8:  db '  push r8', 10, 0\n"
		".s_push_r9:  db '  push r9', 10, 0\n"
		".s_push_r10: db '  push r10', 10, 0\n"
		".s_push_r11: db '  push r11', 10, 0\n"
		".exit:\n"
	};
}

func emit_mov_reg_from_rax(reg_id) {
	// Emit: mov <reg>, rax\n for supported reg ids.
	// Convention: rdi = reg_id
	asm {
		"mov rax, rdi\n"
		"cmp rax, 0\n" "je .rdi\n"
		"cmp rax, 1\n" "je .rsi\n"
		"cmp rax, 2\n" "je .rdx\n"
		"cmp rax, 3\n" "je .rcx\n"
		"cmp rax, 4\n" "je .r8\n"
		"cmp rax, 5\n" "je .r9\n"
		"cmp rax, 6\n" "je .r10\n"
		"cmp rax, 7\n" "je .r11\n"
		"call die_expr_expected_factor\n"
		".rdi:\n" "lea rdi, [rel .s_mov_rdi]\n" "jmp .emit\n"
		".rsi:\n" "lea rdi, [rel .s_mov_rsi]\n" "jmp .emit\n"
		".rdx:\n" "lea rdi, [rel .s_mov_rdx]\n" "jmp .emit\n"
		".rcx:\n" "lea rdi, [rel .s_mov_rcx]\n" "jmp .emit\n"
		".r8:\n"  "lea rdi, [rel .s_mov_r8]\n"  "jmp .emit\n"
		".r9:\n"  "lea rdi, [rel .s_mov_r9]\n"  "jmp .emit\n"
		".r10:\n" "lea rdi, [rel .s_mov_r10]\n" "jmp .emit\n"
		".r11:\n" "lea rdi, [rel .s_mov_r11]\n"
		".emit:\n"
		"call emit_cstr\n"
		"jmp .exit\n"
		".s_mov_rdi: db '  mov rdi, rax', 10, 0\n"
		".s_mov_rsi: db '  mov rsi, rax', 10, 0\n"
		".s_mov_rdx: db '  mov rdx, rax', 10, 0\n"
		".s_mov_rcx: db '  mov rcx, rax', 10, 0\n"
		".s_mov_r8:  db '  mov r8, rax', 10, 0\n"
		".s_mov_r9:  db '  mov r9, rax', 10, 0\n"
		".s_mov_r10: db '  mov r10, rax', 10, 0\n"
		".s_mov_r11: db '  mov r11, rax', 10, 0\n"
		".exit:\n"
	};
}

func locals_get_or_alloc(name_ptr, name_len) {
	// Get stack offset for a local variable name, allocating if needed.
	// Local layout: { name_ptr, name_len, offset }
	// Returns:
	// - rax = offset (u64, for [rbp-offset])
	// - rdx = is_new (1 if allocated, else 0)
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=vec [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel locals_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call locals_reset\n"
		"mov r12, [rel locals_emitted]\n"
		".have_vec:\n"
		"mov [rsp+16], r12\n"

		// n = vec_len(vec)
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+24], rax\n"
		"xor ebx, ebx\n" // i=0

		".scan:\n"
		"cmp rbx, [rsp+24]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, rbx\n"
		"call vec_get\n"       // rax = Local*
		"mov r13, rax\n"

		// compare name (ptr,len)
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .found\n"
		"inc rbx\n"
		"jmp .scan\n"

		".found:\n"
		"mov rax, [r13+16]\n" // offset
		"xor edx, edx\n"       // is_new=0
		"jmp .done\n"

		".not_found:\n"
		// allocate new Local
		"mov r14, [rel locals_next_off]\n"
		"add qword [rel locals_next_off], 8\n"
		"mov rdi, 24\n"
		"call heap_alloc\n" // rax=Local*
		"mov r15, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [r15+0], r8\n"
		"mov [r15+8], r9\n"
		"mov [r15+16], r14\n"

		"mov rdi, [rsp+16]\n"
		"mov rsi, r15\n"
		"call vec_push\n"

		"mov rax, r14\n" // offset
		"mov rdx, 1\n"   // is_new=1

		".done:\n"
		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func var_label_from_ident(name_ptr, name_len) {
	// Build a Slice* with label "v_<ident>".
	// Convention: rdi=name_ptr, rsi=name_len
	// Returns: rax = Slice*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=lab_ptr [24]=lab_len

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// prefix = \"v_\"
		"lea rdi, [rel .s_prefix]\n"
		"mov rsi, 2\n"
		"call slice_to_cstr\n"   // rax=ptr
		"mov r12, rax\n"         // prefix ptr

		// lab = str_concat(prefix,2, name_ptr, name_len)
		"mov rdi, r12\n"
		"mov rsi, 2\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call str_concat\n"      // rax=ptr, rdx=len
		"mov [rsp+16], rax\n"
		"mov [rsp+24], rdx\n"

		// Slice on heap
		"mov rdi, 16\n"
		"call heap_alloc\n"      // rax = Slice*
		"mov rbx, rax\n"
		"mov r13, [rsp+16]\n"   // ptr
		"mov r14, [rsp+24]\n"   // len
		"mov [rbx+0], r13\n"
		"mov [rbx+8], r14\n"
		"mov rax, rbx\n"

		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp .exit\n"
		".s_prefix: db 'v_', 0\n"
		".exit:\n"
	};
}

func vars_define_if_needed(label_sl) {
	// Ensure `label_sl` is defined in .bss exactly once.
	// Convention: rdi = Slice*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 24\n" // [0]=label_sl [8]=vec [16]=n

		"mov [rsp+0], rdi\n"
		"call vars_init_if_needed\n"
		"mov r12, [rel vars_emitted]\n"
		"mov [rsp+8], r12\n"

		// n = vec_len(vec)
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+16], rax\n"
		"xor ebx, ebx\n" // i=0

		".scan:\n"
		"cmp rbx, [rsp+16]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, rbx\n"
		"call vec_get\n"       // rax = Slice* entry
		"mov r13, rax\n"

		// compare entry vs label
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov r14, [rsp+0]\n"
		"mov rdx, [r14+0]\n"
		"mov rcx, [r14+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .done\n"
		"inc rbx\n"
		"jmp .scan\n"

		".not_found:\n"
		// Emit bss definition and remember it.
		"lea rdi, [rel .s_bss]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+0]\n"
		"call slice_parts\n"      // rax=ptr rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_def]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_text]\n"
		"call emit_cstr\n"

		// vec_push(vec, label_sl)
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+0]\n"
		"call vec_push\n"

		".done:\n"
		"add rsp, 24\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp .exit\n"
		".s_bss:  db 'section .bss', 10, 0\n"
		".s_def:  db ': resq 1', 10, 0\n"
		".s_text: db 'section .text', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_factor_emit(p) {
	// factor := INT | IDENT | '(' expr ')'
	// Also supports:
	//   ptr8  '[' addr ']'  (load byte, zero-extend)
	//   ptr64 '[' addr ']'  (load qword)
	// where addr is either:
	//   - IDENT (shorthand for address of global var slot v_<ident>)
	//   - expr  (evaluated as an address)
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 48\n" // [0]=p [8]=name_ptr [16]=name_len [24]=argc [32]=ptr_width
		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		"mov rax, [r12+8]\n"   // kind
		"cmp rax, 2\n"          // TOK_INT
		"je .int\n"
		"cmp rax, 1\n"          // TOK_IDENT
		"je .ident\n"
		"cmp rax, 30\n"         // TOK_LPAREN
		"je .lparen\n"
		"call die_expr_expected_factor\n"

		".int:\n"
		// value = atoi_u64_or_panic(ptr,len)
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"call atoi_u64_or_panic\n"  // rax=value
		"mov r12, [rsp+0]\n"       // be conservative about helper clobbers

		// emit: push qword <value>\n
		"sub rsp, 16\n"            // spill value across emits (keep alignment)
		"mov [rsp+0], rax\n"
		"lea rdi, [rel .s_push]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+0]\n"       // value
		"call emit_u64\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"add rsp, 16\n"

		// consume int
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".ident:\n"
		// Save ident parts for calls / ptr loads.
		"mov rax, [r12+16]\n" "mov [rsp+8], rax\n"
		"mov rax, [r12+24]\n" "mov [rsp+16], rax\n"

		// addr[ident] => push address of local slot
		"mov rdi, r12\n"
		"call parser_peek_kind\n" // rax=next kind
		"cmp rax, 34\n"          // TOK_LBRACK
		"jne .ident_not_addr\n"
		"mov rdi, [rsp+8]\n"     // name_ptr
		"mov rsi, [rsp+16]\n"    // name_len
		"lea rdx, [rel .s_addr]\n"
		"mov rcx, 4\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .addr_factor\n"
		".ident_not_addr:\n"

		// Call? IDENT '(' ... ')'
		"mov rdi, r12\n"
		"call parser_peek_kind\n" // rax=next kind
		"cmp rax, 30\n"          // TOK_LPAREN
		"je .call\n"
		// ptr8/ptr64 load? IDENT '[' ... ']'
		"cmp rax, 34\n"          // TOK_LBRACK
		"je .maybe_ptr_load\n"
		"jmp .var_load\n"

		".addr_factor:\n"
		// consume 'addr'
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '['
		"mov rax, [r12+8]\n"
		"cmp rax, 34\n" // TOK_LBRACK
		"je .addr_lb_ok\n"
		"call die_expr_expected_lbrack\n"
		".addr_lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect IDENT
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"je .addr_id_ok\n"
		"call die_expr_expected_factor\n"
		".addr_id_ok:\n"
		"mov rdi, [r12+16]\n" // name_ptr
		"mov rsi, [r12+24]\n" // name_len
		"call locals_get_or_alloc\n" // rax=off, rdx=is_new
		"mov r13, rax\n" // off
		// init new local to 0 (bss-like behavior)
		"test rdx, rdx\n"
		"jz .addr_no_init\n"
		"lea rdi, [rel .s_mov_loc0]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_mov_loc1]\n"
		"call emit_cstr\n"
		".addr_no_init:\n"
		// emit: lea rax, [rbp-<off>] ; push rax
		"lea rdi, [rel .s_lea_rbp0]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		// consume IDENT
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ']'
		"mov rax, [r12+8]\n"
		"cmp rax, 35\n" // TOK_RBRACK
		"je .addr_rb_ok\n"
		"call die_expr_expected_rbrack\n"
		".addr_rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".maybe_ptr_load:\n"
		// Only treat as ptr load if ident is exactly "ptr8" or "ptr64".
		"mov rdi, [rsp+8]\n"     // name_ptr
		"mov rsi, [rsp+16]\n"    // name_len
		"lea rdx, [rel .s_ptr8]\n"
		"mov rcx, 4\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .ptr8_load\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"lea rdx, [rel .s_ptr64]\n"
		"mov rcx, 5\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .ptr64_load\n"
		"jmp .var_load\n"

		".ptr8_load:\n"
		"mov qword [rsp+32], 8\n"
		"jmp .ptr_load\n"
		".ptr64_load:\n"
		"mov qword [rsp+32], 64\n"
		"jmp .ptr_load\n"

		".ptr_load:\n"
		// consume ptr8/ptr64 ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '['
		"mov rax, [r12+8]\n"
		"cmp rax, 34\n"          // TOK_LBRACK
		"je .ptr_lb_ok\n"
		"call die_expr_expected_lbrack\n"
		".ptr_lb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"      // consume '['
		"mov r12, [rsp+0]\n"

		// addr parsing: always parse full expr as address value
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		".ptr_addr_done:\n"
		// expect ']'
		"mov rax, [r12+8]\n"
		"cmp rax, 35\n"           // TOK_RBRACK
		"je .ptr_rb_ok\n"
		"call die_expr_expected_rbrack\n"
		".ptr_rb_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"      // consume ']'

		// emit runtime load based on width; stack: [addr]
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"mov rax, [rsp+32]\n"     // width
		"cmp rax, 8\n"
		"je .emit_load8\n"
		"lea rdi, [rel .s_load64]\n"
		"jmp .emit_load\n"
		".emit_load8:\n"
		"lea rdi, [rel .s_load8]\n"
		".emit_load:\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".var_load:\n"
		// variable load: alias reg or stack local
		"mov rdi, [r12+16]\n"  // name_ptr
		"mov rsi, [r12+24]\n"  // name_len
		"call aliases_get\n"     // rax=reg_id, rdx=found
		"test rdx, rdx\n"
		"jz .var_local\n"
		"mov rdi, rax\n"        // reg_id
		"call emit_push_reg\n"
		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".var_local:\n"
		"mov rdi, [r12+16]\n"  // name_ptr
		"mov rsi, [r12+24]\n"  // name_len
		"call consts_get\n"      // rax=value, rdx=found
		"test rdx, rdx\n"
		"jz .var_really_local\n"
		"mov r13, rax\n"        // save value
		"lea rdi, [rel .s_mov_imm]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"
		".var_really_local:\n"
		"mov rdi, [r12+16]\n"  // name_ptr
		"mov rsi, [r12+24]\n"  // name_len
		"call locals_get_or_alloc\n" // rax=off, rdx=is_new
		"mov r13, rax\n"        // off
		"test rdx, rdx\n"
		"jz .var_no_init\n"
		// init new local to 0 (bss-like behavior)
		"lea rdi, [rel .s_mov_loc0]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_mov_loc1]\n"
		"call emit_cstr\n"
		".var_no_init:\n"
		// emit: push qword [rbp-<off>]\n
		"lea rdi, [rel .s_push_rbp0]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n"
		"call emit_cstr\n"

		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".call:\n"

		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect '('
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n"          // TOK_LPAREN
		"je .call_lp_ok\n"
		"call die_expr_expected_lparen\n"
		".call_lp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"      // consume '('
		"mov r12, [rsp+0]\n"

		// argc = 0
		"mov qword [rsp+24], 0\n"

		// empty args if next is ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n"          // TOK_RPAREN
		"je .call_rp_expect\n"

		".call_arg_loop:\n"
		// enforce <= 6 args
		"mov rax, [rsp+24]\n"
		"cmp rax, 6\n"
		"jb .call_arg_ok\n"
		"call die_expr_too_many_args\n"
		".call_arg_ok:\n"

		// parse one expr, then pop into rax
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"

		// move rax into arg reg based on argc
		"mov rax, [rsp+24]\n"
		"cmp rax, 0\n" "je .arg_rdi\n"
		"cmp rax, 1\n" "je .arg_rsi\n"
		"cmp rax, 2\n" "je .arg_rdx\n"
		"cmp rax, 3\n" "je .arg_rcx\n"
		"cmp rax, 4\n" "je .arg_r8\n"
		"jmp .arg_r9\n"
		".arg_rdi:\n" "lea rdi, [rel .s_mov_rdi]\n" "jmp .arg_emit\n"
		".arg_rsi:\n" "lea rdi, [rel .s_mov_rsi]\n" "jmp .arg_emit\n"
		".arg_rdx:\n" "lea rdi, [rel .s_mov_rdx]\n" "jmp .arg_emit\n"
		".arg_rcx:\n" "lea rdi, [rel .s_mov_rcx]\n" "jmp .arg_emit\n"
		".arg_r8:\n"  "lea rdi, [rel .s_mov_r8]\n"  "jmp .arg_emit\n"
		".arg_r9:\n"  "lea rdi, [rel .s_mov_r9]\n"  "jmp .arg_emit\n"
		".arg_emit:\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"

		// argc++
		"mov rax, [rsp+24]\n"
		"inc rax\n"
		"mov [rsp+24], rax\n"

		// if ',' then consume and continue
		"mov rax, [r12+8]\n"
		"cmp rax, 37\n"          // TOK_COMMA
		"jne .call_rp_expect\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .call_arg_loop\n"

		".call_rp_expect:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n"          // TOK_RPAREN
		"je .call_rp_ok\n"
		"call die_expr_expected_rparen\n"
		".call_rp_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"      // consume ')'

		// emit: call <name>\n then push rax
		"lea rdi, [rel .s_call]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".lparen:\n"
		// consume '('
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n"          // TOK_RPAREN
		"je .rparen_ok\n"
		"call die_expr_expected_rparen\n"
		".rparen_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"

		".done:\n"
		"add rsp, 48\n"
		"pop r13\n"
		"pop r12\n"
		"jmp .exit\n"

		".s_push: db '  push qword ', 0\n"
		".s_push_mem: db '  push qword [rel ', 0\n"
		".s_push_rbp0: db '  push qword [rbp-', 0\n"
		".s_rbr:  db ']', 10, 0\n"
		".s_mov_loc0: db '  mov qword [rbp-', 0\n"
		".s_mov_loc1: db '], 0', 10, 0\n"
		".s_lea_rbp0: db '  lea rax, [rbp-', 0\n"
		".s_mov_imm:  db '  mov rax, ', 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_mov_rdi:  db '  mov rdi, rax', 10, 0\n"
		".s_mov_rsi:  db '  mov rsi, rax', 10, 0\n"
		".s_mov_rdx:  db '  mov rdx, rax', 10, 0\n"
		".s_mov_rcx:  db '  mov rcx, rax', 10, 0\n"
		".s_mov_r8:   db '  mov r8, rax', 10, 0\n"
		".s_mov_r9:   db '  mov r9, rax', 10, 0\n"
		".s_call:     db '  call ', 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_nl:   db 10, 0\n"
		".s_addr: db 'addr', 0\n"
		".s_ptr8:  db 'ptr8', 0\n"
		".s_ptr64: db 'ptr64', 0\n"
		".s_lea_rax0: db '  lea rax, [rel ', 0\n"
		".s_lea_rax1: db ']', 10, 0\n"
		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_load8:    db '  movzx rax, byte [rbx]', 10, 0\n"
		".s_load64:   db '  mov rax, qword [rbx]', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_unary_emit(p) {
	// unary := ('+'|'-'|'~'|'!') unary | factor
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"push r13\n"
		"mov r12, rdi\n"

		"mov rax, [r12+8]\n"
		"cmp rax, 40\n"         // TOK_PLUS
		"je .uplus\n"
		"cmp rax, 41\n"         // TOK_MINUS
		"je .uminus\n"
		"cmp rax, 63\n"         // TOK_TILDE
		"je .utilde\n"
		"cmp rax, 64\n"         // TOK_BANG
		"je .ubang\n"
		"jmp .factor\n"

		".uplus:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		"jmp .done\n"

		".uminus:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rax; neg rax; push rax
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_neg]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".utilde:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rax; not rax; push rax
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_not]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".ubang:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rax; test rax,rax; sete al; movzx rax,al; push rax
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_test]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_sete]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_movzx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".factor:\n"
		"mov rdi, r12\n"
		"call expr_parse_factor_emit\n"

		".done:\n"
		"pop r13\n"
		"pop r12\n"
		"jmp .exit\n"

		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_neg:      db '  neg rax', 10, 0\n"
		".s_not:      db '  not rax', 10, 0\n"
		".s_test:     db '  test rax, rax', 10, 0\n"
		".s_sete:     db '  sete al', 10, 0\n"
		".s_movzx:    db '  movzx rax, al', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_mov_imm:  db '  mov rax, ', 0\n"
		".exit:\n"
	};
}

func expr_parse_term_emit(p) {
	// term := unary (('*'|'/|'%') unary)*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"

		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 42\n"         // TOK_STAR
		"je .op_mul\n"
		"cmp rax, 43\n"         // TOK_SLASH
		"je .op_div\n"
		"cmp rax, 44\n"         // TOK_PERCENT
		"je .op_mod\n"
		"jne .done\n"

		".op_mul:\n"
		// consume '*'
		"mov rdi, r12\n"
		"call parser_next\n"
		// rhs
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rbx; pop rax; imul rax, rbx; push rax
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_imul]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".op_div:\n"
		// consume '/'
		"mov rdi, r12\n"
		"call parser_next\n"
		// rhs
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rbx; pop rax; xor rdx,rdx; div rbx; push rax
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_xor_rdx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_div]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".op_mod:\n"
		// consume '%'
		"mov rdi, r12\n"
		"call parser_next\n"
		// rhs
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"
		// emit: pop rbx; pop rax; xor rdx,rdx; div rbx; push rdx
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_xor_rdx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_div]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rdx]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".done:\n"
		"pop r12\n"
		"jmp .exit\n"

		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_imul:     db '  imul rax, rbx', 10, 0\n"
		".s_xor_rdx:  db '  xor rdx, rdx', 10, 0\n"
		".s_div:      db '  div rbx', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_push_rdx: db '  push rdx', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_additive_emit(p) {
	// additive := term (('+'|'-') term)*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_term_emit\n"

		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 40\n"         // TOK_PLUS
		"je .plus\n"
		"cmp rax, 41\n"         // TOK_MINUS
		"je .minus\n"
		"jmp .done\n"

		".plus:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_term_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_add]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".minus:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_term_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_sub]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".done:\n"
		"pop r12\n"
		"jmp .exit\n"

		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_add:      db '  add rax, rbx', 10, 0\n"
		".s_sub:      db '  sub rax, rbx', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_shift_emit(p) {
	// shift := additive (('<<'|'>>') additive)*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_additive_emit\n"

		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 70\n"         // TOK_SHL
		"je .shl\n"
		"cmp rax, 71\n"         // TOK_SHR
		"je .shr\n"
		"jmp .done\n"

		".shl:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_additive_emit\n"
		// pop rcx; pop rax; shl rax, cl; push rax
		"lea rdi, [rel .s_pop_rcx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_shl]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".shr:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_additive_emit\n"
		// pop rcx; pop rax; shr rax, cl; push rax
		"lea rdi, [rel .s_pop_rcx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_shr]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".done:\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rcx:  db '  pop rcx', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_shl:      db '  shl rax, cl', 10, 0\n"
		".s_shr:      db '  shr rax, cl', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_relational_emit(p) {
	// relational := shift (('<'|'>'|'<='|'>=') shift)*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"push r13\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_shift_emit\n"

		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 53\n" // TOK_LT
		"je .op\n"
		"cmp rax, 54\n" // TOK_GT
		"je .op\n"
		"cmp rax, 55\n" // TOK_LE
		"je .op\n"
		"cmp rax, 56\n" // TOK_GE
		"je .op\n"
		"jmp .done\n"

		".op:\n"
		"mov r13, rax\n" // op
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_shift_emit\n"
		// pop rhs/lhs; cmp; setcc; movzx; push
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_cmp]\n"
		"call emit_cstr\n"
		"cmp r13, 53\n" "je .setl\n"
		"cmp r13, 54\n" "je .setg\n"
		"cmp r13, 55\n" "je .setle\n"
		"jmp .setge\n"
		".setl:\n"  "lea rdi, [rel .s_setl]\n"  "jmp .emit_set\n"
		".setg:\n"  "lea rdi, [rel .s_setg]\n"  "jmp .emit_set\n"
		".setle:\n" "lea rdi, [rel .s_setle]\n" "jmp .emit_set\n"
		".setge:\n" "lea rdi, [rel .s_setge]\n" "jmp .emit_set\n"
		".emit_set:\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_movzx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".done:\n"
		"pop r13\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_cmp:      db '  cmp rax, rbx', 10, 0\n"
		".s_setl:     db '  setl al', 10, 0\n"
		".s_setg:     db '  setg al', 10, 0\n"
		".s_setle:    db '  setle al', 10, 0\n"
		".s_setge:    db '  setge al', 10, 0\n"
		".s_movzx:    db '  movzx rax, al', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_equality_emit(p) {
	// equality := relational (('=='|'!=') relational)*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"push r13\n"
		"mov r12, rdi\n"

		"mov rdi, r12\n"
		"call expr_parse_relational_emit\n"

		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 51\n" // TOK_EQEQ
		"je .op\n"
		"cmp rax, 52\n" // TOK_NE
		"je .op\n"
		"jmp .done\n"

		".op:\n"
		"mov r13, rax\n" // op
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_relational_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_cmp]\n"
		"call emit_cstr\n"
		"cmp r13, 51\n" "je .sete\n"
		"jmp .setne\n"
		".sete:\n"  "lea rdi, [rel .s_sete]\n"  "jmp .emit_set\n"
		".setne:\n" "lea rdi, [rel .s_setne]\n" "jmp .emit_set\n"
		".emit_set:\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_movzx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"jmp .loop\n"

		".done:\n"
		"pop r13\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rbx:  db '  pop rbx', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_cmp:      db '  cmp rax, rbx', 10, 0\n"
		".s_sete:     db '  sete al', 10, 0\n"
		".s_setne:    db '  setne al', 10, 0\n"
		".s_movzx:    db '  movzx rax, al', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_band_emit(p) {
	// band := equality ( '&' equality )*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rdi, r12\n"
		"call expr_parse_equality_emit\n"
		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 60\n" // TOK_AND
		"jne .done\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_equality_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_and]\n"     "call emit_cstr\n"
		"lea rdi, [rel .s_push]\n"    "call emit_cstr\n"
		"jmp .loop\n"
		".done:\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rbx: db '  pop rbx', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_and:     db '  and rax, rbx', 10, 0\n"
		".s_push:    db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_bxor_emit(p) {
	// bxor := band ( '^' band )*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rdi, r12\n"
		"call expr_parse_band_emit\n"
		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 62\n" // TOK_XOR
		"jne .done\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_band_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_xor]\n"     "call emit_cstr\n"
		"lea rdi, [rel .s_push]\n"    "call emit_cstr\n"
		"jmp .loop\n"
		".done:\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rbx: db '  pop rbx', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_xor:     db '  xor rax, rbx', 10, 0\n"
		".s_push:    db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_bor_emit(p) {
	// bor := bxor ( '|' bxor )*
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rdi, r12\n"
		"call expr_parse_bxor_emit\n"
		".loop:\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 61\n" // TOK_OR
		"jne .done\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_bxor_emit\n"
		"lea rdi, [rel .s_pop_rbx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_or]\n"      "call emit_cstr\n"
		"lea rdi, [rel .s_push]\n"    "call emit_cstr\n"
		"jmp .loop\n"
		".done:\n"
		"pop r12\n"
		"jmp .exit\n"
		".s_pop_rbx: db '  pop rbx', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_or:      db '  or rax, rbx', 10, 0\n"
		".s_push:    db '  push rax', 10, 0\n"
		".exit:\n"
	};
}

func expr_parse_top_emit(p) {
	// Parse one expression and require EOF.
	// Convention: rdi = Parser*
	asm {
		"push r12\n"
		"mov r12, rdi\n"
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"mov rax, [r12+8]\n"
		"test rax, rax\n"       // TOK_EOF
		"je .ok\n"
		"call die_expr_expected_eof\n"
		".ok:\n"
		"pop r12\n"
	};
}
