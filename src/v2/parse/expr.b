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

func die_expr_expected_rparen_call_scan() {
	die("expr: expected ')' (call scan)");
}

func die_expr_expected_rparen_call_end() {
	die("expr: expected ')' (call end)");
}

func die_expr_expected_eof() {
	die("expr: expected EOF");
}

func die_expr_expected_lparen() {
	die("expr: expected '('");
}

func die_expr_expected_comma() {
	die("expr: expected ','");
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

func die_expr_undefined_ident() {
	die("expr: undefined identifier");
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

func rodata_reset() {
	// Reset string literal table for a new compilation unit.
	asm {
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel rodata_emitted], rax\n"
		"mov qword [rel rodata_counter], 0\n"
	};
}

func structs_reset() {
	// Reset v2 struct type table.
	asm {
		"mov r12, [rel structs_emitted]\n"
		"test r12, r12\n"
		"jnz .have\n"
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rel structs_emitted], rax\n"
		"jmp .done\n"
		".have:\n"
		"mov qword [r12+8], 0\n" // len=0
		".done:\n"
	};
}

func die_struct_duplicate() {
	die("struct: duplicate definition");
}

func die_struct_unknown() {
	die("struct: unknown type");
}

func die_struct_unknown_field() {
	die("struct: unknown field");
}

func die_struct_by_value_incomplete() {
	die("struct: by-value field requires complete type");
}

func die_struct_by_value_recursive() {
	die("struct: recursive by-value field is not allowed");
}

func die_struct_field_access_needs_type() {
	die("struct: field access requires a typed base");
}

func die_struct_field_not_qword() {
	die("struct: field access only supports 1/2/4/8-byte fields (u8/u16/u32/u64/i64)");
}

