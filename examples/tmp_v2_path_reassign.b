// scratch: reassign path from argv+16 under condition

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	if (argc >= 3) {
		path = ptr64[argv + 16];
	}
	if (ptr8[path] == 0) { return 0; }
	return 0;
}
