// scratch: reproduce v2 driver segfault from p4_codegen_smoke (closer)

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func is_dump_ir_arg(p) {
	// "--dump-ir"\0
	if (ptr8[p + 0] != 45) { return 0; }
	if (ptr8[p + 1] != 45) { return 0; }
	if (ptr8[p + 2] != 100) { return 0; }
	if (ptr8[p + 3] != 117) { return 0; }
	if (ptr8[p + 4] != 109) { return 0; }
	if (ptr8[p + 5] != 112) { return 0; }
	if (ptr8[p + 6] != 45) { return 0; }
	if (ptr8[p + 7] != 105) { return 0; }
	if (ptr8[p + 8] != 114) { return 0; }
	if (ptr8[p + 9] != 0) { return 0; }
	return 1;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var dump_ir = 0;
	var path = ptr64[argv + 8];
	if (is_dump_ir_arg(path) == 1) {
		dump_ir = 1;
		if (argc < 3) { return 1; }
		path = ptr64[argv + 16];
	}

	var p;
	var n;
	p = read_file(path);
	alias rdx : n_reg;
	n = n_reg;

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);

	var parse_errors = ptr64[prog + 8];
	if (parse_errors != 0) { return 1; }

	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) { return 1; }

	var bytes = 0;
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
