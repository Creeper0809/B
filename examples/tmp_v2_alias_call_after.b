// scratch: call after alias rdx:n_reg in main

import io;

func foo(x) { return x; }

func main() {
	var p = read_stdin_cap(16);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { return foo(n); }
	return foo(n);
}
