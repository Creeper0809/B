// v3_hosted: parser (Phase 1.2)

import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.ast;

import io;
import vec;

struct Parser {
	lex: u64;
	tok: u64;
	kind: u64;
	errors: u64;
};

func parser_bump(p) {
	var lexp = ptr64[p + 0];
	var tokp = ptr64[p + 8];
	var k = lexer_next(lexp, tokp);
	ptr64[p + 16] = k;
	return k;
}

func parser_init(p, lexp, tokp) {
	ptr64[p + 0] = lexp;
	ptr64[p + 8] = tokp;
	ptr64[p + 16] = TokKind.ERR;
	ptr64[p + 24] = 0;
	parser_bump(p);
	return 0;
}

func parser_err_here(p, msg) {
	var tokp = ptr64[p + 8];
	var line = ptr64[tokp + 24];
	var col = ptr64[tokp + 40];
	print_str("error at ");
	print_u64(line);
	print_str(":");
	print_u64(col);
	print_str(": ");
	print_str(msg);
	print_str("\n");
	ptr64[p + 24] = ptr64[p + 24] + 1;
	return 0;
}

func parser_expect(p, want_kind, msg) {
	var k = ptr64[p + 16];
	if (k != want_kind) {
		parser_err_here(p, msg);
		return 0;
	}
	return 1;
}

func parser_match(p, want_kind) {
	if (ptr64[p + 16] == want_kind) {
		parser_bump(p);
		return 1;
	}
	return 0;
}

func parser_sync_stmt(p) {
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) { return 0; }
		if (k == TokKind.SEMI) { parser_bump(p); return 0; }
		// Avoid infinite loops on error recovery (e.g. top-level stray '}').
		if (k == TokKind.RBRACE) { parser_bump(p); return 0; }
		parser_bump(p);
	}
	return 0;
}

func parser_skip_braced(p) {
	// Assumes current token is '{'. Skips until matching '}' (handles nesting).
	if (parser_expect(p, TokKind.LBRACE, "expected '{'") == 0) { return 0; }
	var depth = 0;
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) {
			parser_err_here(p, "unexpected EOF in block");
			return 0;
		}
		if (k == TokKind.LBRACE) { depth = depth + 1; }
		else if (k == TokKind.RBRACE) {
			depth = depth - 1;
			parser_bump(p);
			if (depth == 0) { return 0; }
			continue;
		}
		parser_bump(p);
	}
	return 0;
}

func parse_u64_token(tok) {
	// Parse u64 from token text (decimal only for now)
	var ptr = ptr64[tok + 8];
	var len = ptr64[tok + 16];
	var val = 0;
	var i = 0;
	while (i < len) {
		var ch = ptr8[ptr + i];
		if (ch >= 48 && ch <= 57) {
			val = val * 10 + (ch - 48);
		} else {
			// Non-digit: stop parsing
			return val;
		}
		i = i + 1;
	}
	return val;
}

func type_new_name(name_ptr, name_len, tokp) {
	var t = heap_alloc(64);
	if (t == 0) { return 0; }
	ptr64[t + 0] = AstTypeKind.NAME;
	ptr64[t + 8] = name_ptr;
	ptr64[t + 16] = name_len;
	ptr64[t + 24] = ptr64[tokp + 32];
	ptr64[t + 32] = ptr64[tokp + 24];
	ptr64[t + 40] = ptr64[tokp + 40];
	ptr64[t + 48] = 0;
	ptr64[t + 56] = 0;
	return t;
}

func type_new_qual_name(mod_ptr, mod_len, name_ptr, name_len, tokp) {
	var t = heap_alloc(64);
	if (t == 0) { return 0; }
	ptr64[t + 0] = AstTypeKind.QUAL_NAME;
	ptr64[t + 8] = mod_ptr;
	ptr64[t + 16] = mod_len;
	ptr64[t + 24] = ptr64[tokp + 32];
	ptr64[t + 32] = ptr64[tokp + 24];
	ptr64[t + 40] = ptr64[tokp + 40];
	ptr64[t + 48] = name_ptr;
	ptr64[t + 56] = name_len;
	return t;
}

func type_new_ptr(inner, nullable, tokp) {
	var t = heap_alloc(64);
	if (t == 0) { return 0; }
	ptr64[t + 0] = AstTypeKind.PTR;
	ptr64[t + 8] = inner;
	ptr64[t + 16] = nullable;
	ptr64[t + 24] = ptr64[tokp + 32];
	ptr64[t + 32] = ptr64[tokp + 24];
	ptr64[t + 40] = ptr64[tokp + 40];
	ptr64[t + 48] = 0;
	ptr64[t + 56] = 0;
	return t;
}

func type_new_slice(inner, tokp) {
	var t = heap_alloc(64);
	if (t == 0) { return 0; }
	ptr64[t + 0] = AstTypeKind.SLICE;
	ptr64[t + 8] = inner;
	ptr64[t + 16] = 0;
	ptr64[t + 24] = ptr64[tokp + 32];
	ptr64[t + 32] = ptr64[tokp + 24];
	ptr64[t + 40] = ptr64[tokp + 40];
	ptr64[t + 48] = 0;
	ptr64[t + 56] = 0;
	return t;
}

func parser_parse_u64_dec(p, n) {
	var i = 0;
	var v = 0;
	while (i < n) {
		var ch = ptr8[p + i];
		if (ch < 48) { break; }
		if (ch > 57) { break; }
		v = (v * 10) + (ch - 48);
		i = i + 1;
	}
	return v;
}

func type_new_array(inner, len, tokp) {
	var t = heap_alloc(64);
	if (t == 0) { return 0; }
	ptr64[t + 0] = AstTypeKind.ARRAY;
	ptr64[t + 8] = inner;
	ptr64[t + 16] = len;
	ptr64[t + 24] = ptr64[tokp + 32];
	ptr64[t + 32] = ptr64[tokp + 24];
	ptr64[t + 40] = ptr64[tokp + 40];
	ptr64[t + 48] = 0;
	ptr64[t + 56] = 0;
	return t;
}

func expr_new_leaf(kind, tokp) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = kind;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = 0;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = ptr64[tokp + 8];
	ptr64[e + 48] = ptr64[tokp + 16];
	ptr64[e + 56] = ptr64[tokp + 32];
	ptr64[e + 64] = ptr64[tokp + 24];
	ptr64[e + 72] = ptr64[tokp + 40];
	return e;
}

func expr_new_unary(op, rhs, tokp) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.UNARY;
	ptr64[e + 8] = op;
	ptr64[e + 16] = rhs;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = ptr64[tokp + 8];
	ptr64[e + 48] = ptr64[tokp + 16];
	ptr64[e + 56] = ptr64[tokp + 32];
	ptr64[e + 64] = ptr64[tokp + 24];
	ptr64[e + 72] = ptr64[tokp + 40];
	return e;
}

func expr_new_binary(op, lhs, rhs, tokp) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.BINARY;
	ptr64[e + 8] = op;
	ptr64[e + 16] = lhs;
	ptr64[e + 24] = rhs;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = ptr64[tokp + 8];
	ptr64[e + 48] = ptr64[tokp + 16];
	ptr64[e + 56] = ptr64[tokp + 32];
	ptr64[e + 64] = ptr64[tokp + 24];
	ptr64[e + 72] = ptr64[tokp + 40];
	return e;
}

func expr_new_call(callee, args, tokp) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.CALL;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = callee;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = args;
	ptr64[e + 40] = ptr64[tokp + 8];
	ptr64[e + 48] = ptr64[tokp + 16];
	ptr64[e + 56] = ptr64[tokp + 32];
	ptr64[e + 64] = ptr64[tokp + 24];
	ptr64[e + 72] = ptr64[tokp + 40];
	return e;
}

