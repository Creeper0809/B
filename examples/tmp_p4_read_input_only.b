// scratch: include read_input/read_stdin_cap path handling

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func read_input(path) {
	var r = heap_alloc(16);
	if (r == 0) { return 0; }
	var p = 0;
	var n = 0;
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			p = read_stdin_cap(1048576);
			alias rdx : n_reg;
			n = n_reg;
		} else {
			return 0;
		}
	} else {
		p = read_file(path);
		alias rdx : n_reg;
		n = n_reg;
	}
	ptr64[r + 0] = p;
	ptr64[r + 8] = n;
	return r;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var inp = read_input(path);
	if (inp == 0) { return 1; }
	var p = ptr64[inp + 0];
	var n = ptr64[inp + 8];

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	typecheck_program(prog);
	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) { return 2; }
	return 0;
}
