// scratch: option parse like p4 (no imports)

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

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var dump_ir = 0;
	var path = ptr64[argv + 8];
	if (is_dump_ir_arg(path) == 1) {
		dump_ir = 1;
		if (argc < 3) { return 1; }
		path = ptr64[argv + 16];
	}
	if (dump_ir == 1) {
		if (ptr8[path] == 0) { return 0; }
	}
	return 0;
}
