// scratch: does v2 driver segfault on calling a user-defined helper?

func helper(x) {
	if (x == 0) { return 0; }
	return 1;
}

func main(argc, argv) {
	var p = ptr64[argv + 8];
	return helper(p);
}
