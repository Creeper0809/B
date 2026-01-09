import io;
import file;

func helper(path) {
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	print_u64(n);
	print_str("\n");
	return 0;
}

func main(argc, argv) {
	return helper(ptr64[argv + 8]);
}
