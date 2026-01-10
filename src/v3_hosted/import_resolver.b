// Import resolver for v3_hosted compiler
// Collects imports, resolves paths, and merges multiple modules into one AST

import io;
import file;
import vec;
import hashmap;

import v3_hosted.ast;
import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.parser;

// ImportResolver state
// offset 0: visited (hashmap: path -> 1)
// offset 8: pending (vec of path strings)
// offset 16: all_decls (vec of AstDecl*)

func import_resolver_new() {
	var ir = heap_alloc(24);
	if (ir == 0) { return 0; }
	
	ptr64[ir + 0] = hashmap_new();
	ptr64[ir + 8] = vec_new(4);
	ptr64[ir + 16] = vec_new(16);
	
	return ir;
}

// Convert module name to file path
// "v3_hosted.lexer" -> "src/v3_hosted/lexer.b"
// "test_helper" -> "test/test_helper.b"
func resolve_import_path(name_ptr, name_len) {
	var buf = heap_alloc(256);
	if (buf == 0) { return 0; }
	
	var pos = 0;
	var has_dot = 0;
	
	// Check if name contains a dot
	var i = 0;
	while (i < name_len) {
		if (ptr8[name_ptr + i] == 46) { // '.'
			has_dot = 1;
			break;
		}
		i = i + 1;
	}
	
	// Check if starts with "v3_hosted."
	var is_v3_hosted = 0;
	if (name_len >= 10) {
		if (ptr8[name_ptr] == 118 && ptr8[name_ptr + 1] == 51 && ptr8[name_ptr + 2] == 95 &&
		    ptr8[name_ptr + 3] == 104 && ptr8[name_ptr + 4] == 111 && ptr8[name_ptr + 5] == 115 &&
		    ptr8[name_ptr + 6] == 116 && ptr8[name_ptr + 7] == 101 && ptr8[name_ptr + 8] == 100 &&
		    ptr8[name_ptr + 9] == 46) { // "v3_hosted."
			is_v3_hosted = 1;
		}
	}
	
	if (is_v3_hosted == 1) {
		// Add "src/" prefix
		ptr8[buf + pos] = 115; pos = pos + 1; // 's'
		ptr8[buf + pos] = 114; pos = pos + 1; // 'r'
		ptr8[buf + pos] = 99; pos = pos + 1; // 'c'
		ptr8[buf + pos] = 47; pos = pos + 1;  // '/'
	} else if (has_dot == 0) {
		// Simple name without dots: assume test/ folder
		ptr8[buf + pos] = 116; pos = pos + 1; // 't'
		ptr8[buf + pos] = 101; pos = pos + 1; // 'e'
		ptr8[buf + pos] = 115; pos = pos + 1; // 's'
		ptr8[buf + pos] = 116; pos = pos + 1; // 't'
		ptr8[buf + pos] = 47; pos = pos + 1;  // '/'
	}
	
	// Convert dots to slashes and copy name
	i = 0;
	while (i < name_len) {
		var c = ptr8[name_ptr + i];
		if (c == 46) { // '.' -> '/'
			ptr8[buf + pos] = 47;
		} else {
			ptr8[buf + pos] = c;
		}
		pos = pos + 1;
		i = i + 1;
	}
	
	// Add ".b" extension
	ptr8[buf + pos] = 46; pos = pos + 1;  // '.'
	ptr8[buf + pos] = 98; pos = pos + 1;  // 'b'
	ptr8[buf + pos] = 0; // null terminator
	
	return buf;
}

// Check if path is already visited
func import_resolver_is_visited(ir, path_ptr, path_len) {
	var visited = ptr64[ir + 0];
	return hashmap_has(visited, path_ptr, path_len);
}

// Mark path as visited
func import_resolver_mark_visited(ir, path_ptr, path_len) {
	var visited = ptr64[ir + 0];
	// Copy path string
	var path_copy = heap_alloc(path_len + 1);
	if (path_copy == 0) { return 0; }
	var i = 0;
	while (i < path_len) {
		ptr8[path_copy + i] = ptr8[path_ptr + i];
		i = i + 1;
	}
	ptr8[path_copy + path_len] = 0;
	
	hashmap_put(visited, path_copy, path_len, 1);
	return 0;
}

// Parse a single file and collect its imports
func import_resolver_parse_file(ir, path_ptr) {
	// Read file
	alias rdx : n_content;
	var content = read_file(path_ptr);
	var n = n_content;
	if (content == 0) {
		// Failed to read file
		return 0;
	}
	
	// Lex and parse
	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	if (lex == 0 || tok == 0 || prs == 0 || prog == 0) {
		return 0;
	}
	
	lexer_init(lex, content, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	
	var parse_errors = ptr64[prog + 8];
	if (parse_errors != 0) {
		// Parse errors occurred
		return 0;
	}
	
	// Collect decls and find imports
	var decls = ptr64[prog + 0];
	if (decls != 0) {
		var nd = vec_len(decls);
		var i = 0;
		while (i < nd) {
			var d = vec_get(decls, i);
			var dk = ptr64[d + 0];
			
			if (dk == AstDeclKind.IMPORT) {
				// Found import, resolve and add to pending
				var name_ptr = ptr64[d + 8];
				var name_len = ptr64[d + 16];
				
				// Skip standard library imports
				// These are handled by v2c linker, not our import system
				var skip = 0;
				
				// Check common stdlib names
				if (name_len <= 10) {
					// io, file, vec, hashmap, etc.
					skip = 1;
				}
				
				if (skip == 1) {
					i = i + 1;
					continue;
				}
				
				var import_path = resolve_import_path(name_ptr, name_len);
				if (import_path != 0) {
					// Check if not already visited
					var import_len = 0;
					while (ptr8[import_path + import_len] != 0) {
						import_len = import_len + 1;
					}
					
					if (import_resolver_is_visited(ir, import_path, import_len) == 0) {
						var pending = ptr64[ir + 8];
						vec_push(pending, import_path);
						import_resolver_mark_visited(ir, import_path, import_len);
					}
				}
			} else {
				// Non-import decl: add to all_decls
				var all_decls = ptr64[ir + 16];
				vec_push(all_decls, d);
			}
			
			i = i + 1;
		}
	}
	
	return 1;
}

// Resolve all imports starting from main file
func import_resolver_resolve(ir, main_path_ptr, main_path_len) {
	// Mark main as visited and add to pending
	import_resolver_mark_visited(ir, main_path_ptr, main_path_len);
	var pending = ptr64[ir + 8];
	vec_push(pending, main_path_ptr);
	
	// Process pending files
	while (vec_len(pending) > 0) {
		var path = vec_pop(pending);
		if (path == 0) { break; }
		
		var ok = import_resolver_parse_file(ir, path);
		if (ok == 0) {
			return 0;
		}
	}
	
	return 1;
}

// Create merged program with all collected decls
func import_resolver_create_program(ir) {
	var prog = heap_alloc(16);
	if (prog == 0) { return 0; }
	
	ptr64[prog + 0] = ptr64[ir + 16]; // all_decls
	ptr64[prog + 8] = 0; // no errors
	
	return prog;
}
