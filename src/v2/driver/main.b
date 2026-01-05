// v2 driver entry (P0 scaffolding)
//
// Goal (P0): run v1 pipeline under a v2 entrypoint so we can start
// swapping out v2/lex + v2/parse gradually while keeping regression.
//
// For now we intentionally reuse v1 symbols:
// - read_file, lexer_new, parser_new, parse_program_emit_funcs
// - emit_* utilities and core Vec/Slice

func die_import_cycle() {
	die("import: cycle detected");
}

func die_import_not_found() {
	die("import: module not found");
}


func cstr_len(s) {
	// Convention: rdi = cstr
	// Returns: rax = length (excluding NUL)
	asm {
		"xor eax, eax\n"
		".loop:\n"
		"mov dl, byte [rdi+rax]\n"
		"test dl, dl\n"
		"jz .done\n"
		"inc rax\n"
		"jmp .loop\n"
		".done:\n"
	};
}

func cstr_eq(a, b) {
	// Convention: rdi=a, rsi=b
	// Returns: rax=1 if equal, else 0
	asm {
		"xor ecx, ecx\n" // i=0
		".loop:\n"
		"mov al, byte [rdi+rcx]\n"
		"mov dl, byte [rsi+rcx]\n"
		"cmp al, dl\n"
		"jne .no\n"
		"test al, al\n"
		"jz .yes\n"
		"inc rcx\n"
		"jmp .loop\n"
		".yes:\n"
		"mov eax, 1\n"
		"jmp .done\n"
		".no:\n"
		"xor eax, eax\n"
		".done:\n"
	};
}

func dirname_cstr(path) {
	// Returns a newly allocated cstr containing directory of `path`,
	// including the trailing '/'. If no '/', returns "./".
	// Convention: rdi=path
	// Returns: rax=cstr
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"sub rsp, 16\n" // [0]=path [8]=last_slash_idx
		"mov [rsp+0], rdi\n"
		"mov qword [rsp+8], -1\n" // last_slash_idx = -1
		"xor r13d, r13d\n" // i=0
		".scan:\n"
		"mov r12, [rsp+0]\n"
		"mov al, byte [r12+r13]\n"
		"test al, al\n"
		"jz .scan_done\n"
		"cmp al, '/'\n"
		"jne .no_slash\n"
		"mov [rsp+8], r13\n"
		".no_slash:\n"
		"inc r13\n"
		"jmp .scan\n"
		".scan_done:\n"
		"mov rbx, [rsp+8]\n"
		"cmp rbx, -1\n"
		"jne .have_slash\n"
		// no slash => return "./"
		"mov rdi, 3\n" // '.', '/', '\0'
		"call heap_alloc\n"
		"mov r12, rax\n"
		"mov byte [r12+0], '.'\n"
		"mov byte [r12+1], '/'\n"
		"mov byte [r12+2], 0\n"
		"mov rax, r12\n"
		"jmp .done\n"
		".have_slash:\n"
		// n = last_slash_idx + 1
		"mov rcx, rbx\n"
		"inc rcx\n"
		"mov [rsp+8], rcx\n" // save n across calls
		// alloc (n + 1)
		"mov rdi, rcx\n"
		"inc rdi\n"
		"call heap_alloc\n"
		"mov r12, rax\n" // dst
		"mov rcx, [rsp+8]\n" // reload n
		// memcpy(dst, path, n)
		"mov rdi, r12\n"
		"mov rsi, [rsp+0]\n"
		"mov rdx, rcx\n"
		"call memcpy\n"
		"mov rcx, [rsp+8]\n" // reload n (memcpy may clobber)
		// dst[n] = 0
		"mov byte [r12+rcx], 0\n"
		"mov rax, r12\n"
		".done:\n"
		"add rsp, 16\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func file_exists(path) {
	// Convention: rdi=path(cstr)
	// Returns: rax=1 if openable, else 0
	asm {
		"push rbx\n"
		"mov rbx, rdi\n"
		"xor rsi, rsi\n" // O_RDONLY
		"xor rdx, rdx\n"
		"call sys_open\n"
		"test rax, rax\n"
		"js .no\n"
		// close(fd)
		"mov rdi, rax\n"
		"call sys_close\n"
		"mov rax, 1\n"
		"jmp .done\n"
		".no:\n"
		"xor eax, eax\n"
		".done:\n"
		"pop rbx\n"
	};
}

