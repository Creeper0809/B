// Ad-hoc debug driver: prints extra info from typechecker FIELD failures.

import io;

import v3_hosted.typecheck;

func main(argc, argv) {
	if (argc < 2) {
		print_str("usage: tmp_debug_field_base_ty <file>\n");
		return 1;
	}
	// Enable debug prints in typechecker.
	tc_debug_field = 1;
	tc_debug_var = 1;
	tc_debug_ident = 1;

	var path = ptr64[argv + 8];
	var errs = typecheck_entry_file(path);
	print_str("type_errors=");
	print_u64(errs);
	print_str("\n");
	if (errs != 0) { return 1; }
	return 0;
}
