// v3_hosted: isolate driver helpers (no lexer scan)

import io;
import file;
import vec;

func v3hA_cstr_len(s) {
	var n = 0;
	while (ptr8[s + n] != 0) { n = n + 1; }
	return n;
}

func v3hA_cstr_eq(a, b) {
	var i = 0;
	while (1) {
		var ac = ptr8[a + i];
		var bc = ptr8[b + i];
		if (ac != bc) { return 0; }
		if (ac == 0) { return 1; }
		i = i + 1;
	}
	return 0;
}

func v3hA_vec_contains_cstr(v, s) {
	var n = vec_len(v);
	var i = 0;
	while (i < n) {
		var it = vec_get(v, i);
		if (v3hA_cstr_eq(it, s) == 1) { return 1; }
		i = i + 1;
	}
	return 0;
}

func v3hA_diag_err_at_tok(tokp, msg) {
	var line = ptr64[tokp + 24];
	var col = ptr64[tokp + 40];
	print_str("error at ");
	print_u64(line);
	print_str(":");
	print_u64(col);
	print_str(": ");
	print_str(msg);
	print_str("\n");
	return 0;
}

func v3hA_path_dir_len(path) {
	var n = v3hA_cstr_len(path);
	var i = 0;
	var last_slash = 0;
	var saw = 0;
	while (i < n) {
		if (ptr8[path + i] == 47) { last_slash = i; saw = 1; }
		i = i + 1;
	}
	if (saw == 0) { return 0; }
	return last_slash + 1;
}

func v3hA_make_sibling_module_path(cur_path, mod_ptr, mod_len) {
	var dir_len = v3hA_path_dir_len(cur_path);
	var total = dir_len + mod_len + 2 + 1;
	var buf = heap_alloc(total);
	if (buf == 0) { return 0; }
	var i = 0;
	while (i < dir_len) {
		ptr8[buf + i] = ptr8[cur_path + i];
		i = i + 1;
	}
	var j = 0;
	while (j < mod_len) {
		ptr8[buf + dir_len + j] = ptr8[mod_ptr + j];
		j = j + 1;
	}
	ptr8[buf + dir_len + mod_len + 0] = 46;
	ptr8[buf + dir_len + mod_len + 1] = 98;
	ptr8[buf + dir_len + mod_len + 2] = 0;
	return buf;
}
