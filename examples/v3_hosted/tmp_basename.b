import io;
import v3_hosted.driver;

func main(argc, argv) {
	var p = ptr64[argv + 8];
	var bp_slot;
	var bl_slot;
	path_basename_no_ext(p, bp_slot, bl_slot);
	print_str_len(ptr64[bp_slot], ptr64[bl_slot]);
	print_str("\n");
	return 0;
}