func structs_get_field(type_ptr, type_len, field_ptr, field_len) {
	// Returns: rax=Field*, rdx=found
	// Convention: rdi=type_ptr, rsi=type_len, rdx=field_ptr, rcx=field_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 48\n" // [0]=type_ptr [8]=type_len [16]=field_ptr [24]=field_len [32]=fields_vec [40]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"

		// def = structs_get(type)
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+8]\n" "call structs_get\n"
		"test rdx, rdx\n" "jnz .have_def\n"
		"xor eax, eax\n" "xor edx, edx\n" "jmp .done\n"
		".have_def:\n"
		"mov r12, rax\n" // def*
		"mov r13, [r12+16]\n" // fields_vec
		"mov [rsp+32], r13\n"
		"mov rdi, r13\n" "call vec_len\n"
		"mov [rsp+40], rax\n"
		"mov rbx, rax\n" // i=n

		".scan:\n"
		"test rbx, rbx\n" "jz .not_found\n"
		"dec rbx\n"
		"mov rdi, [rsp+32]\n" "mov rsi, rbx\n" "call vec_get\n" // rax=Field*
		"mov r14, rax\n"
		"mov rdi, [r14+0]\n" "mov rsi, [r14+8]\n"
		"mov rdx, [rsp+16]\n" "mov rcx, [rsp+24]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n" "jnz .found\n"
		"jmp .scan\n"

		".found:\n"
		"mov rax, r14\n"
		"mov rdx, 1\n"
		"jmp .done\n"
		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"

		".done:\n"
		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func structs_get(name_ptr, name_len) {
	// Returns: rax=StructDef*, rdx=found
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 32\n" // [0]=name_ptr [8]=name_len [16]=vec [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel structs_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call structs_reset\n"
		"mov r12, [rel structs_emitted]\n"
		".have_vec:\n"
		"mov [rsp+16], r12\n"

		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+24], rax\n"
		"mov rbx, rax\n" // i = n

		".scan:\n"
		"test rbx, rbx\n"
		"jz .not_found\n"
		"dec rbx\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, rbx\n"
		"call vec_get\n" // rax=StructDef*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .found\n"
		"jmp .scan\n"

		".found:\n"
		"mov rax, r13\n"
		"mov rdx, 1\n"
		"jmp .done\n"

		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"

		".done:\n"
		"add rsp, 32\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func structs_add(name_ptr, name_len) {
	// Create and register a new StructDef with empty fields.
	// Returns: rax=StructDef*
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 16\n" // [0]=name_ptr [8]=name_len
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel structs_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call structs_reset\n"
		"mov r12, [rel structs_emitted]\n"
		".have_vec:\n"

		// reject duplicates
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call structs_get\n"
		"test rdx, rdx\n"
		"jz .dup_ok\n"
		"call die_struct_duplicate\n"
		".dup_ok:\n"

		// fields_vec = vec_new(8)
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov r13, rax\n"

		// allocate StructDef {name_ptr,name_len,fields_vec,size,in_progress}
		"mov rdi, 40\n"
		"call heap_alloc\n" // rax=StructDef*
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [rax+0], r8\n"
		"mov [rax+8], r9\n"
		"mov [rax+16], r13\n"
		"mov qword [rax+24], 0\n" // size
		"mov qword [rax+32], 1\n" // in_progress=1
		"mov r14, rax\n" // keep def* across vec_push

		"mov rdi, r12\n"
		"mov rsi, r14\n"
		"call vec_push\n"
		"mov rax, r14\n" // return def*

		"add rsp, 16\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func rodata_add_string(tok_ptr, tok_len) {
	// Record a string literal token to be emitted into .rodata.
	// Returns: rax = label_id (u64)
	// Convention: rdi=tok_ptr, rsi=tok_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 24\n" // [0]=tok_ptr [8]=tok_len [16]=n
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel rodata_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call rodata_reset\n"
		"mov r12, [rel rodata_emitted]\n"
		".have_vec:\n"

		// If already present (by token location), reuse existing label id.
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov [rsp+16], rax\n"
		"xor ebx, ebx\n" // i=0
		".scan:\n"
		"cmp rbx, [rsp+16]\n"
		"jae .insert\n"
		"mov rdi, r12\n" "mov rsi, rbx\n" "call vec_get\n" // rax=RodataStr*
		"mov r14, rax\n"
		"mov r15, [rsp+0]\n" // tok_ptr
		"cmp [r14+0], r15\n"
		"jne .scan_next\n"
		"mov r15, [rsp+8]\n" // tok_len
		"cmp [r14+8], r15\n"
		"jne .scan_next\n"
		"mov rax, [r14+16]\n" // label_id
		"jmp .done\n"
		".scan_next:\n"
		"inc rbx\n"
		"jmp .scan\n"

		".insert:\n"

		"mov r13, [rel rodata_counter]\n"
		"inc r13\n"
		"mov [rel rodata_counter], r13\n"

		// RodataStr {tok_ptr,tok_len,label_id}
		"mov rdi, 24\n"
		"call heap_alloc\n"
		"mov r14, rax\n"
		"mov r8,  [rsp+0]\n" "mov [r14+0], r8\n"
		"mov r8,  [rsp+8]\n" "mov [r14+8], r8\n"
		"mov [r14+16], r13\n"
		"mov rdi, r12\n"
		"mov rsi, r14\n"
		"call vec_push\n"
		"mov rax, r13\n"

		".done:\n"
		"add rsp, 24\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func rodata_decode_string(tok_ptr, tok_len) {
	// Decode a TOK_STR token (including quotes) into raw bytes.
	// Supports escapes: \n \t \r \0 \\ \".
	// Returns: rax=buf_ptr, rdx=buf_len
	// Convention: rdi=tok_ptr, rsi=tok_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"

		"mov r12, rdi\n" // tok_ptr
		"mov r13, rsi\n" // tok_len
		// buf = heap_alloc(tok_len)
		"mov rdi, r13\n"
		"call heap_alloc\n"
		"mov r14, rax\n" // buf
		"xor r15d, r15d\n" // out_len

		// p = tok_ptr+1, end = tok_ptr+tok_len-1
		"lea rbx, [r12+1]\n" // p
		"mov rdx, r12\n"
		"add rdx, r13\n"
		"dec rdx\n" // end (points to closing quote)

		".loop:\n"
		"cmp rbx, rdx\n"
		"jae .done\n"
		"mov al, [rbx]\n"
		"cmp al, 92\n" // '\\'
		"jne .plain\n"
		// escape
		"inc rbx\n"
		"cmp rbx, rdx\n"
		"jae .done\n"
		"mov al, [rbx]\n"
		"mov r11b, al\n" // tmp
		"movzx eax, r11b\n"
		"cmp r11b, 'n'\n" "jne .esc_t\n" "mov eax, 10\n" "jmp .esc_write\n"
		".esc_t:\n" "cmp r11b, 't'\n" "jne .esc_r\n" "mov eax, 9\n" "jmp .esc_write\n"
		".esc_r:\n" "cmp r11b, 'r'\n" "jne .esc_0\n" "mov eax, 13\n" "jmp .esc_write\n"
		".esc_0:\n" "cmp r11b, '0'\n" "jne .esc_bs\n" "xor eax, eax\n" "jmp .esc_write\n"
		".esc_bs:\n" "cmp r11b, 92\n"  "jne .esc_q\n" "mov eax, 92\n" "jmp .esc_write\n"
		".esc_q:\n"  "cmp r11b, '\"'\n" "jne .esc_write\n" "mov eax, 34\n"
		".esc_write:\n"
		"mov [r14+r15], al\n"
		"inc r15\n"
		"inc rbx\n"
		"jmp .loop\n"

		".plain:\n"
		"mov [r14+r15], al\n"
		"inc r15\n"
		"inc rbx\n"
		"jmp .loop\n"

		".done:\n"
		"mov rax, r14\n"
		"mov rdx, r15\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func rodata_emit_all() {
	// Emit all recorded string literals as NASM .rodata.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 56\n" // [0]=vec [8]=n [16]=i [24]=entry [32]=buf [40]=len [48]=j

		"mov r12, [rel rodata_emitted]\n"
		"test r12, r12\n"
		"jz .done\n"
		"mov [rsp+0], r12\n"
		"mov rdi, r12\n"
		"call vec_len\n"
		"test rax, rax\n"
		"jz .done\n"
		"mov [rsp+8], rax\n" // n
		"mov qword [rsp+16], 0\n" // i

		"lea rdi, [rel .s_rodata]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"

		".loop_i:\n"
		"mov rax, [rsp+16]\n" // i
		"cmp rax, [rsp+8]\n"  // n
		"jae .done\n"
		"mov rdi, [rsp+0]\n" // vec
		"mov rsi, [rsp+16]\n" // i
		"call vec_get\n"        // rax=RodataStr*
		"mov [rsp+24], rax\n"
		"mov r13, rax\n"

		// label: str_<id>:
		"lea rdi, [rel .s_str0]\n" "call emit_cstr\n"
		"mov r13, [rsp+24]\n"
		"mov rdi, [r13+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_str1]\n" "call emit_cstr\n"

		// decode -> buf,len
		"mov r13, [rsp+24]\n"
		"mov rdi, [r13+0]\n" "mov rsi, [r13+8]\n" "call rodata_decode_string\n"
		"mov [rsp+32], rax\n" // buf
		"mov [rsp+40], rdx\n" // len

		// emit db prefix
		"lea rdi, [rel .s_db]\n" "call emit_cstr\n"
		"mov qword [rsp+48], 0\n" // j

		".loop_j:\n"
		"mov rax, [rsp+48]\n" // j
		"cmp rax, [rsp+40]\n" // len
		"jae .term\n"
		"mov r14, [rsp+32]\n" // buf
		"mov rbx, [rsp+48]\n" // j
		"movzx rax, byte [r14+rbx]\n"
		"mov rdi, rax\n" "call emit_u64\n"
		"lea rdi, [rel .s_comma]\n" "call emit_cstr\n"
		"mov rax, [rsp+48]\n" "inc rax\n" "mov [rsp+48], rax\n"
		"jmp .loop_j\n"

		".term:\n"
		"lea rdi, [rel .s_zero_nl]\n" "call emit_cstr\n"
		// i++
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n"
		"jmp .loop_i\n"

		".done:\n"
		"add rsp, 56\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_rodata:  db 'section .rodata', 10, 0\n"
		".s_str0:    db 'str_', 0\n"
		".s_str1:    db ':', 10, 0\n"
		".s_db:      db '  db ', 0\n"
		".s_comma:   db ', ', 0\n"
		".s_zero_nl: db '0', 10, 0\n"
		".exit:\n"
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
		"jmp near .exit\n"
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
		"jmp near .exit\n"
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

