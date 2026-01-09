// v3_hosted codegen smoke driver for golden tests.
//
// Note: keep this driver simple. In particular, avoid large inline asm blocks
// here; they can stress the Stage1/v2 compiler driver.

import io;
import file;
import slice;

import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func main(argc, argv) {
	if (argc < 2) { return 1; }

	var dump_ir = 0;
	var path = ptr64[argv + 8];
	if (argc >= 3) {
		var a1 = ptr64[argv + 8];
		var a2 = ptr64[argv + 16];
		// usage: p4_codegen_smoke_golden [--dump-ir] <file>
		if (slice_eq(a1, 9, "--dump-ir", 9) == 1) {
			dump_ir = 1;
			path = a2;
		}
	}
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { return 2; }

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
	if (ptr64[prog + 8] != 0) { return 1; }
	if (typecheck_program(prog) != 0) { return 1; }

	var bytes = 0;
	if (dump_ir == 1) {
		bytes = v3h_codegen_program_dump_ir(prog);
	}
	else {
		bytes = v3h_codegen_program(prog);
	}
	if (bytes == 0) { return 2; }
	var out_p = ptr64[bytes + 0];
	var out_n = ptr64[bytes + 8];
	if (out_p == 0) { return 2; }
	sys_write(1, out_p, out_n);
	return 0;
}
