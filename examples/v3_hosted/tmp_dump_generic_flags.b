// Debug helper: dump func decl_flags and type_params presence.
// Not used by tests.

import io;

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;
import v3_hosted.parser;
import v3_hosted.typecheck;

import vec;

func main(argc, argv) {
	var p = read_stdin_cap(1048576);
	alias rdx : n_reg;
	var n = n_reg;

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	if (lex == 0 || tok == 0 || prs == 0 || prog == 0) { return 1; }

	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);

	var parse_errors = ptr64[prog + 8];
	print_str("parse_errors=");
	print_u64(parse_errors);
	print_str("\n");
	if (parse_errors != 0) { return 1; }

	var ty_errors = typecheck_program(prog);
	print_str("type_errors=");
	print_u64(ty_errors);
	print_str("\n");

	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var ndecl = vec_len(decls);
	var i = 0;
	while (i < ndecl) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			print_str("func name_ptr=");
			print_u64(ptr64[d + 8]);
			print_str(" name_len=");
			print_u64(ptr64[d + 16]);
			print_str(" flags=");
			print_u64(ptr64[d + 80]);
			print_str(" type_params_ptr=");
			print_u64(ptr64[d + 96]);
			if (ptr64[d + 96] != 0 && vec_len(ptr64[d + 96]) > 0) {
				var tp0 = vec_get(ptr64[d + 96], 0);
				print_str(" tp0_len=");
				if (tp0 != 0) { print_u64(ptr64[tp0 + 8]); } else { print_u64(0); }
				print_str(" tp0_b0=");
				if (tp0 != 0) {
					var tpp = ptr64[tp0 + 0];
					if (tpp != 0) { print_u64(ptr8[tpp]); } else { print_u64(0); }
				} else { print_u64(0); }
			}
			// Dump first param type name info if present.
			var params = ptr64[d + 24];
			if (params != 0 && vec_len(params) > 0) {
				var ps0 = vec_get(params, 0);
				var ty0 = 0;
				if (ps0 != 0) { ty0 = ptr64[ps0 + 48]; }
				print_str(" p0_ty_kind=");
				if (ty0 != 0) { print_u64(ptr64[ty0 + 0]); } else { print_u64(0); }
				print_str(" p0_name_len=");
				if (ty0 != 0) { print_u64(ptr64[ty0 + 16]); } else { print_u64(0); }
				print_str(" p0_name_b0=");
				if (ty0 != 0) {
					var np = ptr64[ty0 + 8];
					if (np != 0) { print_u64(ptr8[np]); } else { print_u64(0); }
				} else { print_u64(0); }
			}
			// Dump return type name info if present.
			var rt = ptr64[d + 32];
			print_str(" rt_kind=");
			if (rt != 0) { print_u64(ptr64[rt + 0]); } else { print_u64(0); }
			print_str(" rt_name_len=");
			if (rt != 0) { print_u64(ptr64[rt + 16]); } else { print_u64(0); }
			print_str(" rt_name_b0=");
			if (rt != 0) {
				var rnp = ptr64[rt + 8];
				if (rnp != 0) { print_u64(ptr8[rnp]); } else { print_u64(0); }
			} else { print_u64(0); }
			print_str("\n");
		}
		i = i + 1;
	}
	return 0;
}
