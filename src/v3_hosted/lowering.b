// v3_hosted: AST lowering (Phase 5.1+)
//
// MVP (Jan 2026): This pass does not rewrite the AST yet.
// Instead, it builds a canonical "type-function" side table for generic
// templates so we can migrate semantics from typecheck into comptime eval
// incrementally without breaking the existing pipeline.

import v3_hosted.ast;
import vec;

// Lowering helpers

func lw_expr_new_type_lit(t, start_off, line, col) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.TYPE_LIT;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = t;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = 0;
	ptr64[e + 48] = 0;
	ptr64[e + 56] = start_off;
	ptr64[e + 64] = line;
	ptr64[e + 72] = col;
	return e;
}

func lw_expr_new_ident(name_ptr, name_len, start_off, line, col) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.IDENT;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = 0;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = 0;
	ptr64[e + 40] = name_ptr;
	ptr64[e + 48] = name_len;
	ptr64[e + 56] = start_off;
	ptr64[e + 64] = line;
	ptr64[e + 72] = col;
	return e;
}

func lw_expr_new_call(callee, args, start_off, line, col) {
	var e = heap_alloc(80);
	if (e == 0) { return 0; }
	ptr64[e + 0] = AstExprKind.CALL;
	ptr64[e + 8] = 0;
	ptr64[e + 16] = callee;
	ptr64[e + 24] = 0;
	ptr64[e + 32] = args;
	ptr64[e + 40] = 0;
	ptr64[e + 48] = 0;
	ptr64[e + 56] = start_off;
	ptr64[e + 64] = line;
	ptr64[e + 72] = col;
	return e;
}

func lw_lower_type_in_place(t) {
	if (t == 0) { return 0; }
	var k = ptr64[t + 0];
	if (k == AstTypeKind.PTR || k == AstTypeKind.SLICE) {
		lw_lower_type_in_place(ptr64[t + 8]);
		return 0;
	}
	if (k == AstTypeKind.TUPLE) {
		var elems = ptr64[t + 48];
		if (elems != 0) {
			var n = vec_len(elems);
			var i = 0;
			while (i < n) {
				lw_lower_type_in_place(vec_get(elems, i));
				i = i + 1;
			}
		}
		return 0;
	}
	if (k == AstTypeKind.ARRAY) {
		lw_lower_type_in_place(ptr64[t + 8]);
		var len_expr = ptr64[t + 48];
		if (len_expr != 0) { lw_lower_expr_in_place(len_expr); }
		return 0;
	}
	if (k == AstTypeKind.GENERIC) {
		var base = ptr64[t + 8];
		var args_ast = ptr64[t + 48];
		if (base == 0 || args_ast == 0) { return 0; }
		lw_lower_type_in_place(base);

		// Only lower Name<...> / Mod.Name<...> where the base resolves to a name.
		var base_k = ptr64[base + 0];
		var name_ptr = 0;
		var name_len = 0;
		if (base_k == AstTypeKind.NAME) {
			name_ptr = ptr64[base + 8];
			name_len = ptr64[base + 16];
		} else if (base_k == AstTypeKind.QUAL_NAME) {
			name_ptr = ptr64[base + 48];
			name_len = ptr64[base + 56];
		} else {
			return 0;
		}

		// Build callee name: "__typefn$" + StructName
		var prefix_len = 9;
		var callee_len = prefix_len + name_len;
		var callee_name = heap_alloc(callee_len);
		if (callee_name == 0) { return 0; }
		ptr8[callee_name + 0] = 95; // '_'
		ptr8[callee_name + 1] = 95; // '_'
		ptr8[callee_name + 2] = 116; // 't'
		ptr8[callee_name + 3] = 121; // 'y'
		ptr8[callee_name + 4] = 112; // 'p'
		ptr8[callee_name + 5] = 101; // 'e'
		ptr8[callee_name + 6] = 102; // 'f'
		ptr8[callee_name + 7] = 110; // 'n'
		ptr8[callee_name + 8] = 36;  // '$'
		var j = 0;
		while (j < name_len) {
			ptr8[callee_name + prefix_len + j] = ptr8[name_ptr + j];
			j = j + 1;
		}

		var start_off = ptr64[t + 24];
		var line = ptr64[t + 32];
		var col = ptr64[t + 40];
		var callee_ident = lw_expr_new_ident(callee_name, callee_len, start_off, line, col);
		if (callee_ident == 0) { return 0; }

		var call_args = vec_new(4);
		if (call_args == 0) { return 0; }
		var an = vec_len(args_ast);
		var ai = 0;
		while (ai < an) {
			var raw = vec_get(args_ast, ai);
			var tag = raw & 1;
			if (tag == 0) {
				var aty = raw;
				lw_lower_type_in_place(aty);
				var te = lw_expr_new_type_lit(aty, start_off, line, col);
				if (te != 0) { vec_push(call_args, te); }
			} else {
				var ve = raw - 1;
				lw_lower_expr_in_place(ve);
				vec_push(call_args, ve);
			}
			ai = ai + 1;
		}

		var call = lw_expr_new_call(callee_ident, call_args, start_off, line, col);
		if (call == 0) { return 0; }

		// Rewrite this AstType node in-place to COMPTIME_EXPR.
		ptr64[t + 0] = AstTypeKind.COMPTIME_EXPR;
		ptr64[t + 8] = call; // a=AstExpr*
		ptr64[t + 16] = 0;
		ptr64[t + 48] = 0;
		ptr64[t + 56] = 0;
		return 0;
	}
	return 0;
}