func expr_new_cast(type_ptr, expr_ptr, tokp) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.CAST;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = type_ptr;
	ptr64[e + 24] = expr_ptr;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = ptr64[tokp + 8];
	ptr64[e + 48] = ptr64[tokp + 16];
	ptr64[e + 56] = ptr64[tokp + 32];
	ptr64[e + 64] = ptr64[tokp + 24];
	ptr64[e + 72] = ptr64[tokp + 40];
	return e;
}

func stmt_new_block(stmts, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.BLOCK;
	ptr64[s + 8] = stmts;
	ptr64[s + 16] = 0;
	ptr64[s + 24] = 0;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = 0;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func stmt_new_var(name_ptr, name_len, type_ptr, init_expr, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.VAR;
	ptr64[s + 8] = 0;
	ptr64[s + 16] = 0;
	ptr64[s + 24] = 0;
	ptr64[s + 32] = name_ptr;
	ptr64[s + 40] = name_len;
	ptr64[s + 48] = type_ptr;
	ptr64[s + 56] = init_expr;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func stmt_new_expr(expr_ptr, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.EXPR;
	ptr64[s + 8] = 0;
	ptr64[s + 16] = 0;
	ptr64[s + 24] = 0;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = expr_ptr;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func stmt_new_return(expr_ptr, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.RETURN;
	ptr64[s + 8] = 0;
	ptr64[s + 16] = 0;
	ptr64[s + 24] = 0;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = expr_ptr;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func stmt_new_if(cond, then_s, else_s, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.IF;
	ptr64[s + 8] = cond;
	ptr64[s + 16] = then_s;
	ptr64[s + 24] = else_s;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = 0;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func stmt_new_while(cond, body, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.WHILE;
	ptr64[s + 8] = cond;
	ptr64[s + 16] = body;
	ptr64[s + 24] = 0;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = 0;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func foreach_bind_new(name0_ptr, name0_len, name1_ptr, name1_len, has_two) {
	var b = heap_alloc(48);
	if (b == 0) { return 0; }
	ptr64[b + 0] = name0_ptr;
	ptr64[b + 8] = name0_len;
	ptr64[b + 16] = name1_ptr;
	ptr64[b + 24] = name1_len;
	ptr64[b + 32] = has_two;
	ptr64[b + 40] = 0; // elem_size_bytes (filled by typecheck)
	return b;
}

func stmt_new_foreach(bind, iter_expr, body, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.FOREACH;
	ptr64[s + 8] = bind;
	ptr64[s + 16] = iter_expr;
	ptr64[s + 24] = body;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = 0;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func decl_new_simple(kind, name_ptr, name_len, is_public, tokp) {
	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = kind;
	ptr64[d + 8] = name_ptr;
	ptr64[d + 16] = name_len;
	ptr64[d + 24] = 0;
	ptr64[d + 32] = 0;
	ptr64[d + 40] = 0;
	ptr64[d + 48] = ptr64[tokp + 32];
	ptr64[d + 56] = ptr64[tokp + 24];
	ptr64[d + 64] = ptr64[tokp + 40];
	ptr64[d + 72] = is_public;
	ptr64[d + 80] = 0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	return d;
}

func decl_new_global_var(kind, name_ptr, name_len, is_public, type_ptr, init_expr, tokp) {
	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = kind;
	ptr64[d + 8] = name_ptr;
	ptr64[d + 16] = name_len;
	ptr64[d + 24] = type_ptr;
	ptr64[d + 32] = init_expr;
	ptr64[d + 40] = 0;
	ptr64[d + 48] = ptr64[tokp + 32];
	ptr64[d + 56] = ptr64[tokp + 24];
	ptr64[d + 64] = ptr64[tokp + 40];
	ptr64[d + 72] = is_public;
	ptr64[d + 80] = 0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	return d;
}

func decl_new_func(name_ptr, name_len, is_public, params, ret_type, body, tokp) {
	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = AstDeclKind.FUNC;
	ptr64[d + 8] = name_ptr;
	ptr64[d + 16] = name_len;
	ptr64[d + 24] = params;
	ptr64[d + 32] = ret_type;
	ptr64[d + 40] = body;
	ptr64[d + 48] = ptr64[tokp + 32];
	ptr64[d + 56] = ptr64[tokp + 24];
	ptr64[d + 64] = ptr64[tokp + 40];
	ptr64[d + 72] = is_public;
	ptr64[d + 80] = 0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	return d;
}

func decl_new_struct(name_ptr, name_len, is_public, fields, tokp) {
	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = AstDeclKind.STRUCT;
	ptr64[d + 8] = name_ptr;
	ptr64[d + 16] = name_len;
	ptr64[d + 24] = fields;
	ptr64[d + 32] = 0;
	ptr64[d + 40] = 0;
	ptr64[d + 48] = ptr64[tokp + 32];
	ptr64[d + 56] = ptr64[tokp + 24];
	ptr64[d + 64] = ptr64[tokp + 40];
	ptr64[d + 72] = is_public;
	ptr64[d + 80] = 0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	return d;
}

func decl_new_enum(name_ptr, name_len, is_public, variants, tokp) {
	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = AstDeclKind.ENUM;
	ptr64[d + 8] = name_ptr;
	ptr64[d + 16] = name_len;
	ptr64[d + 24] = variants;
	ptr64[d + 32] = 0;
	ptr64[d + 40] = 0;
	ptr64[d + 48] = ptr64[tokp + 32];
	ptr64[d + 56] = ptr64[tokp + 24];
	ptr64[d + 64] = ptr64[tokp + 40];
	ptr64[d + 72] = is_public;
	ptr64[d + 80] = 0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	return d;
}

// AstDecl.decl_flags (keep in sync with typecheck)
const PARSER_DECL_FLAG_EXTERN = 1;
const PARSER_DECL_RETREG_SHIFT = 8;

func parser_reg_id(tokp) {
	// Map IDENT token text to x86-64 reg id (0..15). Unknown => 255.
	var p = ptr64[tokp + 8];
	var n = ptr64[tokp + 16];
	if (slice_eq_parts(p, n, "rax", 3) == 1) { return 0; }
	if (slice_eq_parts(p, n, "rcx", 3) == 1) { return 1; }
	if (slice_eq_parts(p, n, "rdx", 3) == 1) { return 2; }
	if (slice_eq_parts(p, n, "rbx", 3) == 1) { return 3; }
	if (slice_eq_parts(p, n, "rsi", 3) == 1) { return 6; }
	if (slice_eq_parts(p, n, "rdi", 3) == 1) { return 7; }
	if (slice_eq_parts(p, n, "r8", 2) == 1) { return 8; }
	if (slice_eq_parts(p, n, "r9", 2) == 1) { return 9; }
	if (slice_eq_parts(p, n, "r10", 3) == 1) { return 10; }
	if (slice_eq_parts(p, n, "r11", 3) == 1) { return 11; }
	if (slice_eq_parts(p, n, "r12", 3) == 1) { return 12; }
	if (slice_eq_parts(p, n, "r13", 3) == 1) { return 13; }
	if (slice_eq_parts(p, n, "r14", 3) == 1) { return 14; }
	if (slice_eq_parts(p, n, "r15", 3) == 1) { return 15; }
	return 255;
}

func parse_type(p) {
	var k = ptr64[p + 16];
	var tokp = ptr64[p + 8];
	if (k == TokKind.LBRACK) {
		// Slice type: []T
		// Array type: [N]T
		parser_bump(p); // '['
		if (ptr64[p + 16] == TokKind.RBRACK) {
			parser_bump(p);
			var inner2 = parse_type(p);
			return type_new_slice(inner2, tokp);
		}
		if (ptr64[p + 16] != TokKind.INT) {
			parser_err_here(p, "type: expected ']' or array length");
			return 0;
		}
		var ntok = ptr64[p + 8];
		var n_ptr = ptr64[ntok + 8];
		var n_len = ptr64[ntok + 16];
		var n = parser_parse_u64_dec(n_ptr, n_len);
		parser_bump(p); // INT
		parser_expect(p, TokKind.RBRACK, "type: expected ']' for array");
		if (ptr64[p + 16] == TokKind.RBRACK) { parser_bump(p); }
		var inner3 = parse_type(p);
		return type_new_array(inner3, n, tokp);
	}
	if (k == TokKind.STAR) {
		// Pointer type: *T or *T?
		parser_bump(p);
		var inner = parse_type(p);
		var nullable = 0;
		if (ptr64[p + 16] == TokKind.QUESTION) {
			nullable = 1;
			parser_bump(p);
		}
		return type_new_ptr(inner, nullable, tokp);
	}
	if (k == TokKind.IDENT) {
		var name0_ptr = ptr64[tokp + 8];
		var name0_len = ptr64[tokp + 16];
		parser_bump(p);
		if (ptr64[p + 16] == TokKind.DOT) {
			parser_bump(p);
			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "type: expected name after '.'");
				return 0;
			}
			var tokp2 = ptr64[p + 8];
			var name1_ptr = ptr64[tokp2 + 8];
			var name1_len = ptr64[tokp2 + 16];
			parser_bump(p);
			return type_new_qual_name(name0_ptr, name0_len, name1_ptr, name1_len, tokp);
		}
		return type_new_name(name0_ptr, name0_len, tokp);
	}
	parser_err_here(p, "type: expected name");
	return 0;
}

func parse_primary(p) {
	var k = ptr64[p + 16];
	var tokp = ptr64[p + 8];

	if (k == TokKind.KW_NULL) {
		var e0 = expr_new_leaf(AstExprKind.NULL, tokp);
		parser_bump(p);
		return e0;
	}

	if (k == TokKind.IDENT) {
		// builtin cast(Type, expr)
		var name_ptr = ptr64[tokp + 8];
		var name_len = ptr64[tokp + 16];
		// If this is `cast(`, parse as a dedicated AST node.
		if (slice_eq_parts(name_ptr, name_len, "cast", 4) == 1) {
			// consume 'cast'
			parser_bump(p);
			parser_expect(p, TokKind.LPAREN, "cast: expected '('");
			if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
			var t = parse_type(p);
			parser_expect(p, TokKind.COMMA, "cast: expected ','");
			if (ptr64[p + 16] == TokKind.COMMA) { parser_bump(p); }
			var e = parse_expr(p);
			parser_expect(p, TokKind.RPAREN, "cast: expected ')'");
			if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
			return expr_new_cast(t, e, tokp);
		}

		// builtin offsetof(Type, field)
		if (slice_eq_parts(name_ptr, name_len, "offsetof", 8) == 1) {
			// consume 'offsetof'
			parser_bump(p);
			parser_expect(p, TokKind.LPAREN, "offsetof: expected '('");
			if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }

			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "offsetof: expected type name");
				return 0;
			}
			var ty_tok = ptr64[p + 8];
			var t = type_new_name(ptr64[ty_tok + 8], ptr64[ty_tok + 16], ty_tok);
			parser_bump(p);

			parser_expect(p, TokKind.COMMA, "offsetof: expected ','");
			if (ptr64[p + 16] == TokKind.COMMA) { parser_bump(p); }

			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "offsetof: expected field name");
				return 0;
			}
			var field_tok = ptr64[p + 8];
			var field_ptr = ptr64[field_tok + 8];
			var field_len = ptr64[field_tok + 16];
			parser_bump(p);

			parser_expect(p, TokKind.RPAREN, "offsetof: expected ')'");
			if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }

			var eoff = heap_alloc(80);
			if (eoff == 0) { return 0; }
			ptr64[eoff + 0] = AstExprKind.OFFSETOF;
			ptr64[eoff + 8] = 0; // filled by typecheck
			ptr64[eoff + 16] = t; // AstType*
			ptr64[eoff + 24] = field_ptr;
			ptr64[eoff + 32] = field_len;
			ptr64[eoff + 40] = ptr64[tokp + 8];
			ptr64[eoff + 48] = ptr64[tokp + 16];
			ptr64[eoff + 56] = ptr64[tokp + 32];
			ptr64[eoff + 64] = ptr64[tokp + 24];
			ptr64[eoff + 72] = ptr64[tokp + 40];
			return eoff;
		}

		var e = expr_new_leaf(AstExprKind.IDENT, tokp);
		parser_bump(p);
		return e;
	}
	if (k == TokKind.INT) {
		var e = expr_new_leaf(AstExprKind.INT, tokp);
		parser_bump(p);
		return e;
	}
	if (k == TokKind.STRING) {
		var e = expr_new_leaf(AstExprKind.STRING, tokp);
		parser_bump(p);
		return e;
	}
	if (k == TokKind.CHAR) {
		var e = expr_new_leaf(AstExprKind.CHAR, tokp);
		parser_bump(p);
		return e;
	}
	if (k == TokKind.LPAREN) {
		parser_bump(p);
		var e = parse_expr(p);
		parser_expect(p, TokKind.RPAREN, "expected ')'");
		if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
		return e;
	}
	if (k == TokKind.LBRACE) {
		// brace-init expression: {e0, e1, ...}
		var tokp2 = ptr64[p + 8];
		parser_bump(p); // '{'
		var elems = vec_new(4);
		if (elems == 0) { return 0; }
		if (ptr64[p + 16] != TokKind.RBRACE) {
			while (1) {
				var a = parse_expr(p);
				if (a != 0) { vec_push(elems, a); }
				if (ptr64[p + 16] == TokKind.COMMA) {
					parser_bump(p);
					// allow trailing comma
					if (ptr64[p + 16] == TokKind.RBRACE) { break; }
					continue;
				}
				break;
			}
		}
		parser_expect(p, TokKind.RBRACE, "brace-init: expected '}'");
		if (ptr64[p + 16] == TokKind.RBRACE) { parser_bump(p); }
		var e2 = heap_alloc(80);
		if (e2 == 0) { return 0; }
		ptr64[e2 + 0] = AstExprKind.BRACE_INIT;
		ptr64[e2 + 8] = 0;
		ptr64[e2 + 16] = 0;
		ptr64[e2 + 24] = 0;
		ptr64[e2 + 32] = elems;
		ptr64[e2 + 40] = ptr64[tokp2 + 8];
		ptr64[e2 + 48] = ptr64[tokp2 + 16];
		ptr64[e2 + 56] = ptr64[tokp2 + 32];
		ptr64[e2 + 64] = ptr64[tokp2 + 24];
		ptr64[e2 + 72] = ptr64[tokp2 + 40];
		return e2;
	}

	parser_err_here(p, "expected expression");
	parser_bump(p);
	return 0;
}

