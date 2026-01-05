// v3_hosted: isolate alias usage

import io;
import file;
import vec;

import v3_hosted.lexer;
import v3_hosted.token;

func v3h_alias_only(path) {
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { return 1; }
	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	lexer_init(lex, p, n);
	lexer_next(lex, tok);
	return 0;
}
