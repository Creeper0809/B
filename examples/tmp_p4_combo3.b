// scratch: import set + simplified is_dump_ir_arg + real do_compile

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func is_dump_ir_arg(p) {
	var w = ptr64[p + 0];
	if (w != 0x692d706d75642d2d) { return 0; }
	if (ptr8[p + 8] != 114) { return 0; }
	if (ptr8[p + 9] != 0) { return 0; }
	return 1;
}

func do_compile(p, n, dump_ir) {
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
		return 1;
	}

	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) {
		return 1;
	}

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

func main(argc, argv) {
	alias rdx : n_reg;
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var dump_ir = is_dump_ir_arg(path);
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(16);
			var n = n_reg;
			return do_compile(p, n, dump_ir);
		}
		return 1;
	}
	var p = read_file(path);
	var n = n_reg;
	return do_compile(p, n, dump_ir);
}