func parse_postfix(p) {
	var e = parse_primary(p);
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.LPAREN) {

			// call
			var tokp = ptr64[p + 8];

			parser_bump(p); // '('
			var args = vec_new(4);
			if (args == 0) { return 0; }
			if (ptr64[p + 16] != TokKind.RPAREN) {
				while (1) {
					var a = parse_expr(p);
					if (a != 0) { vec_push(args, a); }
					if (ptr64[p + 16] == TokKind.COMMA) {
						parser_bump(p);
						continue;
					}
					break;
				}
			}
			parser_expect(p, TokKind.RPAREN, "call: expected ')'");
			if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
			e = expr_new_call(e, args, tokp);
			continue;
		}
		if (k == TokKind.LBRACK) {
			// index: e[expr] or e[$expr]
			var tokp2 = ptr64[p + 8];
			parser_bump(p); // '['
			var unsafe = 0;
			if (ptr64[p + 16] == TokKind.DOLLAR) {
				unsafe = 1;
				parser_bump(p);
			}
			var idx = parse_expr(p);
			parser_expect(p, TokKind.RBRACK, "index: expected ']'");
			if (ptr64[p + 16] == TokKind.RBRACK) { parser_bump(p); }
			var ex = heap_alloc(80);
			if (ex == 0) { return 0; }
			ptr64[ex + 0] = AstExprKind.INDEX;
			ptr64[ex + 8] = unsafe;
			ptr64[ex + 16] = e;
			ptr64[ex + 24] = idx;
			ptr64[ex + 32] = 0;
			ptr64[ex + 40] = ptr64[tokp2 + 8];
			ptr64[ex + 48] = ptr64[tokp2 + 16];
			ptr64[ex + 56] = ptr64[tokp2 + 32];
			ptr64[ex + 64] = ptr64[tokp2 + 24];
			ptr64[ex + 72] = ptr64[tokp2 + 40];
			e = ex;
			continue;
		}
		if (k == TokKind.DOT || k == TokKind.ARROW) {
			// field access: e.field or e->field
			var tokp3 = ptr64[p + 8];
			var via_ptr = 0;
			if (k == TokKind.ARROW) { via_ptr = 1; }
			parser_bump(p);
			var raw = 0;
			if (ptr64[p + 16] == TokKind.DOLLAR) {
				raw = 1;
				parser_bump(p);
			}
			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "field: expected name");
				continue;
			}
			var ftok = ptr64[p + 8];
			var field_ptr = ptr64[ftok + 8];
			var field_len = ptr64[ftok + 16];
			parser_bump(p);
			var ex2 = heap_alloc(80);
			if (ex2 == 0) { return 0; }
			ptr64[ex2 + 0] = AstExprKind.FIELD;
			// Typecheck will compute and store field offset in op.
			ptr64[ex2 + 8] = 0;
			ptr64[ex2 + 16] = e;
			ptr64[ex2 + 24] = field_ptr;
			// Pack (pre-typecheck): [field_len:62][via_ptr:1][raw:1]
			// Avoids relying on 2^63 literals/shifts in the bootstrap compiler.
			var packed = (field_len << 2);
			packed = packed | ((via_ptr & 1) << 1);
			packed = packed | (raw & 1);
			ptr64[ex2 + 32] = packed;
			ptr64[ex2 + 40] = ptr64[tokp3 + 8];
			ptr64[ex2 + 48] = ptr64[tokp3 + 16];
			ptr64[ex2 + 56] = ptr64[tokp3 + 32];
			ptr64[ex2 + 64] = ptr64[tokp3 + 24];
			ptr64[ex2 + 72] = ptr64[tokp3 + 40];
			e = ex2;
			continue;
		}
		// postfix ++ / -- (Phase 6.1)
		if (k == TokKind.PLUSPLUS) {
			var tokp4 = ptr64[p + 8];
			parser_bump(p);
			e = expr_new_unary(TokKind.PLUSPLUS, e, tokp4);
			continue;
		}
		if (k == TokKind.MINUSMINUS) {
			var tokp5 = ptr64[p + 8];
			parser_bump(p);
			e = expr_new_unary(TokKind.MINUSMINUS, e, tokp5);
			continue;
		}
		break;
	}
	return e;
}

