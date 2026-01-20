// v1 condition parser (&&/|| short-circuit)
// Roadmap: docs/roadmap.md (stage 9)
// Planned:
// - parse_cond_emit_jfalse(target)
// - cond_atom / cond_not / cond_and / cond_or

func die_cond_expected_rparen() {
	die("cond: expected ')'");
}

func die_cond_expected_operand() {
	die("cond: expected operand");
}

func cond_or_emit_jfalse(p, target) {
	// Emit code that jumps to target label if condition is false.
	// Grammar:
	//   or := and ( '||' and )*
	// Convention: rdi=Parser*, rsi=Slice* target
	// NOTE: Implemented using asm-local labels to avoid Stage1 label collisions.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// label_ok = label_next()
		"call label_next\n"
		"mov r14, rax\n" // label_ok Slice*

		".loop:\n"
		// if (and(...) is true) jump label_ok; else fallthrough
		"mov rdi, [rsp+0]\n"
		"mov rsi, r14\n"
		"call cond_and_emit_jtrue\n"

		// if next token is '||', consume and continue
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 66\n" // TOK_OROR
		"jne .done_or\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .loop\n"

		".done_or:\n"
		// none of the clauses were true => jump false target
		"lea rdi, [rel .s_jmp]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n" // target Slice*
		"call slice_parts\n"      // rax=ptr, rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"

		// label_ok:
		"mov rdi, r14\n"
		"call slice_parts\n"
		"mov rbx, rax\n" // ptr
		"mov r15, rdx\n" // len
		"mov rdi, rbx\n"
		"mov rsi, r15\n"
		"call emit_str\n"
		"lea rdi, [rel .s_colon_nl]\n"
		"call emit_cstr\n"

		"add rsp, 16\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".s_jmp:       db '  jmp ', 0\n"
		".s_nl:        db 10, 0\n"
		".s_colon_nl:  db ':', 10, 0\n"
		".exit:\n"
	};
}

func cond_or_emit_jtrue(p, target) {
	// Emit code that jumps to target label if condition is true.
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		".loop:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_and_emit_jtrue\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 66\n" // TOK_OROR
		"jne .done\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .loop\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func cond_and_emit_jfalse(p, target) {
	// and := not ( '&&' not )*
	// Emit jump to target if AND-expression is false.
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		".loop:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_not_emit_jfalse\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 65\n" // TOK_ANDAND
		"jne .done\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .loop\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func cond_and_emit_jtrue(p, target) {
	// Emit jump to target if AND-expression is true.
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// label_fail = label_next()
		"call label_next\n"
		"mov r14, rax\n" // Slice*

		".loop:\n"
		// if (not is false) jump label_fail
		"mov rdi, [rsp+0]\n"
		"mov rsi, r14\n"
		"call cond_not_emit_jfalse\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 65\n" // TOK_ANDAND
		"jne .all_true\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .loop\n"

		".all_true:\n"
		"lea rdi, [rel .s_jmp]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n" // target Slice*
		"call slice_parts\n"
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"

		// label_fail:
		"mov rdi, r14\n"
		"call slice_parts\n"
		"mov rbx, rax\n"
		"mov r13, rdx\n"
		"mov rdi, rbx\n"
		"mov rsi, r13\n"
		"call emit_str\n"
		"lea rdi, [rel .s_colon_nl]\n"
		"call emit_cstr\n"

		"add rsp, 16\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".s_jmp:       db '  jmp ', 0\n"
		".s_nl:        db 10, 0\n"
		".s_colon_nl:  db ':', 10, 0\n"
		".exit:\n"
	};
}