func normalize_root(path) {
	// Ensure trailing '/'. If already present, returns original pointer.
	// Convention: rdi=path(cstr)
	// Returns: rax=cstr
	asm {
		"push rbx\n"
		"push r12\n"
		"sub rsp, 16\n" // [0]=path [8]=len
		"mov [rsp+0], rdi\n"
		"call cstr_len\n"
		"mov [rsp+8], rax\n"
		"cmp rax, 0\n"
		"jne .chk_last\n"
		// empty => return "./"
		"mov rdi, 3\n"
		"call heap_alloc\n"
		"mov r12, rax\n"
		"mov byte [r12+0], '.'\n"
		"mov byte [r12+1], '/'\n"
		"mov byte [r12+2], 0\n"
		"mov rax, r12\n"
		"jmp .done\n"
		".chk_last:\n"
		"mov rbx, [rsp+0]\n" // path
		"mov rcx, [rsp+8]\n" // len
		"dec rcx\n"
		"mov al, byte [rbx+rcx]\n"
		"cmp al, '/'\n"
		"jne .need_slash\n"
		"mov rax, rbx\n"
		"jmp .done\n"
		".need_slash:\n"
		// alloc len+2
		"mov rdi, [rsp+8]\n"
		"add rdi, 2\n"
		"call heap_alloc\n"
		"mov r12, rax\n" // dst
		// memcpy(dst, path, len)
		"mov rdi, r12\n"
		"mov rsi, [rsp+0]\n"
		"mov rdx, [rsp+8]\n"
		"call memcpy\n"
		// dst[len] = '/'; dst[len+1]=0
		"mov rcx, [rsp+8]\n"
		"mov byte [r12+rcx], '/'\n"
		"inc rcx\n"
		"mov byte [r12+rcx], 0\n"
		"mov rax, r12\n"
		".done:\n"
		"add rsp, 16\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func try_resolve_in_root(root_cstr, rel_cstr) {
	// Try `<root>/<rel>.b` then `<root>/<rel>/__init__.b`.
	// Convention: rdi=root, rsi=rel
	// Returns: rax=resolved_path (cstr), rdx=ok(1/0)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 48\n" // [0]=root [8]=rel [16]=root_len [24]=rel_len [32]=p [40]=n
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		// root_len
		"mov rdi, [rsp+0]\n"
		"call cstr_len\n"
		"mov [rsp+16], rax\n"
		// rel_len
		"mov rdi, [rsp+8]\n"
		"call cstr_len\n"
		"mov [rsp+24], rax\n"
		// p = root + rel
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+16]\n" "mov rdx, [rsp+8]\n" "mov rcx, [rsp+24]\n" "call str_concat\n"
		"mov [rsp+32], rax\n" "mov [rsp+40], rdx\n"
		// p = p + ".b"
		"mov rdi, [rsp+32]\n" "mov rsi, [rsp+40]\n" "lea rdx, [rel .s_dot_b]\n" "mov rcx, 2\n" "call str_concat\n"
		"mov [rsp+32], rax\n" "mov [rsp+40], rdx\n"
		// exists?
		"mov rdi, [rsp+32]\n"
		"call file_exists\n"
		"cmp rax, 1\n"
		"je .ok\n"
		// p = root + rel
		"mov rdi, [rsp+0]\n" "mov rsi, [rsp+16]\n" "mov rdx, [rsp+8]\n" "mov rcx, [rsp+24]\n" "call str_concat\n"
		"mov [rsp+32], rax\n" "mov [rsp+40], rdx\n"
		// p = p + "/__init__.b"
		"mov rdi, [rsp+32]\n" "mov rsi, [rsp+40]\n" "lea rdx, [rel .s_init]\n" "mov rcx, 11\n" "call str_concat\n"
		"mov [rsp+32], rax\n" "mov [rsp+40], rdx\n"
		"mov rdi, [rsp+32]\n"
		"call file_exists\n"
		"cmp rax, 1\n"
		"je .ok\n"
		// fail
		"xor eax, eax\n"
		"xor edx, edx\n"
		"jmp .done\n"
		".ok:\n"
		"mov rax, [rsp+32]\n"
		"mov edx, 1\n"
		".done:\n"
		"add rsp, 48\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_dot_b: db '.', 'b', 0\n"
		".s_init: db '/', '_','_','i','n','i','t','_','_','.', 'b', 0\n"
		".exit:\n"
	};
}