func parse_unary(p) {
	var k = ptr64[p + 16];
	var is_prefix = 0;
	if (k == TokKind.PLUS) { is_prefix = 1; }
	else if (k == TokKind.MINUS) { is_prefix = 1; }
	else if (k == TokKind.BANG) { is_prefix = 1; }
	else if (k == TokKind.TILDE) { is_prefix = 1; }
	else if (k == TokKind.AMP) { is_prefix = 1; }
	else if (k == TokKind.STAR) { is_prefix = 1; }
	else if (k == TokKind.DOLLAR) { is_prefix = 1; }
	if (is_prefix == 0) {
		return parse_postfix(p);
	}

	var tokp = ptr64[p + 8];
	var op = k;
	parser_bump(p);
	var rhs = parse_unary(p);
	return expr_new_unary(op, rhs, tokp);
}

func parse_mul(p) {
	// Phase 1.x: no arithmetic precedence yet; keep '*' grouped with '+'
	// by deferring all arithmetic binary operators to parse_add().
	return parse_unary(p);
}

func parse_add(p) {
	var e = parse_mul(p);
	while (1) {
		var k = ptr64[p + 16];
		var is_arith = 0;
		if (k == TokKind.PLUS) { is_arith = 1; }
		else if (k == TokKind.MINUS) { is_arith = 1; }
		else if (k == TokKind.STAR) { is_arith = 1; }
		else if (k == TokKind.SLASH) { is_arith = 1; }
		else if (k == TokKind.PERCENT) { is_arith = 1; }
		if (is_arith == 0) { break; }
		var tokp = ptr64[p + 8];
		var op = k;
		parser_bump(p);
		var rhs = parse_mul(p);
		e = expr_new_binary(op, e, rhs, tokp);
	}
	return e;
}

func parse_shift(p) {
	var e = parse_add(p);
	while (1) {
		var k = ptr64[p + 16];
		if (k != TokKind.LSHIFT) { if (k != TokKind.RSHIFT) { if (k != TokKind.ROTL) { if (k != TokKind.ROTR) { break; } } } }
		var tokp = ptr64[p + 8];
		var op = k;
		parser_bump(p);
		var rhs = parse_add(p);
		e = expr_new_binary(op, e, rhs, tokp);
	}
	return e;
}

func parse_rel(p) {
	var e = parse_shift(p);
	while (1) {
		var k = ptr64[p + 16];
		var is_rel = 0;
		if (k == TokKind.LT) { is_rel = 1; }
		else if (k == TokKind.GT) { is_rel = 1; }
		else if (k == TokKind.LTE) { is_rel = 1; }
		else if (k == TokKind.GTE) { is_rel = 1; }
		if (is_rel == 0) { break; }
		var tokp = ptr64[p + 8];
		var op = k;
		parser_bump(p);
		var rhs = parse_shift(p);
		e = expr_new_binary(op, e, rhs, tokp);
	}
	return e;
}

func parse_eq(p) {
	var e = parse_rel(p);
	while (1) {
		var k = ptr64[p + 16];
		if (k != TokKind.EQEQ) {
			if (k != TokKind.NEQ) {
				if (k != TokKind.EQEQEQ) { if (k != TokKind.NEQEQ) { break; } }
			}
		}
		var tokp = ptr64[p + 8];
		var op = k;
		parser_bump(p);
		var rhs = parse_rel(p);
		e = expr_new_binary(op, e, rhs, tokp);
	}
	return e;
}

func stmt_new_wipe(a0, b0, tokp) {
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.WIPE;
	ptr64[s + 8] = a0; // expr0: variable or ptr
	ptr64[s + 16] = b0; // expr1: len (or 0)
	ptr64[s + 24] = 0;
	ptr64[s + 32] = 0;
	ptr64[s + 40] = 0;
	ptr64[s + 48] = 0;
	ptr64[s + 56] = 0;
	ptr64[s + 64] = ptr64[tokp + 32];
	ptr64[s + 72] = ptr64[tokp + 24];
	ptr64[s + 80] = ptr64[tokp + 40];
	ptr64[s + 88] = 0;
	return s;
}

func parse_wipe_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // wipe
	var a0 = parse_expr(p);
	var b0 = 0;
	if (parser_match(p, TokKind.COMMA) == 1) {
		b0 = parse_expr(p);
	}
	parser_expect(p, TokKind.SEMI, "wipe: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return stmt_new_wipe(a0, b0, kw_tok);
}

func parse_bitand(p) {
	var e = parse_eq(p);
	while (ptr64[p + 16] == TokKind.AMP) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_eq(p);
		e = expr_new_binary(TokKind.AMP, e, rhs, tokp);
	}
	return e;
}

