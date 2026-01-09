// scratch: import set + is_dump_ir_arg + trivial do_compile + stdin/file branches

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func is_dump_ir_arg(p) {
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

func do_compile(p, n, dump_ir) { return 0; }

func main(argc, argv) {
	alias rdx : n_reg;
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(16);
			var n = n_reg;
			return do_compile(p, n, 0);
		}
		return 1;
	}
	var p = read_file(path);
	var n = n_reg;
	return do_compile(p, n, 0);
}
