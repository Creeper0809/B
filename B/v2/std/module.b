// v2 library: module path resolution helpers
//
// Intended for v2-compiled output binaries.

import io;
import vec;
import mem;
import str;
import file;
import panic;

var module_roots;

func cstr_len(s) {
	return strlen(s);
}

func dirname_cstr(path) {
	// Returns new cstr containing directory (with trailing '/'), or "./".
	var last = 18446744073709551615; // -1
	var i = 0;
	while (ptr8[path + i] != 0) {
		if (ptr8[path + i] == 47) {
			last = i;
		}
		i = i + 1;
	}

	if (last == 18446744073709551615) {
		var out = heap_alloc(3);
		if (out == 0) { die("dirname_cstr: oom"); }
		ptr8[out + 0] = 46;
		ptr8[out + 1] = 47;
		ptr8[out + 2] = 0;
		return out;
	}

	var n = last + 1;
	var out2 = heap_alloc(n + 1);
	if (out2 == 0) { die("dirname_cstr: oom"); }
	memcpy(out2, path, n);
	ptr8[out2 + n] = 0;
	return out2;
}

func normalize_root(path) {
	var n = cstr_len(path);
	if (n == 0) {
		var out = heap_alloc(3);
		if (out == 0) { die("normalize_root: oom"); }
		ptr8[out + 0] = 46;
		ptr8[out + 1] = 47;
		ptr8[out + 2] = 0;
		return out;
	}

	var last = ptr8[path + (n - 1)];
	if (last == 47) {
		return path;
	}

	var out2 = heap_alloc(n + 2);
	if (out2 == 0) { die("normalize_root: oom"); }
	memcpy(out2, path, n);
	ptr8[out2 + n] = 47;
	ptr8[out2 + n + 1] = 0;
	return out2;
}

func module_add_root(root_cstr) {
	var root2 = normalize_root(root_cstr);
	if (module_roots == 0) {
		module_roots = vec_new(4);
		if (module_roots == 0) { die("module_add_root: oom"); }
	}
	vec_push(module_roots, root2);
	return 0;
}

func try_resolve_in_root(root_cstr, rel_cstr) {
	// Returns: rax=path, rdx=ok
	var root_len = cstr_len(root_cstr);
	var rel_len = cstr_len(rel_cstr);

	var p = str_concat(root_cstr, root_len, rel_cstr, rel_len);
	alias rdx : n;
	var pn = n;

	var p2 = str_concat(p, pn, ".b", 2);
	alias rdx : n2;

	if (file_exists(p2) == 1) {
		alias rdx : ok;
		ok = 1;
		return p2;
	}

	var p3 = str_concat(root_cstr, root_len, rel_cstr, rel_len);
	alias rdx : n3;
	var pn3 = n3;

	var p4 = str_concat(p3, pn3, "/__init__.b", 11);
	alias rdx : n4;

	if (file_exists(p4) == 1) {
		alias rdx : ok;
		ok = 1;
		return p4;
	}

	alias rdx : ok;
	ok = 0;
	return 0;
}

func resolve_import_to_file(dir_cstr, rel_cstr) {
	var path0 = try_resolve_in_root(dir_cstr, rel_cstr);
	alias rdx : ok;
	if (ok != 0) {
		return path0;
	}

	if (module_roots == 0) {
		die("import: module not found");
	}

	var i = 0;
	var n = vec_len(module_roots);
	while (i < n) {
		var root = vec_get(module_roots, i);
		var path1 = try_resolve_in_root(root, rel_cstr);
		if (ok != 0) {
			return path1;
		}
		i = i + 1;
	}

	die("import: module not found");
	return 0;
}
