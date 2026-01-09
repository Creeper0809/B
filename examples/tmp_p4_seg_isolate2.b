// scratch: stdin only + argc/argv parsing + call helper

import io;

func do_compile(p, n, dump_ir) { return 0; }

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (ptr8[path] != 45) { return 1; }
	if (ptr8[path + 1] != 0) { return 1; }
	var p = read_stdin_cap(1048576);
	alias rdx : n_reg;
	var n = n_reg;
	return do_compile(p, n, 0);
}