func locals_get(name_ptr, name_len) {
	// Get stack offset for a local variable name.
	// Returns:
	// - rax = offset (u64)
	// - rdx = found (1 if found else 0)
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
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
		"mov rbx, rax\n" // i = n

		".scan:\n"
		"test rbx, rbx\n"
		"jz .not_found\n"
		"dec rbx\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, rbx\n"
		"call vec_get\n" // rax=Local*
		"mov r13, rax\n"

		// compare name
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jnz .found\n"
		"jmp .scan\n"

		".found:\n"
		"mov rax, [r13+16]\n" // off
		"mov rdx, 1\n"
		"jmp .done\n"

		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"

		".done:\n"
		"add rsp, 32\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func locals_alloc(name_ptr, name_len) {
	// Always allocate a fresh local slot (supports shadowing).
	// Returns: rax = offset
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 16\n" // [0]=name_ptr [8]=name_len

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		"mov r12, [rel locals_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call locals_reset\n"
		"mov r12, [rel locals_emitted]\n"
		".have_vec:\n"

		"mov r14, [rel locals_next_off]\n"
		"add qword [rel locals_next_off], 8\n"
		"mov rdi, 56\n"
		"call heap_alloc\n" // rax=Local*
		"mov r15, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [r15+0], r8\n"
		"mov [r15+8], r9\n"
		"mov [r15+16], r14\n"
		"mov qword [r15+24], 8\n"  // size
		"mov qword [r15+32], 0\n" // type_ptr
		"mov qword [r15+40], 0\n" // type_len
		"mov qword [r15+48], 0\n" // type_is_ptr

		"mov rdi, r12\n"
		"mov rsi, r15\n"
		"call vec_push\n"

		"mov rax, r14\n"

		"add rsp, 16\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func locals_alloc_array(name_ptr, name_len, elems) {
	// Allocate a fresh local array of `elems` qword slots.
	// Returns: rax = base offset for a[0] (u64, for [rbp-off]).
	// Convention: rdi=name_ptr, rsi=name_len, rdx=elems
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"push rbx\n"
		"sub rsp, 24\n" // [0]=name_ptr [8]=name_len [16]=elems

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"

		"mov r12, [rel locals_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call locals_reset\n"
		"mov r12, [rel locals_emitted]\n"
		".have_vec:\n"

		// elems must be > 0
		"mov rbx, [rsp+16]\n"
		"test rbx, rbx\n"
		"jnz .elems_ok\n"
		"call die_expr_expected_factor\n"
		".elems_ok:\n"

		// base_off = locals_next_off + (elems-1)*8
		"mov r14, [rel locals_next_off]\n" // cur
		"mov r15, rbx\n"
		"dec r15\n"
		"shl r15, 3\n" // (elems-1)*8
		"add r14, r15\n" // base_off

		// locals_next_off += elems*8
		"mov r15, rbx\n"
		"shl r15, 3\n"
		"add [rel locals_next_off], r15\n"

		// allocate new Local {name_ptr,name_len,offset,size,type...}
		"mov rdi, 56\n"
		"call heap_alloc\n" // rax=Local*
		"mov r13, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [r13+0], r8\n"
		"mov [r13+8], r9\n"
		"mov [r13+16], r14\n"
		"mov rax, [rsp+16]\n" // elems
		"shl rax, 3\n"         // elems*8
		"mov [r13+24], rax\n"  // size
		"mov qword [r13+32], 0\n" // type_ptr
		"mov qword [r13+40], 0\n" // type_len
		"mov qword [r13+48], 0\n" // type_is_ptr

		"mov rdi, r12\n"
		"mov rsi, r13\n"
		"call vec_push\n"

		"mov rax, r14\n"

		"add rsp, 24\n"
		"pop rbx\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func locals_get_or_alloc(name_ptr, name_len) {
	// Get stack offset for a local variable name, allocating if needed.
	// Local layout: { name_ptr, name_len, offset, size, type_ptr, type_len, type_is_ptr }
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
		"mov rbx, rax\n" // i = n

		".scan:\n"
		"test rbx, rbx\n"
		"jz .not_found\n"
		"dec rbx\n"
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
		"jmp .scan\n"

		".found:\n"
		"mov rax, [r13+16]\n" // offset
		"xor edx, edx\n"       // is_new=0
		"jmp .done\n"

		".not_found:\n"
		// allocate new Local
		"mov r14, [rel locals_next_off]\n"
		"add qword [rel locals_next_off], 8\n"
		"mov rdi, 56\n"
		"call heap_alloc\n" // rax=Local*
		"mov r15, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [r15+0], r8\n"
		"mov [r15+8], r9\n"
		"mov [r15+16], r14\n"
		"mov qword [r15+24], 8\n"  // size
		"mov qword [r15+32], 0\n" // type_ptr
		"mov qword [r15+40], 0\n" // type_len
		"mov qword [r15+48], 0\n" // type_is_ptr

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

func locals_alloc_ex(name_ptr, name_len, size, type_ptr, type_len, type_is_ptr) {
	// Always allocate a fresh local slot range (supports shadowing).
	// Returns: rax = base offset
	// Convention: rdi=name_ptr, rsi=name_len, rdx=size, rcx=type_ptr, r8=type_len, r9=type_is_ptr
	asm {
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"push rbx\n"
		"sub rsp, 48\n" // [0]=name_ptr [8]=name_len [16]=size [24]=type_ptr [32]=type_len [40]=type_is_ptr

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"
		"mov [rsp+24], rcx\n"
		"mov [rsp+32], r8\n"
		"mov [rsp+40], r9\n"

		"mov r12, [rel locals_emitted]\n"
		"test r12, r12\n"
		"jnz .have_vec\n"
		"call locals_reset\n"
		"mov r12, [rel locals_emitted]\n"
		".have_vec:\n"

		// size must be >= 8 and multiple of 8
		"mov rbx, [rsp+16]\n"
		"cmp rbx, 8\n"
		"jae .sz_ge8\n"
		"call die_expr_expected_factor\n"
		".sz_ge8:\n"
		"mov rax, rbx\n"
		"and rax, 7\n"
		"jz .sz_aligned\n"
		"call die_expr_expected_factor\n"
		".sz_aligned:\n"

		"mov r14, [rel locals_next_off]\n" // base_off
		"add [rel locals_next_off], rbx\n"

		"mov rdi, 56\n"
		"call heap_alloc\n" // rax=Local*
		"mov r15, rax\n"
		"mov r8,  [rsp+0]\n"
		"mov r9,  [rsp+8]\n"
		"mov [r15+0], r8\n"
		"mov [r15+8], r9\n"
		"mov [r15+16], r14\n"
		"mov rax, [rsp+16]\n" "mov [r15+24], rax\n" // size
		"mov rax, [rsp+24]\n" "mov [r15+32], rax\n" // type_ptr
		"mov rax, [rsp+32]\n" "mov [r15+40], rax\n" // type_len
		"mov rax, [rsp+40]\n" "mov [r15+48], rax\n" // type_is_ptr

		"mov rdi, r12\n"
		"mov rsi, r15\n"
		"call vec_push\n"

		"mov rax, r14\n"

		"add rsp, 48\n"
		"pop rbx\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
	};
}

func locals_get_entry(name_ptr, name_len) {
	// Returns: rax=Local*, rdx=found
	// Convention: rdi=name_ptr, rsi=name_len
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
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

		"mov rdi, r12\n" "call vec_len\n"
		"mov [rsp+24], rax\n"
		"mov rbx, rax\n" // i=n

		".scan:\n"
		"test rbx, rbx\n" "jz .not_found\n"
		"dec rbx\n"
		"mov rdi, [rsp+16]\n" "mov rsi, rbx\n" "call vec_get\n" // rax=Local*
		"mov r13, rax\n"
		"mov rdi, [r13+0]\n" "mov rsi, [r13+8]\n"
		"mov rdx, [rsp+0]\n" "mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n" "jnz .found\n"
		"jmp .scan\n"

		".found:\n"
		"mov rax, r13\n"
		"mov rdx, 1\n"
		"jmp .done\n"
		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"
		".done:\n"
		"add rsp, 32\n"
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
		"jmp near .exit\n"
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
		"jmp near .exit\n"
		".s_bss:  db 'section .bss', 10, 0\n"
		".s_def:  db ': resq 1', 10, 0\n"
		".s_text: db 'section .text', 10, 0\n"
		".exit:\n"
	};
}

