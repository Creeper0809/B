// scratch: add out_p/out_n extraction + sys_write

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func main(argc, argv) {
	if (argc < 2) { return 1; }

	var dump_ir = 0;
	var path = ptr64[argv + 8];
	var p;
	var n;
	p = read_file(path);
	alias rdx : n_reg;
	n = n_reg;

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(32);
	var prog = heap_alloc(16);
	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);

	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) { return 1; }

	var bytes;
	if (dump_ir == 1) {
		bytes = v3h_codegen_program_dump_ir(prog);
	} else {
		bytes = v3h_codegen_program(prog);
	}
	if (bytes == 0) { return 2; }
	var out_p = ptr64[bytes + 0];
	var out_n = ptr64[bytes + 8];
	if (out_p == 0) { return 2; }
	sys_write(1, out_p, out_n);
	return 0;
}
