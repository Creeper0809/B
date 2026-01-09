import file;

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	alias rdx : n_reg;
	var p = read_file(path);
	var n = n_reg;
	if (p == 0) { return 2; }
	return 0;
}
