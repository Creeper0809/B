// scratch: pipeline with both stdin and file branches

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func main(argc, argv) {
	alias rdx : n_reg;
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var p = 0;
	var n = 0;
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			p = read_stdin_cap(1048576);
			n = n_reg;
		} else {
			return 1;
		}
	} else {
		p = read_file(path);
		n = n_reg;
	}

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
