// v3_hosted: isolate driver helpers (no printing)

import io;

func v3hB_cstr_len(s) {
	var n = 0;
	while (ptr8[s + n] != 0) { n = n + 1; }
	return n;
}

func v3hB_path_dir_len(path) {
	var n = v3hB_cstr_len(path);
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

func v3hB_make_sibling_module_path(cur_path, mod_ptr, mod_len) {
	var dir_len = v3hB_path_dir_len(cur_path);
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
