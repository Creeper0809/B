// scratch: add cstr_eq but do not call it

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func cstr_eq(a, b) {
	var i = 0;
	while (1) {
		var ac = ptr8[a + i];
		var bc = ptr8[b + i];
		if (ac != bc) { return 0; }
		if (ac == 0) { return 1; }
		i = i + 1;
	}
	return 0;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(32);
	var prog = heap_alloc(16);
	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) { return 1; }

	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) { return 2; }
	return 0;
}