func parse_bitxor(p) {
	var e = parse_bitand(p);
	while (ptr64[p + 16] == TokKind.CARET) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_bitand(p);
		e = expr_new_binary(TokKind.CARET, e, rhs, tokp);
	}
	return e;
}

func parse_bitor(p) {
	var e = parse_bitxor(p);
	while (ptr64[p + 16] == TokKind.PIPE) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_bitxor(p);
		e = expr_new_binary(TokKind.PIPE, e, rhs, tokp);
	}
	return e;
}

func parse_logand(p) {
	var e = parse_bitor(p);
	while (ptr64[p + 16] == TokKind.ANDAND) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_bitor(p);
		e = expr_new_binary(TokKind.ANDAND, e, rhs, tokp);
	}
	return e;
}

func parse_logor(p) {
	var e = parse_logand(p);
	while (ptr64[p + 16] == TokKind.OROR) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_logand(p);
		e = expr_new_binary(TokKind.OROR, e, rhs, tokp);
	}
	return e;
}

func parse_assign(p) {
	var e = parse_logor(p);
	var k = ptr64[p + 16];
	if (k == TokKind.EQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.EQ, e, rhs, tokp);
	}
	// compound assignment (Phase 6.1)
	else if (k == TokKind.PLUSEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.PLUSEQ, e, rhs, tokp);
	}
	else if (k == TokKind.MINUSEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.MINUSEQ, e, rhs, tokp);
	}
	else if (k == TokKind.STAREQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.STAREQ, e, rhs, tokp);
	}
	else if (k == TokKind.SLASHEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.SLASHEQ, e, rhs, tokp);
	}
	else if (k == TokKind.PERCENTEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.PERCENTEQ, e, rhs, tokp);
	}
	else if (k == TokKind.AMPEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.AMPEQ, e, rhs, tokp);
	}
	else if (k == TokKind.PIPEEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.PIPEEQ, e, rhs, tokp);
	}
	else if (k == TokKind.CARETEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.CARETEQ, e, rhs, tokp);
	}
	else if (k == TokKind.LSHIFTEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.LSHIFTEQ, e, rhs, tokp);
	}
	else if (k == TokKind.RSHIFTEQ) {
		var tokp = ptr64[p + 8];
		parser_bump(p);
		var rhs = parse_assign(p);
		e = expr_new_binary(TokKind.RSHIFTEQ, e, rhs, tokp);
	}
	return e;
}

func parse_expr(p) {
	return parse_assign(p);
}

func parse_var_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // var

	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "var: expected name");
		parser_sync_stmt(p);
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);

	var t = 0;
	// v2-style local array: var a[N] (= {...})?;  (u64 array only)
	if (ptr64[p + 16] == TokKind.LBRACK) {
		parser_bump(p); // '['
		if (ptr64[p + 16] != TokKind.INT) {
			parser_err_here(p, "var: expected array length");
		} else {
			var ntok = ptr64[p + 8];
			var n_ptr = ptr64[ntok + 8];
			var n_len = ptr64[ntok + 16];
			var n = parser_parse_u64_dec(n_ptr, n_len);
			parser_bump(p); // INT
			parser_expect(p, TokKind.RBRACK, "var: expected ']' for array");
			if (ptr64[p + 16] == TokKind.RBRACK) { parser_bump(p); }
			var u64t = type_new_name("u64", 3, kw_tok);
			t = type_new_array(u64t, n, kw_tok);
		}
	}
	if (parser_match(p, TokKind.COLON) == 1) {
		if (t != 0) {
			parser_err_here(p, "var: cannot combine name[N] with ':' type");
		}
		t = parse_type(p);
	}

	var init = 0;
	if (parser_match(p, TokKind.EQ) == 1) {
		init = parse_expr(p);
	}

	parser_expect(p, TokKind.SEMI, "var: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return stmt_new_var(name_ptr, name_len, t, init, kw_tok);
}

func parse_return_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // return
	var e = 0;
	if (ptr64[p + 16] != TokKind.SEMI) {
		e = parse_expr(p);
	}
	parser_expect(p, TokKind.SEMI, "return: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return stmt_new_return(e, kw_tok);
}

func parse_if_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // if
	parser_expect(p, TokKind.LPAREN, "if: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
	var cond = parse_expr(p);
	parser_expect(p, TokKind.RPAREN, "if: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
	var then_s = parse_stmt(p);
	var else_s = 0;
	if (parser_match(p, TokKind.KW_ELSE) == 1) {
		else_s = parse_stmt(p);
	}
	return stmt_new_if(cond, then_s, else_s, kw_tok);
}

func parse_while_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // while
	parser_expect(p, TokKind.LPAREN, "while: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
	var cond = parse_expr(p);
	parser_expect(p, TokKind.RPAREN, "while: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
	var body = parse_stmt(p);
	return stmt_new_while(cond, body, kw_tok);
}

func parse_foreach_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // foreach
	parser_expect(p, TokKind.LPAREN, "foreach: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }

	// v3 MVP: require `var` in foreach binding.
	parser_expect(p, TokKind.KW_VAR, "foreach: expected 'var'");
	if (ptr64[p + 16] == TokKind.KW_VAR) { parser_bump(p); }

	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "foreach: expected binding name");
		return 0;
	}
	var t0 = ptr64[p + 8];
	var name0_ptr = ptr64[t0 + 8];
	var name0_len = ptr64[t0 + 16];
	parser_bump(p);

	var has_two = 0;
	var name1_ptr = 0;
	var name1_len = 0;
	if (ptr64[p + 16] == TokKind.COMMA) {
		parser_bump(p);
		has_two = 1;
		if (ptr64[p + 16] != TokKind.IDENT) {
			parser_err_here(p, "foreach: expected second binding name");
			return 0;
		}
		var t1 = ptr64[p + 8];
		name1_ptr = ptr64[t1 + 8];
		name1_len = ptr64[t1 + 16];
		parser_bump(p);
	}

	// Expect `in` (IDENT token with text "in").
	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "foreach: expected 'in'");
		return 0;
	}
	var tin = ptr64[p + 8];
	if (slice_eq_parts(ptr64[tin + 8], ptr64[tin + 16], "in", 2) == 0) {
		parser_err_here(p, "foreach: expected 'in'");
		return 0;
	}
	parser_bump(p);

	var iter_expr = parse_expr(p);
	parser_expect(p, TokKind.RPAREN, "foreach: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
	var body = parse_stmt(p);
	var bind = foreach_bind_new(name0_ptr, name0_len, name1_ptr, name1_len, has_two);
	return stmt_new_foreach(bind, iter_expr, body, kw_tok);
}

