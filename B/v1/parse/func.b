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
		"jmp .exit\n"
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
		"jmp .exit\n"
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
		"jmp .exit\n"

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
		// enforce <=6 args
		"mov rdi, [rsp+8]\n"
		"call vec_len\n"
		"mov r12, [rsp+0]\n" // be conservative about helper clobbers
		"cmp rax, 6\n"
		"jb .len_ok\n"
		"call die_func_too_many_args\n"
		".len_ok:\n"

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
		"sub rsp, 80\n" // [0]=p [8]=name_ptr [16]=name_len [24]=name_sl [32]=ret_sl [40]=args_vec [48]=loop_s [56]=loop_e [64]=argc [72]=i

		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		".top_loop:\n"
		"mov r12, [rsp+0]\n" // reload p (helpers may clobber callee-saved regs)
		"mov rax, [r12+8]\n"
		"test rax, rax\n" // TOK_EOF
		"je .done\n"

		// top-level: const decl or func decl
		"cmp rax, 20\n" // TOK_KW_CONST
		"je .do_const\n"
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

		// ret label Slice*
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call ret_label_from_func_name\n"
		"mov [rsp+32], rax\n"

		// emit function label
		"mov rdi, [rsp+24]\n"
		"call emit_slice_label_def\n"

		// reset locals table for this function
		"call locals_reset\n"
		"call aliases_reset\n"

		// function prologue + fixed local frame
		"lea rdi, [rel .s_pro0]\n" "call emit_cstr\n"
		"mov rdi, 1024\n" "call emit_u64\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"

		// spill args to stack locals
		"mov rdi, [rsp+40]\n" "call vec_len\n"
		"mov [rsp+64], rax\n" // argc
		"mov qword [rsp+72], 0\n" // i
		".spill_loop:\n"
		"mov rbx, [rsp+72]\n"
		"cmp rbx, [rsp+64]\n" "jae .spill_done\n"
		"mov rdi, [rsp+40]\n" "mov rsi, rbx\n" "call vec_get\n" // rax=ArgName*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n" // name_ptr
		"mov rsi, [r13+8]\n" // name_len
		"call locals_get_or_alloc\n" // rax=off
		"mov rdi, rax\n" // off
		"mov rsi, rbx\n" // reg_id
		"call emit_store_arg_to_local\n"
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

		".do_const:\n"
		// const IDENT = INT ;
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
		"call die_stmt_expected_eq\n"
		".c_eq_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// expect INT
		"mov rax, [r12+8]\n"
		"cmp rax, 2\n" // TOK_INT
		"je .c_int_ok\n"
		"call die_stmt_unexpected_token\n"
		".c_int_ok:\n"
		"mov rdi, [r12+16]\n" // ptr
		"mov rsi, [r12+24]\n" // len
		"call atoi_u64_or_panic\n" // rax=value
		"mov r13, rax\n" // save value
		"mov r12, [rsp+0]\n" // atoi helpers may clobber
		"mov rdi, r12\n" "call parser_next\n" // consume INT
		"mov r12, [rsp+0]\n"

		// expect ';'
		"mov rax, [r12+8]\n"
		"cmp rax, 36\n" // TOK_SEMI
		"je .c_semi_ok\n"
		"call die_stmt_expected_semi\n"
		".c_semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"

		// consts_set(name_ptr,name_len,value)
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"mov rdx, r13\n"
		"call consts_set\n"
		"jmp .top_loop\n"

		".done:\n"
		"add rsp, 80\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp .exit\n"
		".s_pro0: db '  push rbp', 10, '  mov rbp, rsp', 10, '  sub rsp, ', 0\n"
		".s_nl: db 10, 0\n"
		".s_xor: db '  xor rax, rax', 10, 0\n"
		".s_ret: db '  mov rsp, rbp', 10, '  pop rbp', 10, '  ret', 10, 0\n"
		".exit:\n"
	};
}
