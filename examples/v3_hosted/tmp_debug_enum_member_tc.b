// 임시 디버그 드라이버: enum 멤버(Color.Green)가 typecheck 이후
// AstExpr(FIELD)의 op/extra에 어떻게 저장되는지 확인용.
//
// 사용법:
//   ./bin/v2c ./examples/v3_hosted/tmp_debug_enum_member_tc.b
//   ./build/tmp_debug_enum_member_tc.b.v2_out_bin ./test/v3_hosted/codegen_golden/08_enum_value.b

import io;
import file;
import vec;
import slice;

import v3_hosted.ast;
import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.parser;
import v3_hosted.typecheck;

func dump_u64(label_ptr, label_len, v) {
	sys_write(1, label_ptr, label_len);
	print_u64(v);
	print_str("\n");
	return 0;
}

func dump_slice(label_ptr, label_len, p, n) {
	sys_write(1, label_ptr, label_len);
	if (p != 0 && n != 0) { sys_write(1, p, n); }
	print_str("\n");
	return 0;
}

func find_return_expr_in_stmt(s) {
	if (s == 0) { return 0; }
	var k = ptr64[s + 0];
	if (k == AstStmtKind.RETURN) {
		return ptr64[s + 56];
	}
	if (k == AstStmtKind.BLOCK) {
		var stmts = ptr64[s + 8];
		if (stmts != 0) {
			var n = vec_len(stmts);
			var i = 0;
			while (i < n) {
				var e = find_return_expr_in_stmt(vec_get(stmts, i));
				if (e != 0) { return e; }
				i = i + 1;
			}
		}
	}
	return 0;
}

func dump_expr(e) {
	if (e == 0) {
		print_str("expr=null\n");
		return 0;
	}
	var k = ptr64[e + 0];
	if (k == AstExprKind.BINARY) {
		dump_u64("BINARY op=", 10, ptr64[e + 8]);
		dump_expr(ptr64[e + 16]);
		dump_expr(ptr64[e + 24]);
		return 0;
	}
	if (k == AstExprKind.FIELD) {
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		dump_u64("FIELD op=", 9, ptr64[e + 8]);
		dump_u64("FIELD extra=", 12, extra);
		dump_u64("FIELD sz=", 9, sz);
		var base = ptr64[e + 16];
		if (base != 0 && ptr64[base + 0] == AstExprKind.IDENT) {
			dump_slice("  base ident=", 13, ptr64[base + 40], ptr64[base + 48]);
		} else {
			dump_u64("  base kind=", 12, ptr64[base + 0]);
		}
		// field name slice: parser stored in e+24; length is not preserved after typecheck overwrite.
		// 그래도 포인터는 남아있으니, extra의 low bits를 길이로 가정해 출력해본다.
		var n0 = extra & 36028797018963967;
		dump_slice("  field(guess)=", 15, ptr64[e + 24], n0);
		return 0;
	}
	if (k == AstExprKind.IDENT) {
		dump_slice("IDENT ", 6, ptr64[e + 40], ptr64[e + 48]);
		return 0;
	}
	if (k == AstExprKind.INT) {
		dump_slice("INT ", 4, ptr64[e + 40], ptr64[e + 48]);
		return 0;
	}
	dump_u64("expr kind=", 10, k);
	return 0;
}

func main(argc, argv) {
	if (argc < 2) {
		print_str("usage: tmp_debug_enum_member_tc <file>\n");
		return 1;
	}
	var path = ptr64[argv + 8];
	var p = read_file(path);
	alias rdx : n_reg;
	var n = n_reg;
	if (p == 0) { return 2; }

	var lex = heap_alloc(40);
	var tok = heap_alloc(48);
	var prs = heap_alloc(40);
	var prog = heap_alloc(16);
	if (lex == 0) { return 3; }
	if (tok == 0) { return 4; }
	if (prs == 0) { return 5; }
	if (prog == 0) { return 6; }

	lexer_init(lex, p, n);
	parser_init(prs, lex, tok);
	parse_program(prs, prog);
	var parse_errors = ptr64[prog + 8];
	if (parse_errors != 0) {
		print_str("parse_errors=\n");
		print_u64(parse_errors);
		print_str("\n");
		return 1;
	}

	// typecheck 전 상태 덤프 (parser가 FIELD.op/extra를 어떻게 세팅했는지 확인)
	var decls_pre = ptr64[prog + 0];
	var main_pre = 0;
	if (decls_pre != 0) {
		var nd_pre = vec_len(decls_pre);
		var i_pre = 0;
		while (i_pre < nd_pre) {
			var d_pre = vec_get(decls_pre, i_pre);
			if (d_pre != 0 && ptr64[d_pre + 0] == AstDeclKind.FUNC) {
				if (slice_eq(ptr64[d_pre + 8], ptr64[d_pre + 16], "main", 4) == 1) {
					main_pre = d_pre;
					break;
				}
			}
			i_pre = i_pre + 1;
		}
	}
	if (main_pre != 0) {
		var body_pre = ptr64[main_pre + 40];
		var rexpr_pre = find_return_expr_in_stmt(body_pre);
		print_str("--- return expr dump (pre-typecheck) ---\n");
		dump_expr(rexpr_pre);
	}

	var ty_errors = typecheck_program(prog);
	print_str("type_errors=");
	print_u64(ty_errors);
	print_str("\n");
	if (ty_errors != 0) { return 1; }

	// find func main
	var decls = ptr64[prog + 0];
	var main_decl = 0;
	if (decls != 0) {
		var nd = vec_len(decls);
		var i = 0;
		while (i < nd) {
			var d = vec_get(decls, i);
			if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
				if (slice_eq(ptr64[d + 8], ptr64[d + 16], "main", 4) == 1) {
					main_decl = d;
					break;
				}
			}
			i = i + 1;
		}
	}
	if (main_decl == 0) {
		print_str("no main\n");
		return 1;
	}

	var body = ptr64[main_decl + 40];
	var rexpr = find_return_expr_in_stmt(body);
	print_str("--- return expr dump (post-typecheck) ---\n");
	dump_expr(rexpr);
	return 0;
}
