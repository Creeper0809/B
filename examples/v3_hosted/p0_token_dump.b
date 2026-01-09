// v3_hosted P0: read file -> lex -> token dump

import io;
import file;
import v3_hosted.lexer;
import v3_hosted.token;

func print_tok(tok) {
	print_str("line=");
	print_u64(ptr64[tok + 24]);
	print_str(":");
	print_u64(ptr64[tok + 40]);
	print_str(" kind=");
	print_u64(ptr64[tok + 0]);
	print_str(" off=");
	print_u64(ptr64[tok + 32]);
	print_str(" text=\"");
	print_str_len(ptr64[tok + 8], ptr64[tok + 16]);
	print_str("\"\n");
	return 0;
}

func main() {
	var p = read_file("./examples/v3_hosted/p0_input.b");
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { sys_exit(1); }

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	if (lex == 0) { sys_exit(3); }
	if (tok == 0) { sys_exit(4); }
	lexer_init(lex, p, n);
	while (1) {
		var k = lexer_next(lex, tok);
		if (k == TokKind.EOF) { break; }
		if (k == TokKind.ERR) { sys_exit(2); }
		print_tok(tok);
	}

	return 0;
}