func parse_for_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // for
	parser_expect(p, TokKind.LPAREN, "for: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
	
	// init (can be empty or var decl or expr stmt)
	var init = 0;
	if (ptr64[p + 16] != TokKind.SEMI) {
		if (ptr64[p + 16] == TokKind.KW_VAR) {
			init = parse_var_stmt(p);
		} else {
			var e = parse_expr(p);
			parser_expect(p, TokKind.SEMI, "for: expected ';'");
			if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
			init = stmt_new_expr(e, kw_tok);
		}
	} else {
		parser_bump(p); // skip first ;
	}
	
	// cond
	var cond = 0;
	if (ptr64[p + 16] != TokKind.SEMI) {
		cond = parse_expr(p);
	}
	parser_expect(p, TokKind.SEMI, "for: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	
	// post
	var post = 0;
	if (ptr64[p + 16] != TokKind.RPAREN) {
		post = parse_expr(p);
	}
	parser_expect(p, TokKind.RPAREN, "for: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
	
	var body = parse_stmt(p);
	// Store in stmt: a=init, b=cond, c=post, expr_ptr=body
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.FOR;
	ptr64[s + 8] = init;
	ptr64[s + 16] = cond;
	ptr64[s + 24] = post;
	ptr64[s + 56] = body;
	ptr64[s + 64] = ptr64[kw_tok + 8];
	ptr64[s + 72] = ptr64[kw_tok + 16];
	ptr64[s + 80] = ptr64[kw_tok + 32];
	ptr64[s + 88] = ptr64[kw_tok + 24];
	return s;
}

func parse_switch_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // switch
	parser_expect(p, TokKind.LPAREN, "switch: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
	var cond = parse_expr(p);
	parser_expect(p, TokKind.RPAREN, "switch: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
	parser_expect(p, TokKind.LBRACE, "switch: expected '{'");
	if (ptr64[p + 16] == TokKind.LBRACE) { parser_bump(p); }
	
	// Parse cases: vector of AstSwitchCase*
	// AstSwitchCase: +0=value_expr, +8=body, +16=?, +24=start_off, +32=line, ...
	var cases = vec_new(4);
	if (cases == 0) { return 0; }
	var default_body = 0;
	
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) {
			parser_err_here(p, "switch: unexpected EOF");
			break;
		}
		if (k == TokKind.RBRACE) {
			parser_bump(p);
			break;
		}
		if (k == TokKind.KW_CASE) {
			var case_tok = ptr64[p + 8];
			parser_bump(p);
			var case_expr = parse_expr(p);
			parser_expect(p, TokKind.COLON, "case: expected ':'");
			if (ptr64[p + 16] == TokKind.COLON) { parser_bump(p); }
			
			// Parse case body (statements until next case/default/})
			var case_stmts = vec_new(4);
			if (case_stmts != 0) {
				while (1) {
					var k2 = ptr64[p + 16];
					if (k2 == TokKind.KW_CASE || k2 == TokKind.KW_DEFAULT || k2 == TokKind.RBRACE || k2 == TokKind.EOF) {
						break;
					}
					var s = parse_stmt(p);
					if (s != 0) { vec_push(case_stmts, s); }
				}
			}
			var case_body = stmt_new_block(case_stmts, case_tok);
			
			// Create AstSwitchCase structure
			var sc = heap_alloc(48);
			if (sc != 0) {
				ptr64[sc + 0] = case_expr;
				ptr64[sc + 8] = case_body;
				ptr64[sc + 16] = 0;
				ptr64[sc + 24] = ptr64[case_tok + 8];
				ptr64[sc + 32] = ptr64[case_tok + 24];
				ptr64[sc + 40] = ptr64[case_tok + 40];
				vec_push(cases, sc);
			}
		}
		else if (k == TokKind.KW_DEFAULT) {
			var def_tok = ptr64[p + 8];
			parser_bump(p);
			parser_expect(p, TokKind.COLON, "default: expected ':'");
			if (ptr64[p + 16] == TokKind.COLON) { parser_bump(p); }
			
			// Parse default body
			var def_stmts = vec_new(4);
			if (def_stmts != 0) {
				while (1) {
					var k3 = ptr64[p + 16];
					if (k3 == TokKind.KW_CASE || k3 == TokKind.KW_DEFAULT || k3 == TokKind.RBRACE || k3 == TokKind.EOF) {
						break;
					}
					var s2 = parse_stmt(p);
					if (s2 != 0) { vec_push(def_stmts, s2); }
				}
			}
			default_body = stmt_new_block(def_stmts, def_tok);
		}
		else {
			parser_err_here(p, "switch: expected 'case' or 'default'");
			parser_sync_stmt(p);
			break;
		}
	}
	
	// Store in stmt: +8=cond, +16=cases, +24=default_body
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.SWITCH;
	ptr64[s + 8] = cond;
	ptr64[s + 16] = cases;
	ptr64[s + 24] = default_body;
	ptr64[s + 64] = ptr64[kw_tok + 8];
	ptr64[s + 72] = ptr64[kw_tok + 16];
	ptr64[s + 80] = ptr64[kw_tok + 32];
	ptr64[s + 88] = ptr64[kw_tok + 24];
	return s;
}

func parse_break_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // break
	
	// Optional: break N (for nested loops), default is 1
	var n = 1;
	if (ptr64[p + 16] == TokKind.INT) {
		var itok = ptr64[p + 8];
		n = parse_u64_token(itok);
		parser_bump(p);
	}
	
	parser_expect(p, TokKind.SEMI, "break: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.BREAK;
	ptr64[s + 8] = n;
	ptr64[s + 64] = ptr64[kw_tok + 8];
	ptr64[s + 72] = ptr64[kw_tok + 16];
	ptr64[s + 80] = ptr64[kw_tok + 32];
	ptr64[s + 88] = ptr64[kw_tok + 24];
	return s;
}

func parse_continue_stmt(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // continue
	
	// Optional: continue N (for nested loops), default is 1
	var n = 1;
	if (ptr64[p + 16] == TokKind.INT) {
		var itok = ptr64[p + 8];
		n = parse_u64_token(itok);
		parser_bump(p);
	}
	
	parser_expect(p, TokKind.SEMI, "continue: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	
	var s = heap_alloc(96);
	if (s == 0) { return 0; }
	ptr64[s + 0] = AstStmtKind.CONTINUE;
	ptr64[s + 8] = n;
	ptr64[s + 64] = ptr64[kw_tok + 8];
	ptr64[s + 72] = ptr64[kw_tok + 16];
	ptr64[s + 80] = ptr64[kw_tok + 32];
	ptr64[s + 88] = ptr64[kw_tok + 24];
	return s;
}

func parse_block(p) {
	var tokp = ptr64[p + 8];
	parser_expect(p, TokKind.LBRACE, "expected '{'");
	if (ptr64[p + 16] == TokKind.LBRACE) { parser_bump(p); }
	var stmts = vec_new(8);
	if (stmts == 0) { return 0; }
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) { parser_err_here(p, "unexpected EOF in block"); break; }
		if (k == TokKind.RBRACE) { parser_bump(p); break; }
		var s = parse_stmt(p);
		if (s != 0) { vec_push(stmts, s); }
	}
	return stmt_new_block(stmts, tokp);
}

func parse_stmt(p) {
	var k = ptr64[p + 16];
	if (k == TokKind.LBRACE) { return parse_block(p); }
	if (k == TokKind.KW_SECRET || k == TokKind.KW_NOSPILL) {
		// Phase 4.3/4.4: modifiers for var.
		var flags = 0;
		while (1) {
			var k2 = ptr64[p + 16];
			if (k2 == TokKind.KW_SECRET) { flags = flags | 1; parser_bump(p); continue; }
			if (k2 == TokKind.KW_NOSPILL) { flags = flags | 2; parser_bump(p); continue; }
			break;
		}
		parser_expect(p, TokKind.KW_VAR, "expected 'var' after modifier");
		if (ptr64[p + 16] == TokKind.KW_VAR) {
			var s0 = parse_var_stmt(p);
			if (s0 != 0) { ptr64[s0 + 8] = flags; }
			return s0;
		}
		parser_sync_stmt(p);
		return 0;
	}
	if (k == TokKind.KW_VAR) { return parse_var_stmt(p); }
	if (k == TokKind.KW_RETURN) { return parse_return_stmt(p); }
	if (k == TokKind.KW_IF) { return parse_if_stmt(p); }
	if (k == TokKind.KW_WHILE) { return parse_while_stmt(p); }
	if (k == TokKind.KW_FOREACH) { return parse_foreach_stmt(p); }
	if (k == TokKind.KW_FOR) { return parse_for_stmt(p); }
	if (k == TokKind.KW_SWITCH) { return parse_switch_stmt(p); }
	if (k == TokKind.KW_BREAK) { return parse_break_stmt(p); }
	if (k == TokKind.KW_CONTINUE) { return parse_continue_stmt(p); }
	if (k == TokKind.KW_WIPE) { return parse_wipe_stmt(p); }
	if (k == TokKind.SEMI) { parser_bump(p); return 0; }

	// expression statement
	var tokp = ptr64[p + 8];
	var e = parse_expr(p);
	
	parser_expect(p, TokKind.SEMI, "expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return stmt_new_expr(e, tokp);
}

func parse_import_decl(p) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p);
	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "import: expected module name");
		parser_sync_stmt(p);
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);
	parser_expect(p, TokKind.SEMI, "import: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return decl_new_simple(AstDeclKind.IMPORT, name_ptr, name_len, 0, kw_tok);
}