func resolve_import_to_file(dir_cstr, rel_cstr) {
	// Search order: importing file dir first, then -I/--module-root roots.
	// Convention: rdi=dir, rsi=rel
	// Returns: rax=resolved_path cstr (dies if not found)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 40\n" // [0]=dir [8]=rel [16]=roots [24]=i [32]=n
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		// try dir
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call try_resolve_in_root\n"
		"test rdx, rdx\n"
		"jnz .ok\n"
		// roots = [rel v2_module_roots]
		"mov rax, [rel v2_module_roots]\n"
		"mov [rsp+16], rax\n"
		"test rax, rax\n"
		"jz .not_found\n"
		// n = vec_len(roots)
		"mov rdi, [rsp+16]\n"
		"call vec_len\n"
		"mov [rsp+32], rax\n"
		"mov qword [rsp+24], 0\n" // i=0 (do not keep in regs across calls)
		".loop:\n"
		"mov rax, [rsp+24]\n"
		"cmp rax, [rsp+32]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+16]\n"
		"mov rsi, [rsp+24]\n"
		"call vec_get\n" // rax=root cstr
		"mov rdi, rax\n"
		"mov rsi, [rsp+8]\n"
		"call try_resolve_in_root\n"
		"test rdx, rdx\n"
		"jnz .ok\n"
		"inc qword [rsp+24]\n"
		"jmp .loop\n"
		".not_found:\n"
		"call die_import_not_found\n"
		".ok:\n"
		// rax already set
		"add rsp, 40\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func module_cache_find(cache, path) {
	// cache: Vec* of ModuleEntry* { path_cstr, state }
	// Returns: rax=entry, rdx=found(1/0)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 40\n" // [0]=cache [8]=path [16]=n [24]=i [32]=entry
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov rdi, [rsp+0]\n"
		"call vec_len\n"
		"mov [rsp+16], rax\n"
		"mov qword [rsp+24], 0\n" // i=0 (do not keep in regs across calls)
		".loop:\n"
		"mov rax, [rsp+24]\n"
		"cmp rax, [rsp+16]\n"
		"jae .not_found\n"
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+24]\n"
		"call vec_get\n" // rax=entry*
		"mov [rsp+32], rax\n"
		"mov rax, [rsp+32]\n"
		"mov rdi, [rax+0]\n" // entry->path
		"mov rsi, [rsp+8]\n" // path
		"call cstr_eq\n" // rax=1 if eq
		"cmp rax, 1\n"
		"je .found\n"
		"inc qword [rsp+24]\n"
		"jmp .loop\n"
		".found:\n"
		"mov rax, [rsp+32]\n"
		"mov edx, 1\n"
		"jmp .done\n"
		".not_found:\n"
		"xor eax, eax\n"
		"xor edx, edx\n"
		".done:\n"
		"add rsp, 40\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func module_cache_add(cache, path) {
	// Returns: rax=entry*
	var cache0;
	var path0;
	var entry0;
	ptr64[cache0] = rdi;
	ptr64[path0] = rsi;
	heap_alloc(16);
	ptr64[entry0] = rax;

	alias r8 : e;
	alias r9 : tmp;
	e = ptr64[entry0];
	tmp = ptr64[path0];
	ptr64[e] = tmp; // path
	e += 8;
	ptr64[e] = 0;   // state

	// cache.push(entry0)
	rdi = ptr64[cache0];
	rsi = ptr64[entry0];
	vec_push(rdi, rsi);
	rax = ptr64[entry0];
}

