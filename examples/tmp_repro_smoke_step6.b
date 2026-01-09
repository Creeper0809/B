import io;
import file;

import v3_hosted.lexer;
import v3_hosted.parser;

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var p = read_file(path);
	// avoid alias by not using length
	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(32);
	var prog = heap_alloc(16);
	if (lex == 0) { return 3; }
	if (tok == 0) { return 4; }
	if (prs == 0) { return 5; }
	if (prog == 0) { return 6; }
	lexer_init(lex, p, 0);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	return 0;
}