func lw_lower_expr_in_place(e) {
	if (e == 0) { return 0; }
	var k = ptr64[e + 0];
	if (k == AstExprKind.UNARY) {
		lw_lower_expr_in_place(ptr64[e + 16]);
		return 0;
	}
	if (k == AstExprKind.BINARY) {
		lw_lower_expr_in_place(ptr64[e + 16]);
		lw_lower_expr_in_place(ptr64[e + 24]);
		return 0;
	}
	if (k == AstExprKind.CALL) {
		lw_lower_expr_in_place(ptr64[e + 16]);
		var args = ptr64[e + 32];
		if (args != 0) {
			var n = vec_len(args);
			var i = 0;
			while (i < n) {
				lw_lower_expr_in_place(vec_get(args, i));
				i = i + 1;
			}
		}
		return 0;
	}
	if (k == AstExprKind.CAST) {
		lw_lower_type_in_place(ptr64[e + 16]);
		lw_lower_expr_in_place(ptr64[e + 24]);
		return 0;
	}
	if (k == AstExprKind.INDEX) {
		lw_lower_expr_in_place(ptr64[e + 16]);
		lw_lower_expr_in_place(ptr64[e + 24]);
		return 0;
	}
	if (k == AstExprKind.BRACE_INIT) {
		// Phase 3.6: typed brace init (struct literal) carries an AstType in a.
		var t0 = ptr64[e + 16];
		if (t0 != 0) { lw_lower_type_in_place(t0); }
		var elems = ptr64[e + 32];
		if (elems != 0) {
			var n2 = vec_len(elems);
			var i2 = 0;
			while (i2 < n2) {
				lw_lower_expr_in_place(vec_get(elems, i2));
				i2 = i2 + 1;
			}
		}
		return 0;
	}
	if (k == AstExprKind.OFFSETOF) {
		lw_lower_type_in_place(ptr64[e + 16]);
		return 0;
	}
	if (k == AstExprKind.FIELD) {
		lw_lower_expr_in_place(ptr64[e + 16]);
		return 0;
	}
	// IDENT/INT/STRING/CHAR/NULL/TYPE_LIT have no children.
	return 0;
}

