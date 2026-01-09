// scratch: import set + simplified is_dump_ir_arg + trivial do_compile

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

func do_compile(p, n, dump_ir) { return dump_ir; }

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
