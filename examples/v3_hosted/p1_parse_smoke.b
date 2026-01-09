// v3_hosted P1: read file/stdin -> lex -> parse top-level decls

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;

import vec;

func main(argc, argv) {
	if (argc < 2) {
		print_str("usage: p1_parse_smoke <file>|-\n");
		return 1;
	}

	var path = ptr64[argv + 8];
	var p;
	var n;
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			p = read_stdin_cap(1048576);
			alias rdx : n_reg;
			n = n_reg;
		} else {
			return 1;
		}
	} else {
		p = read_file(path);
		alias rdx : n_reg;
		n = n_reg;
	}

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

	var decls = ptr64[prog + 0];
	print_str("decls=");
	print_u64(vec_len(decls));
	print_str("\n");
	return 0;
}