func vars_define_data_if_needed(label_sl, init_value) {
	// Ensure `label_sl` is defined in .data exactly once (as qword).
	// Convention: rdi = Slice*, rsi = init_value(u64)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=label_sl [8]=init [16]=vec [24]=n

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"call vars_init_if_needed\n"
		"mov r12, [rel vars_emitted]\n"
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
		// Emit data definition and remember it.
		"lea rdi, [rel .s_data]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+0]\n"
		"call slice_parts\n"      // rax=ptr rdx=len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call emit_str\n"
		"lea rdi, [rel .s_def]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"     // init_value
		"call emit_u64\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_text]\n"
		"call emit_cstr\n"

		// vec_push(vec, label_sl)
		"mov rdi, [rsp+16]\n"
		"mov rsi, [rsp+0]\n"
		"call vec_push\n"

		".done:\n"
		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_data: db 'section .data', 10, 0\n"
		".s_def:  db ': dq ', 0\n"
		".s_nl:   db 10, 0\n"
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
		"sub rsp, 80\n" // [0]=p [8]=name_ptr [16]=name_len [24]=tmp0 [32]=tmp1 [40]=tmp2 [48]=tmp3
		"mov [rsp+0], rdi\n"
		"mov r12, rdi\n"

		"mov rax, [r12+8]\n"   // kind
		"cmp rax, 2\n"          // TOK_INT
		"je .int\n"
		"cmp rax, 3\n"          // TOK_STR
		"je .str\n"
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
		// builtin cast(Type, expr)
		"mov rdi, [rsp+8]\n"     // name_ptr
		"mov rsi, [rsp+16]\n"    // name_len
		"lea rdx, [rel .s_cast]\n"
		"mov rcx, 4\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .not_cast\n"
		"mov rdi, r12\n"
		"call parser_peek_kind\n" // next kind
		"cmp rax, 30\n"          // '('
		"jne .not_cast\n"
		"jmp .cast_builtin\n"
		".not_cast:\n"

		// builtin sizeof(T)
		"mov rdi, [rsp+8]\n"     // name_ptr
		"mov rsi, [rsp+16]\n"    // name_len
		"lea rdx, [rel .s_sizeof]\n"
		"mov rcx, 6\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .not_sizeof\n"
		"mov rdi, r12\n" "call parser_peek_kind\n" // next
		"cmp rax, 30\n" // '('
		"jne .not_sizeof\n"
		"jmp .sizeof_builtin\n"
		".not_sizeof:\n"

		// builtin offsetof(T, field)
		"mov rdi, [rsp+8]\n"     // name_ptr
		"mov rsi, [rsp+16]\n"    // name_len
		"lea rdx, [rel .s_offsetof]\n"
		"mov rcx, 8\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"jz .not_offsetof\n"
		"mov rdi, r12\n" "call parser_peek_kind\n" // next
		"cmp rax, 30\n" // '('
		"jne .not_offsetof\n"
		"jmp .offsetof_builtin\n"
		".not_offsetof:\n"

		// Call? IDENT '(' ... ')'
		"mov rdi, r12\n"
		"call parser_peek_kind\n" // rax=next kind
		"cmp rax, 30\n"          // TOK_LPAREN
		"je .call\n"
		// Dotted const? IDENT '.' IDENT
		"cmp rax, 38\n"          // TOK_DOT
		"je .dotted_const\n"
		// Ptr field? IDENT '->' IDENT
		"cmp rax, 72\n"          // TOK_ARROW
		"je .arrow_field\n"
		// ptr8/ptr64 load? IDENT '[' ... ']'
		"cmp rax, 34\n"          // TOK_LBRACK
		"je .maybe_ptr_load\n"
		"jmp .var_load\n"
		".dotted_const:\n"
		// Consume first ident
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// Consume '.'
		"mov rax, [r12+8]\n" "cmp rax, 38\n" "je .dc_dot_ok\n" "call die_expr_expected_factor\n"
		".dc_dot_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// Second ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .dc_id2_ok\n" "call die_expr_expected_factor\n"
		".dc_id2_ok:\n"
		"mov r13, [r12+16]\n" // p2
		"mov rbx, [r12+24]\n" // n2
		"mov rdi, r12\n" "call parser_next\n" // consume second ident
		"mov r12, [rsp+0]\n"
		// full = concat(p1, '.', p2)
		"lea rdi, [rel .s_dot]\n"
		"mov rsi, 1\n"
		"call slice_to_cstr\n"  // rax=dot_ptr
		"mov rdx, rax\n"
		"mov rdi, [rsp+8]\n"   // p1
		"mov rsi, [rsp+16]\n"  // n1
		"mov rcx, 1\n"
		"call str_concat\n"     // rax=tmp_ptr, rdx=tmp_len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"mov rdx, r13\n"        // p2
		"mov rcx, rbx\n"        // n2
		"call str_concat\n"     // rax=full_ptr, rdx=full_len
		"mov rdi, rax\n"
		"mov rsi, rdx\n"
		"call consts_get\n"     // rax=value, rdx=found
		"test rdx, rdx\n"
		"jnz .dc_found\n"
		"jmp .dc_not_const\n"
		".dc_found:\n"
		"mov r13, rax\n"       // value
		"lea rdi, [rel .s_mov_imm]\n"
		"call emit_cstr\n"
		"mov rdi, r13\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".dc_not_const:\n"
		// Treat as struct field access: <ident>.<field>
		// base local must be typed as struct (non-pointer).
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+16]\n" "call locals_get_entry\n" // rax=Local*
		"test rdx, rdx\n" "jnz .sf_have_local\n"
		"call die_expr_undefined_ident\n"
		".sf_have_local:\n"
		"mov [rsp+24], rax\n" // tmp0 = Local*
		"mov r15, rax\n"
		"mov rax, [r15+32]\n" "test rax, rax\n" "jnz .sf_has_type\n" "call die_struct_field_access_needs_type\n"
		".sf_has_type:\n"
		"mov rax, [r15+48]\n" "test rax, rax\n" "jz .sf_dot_ok\n" "call die_struct_field_access_needs_type\n"
		".sf_dot_ok:\n"
		// struct_size = structs_get(type)->size
		"mov rdi, [r15+32]\n" "mov rsi, [r15+40]\n" "call structs_get\n" // rax=StructDef*, rdx=found
		"test rdx, rdx\n" "jnz .sf_def_ok\n" "call die_struct_by_value_incomplete\n"
		".sf_def_ok:\n"
		"mov rax, [rax+24]\n" "mov [rsp+56], rax\n" // tmp4 = struct_size (aligned)
		"mov rdi, [r15+32]\n" "mov rsi, [r15+40]\n" // type
		"mov rdx, r13\n" "mov rcx, rbx\n" // field
		"call structs_get_field\n"
		"test rdx, rdx\n" "jnz .sf_field_ok\n"
		"call die_struct_unknown_field\n"
		".sf_field_ok:\n"
		"mov [rsp+32], rax\n" // tmp1 = Field*
		"mov rax, [rax+24]\n" "mov [rsp+48], rax\n" // tmp3 = field_size
		"mov r15, [rsp+24]\n" // Local*
		// total_off = (local_off + struct_size - 8) - field_off
		"mov rax, [r15+16]\n" // local_off (top qword)
		"mov rdx, [rsp+56]\n" // struct_size
		"add rax, rdx\n"
		"sub rax, 8\n"
		"mov rdx, [rsp+32]\n" // Field*
		"mov rdx, [rdx+16]\n" // field_off
		"sub rax, rdx\n"
		"mov [rsp+40], rax\n" // tmp2 = total_off
		// emit: load sized field from [rbp-total_off] into rax (zero-extend for <8), then push rax
		"mov rax, [rsp+48]\n" // field_size
		"cmp rax, 1\n" "je .sf_load1\n"
		"cmp rax, 2\n" "je .sf_load2\n"
		"cmp rax, 4\n" "je .sf_load4\n"
		"cmp rax, 8\n" "je .sf_load8\n"
		"call die_struct_field_not_qword\n"
		".sf_load1:\n"
		"lea rdi, [rel .s_movzx_eax_rbpb0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+40]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .sf_load_done\n"
		".sf_load2:\n"
		"lea rdi, [rel .s_movzx_eax_rbpw0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+40]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .sf_load_done\n"
		".sf_load4:\n"
		"lea rdi, [rel .s_mov_eax_rbpd0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+40]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .sf_load_done\n"
		".sf_load8:\n"
		"lea rdi, [rel .s_mov_rax_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [rsp+40]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		".sf_load_done:\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".arrow_field:\n"
		// Parse and emit: <ident>-><field> (qword)
		// Consume first ident
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// Consume '->'
		"mov rax, [r12+8]\n" "cmp rax, 72\n" "je .ar_ok\n" "call die_expr_expected_factor\n"
		".ar_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// Field ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .ar_f_ok\n" "call die_expr_expected_factor\n"
		".ar_f_ok:\n"
		"mov r13, [r12+16]\n" // field_ptr
		"mov rbx, [r12+24]\n" // field_len
		"mov rdi, r12\n" "call parser_next\n" // consume field
		"mov r12, [rsp+0]\n"
		// base local must be typed as *struct
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+16]\n" "call locals_get_entry\n" // rax=Local*
		"test rdx, rdx\n" "jnz .ar_have_local\n" "call die_expr_undefined_ident\n"
		".ar_have_local:\n"
		"mov r15, rax\n"
		"mov rax, [r15+32]\n" "test rax, rax\n" "jnz .ar_has_type\n" "call die_struct_field_access_needs_type\n"
		".ar_has_type:\n"
		"mov rax, [r15+48]\n" "test rax, rax\n" "jnz .ar_ptr_ok\n" "call die_struct_field_access_needs_type\n"
		".ar_ptr_ok:\n"
		"mov rdi, [r15+32]\n" "mov rsi, [r15+40]\n" // type
		"mov rdx, r13\n" "mov rcx, rbx\n" // field
		"call structs_get_field\n"
		"test rdx, rdx\n" "jnz .ar_field_ok\n" "call die_struct_unknown_field\n"
		".ar_field_ok:\n"
		"mov r14, rax\n" // Field*
		"mov rax, [r14+24]\n" "mov [rsp+48], rax\n" // tmp3 = field_size
		// emit: mov rax, qword [rbp-off]; mov{zx}/mov rax/eax, [rax+field_off]; push rax
		"lea rdi, [rel .s_mov_rax_rbp0]\n" "call emit_cstr\n"
		"mov rdi, [r15+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"mov rax, [rsp+48]\n" // field_size
		"cmp rax, 1\n" "je .ar_load1\n"
		"cmp rax, 2\n" "je .ar_load2\n"
		"cmp rax, 4\n" "je .ar_load4\n"
		"cmp rax, 8\n" "je .ar_load8\n"
		"call die_struct_field_not_qword\n"
		".ar_load1:\n"
		"lea rdi, [rel .s_movzx_eax_rax_b0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .ar_load_done\n"
		".ar_load2:\n"
		"lea rdi, [rel .s_movzx_eax_rax_w0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .ar_load_done\n"
		".ar_load4:\n"
		"lea rdi, [rel .s_mov_eax_rax_d0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"jmp .ar_load_done\n"
		".ar_load8:\n"
		"lea rdi, [rel .s_mov_rax_rax0]\n" "call emit_cstr\n"
		"mov rdi, [r14+16]\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		".ar_load_done:\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".cast_builtin:\n"
		// consume 'cast'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '('
		"mov rax, [r12+8]\n" "cmp rax, 30\n" "je .cast_lp_ok\n" "call die_expr_expected_lparen\n"
		".cast_lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// type ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .cast_ty_ok\n" "call die_expr_expected_factor\n"
		".cast_ty_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+24], rax\n" // ty_ptr
		"mov rax, [r12+24]\n" "mov [rsp+32], rax\n" // ty_len
		"mov rdi, r12\n" "call parser_next\n" // consume type
		"mov r12, [rsp+0]\n"
		// expect ','
		"mov rax, [r12+8]\n" "cmp rax, 37\n" "je .cast_comma_ok\n" "call die_expr_expected_comma\n"
		".cast_comma_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ','
		"mov r12, [rsp+0]\n"
		// parse expr
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"
		// expect ')'
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .cast_rp_ok\n" "call die_expr_expected_rparen\n"
		".cast_rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ')'
		"mov r12, [rsp+0]\n"
		// apply cast: pop rax; mask; push rax
		"lea rdi, [rel .s_pop_rax]\n" "call emit_cstr\n"
		"mov rdi, [rsp+24]\n" // ty_ptr
		"mov rsi, [rsp+32]\n" // ty_len
		"lea rdx, [rel .s_u8]\n" "mov rcx, 2\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .cast_u8\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n"
		"lea rdx, [rel .s_u16]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .cast_u16\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n"
		"lea rdx, [rel .s_u32]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .cast_u32\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n"
		"lea rdx, [rel .s_u64]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .cast_u64\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n"
		"lea rdx, [rel .s_i64]\n" "mov rcx, 3\n" "call slice_eq_parts\n"
		"test rax, rax\n" "jnz .cast_u64\n" // treat i64 as no-op for now
		"call die_expr_expected_factor\n" // unknown type
		".cast_u8:\n"
		"lea rdi, [rel .s_and_u8]\n" "call emit_cstr\n" "jmp .cast_push\n"
		".cast_u16:\n"
		"lea rdi, [rel .s_and_u16]\n" "call emit_cstr\n" "jmp .cast_push\n"
		".cast_u32:\n"
		"lea rdi, [rel .s_and_u32]\n" "call emit_cstr\n" "jmp .cast_push\n"
		".cast_u64:\n"
		"jmp .cast_push\n"
		".cast_push:\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".sizeof_builtin:\n"
		// consume 'sizeof'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '('
		"mov rax, [r12+8]\n" "cmp rax, 30\n" "je .sz_lp_ok\n" "call die_expr_expected_lparen\n"
		".sz_lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// optional '*'
		"mov qword [rsp+48], 0\n" // tmp3 = is_ptr
		"mov rax, [r12+8]\n" "cmp rax, 42\n" "jne .sz_no_star\n"
		"mov qword [rsp+48], 1\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		".sz_no_star:\n"
		// type ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .sz_ty_ok\n" "call die_expr_expected_factor\n"
		".sz_ty_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+24], rax\n" // ty_ptr
		"mov rax, [r12+24]\n" "mov [rsp+32], rax\n" // ty_len
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ')'
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .sz_rp_ok\n" "call die_expr_expected_rparen\n"
		".sz_rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// compute size -> r13
		"mov r13, 8\n" // default
		"mov rax, [rsp+48]\n" "test rax, rax\n" "jnz .sz_emit\n" // pointer => 8
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "lea rdx, [rel .s_u8]\n" "mov rcx, 2\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .sz_u8\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "lea rdx, [rel .s_u16]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .sz_u16\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "lea rdx, [rel .s_u32]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .sz_u32\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "lea rdx, [rel .s_u64]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .sz_u64\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "lea rdx, [rel .s_i64]\n" "mov rcx, 3\n" "call slice_eq_parts\n" "test rax, rax\n" "jnz .sz_u64\n"
		// struct size
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "call structs_get\n"
		"test rdx, rdx\n" "jnz .sz_struct_ok\n"
		"call die_struct_unknown\n"
		".sz_struct_ok:\n"
		"mov r13, [rax+24]\n" "jmp .sz_emit\n"
		".sz_u8:\n"  "mov r13, 1\n" "jmp .sz_emit\n"
		".sz_u16:\n" "mov r13, 2\n" "jmp .sz_emit\n"
		".sz_u32:\n" "mov r13, 4\n" "jmp .sz_emit\n"
		".sz_u64:\n" "mov r13, 8\n"
		".sz_emit:\n"
		"lea rdi, [rel .s_mov_imm]\n" "call emit_cstr\n"
		"mov rdi, r13\n" "call emit_u64\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".offsetof_builtin:\n"
		// consume 'offsetof'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '('
		"mov rax, [r12+8]\n" "cmp rax, 30\n" "je .of_lp_ok\n" "call die_expr_expected_lparen\n"
		".of_lp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// type ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .of_ty_ok\n" "call die_expr_expected_factor\n"
		".of_ty_ok:\n"
		"mov rax, [r12+16]\n" "mov [rsp+24], rax\n" // ty_ptr
		"mov rax, [r12+24]\n" "mov [rsp+32], rax\n" // ty_len
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ','
		"mov rax, [r12+8]\n" "cmp rax, 37\n" "je .of_comma_ok\n" "call die_expr_expected_comma\n"
		".of_comma_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// field ident
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .of_f_ok\n" "call die_expr_expected_factor\n"
		".of_f_ok:\n"
		"mov rdx, [r12+16]\n" "mov rcx, [r12+24]\n"
		"mov rdi, [rsp+24]\n" "mov rsi, [rsp+32]\n" "call structs_get_field\n"
		"test rdx, rdx\n" "jnz .of_found\n"
		"call die_struct_unknown_field\n"
		".of_found:\n"
		"mov r13, [rax+16]\n" // field_off
		// consume field
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ')'
		"mov rax, [r12+8]\n" "cmp rax, 31\n" "je .of_rp_ok\n" "call die_expr_expected_rparen\n"
		".of_rp_ok:\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// emit immediate
		"lea rdi, [rel .s_mov_imm]\n" "call emit_cstr\n"
		"mov rdi, r13\n" "call emit_u64\n"
		"lea rdi, [rel .s_nl]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

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
		"call locals_get\n" // rax=off, rdx=found
		"test rdx, rdx\n"
		"jnz .addr_found\n"
		"call die_expr_undefined_ident\n"
		".addr_found:\n"
		"mov r13, rax\n" // off
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
		"jmp .array_load\n"

		".array_load:\n"
		// IDENT '[' expr ']' => load qword from local array base + index*8
		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect '['
		"mov rax, [r12+8]\n"
		"cmp rax, 34\n"          // TOK_LBRACK
		"je .arr_lb_ok\n"
		"call die_expr_expected_lbrack\n"
		".arr_lb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume '['
		"mov r12, [rsp+0]\n"
		// index expr
		"mov rdi, r12\n" "call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"
		// expect ']'
		"mov rax, [r12+8]\n"
		"cmp rax, 35\n"          // TOK_RBRACK
		"je .arr_rb_ok\n"
		"call die_expr_expected_rbrack\n"
		".arr_rb_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ']'
		"mov r12, [rsp+0]\n"
		// resolve base offset
		"mov rdi, [rsp+8]\n"  // name_ptr
		"mov rsi, [rsp+16]\n" // name_len
		"call locals_get\n"     // rax=off, rdx=found
		"test rdx, rdx\n"
		"jnz .arr_off_ok\n"
		"call die_expr_undefined_ident\n"
		".arr_off_ok:\n"
		"mov r13, rax\n" // off
		// emit load: pop r10; lea r11,[rbp-off]; lea r11,[r11+r10*8]; mov rax,[r11]; push rax
		"lea rdi, [rel .s_pop_rbx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_lea_r11_rbp0]\n" "call emit_cstr\n"
		"mov rdi, r13\n" "call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_lea_r11_idx]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_mov_rax_r11]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

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
		"call locals_get\n" // rax=off, rdx=found
		"test rdx, rdx\n"
		"jnz .var_local_found\n"
		// Fall back to global var slot v_<ident>
		"mov rdi, [r12+16]\n"  // name_ptr
		"mov rsi, [r12+24]\n"  // name_len
		"call var_label_from_ident\n" // rax=Slice*
		"mov r13, rax\n"
		"mov rdi, r13\n"
		"call vars_define_if_needed\n"
		"lea rdi, [rel .s_push_mem]\n"
		"call emit_cstr\n"
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_rbr]\n"
		"call emit_cstr\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"
		".var_local_found:\n"
		"mov r13, rax\n"        // off
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

		// --- scan args to collect start positions, then replay in reverse order ---
		// save emit_len so scan output can be discarded
		"mov rax, [rel emit_len]\n"
		"mov [rsp+40], rax\n"

		// arg_starts = vec_new(8)
		"mov rdi, 8\n"
		"call vec_new\n"
		"mov [rsp+24], rax\n" // Vec* arg_starts
		"mov r12, [rsp+0]\n"

		// empty args? if next is ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n"          // TOK_RPAREN
		"je .call_scan_done\n"

		".call_scan_loop:\n"
		// record ArgStart {tok_ptr, tok_line}
		"mov rdi, 16\n"
		"call heap_alloc\n" // rax=ArgStart*
		"mov r12, [rsp+0]\n" // be conservative about helper clobbers
		"mov r13, rax\n"
		"mov r8,  [r12+16]\n" // tok_ptr
		"mov r9,  [r12+32]\n" // tok_line
		"mov [r13+0], r8\n"
		"mov [r13+8], r9\n"
		"mov rdi, [rsp+24]\n"
		"mov rsi, r13\n"
		"call vec_push\n"
		"mov r12, [rsp+0]\n"

		// parse one arg expr (scan)
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"mov r12, [rsp+0]\n"

		// if ',' then consume and continue
		"mov rax, [r12+8]\n"
		"cmp rax, 37\n"          // TOK_COMMA
		"jne .call_scan_done\n"
		"mov rdi, r12\n"
		"call parser_next\n"      // consume ','
		"mov r12, [rsp+0]\n"
		"jmp .call_scan_loop\n"

		".call_scan_done:\n"
		// expect ')'
		"mov rax, [r12+8]\n"
		"cmp rax, 31\n"          // TOK_RPAREN
		"je .call_scan_rp_ok\n"
		"call die_expr_expected_rparen_call_scan\n"
		".call_scan_rp_ok:\n"
		// save lexer state *after* the closing ')'
		"mov rbx, [r12+0]\n"   // lex*
		"mov rax, [rbx+0]\n"   // cur (already advanced past ')')
		"mov [rsp+32], rax\n"  // after_rp_cur
		"mov rax, [rbx+16]\n"  // line
		"mov [rsp+48], rax\n"  // after_rp_line

		// discard scan emissions
		"mov rax, [rsp+40]\n"
		"mov [rel emit_len], rax\n"

		// argc = vec_len(arg_starts)
		"mov rdi, [rsp+24]\n"
		"call vec_len\n"
		"mov [rsp+40], rax\n" // argc
		"mov r12, [rsp+0]\n"

		// stack_args = max(argc-6,0)
		"mov rax, [rsp+40]\n"
		"cmp rax, 6\n"
		"jbe .call_no_stack\n"
		"sub rax, 6\n"
		"mov [rsp+64], rax\n" // stack_args
		"jmp .call_stack_ready\n"
		".call_no_stack:\n"
		"xor eax, eax\n"
		"mov [rsp+64], rax\n"
		".call_stack_ready:\n"

		// if stack_args is odd, pad 8 bytes so rsp stays 16-aligned at call
		"mov rax, [rsp+64]\n"
		"test rax, rax\n"
		"jz .call_emit_args\n"
		"test rax, 1\n"
		"jz .call_emit_args\n"
		"lea rdi, [rel .s_sub_rsp8]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"

		".call_emit_args:\n"
		// replay-parse args in reverse order: i = argc-1 .. 0
		"mov rax, [rsp+40]\n"
		"test rax, rax\n"
		"jz .call_after_args\n"
		"dec rax\n"
		"mov [rsp+56], rax\n" // i
		".call_emit_loop:\n"
		"mov rdi, [rsp+24]\n" // vec
		"mov rsi, [rsp+56]\n"
		"call vec_get\n" // rax=ArgStart*
		"mov r12, [rsp+0]\n" // be conservative
		// restore lexer to arg start
		"mov rbx, [r12+0]\n"  // lex*
		"mov rdx, [rax+0]\n"  // ptr
		"mov [rbx+0], rdx\n"
		"mov rdx, [rax+8]\n"  // line
		"mov [rbx+16], rdx\n"
		"mov rdi, r12\n"
		"call parser_next\n"
		"mov r12, [rsp+0]\n"

		// parse expr and pop into rax
		"mov rdi, r12\n"
		"call expr_parse_bor_emit\n"
		"lea rdi, [rel .s_pop_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"

		// i < 6 ? move into reg : push on stack
		"mov rax, [rsp+56]\n"
		"cmp rax, 6\n"
		"jb .call_arg_reg\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		"jmp .call_arg_done\n"
		".call_arg_reg:\n"
		"mov rax, [rsp+56]\n"
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
		".call_arg_done:\n"

		// next i--
		"mov rax, [rsp+56]\n"
		"test rax, rax\n"
		"jz .call_after_args\n"
		"dec rax\n"
		"mov [rsp+56], rax\n"
		"jmp .call_emit_loop\n"

		".call_after_args:\n"
		// restore lexer to *after* ')', then prime next token
		"mov r12, [rsp+0]\n"
		"mov rbx, [r12+0]\n"  // lex*
		"mov rax, [rsp+32]\n"  // after_rp_cur
		"mov [rbx+0], rax\n"
		"mov rax, [rsp+48]\n"  // after_rp_line
		"mov [rbx+16], rax\n"
		"mov rdi, r12\n"
		"call parser_next\n"     // now p is at token after ')'
		"mov r12, [rsp+0]\n"
		"jmp .call_emit_call\n"

		".call_emit_call:\n"
		// emit: call <name>\n then push rax
		"lea rdi, [rel .s_call]\n"
		"call emit_cstr\n"
		"mov rdi, [rsp+8]\n"
		"mov rsi, [rsp+16]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call emit_cstr\n"

		// caller cleanup for stack args (+ optional alignment pad)
		"mov rax, [rsp+40]\n" // argc
		"cmp rax, 6\n"
		"jbe .call_no_cleanup\n"
		"sub rax, 6\n"          // stack_args
		"mov rbx, rax\n"
		"shl rbx, 3\n"          // bytes = stack_args*8
		"test rax, 1\n"
		"jz .call_cleanup_emit\n"
		"add rbx, 8\n"          // include pad
		".call_cleanup_emit:\n"
		"lea rdi, [rel .s_add_rsp0]\n"
		"call emit_cstr\n"
		"mov rdi, rbx\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_add_rsp1]\n"
		"call emit_cstr\n"
		"mov r12, [rsp+0]\n"
		".call_no_cleanup:\n"

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
		"jmp .done\n"

		".str:\n"
		// String literal: allocate label in .rodata, push its address.
		"mov rdi, [r12+16]\n" // tok_ptr
		"mov rsi, [r12+24]\n" // tok_len
		"call rodata_add_string\n" // rax=label_id
		"mov r13, rax\n"
		"lea rdi, [rel .s_lea_rax_str]\n" "call emit_cstr\n"
		"mov rdi, r13\n" "call emit_u64\n"
		"lea rdi, [rel .s_lea_rax_str1]\n" "call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n" "call emit_cstr\n"
		// consume string
		"mov r12, [rsp+0]\n"
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .done\n"

		".done:\n"
		"add rsp, 80\n"
		"pop r13\n"
		"pop r12\n"
		"jmp near .exit\n"

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
		".s_sub_rsp8: db '  sub rsp, 8', 10, 0\n"
		".s_add_rsp0: db '  add rsp, ', 0\n"
		".s_add_rsp1: db 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_nl:   db 10, 0\n"
		".s_addr: db 'addr', 0\n"
		".s_ptr8:  db 'ptr8', 0\n"
		".s_ptr64: db 'ptr64', 0\n"
		".s_lea_rax0: db '  lea rax, [rel ', 0\n"
		".s_lea_rax1: db ']', 10, 0\n"
		".s_lea_r11_rbp0: db '  lea r11, [rbp-', 0\n"
		".s_lea_r11_idx:  db '  lea r11, [r11+r10*8]', 10, 0\n"
		".s_mov_rax_r11:  db '  mov rax, qword [r11]', 10, 0\n"
		".s_lea_rax_str:  db '  lea rax, [rel str_', 0\n"
		".s_lea_rax_str1: db ']', 10, 0\n"
		".s_dot:     db '.', 0\n"
		".s_cast:    db 'cast', 0\n"
		".s_sizeof:  db 'sizeof', 0\n"
		".s_offsetof: db 'offsetof', 0\n"
		".s_and_u8:  db '  and rax, 255', 10, 0\n"
		".s_and_u16: db '  and rax, 65535', 10, 0\n"
		".s_and_u32: db '  and rax, 4294967295', 10, 0\n"
		".s_u8:      db 'u8', 0\n"
		".s_u16:     db 'u16', 0\n"
		".s_u32:     db 'u32', 0\n"
		".s_u64:     db 'u64', 0\n"
		".s_i64:     db 'i64', 0\n"
		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_load8:    db '  movzx rax, byte [r10]', 10, 0\n"
		".s_load64:   db '  mov rax, qword [r10]', 10, 0\n"
		".s_mov_rax_rbp0: db '  mov rax, qword [rbp-', 0\n"
		".s_mov_rax_rax0: db '  mov rax, qword [rax+', 0\n"
		".s_movzx_eax_rbpb0: db '  movzx eax, byte [rbp-', 0\n"
		".s_movzx_eax_rbpw0: db '  movzx eax, word [rbp-', 0\n"
		".s_mov_eax_rbpd0:    db '  mov eax, dword [rbp-', 0\n"
		".s_movzx_eax_rax_b0: db '  movzx eax, byte [rax+', 0\n"
		".s_movzx_eax_rax_w0: db '  movzx eax, word [rax+', 0\n"
		".s_mov_eax_rax_d0:   db '  mov eax, dword [rax+', 0\n"
		".exit:\n"
	};
}