func parse_imports_resolve_paths(p, out_vec) {
	// Consumes leading top-level import decls and appends module relpaths
	// (cstr like "foo/bar") to out_vec.
	// Convention: rdi=Parser*, rsi=Vec*
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// Keep stack 16-byte aligned for nested calls (SysV ABI).
		"sub rsp, 48\n" // [0]=p [8]=out [16]=path_ptr [24]=path_len [32]=tok_len [40]=pad
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		".loop:\n"
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n"
		"cmp rax, 1\n" // TOK_IDENT
		"jne .done\n"
		"mov rdi, r12\n"
		"lea rsi, [rel .s_import]\n"
		"mov rdx, 6\n"
		"call parser_is_ident_kw\n"
		"test rax, rax\n"
		"jz .done\n"
		// consume 'import'
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		// expect ident part
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .p1_ok\n" "call die_import_expected_ident\n"
		".p1_ok:\n"
		// path = slice_to_cstr(part1)
		"mov rax, [r12+24]\n" "mov [rsp+32], rax\n" // save tok_len
		"mov rdi, [r12+16]\n"     // tok ptr
		"mov rsi, [r12+24]\n"     // tok len
		"call slice_to_cstr\n"     // rax=cstr
		"mov [rsp+16], rax\n"
		"mov rdi, rax\n"
		"call cstr_len\n"
		"mov [rsp+24], rax\n"
		// consume part1
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		".parts:\n"
		"mov rax, [r12+8]\n" "cmp rax, 38\n" "jne .after_parts\n" // TOK_DOT
		"mov rdi, r12\n" "call parser_next\n" // consume '.'
		"mov r12, [rsp+0]\n"
		"mov rax, [r12+8]\n" "cmp rax, 1\n" "je .pn_ok\n" "call die_import_expected_ident\n"
		".pn_ok:\n"
		// path = path + "/"
		"mov rdi, [rsp+16]\n" "mov rsi, [rsp+24]\n" "lea rdx, [rel .s_slash]\n" "mov rcx, 1\n" "call str_concat\n"
		"mov [rsp+16], rax\n" "mov [rsp+24], rdx\n"
		// path = path + ident
		"mov rdi, [rsp+16]\n" "mov rsi, [rsp+24]\n" "mov rdx, [r12+16]\n" "mov rcx, [r12+24]\n" "call str_concat\n"
		"mov [rsp+16], rax\n" "mov [rsp+24], rdx\n"
		// consume ident
		"mov rdi, r12\n" "call parser_next\n"
		"mov r12, [rsp+0]\n"
		"jmp .parts\n"
		".after_parts:\n"
		// expect ';'
		"mov rax, [r12+8]\n" "cmp rax, 36\n" "je .semi_ok\n" "call die_import_expected_semi\n"
		".semi_ok:\n"
		"mov rdi, r12\n" "call parser_next\n" // consume ';'
		"mov r12, [rsp+0]\n"
		// out_vec.push(path_ptr)
		"mov rdi, [rsp+8]\n" "mov rsi, [rsp+16]\n" "call vec_push\n"
		"jmp .loop\n"
		".done:\n"
		"add rsp, 48\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_import: db 'import', 0\n"
		".s_slash: db '/', 0\n"
		".exit:\n"
	};
}

func die_import_expected_ident() {
	die("import: expected identifier");
}

func die_import_expected_semi() {
	die("import: expected ';'");
}

func compile_module_source(path) {
	// Read + lex + parse + emit (into current emitter) one module file.
	var path0;
	var src_ptr;
	var src_len;
	var lex;
	var p;
	ptr64[path0] = rdi;

	print_str("[v2] compile_module_source: ");
	print_str(ptr64[path0]);
	print_str("\n");

	rdi = ptr64[path0];
	read_file(rdi);
	ptr64[src_ptr] = rax;
	ptr64[src_len] = rdx;

	rdi = ptr64[src_ptr];
	rsi = ptr64[src_len];
	lexer_new(rdi, rsi);
	ptr64[lex] = rax;

	rdi = ptr64[lex];
	parser_new(rdi);
	ptr64[p] = rax;

	rdi = ptr64[p];
	asm { "call parse_program_emit_funcs\n" };
}

