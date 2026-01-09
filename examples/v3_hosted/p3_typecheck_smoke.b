// v3_hosted P3: read file/stdin -> lex -> parse -> typecheck (minimal)

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;

import vec;

func main(argc, argv) {
	if (argc < 2) {
		print_str("usage: p3_typecheck_smoke <file>|-\n");
		return 1;
	}

	var path = ptr64[argv + 8];
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(1048576);
			alias rdx : n_reg;
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
			if (parse_errors != 0) {
				print_str("parse_errors=");
				print_u64(parse_errors);
				print_str("\n");
				return 1;
			}

			var ty_errors = typecheck_program(prog);
			print_str("type_errors=");
			print_u64(ty_errors);
			print_str("\n");
			if (ty_errors != 0) { return 1; }
			return 0;
		} else {
			return 1;
		}
	}

	// File entry: parse+typecheck with imports.
	var ty_errors2 = typecheck_entry_file(path);
	print_str("type_errors=");
	print_u64(ty_errors2);
	print_str("\n");
	if (ty_errors2 != 0) { return 1; }
	return 0;
}
