import io;
import v3_hosted.driver;
import vec;

func main(argc, argv) {
	var entry = ptr64[argv + 8];
	var seen = vec_new(8);
	var order = vec_new(8);
	var errs = build_module_order(entry, seen, order);
	print_str("errs=");
	print_u64(errs);
	print_str(" order=");
	print_u64(vec_len(order));
	print_str("\n");
	return 0;
}