func compile_module_recursive(cache_vec, path) {
	// Convention: rdi=cache_vec(Vec*), rsi=path(cstr)
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 96\n" // [0]=cache [8]=path [16]=entry [24]=dir [32]=imports [40]=i [48]=n [56]=imp_path [64]=src_ptr [72]=src_len [80]=lex [88]=p

		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// entry = find(cache, path)
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call module_cache_find\n" // rax=entry, rdx=found
		"test rdx, rdx\n"
		"jnz .have_entry\n"
		// add
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"call module_cache_add\n"
		"mov [rsp+16], rax\n"
		"jmp .check_state\n"
		".have_entry:\n"
		"mov [rsp+16], rax\n"

		".check_state:\n"
		"mov r12, [rsp+16]\n" // entry*
		"mov rax, [r12+8]\n"  // state
		"cmp rax, 1\n"
		"jne .not_visiting\n"
		"call die_import_cycle\n"
		".not_visiting:\n"
		"cmp rax, 2\n"
		"jne .do_visit\n"
		"jmp .done\n"

		".do_visit:\n"
		// Optional trace: print each module as it is first visited.
		"mov rax, [rel v2_trace_imports]\n"
		"test rax, rax\n"
		"jz .no_trace\n"
		"lea rdi, [rel .s_trace]\n"
		"call print_str\n"
		"mov rdi, [rsp+8]\n"
		"call print_str\n"
		"lea rdi, [rel .s_nl]\n"
		"call print_str\n"
		".no_trace:\n"
		// mark visiting
		"mov qword [r12+8], 1\n"

		// dir = dirname(path)
		"mov rdi, [rsp+8]\n"
		"call dirname_cstr\n"
		"mov [rsp+24], rax\n"

		// read_file(path)
		"mov rdi, [rsp+8]\n"
		"call read_file\n" // rax=ptr, rdx=len
		"mov [rsp+64], rax\n"
		"mov [rsp+72], rdx\n"

		// lexer_new(ptr,len)
		"mov rdi, [rsp+64]\n"
		"mov rsi, [rsp+72]\n"
		"call lexer_new\n"
		"mov [rsp+80], rax\n"

		// parser_new(lex)
		"mov rdi, [rsp+80]\n"
		"call parser_new\n"
		"mov [rsp+88], rax\n"

		// imports = vec_new(128)
		// Large enough to avoid Vec growth while scanning leading imports.
		"mov rdi, 128\n"
		"call vec_new\n"
		"mov [rsp+32], rax\n"

		// parse_imports_resolve_paths(p, imports)
		"mov rdi, [rsp+88]\n"
		"mov rsi, [rsp+32]\n"
		"call parse_imports_resolve_paths\n"

		// n = vec_len(imports)
		"mov rdi, [rsp+32]\n"
		"call vec_len\n"
		"mov [rsp+48], rax\n"
		"mov qword [rsp+40], 0\n" // i=0 (do not keep in regs across calls)
		".imp_loop:\n"
		"mov rax, [rsp+40]\n"
		"cmp rax, [rsp+48]\n"
		"jae .after_imps\n"
		"mov rdi, [rsp+32]\n"
		"mov rsi, [rsp+40]\n"
		"call vec_get\n" // rax=imp_path cstr
		"mov [rsp+56], rax\n" // relpath (spill across calls)
		// resolved = resolve_import_to_file(dir, rel)
		"mov rdi, [rsp+24]\n"
		"mov rsi, [rsp+56]\n"
		"call resolve_import_to_file\n" // rax=resolved cstr
		"mov [rsp+56], rax\n" // resolved (spill across calls)
		"mov rdi, [rsp+0]\n" // cache
		"mov rsi, [rsp+56]\n"
		"call compile_module_recursive\n"
		"inc qword [rsp+40]\n"
		"jmp .imp_loop\n"
		".after_imps:\n"

		// Emit this module using the already-read source and the current parser.
		// parse_imports_resolve_paths() has consumed leading imports, so we can
		// continue from the current token and avoid re-reading the file (saves heap).
		"mov rdi, [rsp+88]\n" // Parser*
		"call parse_program_emit_funcs\n"

		// mark done
		"mov r12, [rsp+16]\n"
		"mov qword [r12+8], 2\n"

		".done:\n"
		"add rsp, 96\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_trace: db '[v2] mod ', 0\n"
		".s_nl: db 10, 0\n"
		".exit:\n"
	};
}

func compile_entry(path_cstr) {
	// Compile entry module + its imports into build/v2_out.asm.
	var path0;
	var cache;
	ptr64[path0] = rdi;

	// Safety: ensure DF=0 for rep string builtins (memcpy/strlen/streq).
	// If DF is ever left set, cache lookups and path building can break and
	// lead to duplicate module/function emission.
	asm { "cld\n" };

	// Reset codegen globals per compilation.
	asm { "mov qword [rel label_counter], 0\n" };
	// Avoid Vec growth during large builds (can break dedup state).
	vec_new(1024);
	ptr64[vars_emitted] = rax;
	// Hosted-v3 pulls in many functions; keep this comfortably above that.
	vec_new(8192);
	ptr64[funcs_emitted] = rax;
	asm { "call consts_reset\n" };
	asm { "call structs_reset\n" };
	asm { "call rodata_reset\n" };

	// Emit output prelude once (streaming to avoid Stage1 heap OOM).
	emit_init();
	emit_open("build/v2_out.asm");
	emit_cstr("global _start\n");
	emit_cstr("section .text\n");
	emit_cstr("_start:\n");
	// Pass argc/argv to main via SysV ABI registers.
	// Linux process entry stack: [rsp]=argc, [rsp+8]=argv[0], ...
	emit_cstr("  mov rdi, [rsp]\n");
	emit_cstr("  lea rsi, [rsp+8]\n");
	emit_cstr("  call main\n");
	emit_cstr("  mov rdi, rax\n");
	emit_cstr("  mov rax, 60\n");
	emit_cstr("  syscall\n");

	// NOTE: avoid triggering Vec growth during compilation.
	// Stage1 builds are sensitive to allocator/ABI edge cases; if vec_push grows
	// while compiling large programs, it can corrupt the module cache and cause
	// duplicate compilation/emission.
	// This is a small, bounded allocation (u64 ptrs) and keeps compilation stable.
	// P4 hosted-v3 pulls in a lot of modules; keep this comfortably above that.
	vec_new(4096);
	ptr64[cache] = rax;

	rdi = ptr64[cache];
	rsi = ptr64[path0];
	compile_module_recursive(rdi, rsi);

	// Emit .rodata for string literals (if any).
	asm { "call rodata_emit_all\n" };

	// Flush output and close.
	emit_close();
}

