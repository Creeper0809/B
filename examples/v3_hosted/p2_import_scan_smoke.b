// v3_hosted P2: file loading + import scan (Phase 1.3)
//
// Usage:
//   p2_import_scan_smoke <entry-file>

import io;
import file;

import v3_hosted.driver;

func main(argc, argv) {
	if (argc < 2) {
		print_str("usage: p2_import_scan_smoke <file>\n");
		return 1;
	}

	var entry = ptr64[argv + 8];
	if (entry == 0) { return 1; }

	var seen = vec_new(8);
	var order = vec_new(8);
	if (seen == 0) { return 2; }
	if (order == 0) { return 2; }

	var errs = v3h_build_module_order(entry, seen, order);
	if (errs != 0) { return 2; }

	print_str("modules=");
	print_u64(vec_len(order));
	print_str("\n");

	var n = vec_len(order);
	var i = 0;
	while (i < n) {
		var path = vec_get(order, i);
		var bp = v3h_path_basename_no_ext(path);
		alias rdx : bl_reg;
		var bl = bl_reg;
		print_str_len(bp, bl);
		print_str("\n");
		i = i + 1;
	}

	return 0;
}
