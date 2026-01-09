// scratch: p4 import set + hoisted alias + stdin/file branches

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

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
