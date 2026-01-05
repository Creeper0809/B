// v3_hosted: driver helpers (Phase 1.3)
//
// - Scan "file-top contiguous import" list
// - Resolve imports to sibling .b files
// - Build deterministic module order (deps first)

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;

import vec;

func v3h_cstr_len(s) {
	var n = 0;
	while (ptr8[s + n] != 0) {
		n = n + 1;
	}
	return n;
}

func v3h_cstr_eq(a, b) {
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

func v3h_vec_contains_cstr(v, s) {
	var n = vec_len(v);
	var i = 0;
	while (i < n) {
		var it = vec_get(v, i);
		if (v3h_cstr_eq(it, s) == 1) { return 1; }
		i = i + 1;
	}
	return 0;
}

func v3h_diag_err_at_tok(tokp, msg) {
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

func v3h_path_dir_len(path) {
	// Returns length of directory prefix including trailing '/'.
	var n = v3h_cstr_len(path);
	var i = 0;
	var last_slash = 0;
	var saw = 0;
	while (i < n) {
		if (ptr8[path + i] == 47) { // '/'
			last_slash = i;
			saw = 1;
		}
		i = i + 1;
	}
	if (saw == 0) { return 0; }
	return last_slash + 1;
}

func v3h_path_basename_no_ext(path) {
	// Returns: rax=basename_ptr, rdx=basename_len
	var n = v3h_cstr_len(path);
	var start = path;
	var i = 0;
	while (i < n) {
		if (ptr8[path + i] == 47) { // '/'
			start = path + i + 1;
		}
		i = i + 1;
	}
	// Find last '.' after start.
	var dot = 0;
	var j = 0;
	while (ptr8[start + j] != 0) {
		if (ptr8[start + j] == 46) { dot = start + j; }
		j = j + 1;
	}
	var end = start + j;
	if (dot != 0) {
		// Only strip a trailing ".b".
		if (ptr8[dot + 1] == 98) { // 'b'
			if (ptr8[dot + 2] == 0) { end = dot; }
		}
	}
	alias rdx : out_len;
	out_len = end - start;
	return start;
}

func v3h_make_sibling_module_path(cur_path, mod_ptr, mod_len) {
	var dir_len = v3h_path_dir_len(cur_path);
	var total = dir_len + mod_len + 2 + 1; // ".b" + NUL
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
	ptr8[buf + dir_len + mod_len + 0] = 46; // '.'
	ptr8[buf + dir_len + mod_len + 1] = 98; // 'b'
	ptr8[buf + dir_len + mod_len + 2] = 0;
	return buf;
}

func v3h_scan_leading_imports(path, imports_out) {
	// Returns number of errors.
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) {
		print_str("error: failed to read file\n");
		return 1;
	}

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	if (lex == 0) { return 1; }
	if (tok == 0) { return 1; }

	lexer_init(lex, p, n);

	var errs = 0;
	var in_import_section = 1;

	while (1) {
		var k = lexer_next(lex, tok);
		if (k == TokKind.EOF) { break; }
		if (k == TokKind.ERR) {
			v3h_diag_err_at_tok(tok, "lexer error");
			errs = errs + 1;
			break;
		}

		if (in_import_section == 1) {
			if (k == TokKind.KW_IMPORT) {
				var kw_tok = tok;
				var k2 = lexer_next(lex, tok);
				if (k2 != TokKind.IDENT) {
					v3h_diag_err_at_tok(tok, "import: expected module name");
					errs = errs + 1;
					continue;
				}
				var name_ptr = ptr64[tok + 8];
				var name_len = ptr64[tok + 16];

				var k3 = lexer_next(lex, tok);
				if (k3 != TokKind.SEMI) {
					v3h_diag_err_at_tok(tok, "import: expected ';'");
					errs = errs + 1;
					continue;
				}

				var imp_path = v3h_make_sibling_module_path(path, name_ptr, name_len);
				if (imp_path == 0) { return errs + 1; }
				vec_push(imports_out, imp_path);
				continue;
			}

			if (k == TokKind.SEMI) { continue; }
			in_import_section = 0;
			continue;
		}

		// After first non-import token, any later "import" is an error.
		if (k == TokKind.KW_IMPORT) {
			v3h_diag_err_at_tok(tok, "import must appear in the leading import block");
			errs = errs + 1;
		}
	}

	return errs;
}

func v3h_build_module_order(entry_path, seen, order) {
	// Deterministic: DFS in import appearance order, push deps first.
	// Returns number of errors.
	if (v3h_vec_contains_cstr(seen, entry_path) == 1) { return 0; }
	vec_push(seen, entry_path);

	var imports = vec_new(4);
	if (imports == 0) { return 1; }
	var errs = v3h_scan_leading_imports(entry_path, imports);

	var n = vec_len(imports);
	var i = 0;
	while (i < n) {
		var imp = vec_get(imports, i);
		errs = errs + v3h_build_module_order(imp, seen, order);
		i = i + 1;
	}

	vec_push(order, entry_path);
	return errs;
}
