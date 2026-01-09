// scratch: alias rdx inside non-main function

import io;

func read_n() {
	var p = read_stdin_cap(16);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { return n; }
	return n;
}

func main() {
	return read_n();
}
