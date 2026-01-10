// v3_hosted P4: read file/stdin -> lex -> parse -> typecheck -> codegen asm to stdout

import io;
import file;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;
import v3_hosted.import_resolver;

func main(argc, argv) {
	if (argc < 2) {
		return 1;
	}

	alias rdx : n_reg;

	var path = ptr64[argv + 8];
	
	// stdin not supported with imports (would need to resolve relative paths)
	if (ptr8[path] == 45 && ptr8[path + 1] == 0) {
		// Error: stdin mode not supported
		return 1;
	}

	// Create import resolver
	var ir = import_resolver_new();
	if (ir == 0) {
		return 3;
	}
	
	// Get path length
	var path_len = 0;
	while (ptr8[path + path_len] != 0) {
		path_len = path_len + 1;
	}
	
	// Resolve all imports starting from main file
	var ok = import_resolver_resolve(ir, path, path_len);
	if (ok == 0) {
		return 4;
	}
	
	// Create merged program
	var prog = import_resolver_create_program(ir);
	if (prog == 0) {
		return 5;
	}
	
	// Typecheck
	var ty_errors = typecheck_program(prog);
	if (ty_errors != 0) {
		return 1;
	}

	// Codegen
	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) {
		return 2;
	}
	
	var out_p = ptr64[bytes + 0];
	var out_n = ptr64[bytes + 8];
	if (out_p == 0) {
		return 2;
	}
	
	sys_write(1, out_p, out_n);
	return 0;
}