func parse_global_var_decl(p, decl_kind, is_public) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // var/const
	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "decl: expected name");
		parser_sync_stmt(p);
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);
	var t = 0;
	if (parser_match(p, TokKind.COLON) == 1) { t = parse_type(p); }
	var init = 0;
	if (parser_match(p, TokKind.EQ) == 1) { init = parse_expr(p); }
	parser_expect(p, TokKind.SEMI, "decl: expected ';'");
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return decl_new_global_var(decl_kind, name_ptr, name_len, is_public, t, init, kw_tok);
}

func parse_func_decl(p, is_public) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // func

	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "func: expected name");
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);

	parser_expect(p, TokKind.LPAREN, "func: expected '('");
	if (ptr64[p + 16] == TokKind.LPAREN) { parser_bump(p); }
	var params = vec_new(4);
	if (params == 0) { return 0; }
	var ret_reg0 = 0;
	if (ptr64[p + 16] != TokKind.RPAREN) {
		while (1) {
			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "param: expected name");
				break;
			}
			var ptok = ptr64[p + 8];
			var pname_ptr = ptr64[ptok + 8];
			var pname_len = ptr64[ptok + 16];
			var pline = ptr64[ptok + 24];
			var poff = ptr64[ptok + 32];
			var pcol = ptr64[ptok + 40];
			parser_bump(p);
			// Phase 4.5: optional register annotation: name @ rdi: u64
			var preg = 0;
			if (ptr64[p + 16] == TokKind.AT) {
				parser_bump(p);
				if (ptr64[p + 16] != TokKind.IDENT) {
					parser_err_here(p, "@reg: expected register name");
				}
				else {
					preg = parser_reg_id(ptr64[p + 8]);
					if (preg == 255) { parser_err_here(p, "@reg: unknown register"); }
					else if (preg == 0) { parser_err_here(p, "@reg: param cannot use rax"); }
					parser_bump(p);
				}
			}
			var ptype = 0;
			if (parser_match(p, TokKind.COLON) == 1) {
				ptype = parse_type(p);
			}
			var param_node = stmt_new_var(pname_ptr, pname_len, ptype, 0, ptok);
			if (param_node != 0) { ptr64[param_node + 16] = preg; }
			if (param_node != 0) { vec_push(params, param_node); }
			if (ptr64[p + 16] == TokKind.COMMA) { parser_bump(p); continue; }
			break;
		}
	}
	parser_expect(p, TokKind.RPAREN, "func: expected ')'");
	if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }

	var ret_type = 0;
	if (parser_match(p, TokKind.ARROW) == 1) {
		var ret_reg = 0;
		if (ptr64[p + 16] == TokKind.AT) {
			parser_bump(p);
			if (ptr64[p + 16] != TokKind.IDENT) {
				parser_err_here(p, "@reg: expected return register name");
			}
			else {
				ret_reg = parser_reg_id(ptr64[p + 8]);
				if (ret_reg == 255) { parser_err_here(p, "@reg: unknown register"); ret_reg = 0; }
				parser_bump(p);
			}
		}
		ret_reg0 = ret_reg;
		ret_type = parse_type(p);
	}

	var body = 0;
	if (ptr64[p + 16] == TokKind.LBRACE) {
		body = parse_block(p);
	} else {
		parser_err_here(p, "func: expected body block");
		parser_sync_stmt(p);
	}

	var d = decl_new_func(name_ptr, name_len, is_public, params, ret_type, body, kw_tok);
	if (ret_reg0 != 0) {
		ptr64[d + 80] = ptr64[d + 80] | ((ret_reg0 & 255) << PARSER_DECL_RETREG_SHIFT);
	}
	return d;
}

func parse_braced_decl(p, decl_kind) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p);
	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "decl: expected name");
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) { parser_err_here(p, "unexpected EOF in decl"); break; }
		if (k == TokKind.LBRACE) { break; }
		parser_bump(p);
	}
	if (ptr64[p + 16] == TokKind.LBRACE) { parser_skip_braced(p); }
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return decl_new_simple(decl_kind, name_ptr, name_len, 0, kw_tok);
}

func parse_struct_decl(p, is_public) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // struct

	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "struct: expected name");
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);

	parser_expect(p, TokKind.LBRACE, "struct: expected '{'");
	if (ptr64[p + 16] == TokKind.LBRACE) { parser_bump(p); }

	var fields = vec_new(8);
	if (fields == 0) { return 0; }
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) {
			parser_err_here(p, "unexpected EOF in struct");
			break;
		}
		if (k == TokKind.RBRACE) { parser_bump(p); break; }
		if (k == TokKind.SEMI) { parser_bump(p); continue; }
		if (k == TokKind.COMMA) { parser_bump(p); continue; }
		var fattr = 0;
		var fattr_args = 0;
		while (k == TokKind.AT) {
			// attribute: @[getter] / @[setter]
			parser_bump(p); // '@'
			parser_expect(p, TokKind.LBRACK, "attr: expected '['");
			if (ptr64[p + 16] == TokKind.LBRACK) { parser_bump(p); }
			if (ptr64[p + 16] == TokKind.IDENT) {
				var atok = ptr64[p + 8];
				var ap = ptr64[atok + 8];
				var al = ptr64[atok + 16];
				var is_getter = 0;
				var is_setter = 0;
				if (slice_eq_parts(ap, al, "getter", 6) == 1) { fattr = fattr | 1; is_getter = 1; }
				else if (slice_eq_parts(ap, al, "setter", 6) == 1) { fattr = fattr | 2; is_setter = 1; }
				else { parser_err_here(p, "unknown attribute"); }
				parser_bump(p);
				// Optional: @[getter(func)] / @[setter(func)]
				if (ptr64[p + 16] == TokKind.LPAREN) {
					parser_bump(p);
					if (ptr64[p + 16] != TokKind.IDENT) {
						parser_err_here(p, "attr: expected function name");
					} else {
						var ftok2 = ptr64[p + 8];
						var fp2 = ptr64[ftok2 + 8];
						var fl2 = ptr64[ftok2 + 16];
						parser_bump(p);
						if (fattr_args == 0) {
							fattr_args = heap_alloc(32);
							if (fattr_args != 0) {
								ptr64[fattr_args + 0] = 0;
								ptr64[fattr_args + 8] = 0;
								ptr64[fattr_args + 16] = 0;
								ptr64[fattr_args + 24] = 0;
							}
						}
						if (fattr_args != 0) {
							if (is_getter == 1) { ptr64[fattr_args + 0] = fp2; ptr64[fattr_args + 8] = fl2; }
							if (is_setter == 1) { ptr64[fattr_args + 16] = fp2; ptr64[fattr_args + 24] = fl2; }
						}
					}
					parser_expect(p, TokKind.RPAREN, "attr: expected ')'");
					if (ptr64[p + 16] == TokKind.RPAREN) { parser_bump(p); }
				}
			} else {
				parser_err_here(p, "attr: expected name");
			}
			parser_expect(p, TokKind.RBRACK, "attr: expected ']'");
			if (ptr64[p + 16] == TokKind.RBRACK) { parser_bump(p); }
			k = ptr64[p + 16];
			if (k == TokKind.SEMI) { parser_bump(p); k = ptr64[p + 16]; continue; }
			if (k == TokKind.COMMA) { parser_bump(p); k = ptr64[p + 16]; continue; }
		}
		var field_public = 0;
		if (k == TokKind.KW_PUBLIC) {
			field_public = 1;
			parser_bump(p);
			k = ptr64[p + 16];
			if (k == TokKind.SEMI) { parser_bump(p); continue; }
			if (k == TokKind.COMMA) { parser_bump(p); continue; }
		}
		if (k != TokKind.IDENT) {
			parser_err_here(p, "struct: expected field name");
			parser_bump(p);
			continue;
		}
		var ftok = ptr64[p + 8];
		var fname_ptr = ptr64[ftok + 8];
		var fname_len = ptr64[ftok + 16];
		parser_bump(p);

		parser_expect(p, TokKind.COLON, "struct: expected ':'");
		if (ptr64[p + 16] == TokKind.COLON) { parser_bump(p); }
		var ftype = parse_type(p);
		// Field separator: ',' (preferred) or ';'. Allow '}' immediately after last field.
		if (ptr64[p + 16] == TokKind.COMMA) {
			parser_bump(p);
		} else if (ptr64[p + 16] == TokKind.SEMI) {
			parser_bump(p);
		} else if (ptr64[p + 16] != TokKind.RBRACE) {
			parser_err_here(p, "struct: expected ',' or '}'");
			while (1) {
				var kk = ptr64[p + 16];
				if (kk == TokKind.EOF) { break; }
				if (kk == TokKind.RBRACE) { break; }
				if (kk == TokKind.COMMA) { parser_bump(p); break; }
				if (kk == TokKind.SEMI) { parser_bump(p); break; }
				parser_bump(p);
			}
		}

		var field_node = stmt_new_var(fname_ptr, fname_len, ftype, 0, ftok);
		if (field_node != 0) { ptr64[field_node + 8] = field_public; }
		if (field_node != 0) { ptr64[field_node + 16] = fattr; }
		if (field_node != 0) { ptr64[field_node + 24] = fattr_args; }
		if (field_node != 0) { vec_push(fields, field_node); }
	}
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return decl_new_struct(name_ptr, name_len, is_public, fields, kw_tok);
}

