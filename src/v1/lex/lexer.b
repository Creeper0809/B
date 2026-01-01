// v1 lexer
// Roadmap: docs/roadmap.md (5.2)
// Depends on: token.b, Slice/Vec, std utils
// Planned:
// - line_num tracking
// - // comment skip
// - string/char escapes
// - asm { ... } raw token
// - longest match operators (&&, ||, ->, etc)

func lexer_new(p, n) {
	// Create a lexer over (ptr,len).
	// Convention: rdi=p, rsi=n
	// Returns: rax = Lexer*
	var p0;
	var n0;
	var lex;

	ptr64[p0] = rdi;
	ptr64[n0] = rsi;

	heap_alloc(24);
	ptr64[lex] = rax;

	alias r8 : cur;
	alias r9 : end;
	alias r10 : lp;
	alias r11 : addr;
	cur = ptr64[p0];
	end = cur;
	alias r12 : len0;
	len0 = ptr64[n0];
	end += len0;
	lp = ptr64[lex];
	addr = lp;
	ptr64[addr] = cur;
	addr = lp;
	addr += 8;
	ptr64[addr] = end;
	addr = lp;
	addr += 16;
	ptr64[addr] = 1;
	rax = lp;
}

func lexer_next(lex) {
	// Next token.
	// Convention: rdi = Lexer*
	// Returns:
	// - rax = kind
	// - rdx = ptr
	// - rcx = len
	// - r8  = line
	asm {
		// Preserve callee-saved regs (SysV): rbx, r12-r15
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"

		"mov r12, rdi\n"        // lex*
		"mov r13, [r12+0]\n"    // cur
		"mov r14, [r12+8]\n"    // end
		"mov r15, [r12+16]\n"   // line

		// skip whitespace/newlines/comments
		".skip:\n"
		"cmp r13, r14\n"
		"jae .eof\n"
		"mov al, [r13]\n"
		"cmp al, ' ' \n"
		"je .ws\n"
		"cmp al, 9\n"            // \t
		"je .ws\n"
		"cmp al, 13\n"           // \r
		"je .ws\n"
		"cmp al, 10\n"           // \n
		"je .nl\n"
		"cmp al, '/'\n"
		"jne .tok\n"
		"lea r8, [r13+1]\n"
		"cmp r8, r14\n"
		"jae .tok\n"
		"mov bl, [r8]\n"
		"cmp bl, '/'\n"
		"jne .tok\n"
		// comment: consume until newline or end
		"add r13, 2\n"
		".cmt:\n"
		"cmp r13, r14\n"
		"jae .skip\n"
		"mov al, [r13]\n"
		"cmp al, 10\n"
		"je .skip\n"
		"inc r13\n"
		"jmp .cmt\n"

		".ws:\n"
		"inc r13\n"
		"jmp .skip\n"
		".nl:\n"
		"inc r15\n"
		"inc r13\n"
		"jmp .skip\n"

		".eof:\n"
		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rax, 0\n"
		"mov rdx, r13\n"
		"xor rcx, rcx\n"
		"mov r8, r15\n"
		"jmp .ret\n"

		".tok:\n"
		"mov rbx, r13\n"         // start
		"mov al, [r13]\n"

		// ident/keyword or asm{...}
		"cmp al, '_'\n"
		"je .ident\n"
		"cmp al, 'A'\n"
		"jb .num_or_punct\n"
		"cmp al, 'Z'\n"
		"jbe .ident\n"
		"cmp al, 'a'\n"
		"jb .num_or_punct\n"
		"cmp al, 'z'\n"
		"jbe .ident\n"
		"jmp .num_or_punct\n"

		".ident:\n"
		"inc r13\n"
		".ident_loop:\n"
		"cmp r13, r14\n"
		"jae .ident_done\n"
		"mov al, [r13]\n"
		"cmp al, '_'\n"
		"je .ident_adv\n"
		"cmp al, '0'\n"
		"jb .ident_alpha\n"
		"cmp al, '9'\n"
		"jbe .ident_adv\n"
		".ident_alpha:\n"
		"cmp al, 'A'\n"
		"jb .ident_done\n"
		"cmp al, 'Z'\n"
		"jbe .ident_adv\n"
		"cmp al, 'a'\n"
		"jb .ident_done\n"
		"cmp al, 'z'\n"
		"ja .ident_done\n"
		".ident_adv:\n"
		"inc r13\n"
		"jmp .ident_loop\n"
		".ident_done:\n"

		// default kind = IDENT
		"mov rax, 1\n"
		"mov rcx, r13\n"
		"sub rcx, rbx\n"         // len

		// keyword checks by length + bytes
		// func
		"cmp rcx, 4\n"
		"jne .kw_var\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x636e7566\n"  // 'f''u''n''c'
		"jne .kw_var\n"
		"mov rax, 10\n"
		"jmp .ident_ret\n"
		".kw_var:\n"
		"cmp rcx, 3\n"
		"jne .kw_const\n"
		"mov r9d, dword [rbx]\n"
		"and r9d, 0x00ffffff\n"
		"cmp r9d, 0x00726176\n"  // 'v''a''r'
		"jne .kw_const\n"
		"mov rax, 11\n"
		"jmp .ident_ret\n"
		".kw_const:\n"
		"cmp rcx, 5\n"
		"jne .kw_alias\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x736e6f63\n"  // 'c''o''n''s'
		"jne .kw_alias\n"
		"mov r9b, [rbx+4]\n"
		"cmp r9b, 't'\n"
		"jne .kw_alias\n"
		"mov rax, 20\n"          // TOK_KW_CONST
		"jmp .ident_ret\n"
		".kw_alias:\n"
		"cmp rcx, 5\n"
		"jne .kw_if\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x61696c61\n"  // 'a''l''i''a'
		"jne .kw_if\n"
		"mov r9b, [rbx+4]\n"
		"cmp r9b, 's'\n"
		"jne .kw_if\n"
		"mov rax, 12\n"
		"jmp .ident_ret\n"
		".kw_if:\n"
		"cmp rcx, 2\n"
		"jne .kw_else\n"
		"mov r9w, word [rbx]\n"
		"cmp r9w, 0x6669\n"      // 'i''f'
		"jne .kw_else\n"
		"mov rax, 13\n"
		"jmp .ident_ret\n"
		".kw_else:\n"
		"cmp rcx, 4\n"
		"jne .kw_while\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x65736c65\n"  // 'e''l''s''e'
		"jne .kw_while\n"
		"mov rax, 14\n"
		"jmp .ident_ret\n"
		".kw_while:\n"
		"cmp rcx, 5\n"
		"jne .kw_break\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x6c696877\n"  // 'w''h''i''l'
		"jne .kw_break\n"
		"mov r9b, [rbx+4]\n"
		"cmp r9b, 'e'\n"
		"jne .kw_break\n"
		"mov rax, 15\n"
		"jmp .ident_ret\n"
		".kw_break:\n"
		"cmp rcx, 5\n"
		"jne .kw_continue\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x61657262\n"  // 'b''r''e''a'
		"jne .kw_continue\n"
		"mov r9b, [rbx+4]\n"
		"cmp r9b, 'k'\n"
		"jne .kw_continue\n"
		"mov rax, 16\n"
		"jmp .ident_ret\n"
		".kw_continue:\n"
		"cmp rcx, 8\n"
		"jne .kw_return\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x746e6f63\n"  // 'c''o''n''t'
		"jne .kw_return\n"
		"mov r9d, dword [rbx+4]\n"
		"cmp r9d, 0x65756e69\n"  // 'i''n''u''e'
		"jne .kw_return\n"
		"mov rax, 17\n"
		"jmp .ident_ret\n"
		".kw_return:\n"
		"cmp rcx, 6\n"
		"jne .kw_asm\n"
		"mov r9d, dword [rbx]\n"
		"cmp r9d, 0x75746572\n"  // 'r''e''t''u'
		"jne .kw_asm\n"
		"mov r9w, word [rbx+4]\n"
		"cmp r9w, 0x6e72\n"      // 'r''n'
		"jne .kw_asm\n"
		"mov rax, 18\n"
		"jmp .ident_ret\n"
		".kw_asm:\n"
		"cmp rcx, 3\n"
		"jne .ident_ret\n"
		"mov r9d, dword [rbx]\n"
		"and r9d, 0x00ffffff\n"
		"cmp r9d, 0x006d7361\n"  // 'a''s''m'
		"jne .ident_ret\n"
		// Potential asm { ... } raw token.
		"mov rsi, 19\n"
		"mov r9, r13\n"          // after 'asm'
		"mov r10, r15\n"         // line temp
		".asm_ws:\n"
		"cmp r9, r14\n"
		"jae .asm_not_raw\n"
		"mov al, [r9]\n"
		"cmp al, ' ' \n"
		"je .asm_ws_adv\n"
		"cmp al, 9\n"
		"je .asm_ws_adv\n"
		"cmp al, 13\n"
		"je .asm_ws_adv\n"
		"cmp al, 10\n"
		"jne .asm_ws_done\n"
		"inc r10\n"
		".asm_ws_adv:\n"
		"inc r9\n"
		"jmp .asm_ws\n"
		".asm_ws_done:\n"
		"cmp al, '{'\n"
		"jne .asm_not_raw\n"
		// scan until matching '}' (depth counter)
		"mov r11, 1\n"
		"inc r9\n"
		".asm_scan:\n"
		"cmp r9, r14\n"
		"jae .asm_not_raw\n"
		"mov al, [r9]\n"
		"cmp al, 10\n"
		"jne .asm_brace\n"
		"inc r10\n"
		".asm_brace:\n"
		"cmp al, '{'\n"
		"jne .asm_rbrace\n"
		"inc r11\n"
		"jmp .asm_adv\n"
		".asm_rbrace:\n"
		"cmp al, '}'\n"
		"jne .asm_adv\n"
		"dec r11\n"
		"test r11, r11\n"
		"jnz .asm_adv\n"
		"inc r9\n"              // include closing brace
		"mov r13, r9\n"         // token end
		"mov r15, r10\n"        // updated line
		"mov rcx, r13\n"
		"sub rcx, rbx\n"
		"mov rax, rsi\n"
		"jmp .ident_ret\n"
		".asm_adv:\n"
		"inc r9\n"
		"jmp .asm_scan\n"
		".asm_not_raw:\n"
		// fall back to keyword 'asm' as IDENT (or treat as IDENT/keyword later)
		"mov rax, 1\n"
		"mov rcx, r13\n"
		"sub rcx, rbx\n"

		".ident_ret:\n"
		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rdx, rbx\n"
		"mov r8, r15\n"
		"jmp .ret\n"

		".num_or_punct:\n"
		// number
		"cmp al, '0'\n"
		"jb .punct\n"
		"cmp al, '9'\n"
		"jbe .number\n"
		"jmp .punct\n"

		".number:\n"
		// decimal or hex (0x...)
		"inc r13\n"              // after first digit
		"cmp byte [rbx], '0'\n"
		"jne .num_dec\n"
		"cmp r13, r14\n"
		"jae .num_dec\n"
		"mov al, [r13]\n"
		"cmp al, 'x'\n"
		"je .num_hex\n"
		"cmp al, 'X'\n"
		"je .num_hex\n"
		"jmp .num_dec\n"

		".num_hex:\n"
		"inc r13\n"              // consume x
		"mov r9, r13\n"          // first hex digit position
		".hex_loop:\n"
		"cmp r13, r14\n"
		"jae .hex_done\n"
		"mov al, [r13]\n"
		"cmp al, '0'\n"
		"jb .hex_done\n"
		"cmp al, '9'\n"
		"jbe .hex_adv\n"
		"cmp al, 'a'\n"
		"jb .hex_A\n"
		"cmp al, 'f'\n"
		"jbe .hex_adv\n"
		".hex_A:\n"
		"cmp al, 'A'\n"
		"jb .hex_done\n"
		"cmp al, 'F'\n"
		"ja .hex_done\n"
		".hex_adv:\n"
		"inc r13\n"
		"jmp .hex_loop\n"
		".hex_done:\n"
		// require at least 1 hex digit after 0x
		"cmp r13, r9\n"
		"jne .num_emit\n"
		"lea rdi, [rel .s_bad_hex]\n"
		"call die\n"
		"jmp .num_emit\n"

		".num_dec:\n"
		".num_loop:\n"
		"cmp r13, r14\n"
		"jae .num_emit\n"
		"mov al, [r13]\n"
		"cmp al, '0'\n"
		"jb .num_emit\n"
		"cmp al, '9'\n"
		"ja .num_emit\n"
		"inc r13\n"
		"jmp .num_loop\n"

		".num_emit:\n"
		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rax, 2\n"           // TOK_INT
		"mov rdx, rbx\n"
		"mov rcx, r13\n"
		"sub rcx, rbx\n"
		"mov r8, r15\n"
		"jmp .ret\n"

		".punct:\n"
		// string
		"cmp al, '\"'\n"
		"jne .char\n"
		"inc r13\n"
		".str_loop:\n"
		"cmp r13, r14\n"
		"jae .str_done\n"
		"mov al, [r13]\n"
		"cmp al, 10\n"
		"jne .str_esc\n"
		"inc r15\n"
		".str_esc:\n"
		"cmp al, 92\n"
		"jne .str_quote\n"
		"add r13, 2\n"
		"jmp .str_loop\n"
		".str_quote:\n"
		"cmp al, '\"'\n"
		"je .str_close\n"
		"inc r13\n"
		"jmp .str_loop\n"
		".str_close:\n"
		"inc r13\n"
		".str_done:\n"
		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rax, 3\n"
		"mov rdx, rbx\n"
		"mov rcx, r13\n"
		"sub rcx, rbx\n"
		"mov r8, r15\n"
		"jmp .ret\n"

		".char:\n"
		"cmp al, 39\n"
		"jne .op\n"
		// Convert single-quoted char literal into TOK_INT by allocating digits.
		// Supports: 'a', '\\n', '\\t', '\\r', '\\0', '\\\\', '\\''
		"inc r13\n"              // after opening '
		"cmp r13, r14\n"
		"jae .ch_bad\n"
		"mov al, [r13]\n"
		"cmp al, 92\n"           // '\\'
		"je .ch_esc\n"
		// plain: value = al
		"movzx r11, al\n"
		"inc r13\n"
		"jmp .ch_expect_quote\n"

		".ch_esc:\n"
		"inc r13\n"              // escape code
		"cmp r13, r14\n"
		"jae .ch_bad\n"
		"mov al, [r13]\n"
		"movzx r11, al\n"        // default: literal char
		"cmp al, 'n'\n" "jne .ch_t\n" "mov r11, 10\n" "jmp .ch_esc_done\n"
		".ch_t:\n"  "cmp al, 't'\n" "jne .ch_r\n" "mov r11, 9\n"  "jmp .ch_esc_done\n"
		".ch_r:\n"  "cmp al, 'r'\n" "jne .ch_0\n" "mov r11, 13\n" "jmp .ch_esc_done\n"
		".ch_0:\n"  "cmp al, '0'\n" "jne .ch_bs\n" "mov r11, 0\n"  "jmp .ch_esc_done\n"
		".ch_bs:\n" "cmp al, 92\n"  "jne .ch_sq\n" "mov r11, 92\n" "jmp .ch_esc_done\n"
		".ch_sq:\n" "cmp al, 39\n"  "jne .ch_esc_done\n" "mov r11, 39\n"
		".ch_esc_done:\n"
		"inc r13\n"

		".ch_expect_quote:\n"
		"cmp r13, r14\n"
		"jae .ch_bad\n"
		"mov al, [r13]\n"
		"cmp al, 39\n"           // closing '
		"je .ch_close\n"
		"jmp .ch_bad\n"
		".ch_close:\n"
		"inc r13\n"              // consume closing '

		// itoa_u64_dec(value)
		"mov rdi, r11\n"
		"call itoa_u64_dec\n"    // rax=ptr, rdx=len
		"mov r9, rax\n"
		"mov r10, rdx\n"

		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rax, 2\n"           // TOK_INT
		"mov rdx, r9\n"          // ptr
		"mov rcx, r10\n"         // len
		"mov r8, r15\n"
		"jmp .ret\n"

		".ch_bad:\n"
		"lea rdi, [rel .s_bad_char]\n"
		"call die\n"
		"jmp .eof\n"

		".op:\n"
		// multi-char ops: &&, ||, ==, !=, <=, >=, <<, >>, ->
		"mov rax, 0\n"
		"mov rcx, 1\n"
		"mov dl, [r13]\n"
		"lea r9, [r13+1]\n"
		"cmp r9, r14\n"
		"jae .op_single\n"
		"mov bl, [r9]\n"
		"cmp dl, '&'\n"
		"jne .op_or\n"
		"cmp bl, '&'\n"
		"jne .op_single\n"
		"mov rax, 65\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_or:\n"
		"cmp dl, '|'\n"
		"jne .op_eq\n"
		"cmp bl, '|'\n"
		"jne .op_single\n"
		"mov rax, 66\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_eq:\n"
		"cmp dl, '='\n"
		"jne .op_ne\n"
		"cmp bl, '='\n"
		"jne .op_single\n"
		"mov rax, 51\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_ne:\n"
		"cmp dl, '!'\n"
		"jne .op_le\n"
		"cmp bl, '='\n"
		"jne .op_single\n"
		"mov rax, 52\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_le:\n"
		"cmp dl, '<'\n"
		"jne .op_ge\n"
		"cmp bl, '='\n"
		"jne .op_shl\n"
		"mov rax, 55\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_shl:\n"
		"cmp bl, '<'\n"
		"jne .op_single\n"
		"mov rax, 70\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_ge:\n"
		"cmp dl, '>'\n"
		"jne .op_arrow\n"
		"cmp bl, '='\n"
		"jne .op_shr\n"
		"mov rax, 56\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_shr:\n"
		"cmp bl, '>'\n"
		"jne .op_single\n"
		"mov rax, 71\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"
		".op_arrow:\n"
		"cmp dl, '-'\n"
		"jne .op_single\n"
		"cmp bl, '>'\n"
		"jne .op_single\n"
		"mov rax, 72\n"
		"mov rcx, 2\n"
		"jmp .op_ret\n"

		".op_single:\n"
		"mov dl, [r13]\n"
		"cmp dl, '('\n"  "jne .s_rparen\n" "mov rax, 30\n" "jmp .op_ret\n"
		".s_rparen:\n" "cmp dl, ')'\n" "jne .s_lbrace\n" "mov rax, 31\n" "jmp .op_ret\n"
		".s_lbrace:\n" "cmp dl, '{'\n" "jne .s_rbrace\n" "mov rax, 32\n" "jmp .op_ret\n"
		".s_rbrace:\n" "cmp dl, '}'\n" "jne .s_lbrack\n" "mov rax, 33\n" "jmp .op_ret\n"
		".s_lbrack:\n" "cmp dl, '['\n" "jne .s_rbrack\n" "mov rax, 34\n" "jmp .op_ret\n"
		".s_rbrack:\n" "cmp dl, ']'\n" "jne .s_semi\n" "mov rax, 35\n" "jmp .op_ret\n"
		".s_semi:\n" "cmp dl, ';'\n" "jne .s_comma\n" "mov rax, 36\n" "jmp .op_ret\n"
		".s_comma:\n" "cmp dl, ','\n" "jne .s_dot\n" "mov rax, 37\n" "jmp .op_ret\n"
		".s_dot:\n" "cmp dl, '.'\n" "jne .s_plus\n" "mov rax, 38\n" "jmp .op_ret\n"
		".s_plus:\n" "cmp dl, ':'\n" "jne .s_plus_real\n" "mov rax, 39\n" "jmp .op_ret\n"
		".s_plus_real:\n" "cmp dl, '+'\n" "jne .s_minus\n" "mov rax, 40\n" "jmp .op_ret\n"
		".s_minus:\n" "cmp dl, '-'\n" "jne .s_star\n" "mov rax, 41\n" "jmp .op_ret\n"
		".s_star:\n" "cmp dl, '*'\n" "jne .s_slash\n" "mov rax, 42\n" "jmp .op_ret\n"
		".s_slash:\n" "cmp dl, '/'\n" "jne .s_percent\n" "mov rax, 43\n" "jmp .op_ret\n"
		".s_percent:\n" "cmp dl, '%'\n" "jne .s_eq\n" "mov rax, 44\n" "jmp .op_ret\n"
		".s_eq:\n" "cmp dl, '='\n" "jne .s_lt\n" "mov rax, 50\n" "jmp .op_ret\n"
		".s_lt:\n" "cmp dl, '<'\n" "jne .s_gt\n" "mov rax, 53\n" "jmp .op_ret\n"
		".s_gt:\n" "cmp dl, '>'\n" "jne .s_and\n" "mov rax, 54\n" "jmp .op_ret\n"
		".s_and:\n" "cmp dl, '&'\n" "jne .s_or\n" "mov rax, 60\n" "jmp .op_ret\n"
		".s_or:\n" "cmp dl, '|'\n" "jne .s_xor\n" "mov rax, 61\n" "jmp .op_ret\n"
		".s_xor:\n" "cmp dl, '^'\n" "jne .s_tilde\n" "mov rax, 62\n" "jmp .op_ret\n"
		".s_tilde:\n" "cmp dl, '~'\n" "jne .s_bang\n" "mov rax, 63\n" "jmp .op_ret\n"
		".s_bang:\n" "cmp dl, '!'\n" "jne .s_unknown\n" "mov rax, 64\n" "jmp .op_ret\n"
		".s_unknown:\n" "mov rax, 0\n" "jmp .op_ret\n"

		".op_ret:\n"
		"add r13, rcx\n"
		"mov [r12+0], r13\n"
		"mov [r12+16], r15\n"
		"mov rdx, rbx\n"
		"mov r8, r15\n"
		"mov rcx, rcx\n"
		"jmp .ret\n"

		".ret:\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp .exit\n"
		".s_bad_hex:  db 'lexer: invalid hex literal', 0\n"
		".s_bad_char: db 'lexer: invalid char literal', 0\n"
		".exit:\n"
	};
}