func lw_lower_stmt_in_place(s) {
	if (s == 0) { return 0; }
	var k = ptr64[s + 0];
	if (k == AstStmtKind.BLOCK) {
		var stmts = ptr64[s + 8];
		if (stmts != 0) {
			var n = vec_len(stmts);
			var i = 0;
			while (i < n) {
				lw_lower_stmt_in_place(vec_get(stmts, i));
				i = i + 1;
			}
		}
		return 0;
	}
	if (k == AstStmtKind.VAR) {
		lw_lower_type_in_place(ptr64[s + 48]);
		lw_lower_expr_in_place(ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.EXPR) {
		lw_lower_expr_in_place(ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.RETURN) {
		var es = ptr64[s + 8];
		if (es != 0) {
			var n = vec_len(es);
			var i = 0;
			while (i < n) {
				lw_lower_expr_in_place(vec_get(es, i));
				i = i + 1;
			}
			return 0;
		}
		lw_lower_expr_in_place(ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.DESTRUCT) {
		lw_lower_expr_in_place(ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.IF) {
		lw_lower_expr_in_place(ptr64[s + 8]);
		lw_lower_stmt_in_place(ptr64[s + 16]);
		lw_lower_stmt_in_place(ptr64[s + 24]);
		return 0;
	}
	if (k == AstStmtKind.WHILE) {
		lw_lower_expr_in_place(ptr64[s + 8]);
		lw_lower_stmt_in_place(ptr64[s + 16]);
		return 0;
	}
	if (k == AstStmtKind.FOR) {
		lw_lower_stmt_in_place(ptr64[s + 8]);
		lw_lower_expr_in_place(ptr64[s + 16]);
		lw_lower_stmt_in_place(ptr64[s + 24]);
		lw_lower_stmt_in_place(ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.FOREACH) {
		// Layout (see parser/typecheck):
		//  +8  bind (AstForeachBind*)
		// +16  iter_expr (AstExpr*)
		// +24  body (AstStmt*)
		lw_lower_expr_in_place(ptr64[s + 16]);
		lw_lower_stmt_in_place(ptr64[s + 24]);
		return 0;
	}
	if (k == AstStmtKind.SWITCH) {
		// Layout (see ast.b):
		//  +8  scrutinee expr
		// +16  cases Vec(AstSwitchCase*)
		// +24  default body stmt or 0
		lw_lower_expr_in_place(ptr64[s + 8]);
		var cases = ptr64[s + 16];
		if (cases != 0) {
			var n = vec_len(cases);
			var i = 0;
			while (i < n) {
				var c = vec_get(cases, i);
				if (c != 0) {
					lw_lower_expr_in_place(ptr64[c + 0]);
					lw_lower_stmt_in_place(ptr64[c + 8]);
				}
				i = i + 1;
			}
		}
		var defb = ptr64[s + 24];
		if (defb != 0) { lw_lower_stmt_in_place(defb); }
		return 0;
	}
	if (k == AstStmtKind.WIPE) {
		lw_lower_expr_in_place(ptr64[s + 56]);
		lw_lower_expr_in_place(ptr64[s + 16]);
		return 0;
	}
	return 0;
}

// Lowered type-function registry.
//
// Each entry represents a canonical comptime model:
//   - generic struct template => (type_fn) Name(type_params...) -> type
//
// Entry layout (heap_alloc 48):
//  +0  prog_ptr (AstProgram*)
//  +8  name_ptr
// +16  name_len
// +24  templ_decl_ptr (AstDecl*)
// +32  arity (u64)
// +40  typefn_decl_ptr (AstDecl*)  // synthetic "type-function" decl
var lw_typefns;

func lw_typefns_init_if_needed() {
	if (lw_typefns != 0) { return 0; }
	lw_typefns = vec_new(8);
	if (lw_typefns == 0) { return 1; }
	return 0;
}

func lw_typefns_has_entry(prog, templ_decl) {
	if (lw_typefns == 0) { return 0; }
	var n = vec_len(lw_typefns);
	var i = 0;
	while (i < n) {
		var e = vec_get(lw_typefns, i);
		if (e != 0) {
			if (ptr64[e + 0] == prog && ptr64[e + 24] == templ_decl) { return 1; }
		}
		i = i + 1;
	}
	return 0;
}

func lw_register_generic_struct_typefn(prog, d) {
	// Idempotent: avoid duplicate entries if lowering is re-run.
	if (prog == 0 || d == 0) { return 1; }
	if (lw_typefns_has_entry(prog, d) == 1) { return 0; }

	var name_ptr = ptr64[d + 8];
	var name_len = ptr64[d + 16];
	var type_params = ptr64[d + 96];
	var arity = 0;
	if (type_params != 0) { arity = vec_len(type_params); }

	var ent = heap_alloc(48);
	if (ent == 0) { return 1; }
	ptr64[ent + 0] = prog;
	ptr64[ent + 8] = name_ptr;
	ptr64[ent + 16] = name_len;
	ptr64[ent + 24] = d;
	ptr64[ent + 32] = arity;
	ptr64[ent + 40] = 0;
	vec_push(lw_typefns, ent);
	return 0;
}

func lw_find_generic_struct_typefn_entry(prog, name_ptr, name_len) {
	// Returns registry entry pointer, or 0.
	if (lw_typefns == 0) { return 0; }
	if (prog == 0) { return 0; }
	var n = vec_len(lw_typefns);
	var i = 0;
	while (i < n) {
		var e = vec_get(lw_typefns, i);
		if (e != 0) {
			if (ptr64[e + 0] == prog) {
				if (slice_eq_parts(ptr64[e + 8], ptr64[e + 16], name_ptr, name_len) == 1) {
					return e;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func lw_typefn_entry_templ_decl(e) {
	if (e == 0) { return 0; }
	return ptr64[e + 24];
}

func lw_typefn_entry_arity(e) {
	if (e == 0) { return 0; }
	return ptr64[e + 32];
}

func lw_typefn_entry_typefn_decl(e) {
	if (e == 0) { return 0; }
	return ptr64[e + 40];
}

func lw_find_generic_struct_template_decl(prog, name_ptr, name_len) {
	// Returns AstDecl* for a generic struct template in the given program, or 0.
	// Assumes lower_program() has already populated lw_typefns.
	var e = lw_find_generic_struct_typefn_entry(prog, name_ptr, name_len);
	return lw_typefn_entry_templ_decl(e);
}

func lower_program(prog) {
	// Returns 0 on success.
	// Future work: rewrite AST by desugaring generics into comptime model.
	if (prog == 0) { return 0; }
	if (lw_typefns_init_if_needed() != 0) { return 1; }

	// First, lower all type nodes by desugaring generic types into
	// comptime-call-in-type-position: __typefn$Name(args...) -> type.
	// This keeps semantics the same today (typecheck still instantiates),
	// but makes the lowered AST match the final comptime model.
	//
	// NOTE: This is restricted to type-level generic instantiations.
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var ni = vec_len(decls);
	var ii = 0;
	while (ii < ni) {
		var d0 = vec_get(decls, ii);
		if (d0 != 0) {
			var dk = ptr64[d0 + 0];
			if (dk == AstDeclKind.FUNC) {
				var params = ptr64[d0 + 24];
				if (params != 0) {
					var pn = vec_len(params);
					var pi = 0;
					while (pi < pn) {
						lw_lower_stmt_in_place(vec_get(params, pi));
						pi = pi + 1;
					}
				}
				lw_lower_type_in_place(ptr64[d0 + 32]);
				lw_lower_stmt_in_place(ptr64[d0 + 40]);
			} else if (dk == AstDeclKind.VAR || dk == AstDeclKind.CONST) {
				lw_lower_type_in_place(ptr64[d0 + 24]);
				lw_lower_expr_in_place(ptr64[d0 + 32]);
			} else if (dk == AstDeclKind.TYPE) {
				// Phase 2.6: type alias RHS lowering.
				lw_lower_type_in_place(ptr64[d0 + 24]);
			} else if (dk == AstDeclKind.STRUCT) {
				var fields = ptr64[d0 + 24];
				if (fields != 0) {
					var fn = vec_len(fields);
					var fi = 0;
					while (fi < fn) {
						lw_lower_stmt_in_place(vec_get(fields, fi));
						fi = fi + 1;
					}
				}
			}
		}
		ii = ii + 1;
	}

	// Scan declarations and register generic templates into the canonical
	// comptime "type-function" view.
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.STRUCT) {
			// Generic template if either:
			// - decl_flags marks it as template, or
			// - type_params vec exists
			var flags = ptr64[d + 80];
			var tparams = ptr64[d + 96];
			var is_templ = 0;
			var tflag = flags & 2;
			if (tflag != 0) { is_templ = 1; }
			if (tparams != 0) { is_templ = 1; }
			if (is_templ == 1) {
				// Register in registry.
				lw_register_generic_struct_typefn(prog, d);
				// Materialize a synthetic type-function decl (behavior-preserving).
				var ent = lw_find_generic_struct_typefn_entry(prog, ptr64[d + 8], ptr64[d + 16]);
				if (ent != 0) {
					if (ptr64[ent + 40] == 0) {
						// Name: "__typefn$" + StructName
						var prefix_len = 9;
						var name_ptr = ptr64[d + 8];
						var name_len = ptr64[d + 16];
						var out_len = prefix_len + name_len;
						var out = heap_alloc(out_len);
						if (out != 0) {
							ptr8[out + 0] = 95; // '_'
							ptr8[out + 1] = 95; // '_'
							ptr8[out + 2] = 116; // 't'
							ptr8[out + 3] = 121; // 'y'
							ptr8[out + 4] = 112; // 'p'
							ptr8[out + 5] = 101; // 'e'
							ptr8[out + 6] = 102; // 'f'
							ptr8[out + 7] = 110; // 'n'
							ptr8[out + 8] = 36;  // '$'
							var j = 0;
							while (j < name_len) {
								ptr8[out + prefix_len + j] = ptr8[name_ptr + j];
								j = j + 1;
							}
							// Synthesize decl (AstDeclKind.FUNC). This is skipped by typecheck/codegen
							// because it is marked as a generic template.
							var f = heap_alloc(104);
							if (f != 0) {
								ptr64[f + 0] = AstDeclKind.FUNC;
								ptr64[f + 8] = out;
								ptr64[f + 16] = out_len;
								ptr64[f + 24] = 0;
								ptr64[f + 32] = 0;
								ptr64[f + 40] = 0;
								ptr64[f + 48] = ptr64[d + 48];
								ptr64[f + 56] = ptr64[d + 56];
								ptr64[f + 64] = ptr64[d + 64];
								ptr64[f + 72] = 0;
								ptr64[f + 80] = 2; // generic template flag
								ptr64[f + 88] = 0;
								ptr64[f + 96] = ptr64[d + 96];
								ptr64[ent + 40] = f;
								vec_push(decls, f);
							}
						}
					}
				}
			}
		}
		else if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			// Phase 5.1: canonical comptime view for generic functions.
			// func F<T>(...)  =>  func __comptimefn$F(T: type, ...)  (synthetic; skipped by typecheck/codegen)
			var flags2 = ptr64[d + 80];
			var tparams2 = ptr64[d + 96];
			var is_templ2 = 0;
			var tflag2 = flags2 & 2;
			if (tflag2 != 0) { is_templ2 = 1; }
			if (tparams2 != 0) { is_templ2 = 1; }
			if (is_templ2 == 1 && tparams2 != 0) {
				// Name: "__comptimefn$" + FuncName
				var prefix_len2 = 13;
				var name_ptr2 = ptr64[d + 8];
				var name_len2 = ptr64[d + 16];
				var out_len2 = prefix_len2 + name_len2;
				var out2 = heap_alloc(out_len2);
				if (out2 != 0) {
					ptr8[out2 + 0] = 95; // '_'
					ptr8[out2 + 1] = 95; // '_'
					ptr8[out2 + 2] = 99; // 'c'
					ptr8[out2 + 3] = 111; // 'o'
					ptr8[out2 + 4] = 109; // 'm'
					ptr8[out2 + 5] = 112; // 'p'
					ptr8[out2 + 6] = 116; // 't'
					ptr8[out2 + 7] = 105; // 'i'
					ptr8[out2 + 8] = 109; // 'm'
					ptr8[out2 + 9] = 101; // 'e'
					ptr8[out2 + 10] = 102; // 'f'
					ptr8[out2 + 11] = 110; // 'n'
					ptr8[out2 + 12] = 36;  // '$'
					var j2 = 0;
					while (j2 < name_len2) {
						ptr8[out2 + prefix_len2 + j2] = ptr8[name_ptr2 + j2];
						j2 = j2 + 1;
					}

					// Build new param list: (T0: type, T1: type, ...) + existing params.
					var new_params = vec_new(4);
					if (new_params != 0) {
						var start_off2 = ptr64[d + 48];
						var line2 = ptr64[d + 56];
						var col2 = ptr64[d + 64];
						// AstType NAME "type" (lowering-only; typecheck skips this decl)
						var type_ty = heap_alloc(64);
						if (type_ty != 0) {
							ptr64[type_ty + 0] = AstTypeKind.NAME;
							ptr64[type_ty + 8] = "type";
							ptr64[type_ty + 16] = 4;
							ptr64[type_ty + 24] = start_off2;
							ptr64[type_ty + 32] = line2;
							ptr64[type_ty + 40] = col2;
							ptr64[type_ty + 48] = 0;
							ptr64[type_ty + 56] = 0;
						}
						var tp_n2 = vec_len(tparams2);
						var tp_i2 = 0;
						while (tp_i2 < tp_n2) {
							var tpent = vec_get(tparams2, tp_i2);
							if (tpent != 0) {
								var s = heap_alloc(96);
								if (s != 0) {
									ptr64[s + 0] = AstStmtKind.VAR;
									ptr64[s + 8] = 0;
									ptr64[s + 16] = 0;
									ptr64[s + 24] = 0;
									ptr64[s + 32] = ptr64[tpent + 0];
									ptr64[s + 40] = ptr64[tpent + 8];
									ptr64[s + 48] = type_ty;
									ptr64[s + 56] = 0;
									ptr64[s + 64] = start_off2;
									ptr64[s + 72] = line2;
									ptr64[s + 80] = col2;
									ptr64[s + 88] = 0;
									vec_push(new_params, s);
								}
							}
							tp_i2 = tp_i2 + 1;
						}
						var old_params = ptr64[d + 24];
						if (old_params != 0) {
							var opn = vec_len(old_params);
							var opi = 0;
							while (opi < opn) {
								vec_push(new_params, vec_get(old_params, opi));
								opi = opi + 1;
							}
						}

						var f2 = heap_alloc(104);
						if (f2 != 0) {
							ptr64[f2 + 0] = AstDeclKind.FUNC;
							ptr64[f2 + 8] = out2;
							ptr64[f2 + 16] = out_len2;
							ptr64[f2 + 24] = new_params;
							ptr64[f2 + 32] = ptr64[d + 32];
							ptr64[f2 + 40] = 0;
							ptr64[f2 + 48] = ptr64[d + 48];
							ptr64[f2 + 56] = ptr64[d + 56];
							ptr64[f2 + 64] = ptr64[d + 64];
							ptr64[f2 + 72] = ptr64[d + 72];
							ptr64[f2 + 80] = 2; // generic template flag
							ptr64[f2 + 88] = 0;
							ptr64[f2 + 96] = tparams2;
							vec_push(decls, f2);
						}
					}
				}
			}
		}
		i = i + 1;
	}
	return 0;
}
