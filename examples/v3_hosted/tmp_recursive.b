import io;

func f(n) {
	if (n == 0) { return 0; }
	return f(n - 1);
}

func main(argc, argv) {
	print_u64(f(3));
	print_str("\n");
	return 0;
}
