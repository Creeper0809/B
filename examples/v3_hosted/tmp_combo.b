import io;
import file;

import v3_hosted.driver;
import v3_hosted.ast;
import v3_hosted.parser;

func parse_one_file(path) {
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
	return ptr64[prog + 8];
}

func main(argc, argv) {
	var entry = ptr64[argv + 8];
	var seen = vec_new(8);
	var order = vec_new(8);
	var errs = build_module_order(entry, seen, order);
	print_str("errs=");
	print_u64(errs);
	print_str(" parse=");
	print_u64(parse_one_file(entry));
	print_str("\n");
	return 0;
}
