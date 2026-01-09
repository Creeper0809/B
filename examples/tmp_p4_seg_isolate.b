// scratch: isolate whether do_compile body triggers v2 segfault

import io;
import file;

func do_compile(p, n, dump_ir) {
	if (p == 0) { return 1; }
	if (n == 0) { return 1; }
	if (dump_ir == 123) { return 1; }
	return 0;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(1048576);
			alias rdx : n_reg;
			var n = n_reg;
			return do_compile(p, n, 0);
		}
		return 1;
	}
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	return do_compile(p, n, 0);
}
