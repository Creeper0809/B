// scratch: call helper that does ptr8 indexing with constants

func is_dash(p) {
	if (ptr8[p + 0] != 45) { return 0; }
	if (ptr8[p + 1] != 0) { return 0; }
	return 1;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (is_dash(path) == 1) { return 0; }
	return 0;
}