func cond_not_emit_jfalse(p, target) {
	// not := '!' not | atom
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 64\n" // TOK_BANG
		"jne .atom\n"
		// consume '!'
		"mov rdi, r12\n"
		"call parser_next\n"
		// !A is false when A is true
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_not_emit_jtrue\n"
		"jmp .done\n"

		".atom:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_atom_emit_jfalse\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func cond_not_emit_jtrue(p, target) {
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 64\n" // TOK_BANG
		"jne .atom\n"
		// consume '!'
		"mov rdi, r12\n"
		"call parser_next\n"
		// !A is true when A is false
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_not_emit_jfalse\n"
		"jmp .done\n"

		".atom:\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call cond_atom_emit_jtrue\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func cond_atom_emit_jfalse(p, target) {
	// atom := '(' or ')' | expr [cmp expr]
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"jne .expr\n"
		// consume '('
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"call cond_or_emit_jfalse\n"
		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rparen_ok\n"
		"call die_cond_expected_rparen\n"
		".rparen_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".expr:\n"
		// lhs expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		// check for comparison operator
		"mov rax, [r12+8]\n"
		"cmp rax, 51\n" // TOK_EQEQ
		"je .have_cmp\n"
		"cmp rax, 52\n" // TOK_NE
		"je .have_cmp\n"
		"cmp rax, 53\n" // TOK_LT
		"je .have_cmp\n"
		"cmp rax, 54\n" // TOK_GT
		"je .have_cmp\n"
		"cmp rax, 55\n" // TOK_LE
		"je .have_cmp\n"
		"cmp rax, 56\n" // TOK_GE
		"je .have_cmp\n"

		// no cmp: truthy test
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_test]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_jz]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"call slice_parts\n"      // rax=ptr, rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".have_cmp:\n"
		"mov r14, rax\n" // op
		// consume op
		"mov rdi, r12\n"
		"call parser_next\n"
		// rhs expr
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		// pop rhs/lhs and cmp
		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_cmp]\n"
		"call emit_cstr\n"

		// emit jcc(false) based on op
		"cmp r14, 51\n" // == => false when !=
		"je .jf_ne\n"
		"cmp r14, 52\n" // != => false when ==
		"je .jf_e\n"
		"cmp r14, 53\n" // <  => false when >=
		"je .jf_ge\n"
		"cmp r14, 54\n" // >  => false when <=
		"je .jf_le\n"
		"cmp r14, 55\n" // <= => false when >
		"je .jf_g\n"
		// >= => false when <
		"jmp .jf_l\n"

		".emit_jcc:\n"
		"call emit_cstr\n" // rdi points to opcode string
		"mov rdi, [rsp+8]\n"
		"call slice_parts\n"
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".jf_ne:\n" "lea rdi, [rel .s_jne]\n" "jmp .emit_jcc\n"
		".jf_e:\n"  "lea rdi, [rel .s_je]\n"  "jmp .emit_jcc\n"
		".jf_ge:\n" "lea rdi, [rel .s_jge]\n" "jmp .emit_jcc\n"
		".jf_le:\n" "lea rdi, [rel .s_jle]\n" "jmp .emit_jcc\n"
		".jf_g:\n"  "lea rdi, [rel .s_jg]\n"  "jmp .emit_jcc\n"
		".jf_l:\n"  "lea rdi, [rel .s_jl]\n"  "jmp .emit_jcc\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".s_pop_rbx: db '  pop rbx', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_cmp:     db '  cmp rax, rbx', 10, 0\n"
		".s_test:    db '  test rax, rax', 10, 0\n"
		".s_jz:      db '  jz ', 0\n"
		".s_nl:      db 10, 0\n"
		".s_je:      db '  je ', 0\n"
		".s_jne:     db '  jne ', 0\n"
		".s_jl:      db '  jl ', 0\n"
		".s_jle:     db '  jle ', 0\n"
		".s_jg:      db '  jg ', 0\n"
		".s_jge:     db '  jge ', 0\n"
		".exit:\n"
	};
}

func cond_atom_emit_jtrue(p, target) {
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 16\n" // [rsp+0]=p, [rsp+8]=target
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 30\n" // TOK_LPAREN
		"jne .expr\n"
		// consume '('
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"mov rsi, [rsp+8]\n"
		"call cond_or_emit_jtrue\n"
		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n" // TOK_RPAREN
		"je .rparen_ok\n"
		"call die_cond_expected_rparen\n"
		".rparen_ok:\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".expr:\n"
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		"mov rax, [r12+8]\n"
		"cmp rax, 51\n" "je .have_cmp\n"
		"cmp rax, 52\n" "je .have_cmp\n"
		"cmp rax, 53\n" "je .have_cmp\n"
		"cmp rax, 54\n" "je .have_cmp\n"
		"cmp rax, 55\n" "je .have_cmp\n"
		"cmp rax, 56\n" "je .have_cmp\n"

		// no cmp: truthy test (jnz)
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_test]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_jnz]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"call slice_parts\n"
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".have_cmp:\n"
		"mov r14, rax\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"

		"lea rdi, [rel .s_pop_rbx]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_cmp]\n"
		"call emit_cstr\n"

		// emit jcc(true)
		"cmp r14, 51\n" "je .jt_e\n"
		"cmp r14, 52\n" "je .jt_ne\n"
		"cmp r14, 53\n" "je .jt_l\n"
		"cmp r14, 54\n" "je .jt_g\n"
		"cmp r14, 55\n" "je .jt_le\n"
		"jmp .jt_ge\n"

		".emit_jcc:\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"call slice_parts\n"
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"jmp .done\n"

		".jt_e:\n"  "lea rdi, [rel .s_je]\n"  "jmp .emit_jcc\n"
		".jt_ne:\n" "lea rdi, [rel .s_jne]\n" "jmp .emit_jcc\n"
		".jt_l:\n"  "lea rdi, [rel .s_jl]\n"  "jmp .emit_jcc\n"
		".jt_g:\n"  "lea rdi, [rel .s_jg]\n"  "jmp .emit_jcc\n"
		".jt_le:\n" "lea rdi, [rel .s_jle]\n" "jmp .emit_jcc\n"
		".jt_ge:\n" "lea rdi, [rel .s_jge]\n" "jmp .emit_jcc\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"

		".s_pop_rbx: db '  pop rbx', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_cmp:     db '  cmp rax, rbx', 10, 0\n"
		".s_test:    db '  test rax, rax', 10, 0\n"
		".s_jnz:     db '  jnz ', 0\n"
		".s_nl:      db 10, 0\n"
		".s_je:      db '  je ', 0\n"
		".s_jne:     db '  jne ', 0\n"
		".s_jl:      db '  jl ', 0\n"
		".s_jle:     db '  jle ', 0\n"
		".s_jg:      db '  jg ', 0\n"
		".s_jge:     db '  jge ', 0\n"
		".exit:\n"
	};
}

func parse_cond_emit_jfalse(p, target) {
	// Public entry: jump to target if the condition is false.
	// Convention: rdi=Parser*, rsi=Slice* target
	asm {
		"call cond_or_emit_jfalse\n"
	};
}