func main() {
	// NOTE(Stage1): do not keep argc/argv/i in registers across calls.
	// Some helpers do not reliably preserve callee-saved regs, so we store
	// loop state in stack slots and reload each iteration.
	asm {
		"sub rsp, 40\n" // [rsp+0]=argc [rsp+8]=argv [rsp+16]=i [rsp+24]=roots [rsp+32]=arg
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov qword [rsp+16], 1\n" // i = 1

		// v2_module_roots = vec_new(4)
		"mov rdi, 4\n"
		"call vec_new\n"
		"mov [rsp+24], rax\n"
		"mov [rel v2_module_roots], rax\n"

		".loop:\n"
		"mov rax, [rsp+16]\n" // i
		"cmp rax, [rsp+0]\n"  // argc
		"jae .done\n"
		"mov rdx, rax\n"
		"shl rdx, 3\n"         // i*8
		"mov r8, [rsp+8]\n"  // argv
		"add r8, rdx\n"
		"mov rax, [r8]\n"     // arg ptr
		"mov [rsp+32], rax\n"
		// if arg == "-I" then consume next as root
		"mov rdi, [rsp+32]\n" "lea rsi, [rel .s_opt_I]\n" "call cstr_eq\n"
		"cmp rax, 1\n" "jne .chk_root\n"
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n" // i++
		"cmp rax, [rsp+0]\n" "jae .opt_miss\n"
		"mov rdx, rax\n" "shl rdx, 3\n" "mov r8, [rsp+8]\n" "add r8, rdx\n" "mov rdi, [r8]\n" // next arg
		"call normalize_root\n" // rax=root
		"mov rdi, [rsp+24]\n" "mov rsi, rax\n" "call vec_push\n"
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n" // i++ (skip root)
		"jmp .loop\n"
		".chk_root:\n"
		// if arg == "--trace-imports" then enable module tracing
		"mov rdi, [rsp+32]\n" "lea rsi, [rel .s_opt_trace]\n" "call cstr_eq\n"
		"cmp rax, 1\n" "jne .chk_root2\n"
		"mov qword [rel v2_trace_imports], 1\n"
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n"
		"jmp .loop\n"
		".chk_root2:\n"
		// if arg == "--module-root" then consume next as root
		"mov rdi, [rsp+32]\n" "lea rsi, [rel .s_opt_root]\n" "call cstr_eq\n"
		"cmp rax, 1\n" "jne .is_input\n"
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n" // i++
		"cmp rax, [rsp+0]\n" "jae .opt_miss\n"
		"mov rdx, rax\n" "shl rdx, 3\n" "mov r8, [rsp+8]\n" "add r8, rdx\n" "mov rdi, [r8]\n" // next arg
		"call normalize_root\n" // rax=root
		"mov rdi, [rsp+24]\n" "mov rsi, rax\n" "call vec_push\n"
		"mov rax, [rsp+16]\n" "inc rax\n" "mov [rsp+16], rax\n" // i++ (skip root)
		"jmp .loop\n"
		".is_input:\n"
		"mov rdi, [rsp+32]\n"     // path
		"call compile_entry\n"
		"mov rax, [rsp+16]\n"
		"inc rax\n"
		"mov [rsp+16], rax\n"
		"jmp .loop\n"

		".opt_miss:\n"
		"call die_import_expected_ident\n" // reuse msg for missing arg

		".done:\n"
		"mov rdi, 0\n"
		"call sys_exit\n"
		".s_opt_I: db '-', 'I', 0\n"
		".s_opt_trace: db '-', '-', 't','r','a','c','e','-','i','m','p','o','r','t','s', 0\n"
		".s_opt_root: db '-', '-', 'm','o','d','u','l','e','-','r','o','o','t', 0\n"
	};
}
