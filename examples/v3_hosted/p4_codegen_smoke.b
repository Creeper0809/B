// v3_hosted P4: read file/stdin -> lex -> parse -> typecheck -> codegen asm to stdout

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func main(argc, argv) {
	if (argc < 2) {
		return 1;
	}

	alias rdx : n_reg;

	var path = ptr64[argv + 8];
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(1048576);
			var n = n_reg;

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

			var parse_errors = ptr64[prog + 8];
			if (parse_errors != 0) { return 1; }

			var ty_errors = typecheck_program(prog);
			if (ty_errors != 0) { return 1; }

			var bytes = v3h_codegen_program(prog);
			if (bytes == 0) { return 2; }
			var out_p = ptr64[bytes + 0];
			var out_n = ptr64[bytes + 8];
			if (out_p == 0) { return 2; }
			sys_write(1, out_p, out_n);
			return 0;
		} else {
			return 1;
		}
	}

	var p = read_file(path);
	var n = n_reg;

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

	var parse_errors = ptr64[prog + 8];
	if (parse_errors != 0) { return 1; }

	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) { return 1; }

	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) { return 2; }
	var out_p = ptr64[bytes + 0];
	var out_n = ptr64[bytes + 8];
	if (out_p == 0) { return 2; }
	sys_write(1, out_p, out_n);
	return 0;
}