func expr_parse_unary_emit(p) {
	// unary := ('+'|'-'|'~'|'!'|'&'|'*') unary | factor
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
		"cmp rax, 60\n"         // TOK_AND ('&')
		"je .uaddr\n"
		"cmp rax, 42\n"         // TOK_STAR ('*')
		"je .uderef\n"
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

		".uaddr:\n"
		// address-of: &ident => push address of local slot
		"mov rdi, r12\n"
		"call parser_next\n"      // consume '&'
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n"            // TOK_IDENT
		"je .uaddr_id_ok\n"
		"call die_expr_expected_factor\n"
		".uaddr_id_ok:\n"
		// locals_get_entry(name_ptr,name_len)
		"mov rdi, [r12+16]\n"
		"mov rsi, [r12+24]\n"
		"call locals_get_entry\n"       // rax=Local*, rdx=found
		"test rdx, rdx\n"
		"jnz .uaddr_off_ok\n"
		// Fall back to global var slot v_<ident>
		"mov rdi, [r12+16]\n"  // name_ptr
		"mov rsi, [r12+24]\n"  // name_len
		"call var_label_from_ident\n" // rax=Slice*
		"mov r13, rax\n"
		"mov rdi, r13\n"
		"call vars_define_if_needed\n"
		"lea rdi, [rel .s_lea_rax0]\n"
		"call emit_cstr\n"
		"mov rdi, [r13+0]\n"
		"mov rsi, [r13+8]\n"
		"call emit_str\n"
		"lea rdi, [rel .s_lea_rax1]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		// consume IDENT
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"
		".uaddr_off_ok:\n"
		"mov r13, rax\n"          // Local*
		// emit: lea rax, [rbp-off]; for by-value struct locals, use base address (low end)
		"mov rbx, [r13+16]\n"     // off
		"mov rax, [r13+48]\n" "test rax, rax\n" "jnz .uaddr_use_off\n" // if pointer-typed, keep slot address
		"mov rax, [r13+32]\n" "test rax, rax\n" "jz .uaddr_use_off\n" // if untyped, keep slot address
		"mov rdi, [r13+32]\n" "mov rsi, [r13+40]\n" "call structs_get\n" // rax=StructDef*, rdx=found
		"test rdx, rdx\n" "jz .uaddr_use_off\n"
		"mov rax, [rax+24]\n" // struct_size (aligned, >=8)
		"add rbx, rax\n"
		"sub rbx, 8\n" // base_low_off
		".uaddr_use_off:\n"
		// emit: lea rax, [rbp-rbx]; push rax
		"lea rdi, [rel .s_lea_rbp0]\n"
		"call emit_cstr\n"
		"mov rdi, rbx\n"
		"call emit_u64\n"
		"lea rdi, [rel .s_rbr]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_push_rax]\n"
		"call emit_cstr\n"
		// consume ident
		"mov rdi, r12\n"
		"call parser_next\n"
		"jmp .done\n"

		".uderef:\n"
		// deref load: *expr => load qword [expr]
		"mov rdi, r12\n"
		"call parser_next\n"      // consume '*'
		"mov rdi, r12\n"
		"call expr_parse_unary_emit\n"  // parse inner unary (address expr)
		// emit: pop r10; mov rax, qword [r10]; push rax
		"lea rdi, [rel .s_pop_r10]\n"
		"call emit_cstr\n"
		"lea rdi, [rel .s_load64_r10]\n"
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
		"jmp near .exit\n"

		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_neg:      db '  neg rax', 10, 0\n"
		".s_not:      db '  not rax', 10, 0\n"
		".s_test:     db '  test rax, rax', 10, 0\n"
		".s_sete:     db '  sete al', 10, 0\n"
		".s_movzx:    db '  movzx rax, al', 10, 0\n"
		".s_push_rax: db '  push rax', 10, 0\n"
		".s_lea_rax0: db '  lea rax, [rel ', 0\n"
		".s_lea_rax1: db ']', 10, 0\n"
		".s_mov_imm:  db '  mov rax, ', 0\n"
		".s_pop_r10:      db '  pop r10', 10, 0\n"
		".s_load64_r10:   db '  mov rax, qword [r10]', 10, 0\n"
		".s_lea_rbp0:     db '  lea rax, [rbp-', 0\n"
		".s_rbr:          db ']', 10, 0\n"
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
		"jmp near .exit\n"

		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_imul:     db '  imul rax, r10', 10, 0\n"
		".s_xor_rdx:  db '  xor rdx, rdx', 10, 0\n"
		".s_div:      db '  div r10', 10, 0\n"
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
		"jmp near .exit\n"

		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_add:      db '  add rax, r10', 10, 0\n"
		".s_sub:      db '  sub rax, r10', 10, 0\n"
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
		"jmp near .exit\n"
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
		"jmp near .exit\n"
		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_cmp:      db '  cmp rax, r10', 10, 0\n"
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
		"jmp near .exit\n"
		".s_pop_rbx:  db '  pop r10', 10, 0\n"
		".s_pop_rax:  db '  pop rax', 10, 0\n"
		".s_cmp:      db '  cmp rax, r10', 10, 0\n"
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
		"jmp near .exit\n"
		".s_pop_rbx: db '  pop r10', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_and:     db '  and rax, r10', 10, 0\n"
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
		"jmp near .exit\n"
		".s_pop_rbx: db '  pop r10', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_xor:     db '  xor rax, r10', 10, 0\n"
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
		"jmp near .exit\n"
		".s_pop_rbx: db '  pop r10', 10, 0\n"
		".s_pop_rax: db '  pop rax', 10, 0\n"
		".s_or:      db '  or rax, r10', 10, 0\n"
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
