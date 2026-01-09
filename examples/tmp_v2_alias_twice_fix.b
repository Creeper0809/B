// scratch: two branches with read_stdin_cap/read_file, but only one alias

import io;
import file;

func do_compile(p, n) { return 0; }

func main(argc, argv) {
	alias rdx : n_reg;
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (ptr8[path] == 45) {
		if (ptr8[path + 1] == 0) {
			var p = read_stdin_cap(16);
			var n = n_reg;
			return do_compile(p, n);
		}
		return 1;
	}
	var p = read_file(path);
	var n = n_reg;
	return do_compile(p, n);
}