func parse_enum_decl(p, is_public) {
	var kw_tok = ptr64[p + 8];
	parser_bump(p); // enum

	if (ptr64[p + 16] != TokKind.IDENT) {
		parser_err_here(p, "enum: expected name");
		return 0;
	}
	var tokp = ptr64[p + 8];
	var name_ptr = ptr64[tokp + 8];
	var name_len = ptr64[tokp + 16];
	parser_bump(p);

	parser_expect(p, TokKind.LBRACE, "enum: expected '{'");
	if (ptr64[p + 16] == TokKind.LBRACE) { parser_bump(p); }

	var variants = vec_new(8);
	if (variants == 0) { return 0; }
	var next_val = 0;
	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) {
			parser_err_here(p, "unexpected EOF in enum");
			break;
		}
		if (k == TokKind.RBRACE) { parser_bump(p); break; }
		if (k == TokKind.SEMI) { parser_bump(p); continue; }
		if (k == TokKind.COMMA) { parser_bump(p); continue; }
		if (k != TokKind.IDENT) {
			parser_err_here(p, "enum: expected variant name");
			parser_bump(p);
			continue;
		}
		var vt = ptr64[p + 8];
		var vname_ptr = ptr64[vt + 8];
		var vname_len = ptr64[vt + 16];
		parser_bump(p);

		var v = next_val;
		if (ptr64[p + 16] == TokKind.EQ) {
			parser_bump(p);
			if (ptr64[p + 16] != TokKind.INT) {
				parser_err_here(p, "enum: expected integer value");
			}
			else {
				var it = ptr64[p + 8];
				var ip = ptr64[it + 8];
				var il = ptr64[it + 16];
				v = parser_parse_u64_dec(ip, il);
				parser_bump(p);
			}
		}
		next_val = v + 1;

		// Enum variant node layout: {name_ptr:u64, name_len:u64, value:u64}
		var ent = heap_alloc(24);
		var s = heap_alloc(96);
		if (ent != 0) {
			ptr64[ent + 0] = vname_ptr;
			ptr64[ent + 8] = vname_len;
			ptr64[ent + 16] = v;
			vec_push(variants, ent);
		}

		// Separator: ',' or ';' or '}'
		if (ptr64[p + 16] == TokKind.COMMA) {
			parser_bump(p);
		}
		else if (ptr64[p + 16] == TokKind.SEMI) {
		ptr64[s + 88] = 0;
			parser_bump(p);
		}
		else if (ptr64[p + 16] != TokKind.RBRACE) {
			parser_err_here(p, "enum: expected ',' or '}'");
			while (1) {
				var kk = ptr64[p + 16];
				if (kk == TokKind.EOF) { break; }
				if (kk == TokKind.RBRACE) { break; }
				if (kk == TokKind.COMMA) { parser_bump(p); break; }
				if (kk == TokKind.SEMI) { parser_bump(p); break; }
				parser_bump(p);
			}
		}
	}
	if (ptr64[p + 16] == TokKind.SEMI) { parser_bump(p); }
	return decl_new_enum(name_ptr, name_len, is_public, variants, kw_tok);
}

func parse_program(p, prog_out) {
	var decls = vec_new(8);
	if (decls == 0) { return 0; }
	ptr64[prog_out + 0] = decls;
	ptr64[prog_out + 8] = 0;

	while (1) {
		var k = ptr64[p + 16];
		if (k == TokKind.EOF) { break; }
		if (k == TokKind.ERR) {
			parser_err_here(p, "lexer error");
			parser_bump(p);
			continue;
		}

		var is_public = 0;
		if (k == TokKind.KW_PUBLIC) {
			is_public = 1;
			parser_bump(p);
			k = ptr64[p + 16];
		}

		var d = 0;
		if (k == TokKind.KW_IMPORT) {
			if (is_public == 1) {
				parser_err_here(p, "public: cannot apply to import");
			}
			d = parse_import_decl(p);
		} else if (k == TokKind.KW_PACKED) {
			// Phase 3.4: packed structs: `packed struct Name { ... };`
			parser_bump(p); // packed
			k = ptr64[p + 16];
			if (k != TokKind.KW_STRUCT) {
				parser_err_here(p, "packed: expected 'struct'");
				parser_sync_stmt(p);
				continue;
			}
			d = parse_struct_decl(p, is_public);
		} else if (k == TokKind.KW_EXTERN) {
			// Phase 4.5: extern func (minimal form for @reg MVP)
			var ext_tok = ptr64[p + 8];
			parser_bump(p);
			parser_expect(p, TokKind.KW_FUNC, "extern: expected 'func'");
			if (ptr64[p + 16] == TokKind.KW_FUNC) {
				d = parse_func_decl(p, is_public);
				if (d != 0) { ptr64[d + 80] = ptr64[d + 80] | PARSER_DECL_FLAG_EXTERN; }
			} else {
				parser_err_here(p, "extern: expected 'func'");
				parser_sync_stmt(p);
				continue;
			}
		} else if (k == TokKind.KW_FUNC) {
			d = parse_func_decl(p, is_public);
		} else if (k == TokKind.KW_VAR) {
			d = parse_global_var_decl(p, AstDeclKind.VAR, is_public);
		} else if (k == TokKind.KW_CONST) {
			d = parse_global_var_decl(p, AstDeclKind.CONST, is_public);
		} else if (k == TokKind.KW_ENUM) {
			d = parse_enum_decl(p, is_public);
		} else if (k == TokKind.KW_STRUCT) {
			d = parse_struct_decl(p, is_public);
		} else {
			parser_err_here(p, "top-level: unexpected token");
			parser_sync_stmt(p);
			continue;
		}
		if (d != 0) { vec_push(decls, d); }
	}
	ptr64[prog_out + 8] = ptr64[p + 24];
	return 0;
}
