import v3_hosted.codegen;
import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var bytes_in = read_file_bytes(path);
	if (bytes_in == 0) { return 2; }
	var p = ptr64[bytes_in + 0];
	var n = ptr64[bytes_in + 8];
	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	if (lex == 0) { return 3; }
	if (tok == 0) { return 4; }
	if (prs == 0) { return 5; }
	if (prog == 0) { return 6; }
	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	var parse_errors = ptr64[prog + 8];
	if (parse_errors != 0) { return 1; }
	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) { return 1; }
	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) { return 2; }
	return 0;
}

func read_file_bytes(path) {
	asm {
		sub rsp, 16
		mov [rsp+0], rdi
		mov rdi, [rsp+0]
		call read_file
		mov [rsp+0], rax
		mov [rsp+8], rdx
		mov rdi, 16
		call heap_alloc
		test rax, rax
		jz .oom
		mov rcx, [rsp+0]
		mov [rax+0], rcx
		mov rcx, [rsp+8]
		mov [rax+8], rcx
		xor edx, edx
		add rsp, 16
		jmp .done
		.oom:
		xor eax, eax
		xor edx, edx
		add rsp, 16
		.done:
	}
	return;
}
