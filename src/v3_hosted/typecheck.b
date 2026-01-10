// v3_hosted: minimal type checker (Phase 1.4)
//
// Scope:
// - Minimal types for Phase 1: u64 + error reporting.
// - Minimal checking for `var x: u64 = <expr>;`
// - Skeleton support for `cast(Type, expr)`.

import v3_hosted.ast;
import v3_hosted.lexer;
import v3_hosted.token;
import v3_hosted.driver;
import v3_hosted.parser;
import v3_hosted.lowering;

import file;

import io;
import vec;
import hashmap;

const TC_TY_INVALID = 0;

// Integer types (Phase 2.1)
const TC_TY_U8 = 1;
const TC_TY_U16 = 2;
const TC_TY_U32 = 3;
const TC_TY_U64 = 4;
const TC_TY_I8 = 5;
const TC_TY_I16 = 6;
const TC_TY_I32 = 7;
const TC_TY_I64 = 8;

const TC_TY_BOOL = 9;
const TC_TY_STRING = 10;
const TC_TY_CHAR = 11;

// Untyped null literal (only valid with pointer context).
const TC_TY_NULL = 12;

// Floating-point types (Phase 6.6)
const TC_TY_F32 = 13;
const TC_TY_F64 = 14;

// Pointer types (Phase 2.2)
// Encoding: only supports pointers to named (non-pointer) base types for now.
const TC_TY_PTR_BASE = 1000;
const TC_TY_PTR_NULLABLE_BASE = 2000;

// Slice types (Phase 2.3)
const TC_TY_SLICE_BASE = 3000;

// Compound types allocated on heap (Phase 2.4 arrays)
const TC_COMPOUND_ARRAY = 90001;
const TC_COMPOUND_STRUCT = 90002;
const TC_COMPOUND_PTR = 90003;
const TC_COMPOUND_ENUM = 90004;
// Phase 5.4: 2-value tuple type for multi-return.
const TC_COMPOUND_TUPLE2 = 90005;
// Phase 2.6: distinct type (strong typedef)
const TC_COMPOUND_DISTINCT = 90006;
// Phase 6.7: function pointer type
const TC_COMPOUND_FUNC_PTR = 90007;

// Global error counter (avoid taking addresses of locals; v2 compiler limitation).
var tc_errors;

// Global struct registry (Vec of struct type pointers).
var tc_structs;
// HashMap for O(1) struct lookup: key = "mod_id:name", value = struct ptr
var tc_structs_map;

// Global enum registry (Vec of enum type pointers).
var tc_enums;
// HashMap for O(1) enum lookup
var tc_enums_map;

// Phase 2.6: type alias registry (Vec of TcTypeAlias*).
// TcTypeAlias layout (heap_alloc 56):
//  +0  name_ptr
//  +8  name_len
// +16  mod_id
// +24  is_public
// +32  aliased_ty (the Tc type id returned for this name)
// +40  base_ty (for distinct: underlying type; otherwise equals aliased_ty)
// +48  is_distinct (0/1)
var tc_type_aliases;
// HashMap for O(1) type alias lookup
var tc_type_aliases_map;

// Global pointer-type registry (Vec of compound ptr types).
var tc_ptr_types;

// Phase 6.7: Function pointer type registry (Vec of TcFuncPtrType*).
// TcFuncPtrType layout (heap_alloc 32):
//  +0  compound_kind = TC_COMPOUND_FUNC_PTR
//  +8  param_types (Vec* of TC type ids)
// +16  ret_type (TC type id, 0 = void)
// +24  reserved
var tc_func_ptr_types;

// Global function signature registry (Vec of TcFuncSig*).
// TcFuncSig layout (heap_alloc 64):
//  +0 name_ptr
//  +8 name_len
// +16 mod_id
// +24 param_count
// +32 p0_ty
// +40 p1_ty
// +48 ret_ty (0 means no return type / void)
var tc_funcs;
// HashMap for O(1) function lookup
var tc_funcs_map;

// NOTE: nospill/secret tracking disabled in v3 simplification (moved to v4)
// The variables and functions are kept for compatibility but checking is disabled.
// Phase 4.4 nospill (hosted-friendly approximation):
// Treat `nospill` locals as requiring a dedicated register. If more than
// TC_NOSPILL_LIMIT are declared in a function, report an error.
const TC_STMT_FLAG_SECRET = 1;
const TC_STMT_FLAG_NOSPILL = 2;
const TC_NOSPILL_LIMIT = 4;
var tc_nospill_count;
var tc_nospill_overflowed;
var tc_nospill_overflow_line;
var tc_nospill_overflow_col;
// Track nospill locals (name set) for '&' validation.
// Vec of TcVar* (name_ptr/name_len/ty); only name is used.
var tc_nospill_vars;

func tc_nospill_reset() {
	tc_nospill_count = 0;
	tc_nospill_overflowed = 0;
	tc_nospill_overflow_line = 0;
	tc_nospill_overflow_col = 0;
	if (tc_nospill_vars == 0) { tc_nospill_vars = vec_new(8); }
	if (tc_nospill_vars != 0) { ptr64[tc_nospill_vars + 8] = 0; }
	return 0;
}

func tc_is_nospill_name(name_ptr, name_len) {
	if (tc_nospill_vars == 0) { return 0; }
	var n = vec_len(tc_nospill_vars);
	var i = 0;
	while (i < n) {
		var v = vec_get(tc_nospill_vars, i);
		if (v != 0) {
			if (slice_eq_parts(ptr64[v + 0], ptr64[v + 8], name_ptr, name_len) == 1) { return 1; }
		}
		i = i + 1;
	}
	return 0;
}

func tc_record_nospill_var(name_ptr, name_len, ty) {
	if (tc_nospill_vars == 0) { tc_nospill_vars = vec_new(8); }
	if (tc_nospill_vars == 0) { return 0; }
	var v = heap_alloc(24);
	if (v == 0) { return 0; }
	ptr64[v + 0] = name_ptr;
	ptr64[v + 8] = name_len;
	ptr64[v + 16] = ty;
	vec_push(tc_nospill_vars, v);
	return 0;
}

// Module context for Phase 3.2 (1 file = 1 module).
// tc_modules: Vec of TcModule*
// TcModule layout (heap_alloc 32):
//  +0 name_ptr
//  +8 name_len
// +16 prog (AstProgram*)
// +24 imports (Vec of TcImport*)
// TcImport layout (heap_alloc 16):
//  +0 name_ptr
//  +8 name_len
var tc_modules;
var tc_cur_mod;
var tc_cur_imports;

// AstDecl.decl_flags (keep in sync with parser)
const TC_DECL_FLAG_EXTERN = 1;
const TC_DECL_FLAG_GENERIC_TEMPLATE = 2;
const TC_DECL_RETREG_SHIFT = 8;

func tc_decl_retreg(d) {
	return (ptr64[d + 80] >> TC_DECL_RETREG_SHIFT) & 255;
}

func tc_has_param_reg_anno(params) {
	if (params == 0) { return 0; }
	var pn = vec_len(params);
	var pi = 0;
	while (pi < pn) {
		var ps = vec_get(params, pi);
		if (ps != 0) {
			if (ptr64[ps + 16] != 0) { return 1; }
		}
		pi = pi + 1;
	}
	return 0;
}

func tc_validate_reg_anno_in_func(d) {
	// Phase 4.5: @reg is extern-only.
	var flags = ptr64[d + 80];
	var is_extern = flags & TC_DECL_FLAG_EXTERN;
	var params = ptr64[d + 24];
	var has_param_reg = tc_has_param_reg_anno(params);
	var ret_reg = tc_decl_retreg(d);
	var has_ret_reg = ret_reg != 0;
	if (has_param_reg == 0 && has_ret_reg == 0) { return 0; }
	if (is_extern == 0) {
		tc_err_at(ptr64[d + 56], ptr64[d + 64], "@reg is only allowed on extern functions");
		return 0;
	}
	// If any param uses @reg, require all params to have it (MVP simplicity).
	if (has_param_reg == 1 && params != 0) {
		var pn = vec_len(params);
		var pi = 0;
		while (pi < pn) {
			var ps = vec_get(params, pi);
			if (ps != 0) {
				if (ptr64[ps + 16] == 0) {
					tc_err_at(ptr64[ps + 72], ptr64[ps + 80], "@reg: all params must be annotated (extern MVP)");
				}
				var pty = TC_TY_INVALID;
				if (ptr64[ps + 48] != 0) { pty = tc_type_from_asttype(ptr64[ps + 48]); }
				if (pty != TC_TY_INVALID) {
					// Only 8-byte values supported for register ABI.
					if (tc_is_slice(pty) == 1 || tc_is_array(pty) == 1 || tc_is_struct(pty) == 1 || tc_is_tuple2(pty) == 1) {
						tc_err_at(ptr64[ps + 72], ptr64[ps + 80], "@reg: aggregate params are not supported");
					}
					if (tc_sizeof(pty) != 8) {
						tc_err_at(ptr64[ps + 72], ptr64[ps + 80], "@reg: only 8-byte params are supported");
					}
				}
			}
			pi = pi + 1;
		}
	}
	// Return reg annotation only supported for single 8-byte return (MVP).
	if (has_ret_reg == 1) {
		var ret_ast = ptr64[d + 32];
		if (ret_ast == 0) {
			tc_err_at(ptr64[d + 56], ptr64[d + 64], "@reg: return register requires a return type");
		}
		else {
			var rty = tc_type_from_asttype(ret_ast);
			if (tc_is_slice(rty) == 1 || tc_is_array(rty) == 1 || tc_is_struct(rty) == 1 || tc_is_tuple2(rty) == 1) {
				tc_err_at(ptr64[d + 56], ptr64[d + 64], "@reg: aggregate return is not supported");
			}
			if (tc_sizeof(rty) != 8) {
				tc_err_at(ptr64[d + 56], ptr64[d + 64], "@reg: only 8-byte return is supported");
			}
		}
	}
	return 0;
}

// Phase 3.7: Method call transformation helper.
// Transforms s.method(args) -> TypeName_method(s, args)
// Returns 1 if transformation was performed, 0 otherwise.
func tc_try_method_call(env, e) {
	var callee = ptr64[e + 16];
	var args = ptr64[e + 32];
	if (callee == 0) { return 0; }
	if (ptr64[callee + 0] != AstExprKind.FIELD) { return 0; }
	var base_expr = ptr64[callee + 16];
	if (base_expr == 0) { return 0; }
	var meth_ptr = ptr64[callee + 24];
	var packed0 = ptr64[callee + 32];
	var meth_len = packed0 >> 2;
	var base_ty = tc_expr(env, base_expr);
	var struct_ty = 0;
	if (tc_is_ptr(base_ty) == 1) {
		struct_ty = tc_ptr_base(base_ty);
	}
	else if (tc_is_struct(base_ty) == 1) {
		struct_ty = base_ty;
	}
	if (struct_ty == 0) { return 0; }
	if (tc_is_struct(struct_ty) == 0) { return 0; }
	var sn_ptr = ptr64[struct_ty + 8];
	var sn_len = ptr64[struct_ty + 16];
	var total_len = sn_len + 1 + meth_len;
	var mn_buf = heap_alloc(total_len + 1);
	if (mn_buf == 0) { return 0; }
	var wi = 0;
	while (wi < sn_len) {
		ptr8[mn_buf + wi] = ptr8[sn_ptr + wi];
		wi = wi + 1;
	}
	ptr8[mn_buf + sn_len] = 95;
	wi = 0;
	while (wi < meth_len) {
		ptr8[mn_buf + sn_len + 1 + wi] = ptr8[meth_ptr + wi];
		wi = wi + 1;
	}
	var fd = tc_find_func_decl_in_prog(tc_cur_ast_prog, mn_buf, total_len);
	if (fd == 0) { return 0; }
	ptr64[callee + 0] = AstExprKind.IDENT;
	ptr64[callee + 40] = mn_buf;
	ptr64[callee + 48] = total_len;
	var new_args = vec_new(8);
	vec_push(new_args, base_expr);
	var an = 0;
	if (args != 0) { an = vec_len(args); }
	var ai = 0;
	while (ai < an) {
		vec_push(new_args, vec_get(args, ai));
		ai = ai + 1;
	}
	ptr64[e + 32] = new_args;
	return 1;
}

// Current AST program being typechecked (for Phase 5.1 monomorphization).
var tc_cur_ast_prog;

// Current function return type (for validating return statements).
var tc_cur_ret_ty;

// Loop nesting depth (for validating break/continue).
var tc_loop_depth;

// break nesting depth (loops + switch).
var tc_break_depth;

// switch nesting depth (for banning continue).
var tc_switch_depth;

// Number of global bindings currently visible in tc_env (used to distinguish
// globals from locals for const-immediate marking).
var tc_env_global_len;

// v2 제한 회피용 전역 스크래치 (call-clobber 방지).
// enum member access(Color.Red) 처리에서 사용하는 임시 값들.
var tc_tmp_expr;
var tc_tmp_enum_base_ptr;
var tc_tmp_enum_base_len;
var tc_tmp_enum_field_ptr;
var tc_tmp_enum_field_len;

// Debug flag (0=off). Used by ad-hoc debug drivers.
var tc_debug_field;
var tc_debug_var;
var tc_debug_ident;

func tc_env_find_index(env, name_ptr, name_len) {
	// Returns: rax=index, rdx=ok
	if (env == 0) {
		alias rdx : ok0;
		ok0 = 0;
		return 0;
	}
	var n = vec_len(env);
	while (n != 0) {
		n = n - 1;
		var ent = vec_get(env, n);
		if (ent != 0) {
			if (slice_eq_parts(ptr64[ent + 0], ptr64[ent + 8], name_ptr, name_len) == 1) {
				alias rdx : ok1;
				ok1 = 1;
				return n;
			}
		}
	}
	alias rdx : ok2;
	ok2 = 0;
	return 0;
}

func tc_find_const_decl_in_prog(prog, name_ptr, name_len) {
	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.CONST) {
			if (slice_eq_parts(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) {
				return d;
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_const_eval_u64_expr_mvp(e) {
	// Returns: rax=value, rdx=ok
	if (e == 0) {
		alias rdx : ok0;
		ok0 = 0;
		return 0;
	}
	var k = ptr64[e + 0];
	if (k == AstExprKind.INT) {
		var v0 = tc_parse_u64_literal(ptr64[e + 40], ptr64[e + 48]);
		alias rdx : ok1;
		ok1 = 1;
		return v0;
	}
	if (k == AstExprKind.UNARY) {
		if (ptr64[e + 8] == TokKind.MINUS) {
			var rhs = ptr64[e + 16];
			if (rhs != 0 && ptr64[rhs + 0] == AstExprKind.INT) {
				var v1 = tc_parse_u64_literal(ptr64[rhs + 40], ptr64[rhs + 48]);
				alias rdx : ok2;
				ok2 = 1;
				return 0 - v1;
			}
		}
	}
	if (k == AstExprKind.FIELD) {
		// Enum variant access (Color.Red) is marked as immediate (size=127).
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		if (sz == 127) {
			alias rdx : ok3;
			ok3 = 1;
			return ptr64[e + 8];
		}
	}
	if (k == AstExprKind.IDENT) {
		// If already marked immediate, reuse.
		var extra2 = ptr64[e + 32];
		var sz2 = (extra2 >> 56) & 127;
		if (sz2 == 127) {
			alias rdx : ok4;
			ok4 = 1;
			return ptr64[e + 8];
		}
	}
	alias rdx : ok5;
	ok5 = 0;
	return 0;
}

func tc_switch_case_is_const(e) {
	if (e == 0) { return 0; }
	var k = ptr64[e + 0];
	if (k == AstExprKind.INT) { return 1; }
	if (k == AstExprKind.IDENT) {
		// Global const identifiers are marked immediate (extra size=127).
		var extra0 = ptr64[e + 32];
		var sz0 = (extra0 >> 56) & 127;
		if (sz0 == 127) { return 1; }
	}
	if (k == AstExprKind.UNARY) {
		if (ptr64[e + 8] == TokKind.MINUS) {
			var rhs = ptr64[e + 16];
			if (rhs != 0 && ptr64[rhs + 0] == AstExprKind.INT) { return 1; }
			if (tc_switch_case_is_const(rhs) == 1) { return 1; }
		}
	}
	if (k == AstExprKind.FIELD) {
		// Enum variant access (Color.Red) is marked as immediate (size=127).
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		if (sz == 127) { return 1; }
	}
	return 0;
}

// Phase 5.1+: comptime value environment (for value generics / array length exprs).
// Vec of entries (heap_alloc 24): {name_ptr, name_len, value_u64}
var ct_value_env;
var ct_eval_failed;
var ct_eval_steps;
var ct_eval_step_limit;

// Phase 5.1: v2 bootstrap can clobber locals across calls.
// Use globals to hold transient comptime vectors in generic type evaluation.
var ct_tmp_args_mixed;
var ct_tmp_type_args_tc;

// Phase 5.2: named args. Parser stores a Vec(u64) of [name_ptr,name_len] pairs in CALL.op.
// We normalize them into positional order (matching param order) before further processing.
func tc_normalize_named_call_args(env, call_expr) {
	if (call_expr == 0) { return 0; }
	if (ptr64[call_expr + 0] != AstExprKind.CALL) { return 0; }
	var names = ptr64[call_expr + 8];
	if (names == 0) { return 0; }
	var callee = ptr64[call_expr + 16];
	var args = ptr64[call_expr + 32];
	if (callee == 0 || ptr64[callee + 0] != AstExprKind.IDENT) {
		// Still typecheck args for recovery.
		var i0 = 0;
		var n0 = 0;
		if (args != 0) { n0 = vec_len(args); }
		while (i0 < n0) { tc_expr(env, vec_get(args, i0)); i0 = i0 + 1; }
		tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args require identifier callee");
		ptr64[call_expr + 8] = 0;
		return 1;
	}
	if (tc_cur_ast_prog == 0) {
		ptr64[call_expr + 8] = 0;
		return 0;
	}
	var fn_name_ptr = ptr64[callee + 40];
	var fn_name_len = ptr64[callee + 48];
	var fd = tc_find_func_decl_in_prog(tc_cur_ast_prog, fn_name_ptr, fn_name_len);
	if (fd == 0) {
		// Unknown function: cannot map named args.
		var i1 = 0;
		var n1 = 0;
		if (args != 0) { n1 = vec_len(args); }
		while (i1 < n1) { tc_expr(env, vec_get(args, i1)); i1 = i1 + 1; }
		tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args require known function");
		ptr64[call_expr + 8] = 0;
		return 1;
	}
	var params = ptr64[fd + 24];
	var pn = 0;
	var an = 0;
	if (params != 0) { pn = vec_len(params); }
	if (args != 0) { an = vec_len(args); }
	var nn = vec_len(names);
	if (nn != (an * 2)) {
		tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args: internal name vector mismatch");
		ptr64[call_expr + 8] = 0;
		return 1;
	}
	if (an != pn) {
		tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args: wrong number of arguments");
		// Still proceed best-effort.
	}
	// used flags: Vec(u64) of 0/1.
	var used = vec_new(an + 1);
	var ui = 0;
	while (used != 0 && ui < an) { vec_push(used, 0); ui = ui + 1; }
	var new_args = vec_new(pn + 1);
	var pi = 0;
	while (pi < pn) {
		var ps = 0;
		if (params != 0) { ps = vec_get(params, pi); }
		var pname_ptr = 0;
		var pname_len = 0;
		if (ps != 0) { pname_ptr = ptr64[ps + 32]; pname_len = ptr64[ps + 40]; }
		var found = 18446744073709551615; // -1
		var ai = 0;
		while (ai < an) {
			var off = ai * 2;
			var anp = vec_get(names, off);
			var anl = vec_get(names, off + 1);
			if (slice_eq_parts(anp, anl, pname_ptr, pname_len) == 1) {
				found = ai;
				break;
			}
			ai = ai + 1;
		}
		if (found == 18446744073709551615) {
			tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args: missing argument");
			// Push dummy to keep vector length.
			if (new_args != 0) { vec_push(new_args, 0); }
		} else {
			if (used != 0 && vec_get(used, found) != 0) {
				tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args: duplicate argument");
			}
			if (used != 0) {
				var ubuf = ptr64[used + 0];
				ptr64[ubuf + (found * 8)] = 1;
			}
			var av = vec_get(args, found);
			if (new_args != 0) { vec_push(new_args, av); }
		}
		pi = pi + 1;
	}
	// Check for unknown named args.
	var ai2 = 0;
	while (ai2 < an) {
		var u = 0;
		if (used != 0) { u = vec_get(used, ai2); }
		if (u == 0) {
			tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "named args: unknown argument name");
			break;
		}
		ai2 = ai2 + 1;
	}
	// Replace args and clear name metadata.
	if (new_args != 0) { ptr64[call_expr + 32] = new_args; }
	ptr64[call_expr + 8] = 0;
	return 1;
}

func ct_eval_step() {
	ct_eval_steps = ct_eval_steps + 1;
	if (ct_eval_step_limit != 0 && ct_eval_steps > ct_eval_step_limit) {
		ct_eval_failed = 1;
		return 1;
	}
	return 0;
}

func tc_module_cur() {
	if (tc_modules == 0) { return 0; }
	return vec_get(tc_modules, tc_cur_mod);
}

func tc_module_name_ptr(mod_id) {
	var m = vec_get(tc_modules, mod_id);
	if (m == 0) { return 0; }
	return ptr64[m + 0];
}

func tc_module_name_len(mod_id) {
	var m = vec_get(tc_modules, mod_id);
	if (m == 0) { return 0; }
	return ptr64[m + 8];
}

func tc_module_lookup(name_ptr, name_len) {
	// Returns module id, or 18446744073709551615 if not found.
	if (tc_modules == 0) { return 18446744073709551615; }
	var n = vec_len(tc_modules);
	var i = 0;
	while (i < n) {
		var m = vec_get(tc_modules, i);
		if (m != 0) {
			if (slice_eq_parts(ptr64[m + 0], ptr64[m + 8], name_ptr, name_len) == 1) {
				return i;
			}
		}
		i = i + 1;
	}
	return 18446744073709551615;
}

func tc_imports_contains(imports, name_ptr, name_len) {
	if (imports == 0) { return 0; }
	var n = vec_len(imports);
	var i = 0;
	while (i < n) {
		var it = vec_get(imports, i);
		if (it != 0) {
			if (slice_eq_parts(ptr64[it + 0], ptr64[it + 8], name_ptr, name_len) == 1) {
				return 1;
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_align_up(x, a) {
	if (a <= 1) { return x; }
	var m = a - 1;
	return (x + m) & (~m);
}

func tc_is_struct(ty) {
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_STRUCT) { return 1; }
	return 0;
}
func tc_is_enum(ty) {
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_ENUM) { return 1; }
	return 0;
}

func tc_enum_variants(ty) {
	return ptr64[ty + 24];
}

func tc_struct_fields(ty) {
	return ptr64[ty + 24];
}

func tc_struct_size(ty) {
	return ptr64[ty + 32];
}

func tc_struct_align(ty) {
	return ptr64[ty + 40];
}

func tc_struct_mod_id(ty) {
	return ptr64[ty + 48];
}

func tc_struct_is_public(ty) {
	return ptr64[ty + 56];
}

func tc_struct_field_is_public(f) {
	return ptr64[f + 32];
}

func tc_enum_mod_id(ty) {
	return ptr64[ty + 32];
}

func tc_enum_is_public(ty) {
	return ptr64[ty + 40];
}

func tc_is_tuple2(ty) {
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_TUPLE2) { return 1; }
	return 0;
}

func tc_is_distinct(ty) {
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_DISTINCT) { return 1; }
	return 0;
}

func tc_distinct_base(ty) {
	return ptr64[ty + 8];
}

func tc_distinct_new(base_ty) {
	if (base_ty == TC_TY_INVALID) { return TC_TY_INVALID; }
	var t = heap_alloc(24);
	if (t == 0) { return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_DISTINCT;
	ptr64[t + 8] = base_ty;
	ptr64[t + 16] = 0;
	return t;
}

func tc_tuple2_a(ty) {
	return ptr64[ty + 8];
}

func tc_tuple2_b(ty) {
	return ptr64[ty + 16];
}

func tc_tuple2_new(a_ty, b_ty) {
	var t = heap_alloc(24);
	if (t == 0) { return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_TUPLE2;
	ptr64[t + 8] = a_ty;
	ptr64[t + 16] = b_ty;
	return t;
}

func tc_sizeof(ty) {
	if (tc_is_distinct(ty) == 1) { return tc_sizeof(tc_distinct_base(ty)); }
	if (ty == TC_TY_U8 || ty == TC_TY_I8 || ty == TC_TY_BOOL || ty == TC_TY_CHAR) { return 1; }
	if (ty == TC_TY_U16 || ty == TC_TY_I16) { return 2; }
	if (ty == TC_TY_U32 || ty == TC_TY_I32) { return 4; }
	if (ty == TC_TY_U64 || ty == TC_TY_I64) { return 8; }
	// Phase 6.6: floating-point
	if (ty == TC_TY_F32) { return 4; }
	if (ty == TC_TY_F64) { return 8; }
	if (tc_is_ptr(ty) == 1) { return 8; }
	if (tc_is_slice(ty) == 1) { return 16; }
	if (tc_is_array(ty) == 1) {
		return tc_sizeof(tc_array_elem(ty)) * tc_array_len(ty);
	}
	if (tc_is_struct(ty) == 1) { return tc_struct_size(ty); }
	if (tc_is_enum(ty) == 1) { return 8; }
	if (tc_is_tuple2(ty) == 1) { return 16; }
	// Phase 6.7: function pointer (8 bytes like regular pointer)
	if (tc_is_func_ptr(ty) == 1) { return 8; }
	return 0;
}

func tc_alignof(ty) {
	if (tc_is_distinct(ty) == 1) { return tc_alignof(tc_distinct_base(ty)); }
	if (ty == TC_TY_U8 || ty == TC_TY_I8 || ty == TC_TY_BOOL || ty == TC_TY_CHAR) { return 1; }
	if (ty == TC_TY_U16 || ty == TC_TY_I16) { return 2; }
	if (ty == TC_TY_U32 || ty == TC_TY_I32) { return 4; }
	if (ty == TC_TY_U64 || ty == TC_TY_I64) { return 8; }
	// Phase 6.6: floating-point
	if (ty == TC_TY_F32) { return 4; }
	if (ty == TC_TY_F64) { return 8; }
	if (tc_is_ptr(ty) == 1) { return 8; }
	if (tc_is_slice(ty) == 1) { return 8; }
	if (tc_is_array(ty) == 1) { return tc_alignof(tc_array_elem(ty)); }
	if (tc_is_struct(ty) == 1) { return tc_struct_align(ty); }
	if (tc_is_enum(ty) == 1) { return 8; }
	if (tc_is_tuple2(ty) == 1) { return 8; }
	// Phase 6.7: function pointer
	if (tc_is_func_ptr(ty) == 1) { return 8; }
	return 1;
}

// Scratch buffer for building HashMap keys: "mod_id:name"
// Max key size: 20 (mod_id as decimal) + 1 (:) + 256 (name) = 277
var tc_key_buf;

func tc_make_key(mod_id, name_ptr, name_len) {
	// Returns: rax=ptr, rdx=len
	// Builds key "mod_id:name" in tc_key_buf
	if (tc_key_buf == 0) {
		tc_key_buf = heap_alloc(280);
	}
	var p = tc_key_buf;
	// Write mod_id as decimal
	var m = mod_id;
	var digits = 0;
	var tmp_buf = p + 270; // temp area at end of buffer
	if (m == 0) {
		ptr8[tmp_buf] = 48; // '0'
		digits = 1;
	} else {
		while (m > 0) {
			ptr8[tmp_buf + digits] = 48 + (m % 10);
			m = m / 10;
			digits = digits + 1;
		}
	}
	// Reverse digits into p
	var di = 0;
	while (di < digits) {
		ptr8[p + di] = ptr8[tmp_buf + (digits - 1 - di)];
		di = di + 1;
	}
	// Write ':'
	ptr8[p + digits] = 58;
	var pos = digits + 1;
	// Copy name
	var ni = 0;
	while (ni < name_len) {
		ptr8[p + pos] = ptr8[name_ptr + ni];
		ni = ni + 1;
		pos = pos + 1;
	}
	alias rdx : out_len;
	out_len = pos;
	return p;
}

func tc_struct_lookup_mod(mod_id, name_ptr, name_len) {
	if (tc_structs_map != 0) {
		var key_ptr = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len;
		var result = hashmap_get(tc_structs_map, key_ptr, key_len);
		alias rdx : ok;
		if (ok != 0) { return result; }
		return 0;
	}
	// Fallback to linear search if map not initialized
	if (tc_structs == 0) { return 0; }
	var n = vec_len(tc_structs);
	var i = 0;
	while (i < n) {
		var t = vec_get(tc_structs, i);
		if (t != 0) {
			if (ptr64[t + 48] == mod_id) {
				if (slice_eq_parts(ptr64[t + 8], ptr64[t + 16], name_ptr, name_len) == 1) {
					return t;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_func_lookup(name_ptr, name_len) {
	return tc_func_lookup_mod(tc_cur_mod, name_ptr, name_len);
}

func tc_struct_lookup(name_ptr, name_len) {
	return tc_struct_lookup_mod(tc_cur_mod, name_ptr, name_len);
}

func tc_struct_find_field(ty, field_ptr, field_len) {
	var fields = tc_struct_fields(ty);
	if (fields == 0) { return 0; }
	var n = vec_len(fields);
	var i = 0;
	while (i < n) {
		var f = vec_get(fields, i);
		if (slice_eq_parts(ptr64[f + 0], ptr64[f + 8], field_ptr, field_len) == 1) {
			return f;
		}
		i = i + 1;
	}
	return 0;
}

struct TcVar {
	name_ptr: u64;
	name_len: u64;
	ty: u64;
};

func tc_err_at(line, col, msg) {
	tc_errors = tc_errors + 1;
	print_str("type error at ");
	print_u64(line);
	print_str(":");
	print_u64(col);
	print_str(": ");
	print_str(msg);
	print_str("\n");
	return 0;
}

func tc_type_from_name(name_ptr, name_len) {
	if (slice_eq_parts(name_ptr, name_len, "u8", 2) == 1) { return TC_TY_U8; }
	if (slice_eq_parts(name_ptr, name_len, "u16", 3) == 1) { return TC_TY_U16; }
	if (slice_eq_parts(name_ptr, name_len, "u32", 3) == 1) { return TC_TY_U32; }
	if (slice_eq_parts(name_ptr, name_len, "u64", 3) == 1) { return TC_TY_U64; }
	if (slice_eq_parts(name_ptr, name_len, "i8", 2) == 1) { return TC_TY_I8; }
	if (slice_eq_parts(name_ptr, name_len, "i16", 3) == 1) { return TC_TY_I16; }
	if (slice_eq_parts(name_ptr, name_len, "i32", 3) == 1) { return TC_TY_I32; }
	if (slice_eq_parts(name_ptr, name_len, "i64", 3) == 1) { return TC_TY_I64; }
	if (slice_eq_parts(name_ptr, name_len, "bool", 4) == 1) { return TC_TY_BOOL; }
	// Phase 6.6: floating-point types
	if (slice_eq_parts(name_ptr, name_len, "f32", 3) == 1) { return TC_TY_F32; }
	if (slice_eq_parts(name_ptr, name_len, "f64", 3) == 1) { return TC_TY_F64; }
	// Phase 3.4 MVP: accept bit-width integer aliases like `u3`/`i5`.
	// For hosted tests we model them as full-width u64/i64.
	if (name_len >= 2) {
		var c0 = ptr8[name_ptr];
		var is_bit = 0;
		if (c0 == 117) { is_bit = 1; } // 'u'
		if (c0 == 105) { is_bit = 1; } // 'i'
		if (is_bit == 1) {
			var i = 1;
			var bits = 0;
			var ok = 1;
			while (i < name_len) {
				var ch = ptr8[name_ptr + i];
				if (ch < 48) { ok = 0; break; }
				if (ch > 57) { ok = 0; break; }
				bits = (bits * 10) + (ch - 48);
				i = i + 1;
			}
			if (ok == 1) {
				if (bits > 0) {
					if (bits <= 64) {
						if (c0 == 117) { return TC_TY_U64; }
						return TC_TY_I64;
					}
				}
			}
		}
	}
	return TC_TY_INVALID;
}

func tc_is_int(ty) {
	if (ty == TC_TY_U8) { return 1; }
	if (ty == TC_TY_U16) { return 1; }
	if (ty == TC_TY_U32) { return 1; }
	if (ty == TC_TY_U64) { return 1; }
	if (ty == TC_TY_I8) { return 1; }
	if (ty == TC_TY_I16) { return 1; }
	if (ty == TC_TY_I32) { return 1; }
	if (ty == TC_TY_I64) { return 1; }
	if (tc_is_enum(ty) == 1) { return 1; }
	return 0;
}

// Phase 6.6: floating-point type checks
func tc_is_float(ty) {
	if (ty == TC_TY_F32) { return 1; }
	if (ty == TC_TY_F64) { return 1; }
	return 0;
}

func tc_float_bits(ty) {
	if (ty == TC_TY_F32) { return 32; }
	if (ty == TC_TY_F64) { return 64; }
	return 0;
}

func tc_is_numeric(ty) {
	if (tc_is_int(ty) == 1) { return 1; }
	if (tc_is_float(ty) == 1) { return 1; }
	return 0;
}

func tc_is_signed_int(ty) {
	if (ty == TC_TY_I8) { return 1; }
	if (ty == TC_TY_I16) { return 1; }
	if (ty == TC_TY_I32) { return 1; }
	if (ty == TC_TY_I64) { return 1; }
	if (tc_is_enum(ty) == 1) { return 0; }
	return 0;
}

func tc_int_bits(ty) {
	if (ty == TC_TY_U8) { return 8; }
	if (ty == TC_TY_U16) { return 16; }
	if (ty == TC_TY_U32) { return 32; }
	if (ty == TC_TY_U64) { return 64; }
	if (ty == TC_TY_I8) { return 8; }
	if (ty == TC_TY_I16) { return 16; }
	if (ty == TC_TY_I32) { return 32; }
	if (ty == TC_TY_I64) { return 64; }
	if (tc_is_enum(ty) == 1) { return 64; }
	return 0;
}

func tc_is_ptr(ty) {
	if (ty >= TC_TY_PTR_BASE) {
		if (ty < (TC_TY_PTR_BASE + 256)) { return 1; }
		if (ty >= TC_TY_PTR_NULLABLE_BASE) {
			if (ty < (TC_TY_PTR_NULLABLE_BASE + 256)) { return 1; }
		}
	}
	if (tc_is_compound(ty) == 1) {
		if (ptr64[ty + 0] == TC_COMPOUND_PTR) { return 1; }
	}
	return 0;
}

func tc_enum_lookup_mod(mod_id, name_ptr, name_len) {
	if (tc_enums_map != 0) {
		var key_ptr = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len;
		var result = hashmap_get(tc_enums_map, key_ptr, key_len);
		alias rdx : ok;
		if (ok != 0) { return result; }
		return 0;
	}
	// Fallback to linear search if map not initialized
	if (tc_enums == 0) { return 0; }
	var n = vec_len(tc_enums);
	var i = 0;
	while (i < n) {
		var t = vec_get(tc_enums, i);
		if (t != 0) {
			if (ptr64[t + 32] == mod_id) {
				if (slice_eq_parts(ptr64[t + 8], ptr64[t + 16], name_ptr, name_len) == 1) {
					return t;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_enum_lookup(name_ptr, name_len) {
	return tc_enum_lookup_mod(tc_cur_mod, name_ptr, name_len);
}

func tc_type_alias_lookup_mod(mod_id, name_ptr, name_len) {
	if (tc_type_aliases_map != 0) {
		var key_ptr = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len;
		var result = hashmap_get(tc_type_aliases_map, key_ptr, key_len);
		alias rdx : ok;
		if (ok != 0) { return result; }
		return 0;
	}
	// Fallback to linear search if map not initialized
	if (tc_type_aliases == 0) { return 0; }
	var n = vec_len(tc_type_aliases);
	var i = 0;
	while (i < n) {
		var a = vec_get(tc_type_aliases, i);
		if (a != 0) {
			if (ptr64[a + 16] == mod_id) {
				if (slice_eq_parts(ptr64[a + 0], ptr64[a + 8], name_ptr, name_len) == 1) {
					return a;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_type_alias_lookup(name_ptr, name_len) {
	return tc_type_alias_lookup_mod(tc_cur_mod, name_ptr, name_len);
}

func tc_register_type_alias_decl(d, mod_id, is_public) {
	// AstDeclKind.TYPE layout (parser):
	//  name: d+8/d+16
	//  a: aliased AstType* (d+24)
	//  b: is_distinct (0/1) (d+32)
	if (d == 0) { return 0; }
	var name_ptr = ptr64[d + 8];
	var name_len = ptr64[d + 16];
	var err_line = ptr64[d + 56];
	var err_col = ptr64[d + 64];
	if (tc_type_aliases == 0) { return 0; }
	// Disallow conflicts with existing aliases/structs/enums in same module.
	if (tc_type_alias_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(err_line, err_col, "type: name already defined");
		return 0;
	}
	if (tc_struct_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(err_line, err_col, "type: name conflicts with struct");
		return 0;
	}
	if (tc_enum_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(err_line, err_col, "type: name conflicts with enum");
		return 0;
	}

	var aliased_ast = ptr64[d + 24];
	var is_distinct0 = ptr64[d + 32];
	var base_ty = tc_type_from_asttype(aliased_ast);
	if (base_ty == TC_TY_INVALID) {
		return 0;
	}
	var out_ty = base_ty;
	if (is_distinct0 != 0) {
		out_ty = tc_distinct_new(base_ty);
		if (out_ty == TC_TY_INVALID) {
			tc_err_at(err_line, err_col, "type: failed to create distinct type");
			return 0;
		}
	}
	var rec = heap_alloc(56);
	if (rec == 0) { return 0; }
	ptr64[rec + 0] = name_ptr;
	ptr64[rec + 8] = name_len;
	ptr64[rec + 16] = mod_id;
	ptr64[rec + 24] = is_public;
	ptr64[rec + 32] = out_ty;
	ptr64[rec + 40] = base_ty;
	ptr64[rec + 48] = is_distinct0;
	vec_push(tc_type_aliases, rec);
	// HashMap insert for O(1) lookup
	if (tc_type_aliases_map != 0) {
		var key_ptr = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len;
		hashmap_put(tc_type_aliases_map, key_ptr, key_len, rec);
	}
	return 0;
}

func tc_enum_find_variant(ty, name_ptr, name_len) {
	var vs = tc_enum_variants(ty);
	if (vs == 0) { return 0; }
	var n = vec_len(vs);
	var i = 0;
	while (i < n) {
		var v = vec_get(vs, i);
		// Variant node layout: {name_ptr, name_len, value}
		if (slice_eq_parts(ptr64[v + 0], ptr64[v + 8], name_ptr, name_len) == 1) { return v; }
		i = i + 1;
	}
	return 0;
}

func tc_func_lookup_mod(mod_id, name_ptr, name_len) {
	if (tc_funcs_map != 0) {
		var key_ptr = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len;
		var result = hashmap_get(tc_funcs_map, key_ptr, key_len);
		alias rdx : ok;
		if (ok != 0) { return result; }
		return 0;
	}
	// Fallback to linear search if map not initialized
	if (tc_funcs == 0) { return 0; }
	var n = vec_len(tc_funcs);
	var i = 0;
	while (i < n) {
		var f = vec_get(tc_funcs, i);
		if (f != 0) {
			if (ptr64[f + 16] == mod_id) {
				if (slice_eq_parts(ptr64[f + 0], ptr64[f + 8], name_ptr, name_len) == 1) {
					return f;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_collect_func_sigs_from_prog(prog, mod_id) {
	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			// Phase 5.1: skip generic templates; they are instantiated at call sites.
			var tflag0 = ptr64[d + 80] & TC_DECL_FLAG_GENERIC_TEMPLATE;
			var tparams0 = ptr64[d + 96];
			if (tflag0 != 0 || tparams0 != 0) { i = i + 1; continue; }
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			var params = ptr64[d + 24];
			var ret_ast = ptr64[d + 32];
			var pc = 0;
			var p0 = TC_TY_INVALID;
			var p1 = TC_TY_INVALID;
			if (params != 0) {
				pc = vec_len(params);
				if (pc > 0) {
					var ps0 = vec_get(params, 0);
					if (ps0 != 0 && ptr64[ps0 + 48] != 0) { p0 = tc_type_from_asttype(ptr64[ps0 + 48]); }
				}
				if (pc > 1) {
					var ps1 = vec_get(params, 1);
					if (ps1 != 0 && ptr64[ps1 + 48] != 0) { p1 = tc_type_from_asttype(ptr64[ps1 + 48]); }
				}
			}
			var ret_ty = 0;
			if (ret_ast != 0) { ret_ty = tc_type_from_asttype(ret_ast); }

			var sig = heap_alloc(64);
			if (sig != 0) {
				ptr64[sig + 0] = name_ptr;
				ptr64[sig + 8] = name_len;
				ptr64[sig + 16] = mod_id;
				ptr64[sig + 24] = pc;
				ptr64[sig + 32] = p0;
				ptr64[sig + 40] = p1;
				ptr64[sig + 48] = ret_ty;
				ptr64[sig + 56] = 0;
				vec_push(tc_funcs, sig);
				// HashMap insert for O(1) lookup
				if (tc_funcs_map != 0) {
					var key_ptr_f = tc_make_key(mod_id, name_ptr, name_len);
					alias rdx : key_len_f;
					hashmap_put(tc_funcs_map, key_ptr_f, key_len_f, sig);
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_build_hook_name(struct_ty0, field_meta0, is_set0) {
	// Returns: rax=ptr, rdx=len (not NUL-terminated)
	var sn_ptr0 = ptr64[struct_ty0 + 8];
	var sn_len0 = ptr64[struct_ty0 + 16];
	var fn_ptr0 = ptr64[field_meta0 + 0];
	var fn_len0 = ptr64[field_meta0 + 8];
	var out_len0 = sn_len0 + 5 + fn_len0;
	var out_ptr0 = heap_alloc(out_len0);
	if (out_ptr0 == 0) {
		alias rdx : out_len_z;
		out_len_z = 0;
		return 0;
	}
	var i0 = 0;
	while (i0 < sn_len0) { ptr8[out_ptr0 + i0] = ptr8[sn_ptr0 + i0]; i0 = i0 + 1; }
	ptr8[out_ptr0 + sn_len0 + 0] = 95; // '_'
	if (is_set0 == 1) {
		ptr8[out_ptr0 + sn_len0 + 1] = 115; // 's'
		ptr8[out_ptr0 + sn_len0 + 2] = 101; // 'e'
		ptr8[out_ptr0 + sn_len0 + 3] = 116; // 't'
	} else {
		ptr8[out_ptr0 + sn_len0 + 1] = 103; // 'g'
		ptr8[out_ptr0 + sn_len0 + 2] = 101; // 'e'
		ptr8[out_ptr0 + sn_len0 + 3] = 116; // 't'
	}
	ptr8[out_ptr0 + sn_len0 + 4] = 95; // '_'
	var j0 = 0;
	while (j0 < fn_len0) { ptr8[out_ptr0 + sn_len0 + 5 + j0] = ptr8[fn_ptr0 + j0]; j0 = j0 + 1; }
	alias rdx : out_len_ret;
	out_len_ret = out_len0;
	return out_ptr0;
}

func tc_validate_property_hooks_mod(mod_id) {
	if (tc_structs == 0) { return 0; }
	var tsn = vec_len(tc_structs);
	var tsi = 0;
	while (tsi < tsn) {
		var st = vec_get(tc_structs, tsi);
		if (st != 0 && ptr64[st + 0] == TC_COMPOUND_STRUCT && ptr64[st + 48] == mod_id) {
			var fields0 = ptr64[st + 24];
			var fnn0 = 0;
			if (fields0 != 0) { fnn0 = vec_len(fields0); }
			var fi0 = 0;
			while (fi0 < fnn0) {
				var fm = vec_get(fields0, fi0);
				if (fm != 0) {
					var fattr0 = ptr64[fm + 40];
					var fty0 = ptr64[fm + 16];
					var fsz0 = tc_sizeof(fty0);
					var eline = ptr64[fm + 80];
					var ecol = ptr64[fm + 88];

					var has_getter0 = fattr0 & 1;
					var has_setter0 = fattr0 & 2;

					// getter
					if (has_getter0 != 0) {
						var gptr = ptr64[fm + 48];
						var glen = ptr64[fm + 56];
						if (gptr != 0 && glen != 0) {
							var sigg = tc_func_lookup_mod(mod_id, gptr, glen);
							if (sigg == 0) {
								tc_err_at(eline, ecol, "getter hook: unknown function");
							} else {
								var pcg = ptr64[sigg + 24];
								var p0g = ptr64[sigg + 32];
								var rg = ptr64[sigg + 48];
								var want_self = tc_make_ptr(st, 0);
								if (pcg != 1) {
									tc_err_at(eline, ecol, "getter hook: signature mismatch");
								} else if (p0g != want_self) {
									tc_err_at(eline, ecol, "getter hook: signature mismatch");
								} else if (rg != fty0) {
									tc_err_at(eline, ecol, "getter hook: signature mismatch");
								}
							}
						} else {
							// auto-generated name must not collide
							if (fsz0 != 1 && fsz0 != 8) {
								tc_err_at(eline, ecol, "getter hook: auto hook unsupported field type");
							} else {
								tc_build_hook_name(st, fm, 0);
									alias rdx : glen2;
									gptr = rax;
									glen = glen2;
								if (gptr != 0 && glen != 0) {
									if (tc_func_lookup_mod(mod_id, gptr, glen) != 0) {
										tc_err_at(eline, ecol, "getter hook: auto name conflicts with existing function");
									}
								}
							}
						}
					}

					// setter
					if (has_setter0 != 0) {
						var sptr = ptr64[fm + 64];
						var slen = ptr64[fm + 72];
						if (sptr != 0 && slen != 0) {
							var sigs = tc_func_lookup_mod(mod_id, sptr, slen);
							if (sigs == 0) {
								tc_err_at(eline, ecol, "setter hook: unknown function");
							} else {
								var pcs = ptr64[sigs + 24];
								var p0s = ptr64[sigs + 32];
								var p1s = ptr64[sigs + 40];
								var rs = ptr64[sigs + 48];
								var want_self = tc_make_ptr(st, 0);
								if (pcs != 2) {
									tc_err_at(eline, ecol, "setter hook: signature mismatch");
								} else if (p0s != want_self) {
									tc_err_at(eline, ecol, "setter hook: signature mismatch");
								} else if (p1s != fty0) {
									tc_err_at(eline, ecol, "setter hook: signature mismatch");
								} else if (rs != 0) {
									tc_err_at(eline, ecol, "setter hook: signature mismatch");
								}
							}
						} else {
							if (fsz0 != 1 && fsz0 != 8) {
								tc_err_at(eline, ecol, "setter hook: auto hook unsupported field type");
							} else {
								tc_build_hook_name(st, fm, 1);
								alias rdx : slen2;
								sptr = rax;
								slen = slen2;
								if (sptr != 0 && slen != 0) {
									if (tc_func_lookup_mod(mod_id, sptr, slen) != 0) {
										tc_err_at(eline, ecol, "setter hook: auto name conflicts with existing function");
									}
								}
							}
						}
					}
				}
				fi0 = fi0 + 1;
			}
		}
		tsi = tsi + 1;
	}
	return 0;
}

func tc_is_ptr_nullable(ty) {
	if (ty >= TC_TY_PTR_NULLABLE_BASE) {
		if (ty < (TC_TY_PTR_NULLABLE_BASE + 256)) { return 1; }
	}
	if (tc_is_compound(ty) == 1) {
		if (ptr64[ty + 0] == TC_COMPOUND_PTR) {
			return ptr64[ty + 16] == 1;
		}
	}
	return 0;
}

func tc_ptr_base(ty) {
	if (tc_is_compound(ty) == 1) {
		// {kind, inner, nullable}
		return ptr64[ty + 8];
	}
	if (tc_is_ptr_nullable(ty) == 1) { return ty - TC_TY_PTR_NULLABLE_BASE; }
	return ty - TC_TY_PTR_BASE;
}

func tc_make_ptr(base_ty, nullable) {
	// Allow pointers-to-pointers (double pointers).
	// Create compound pointer type for any base type.
	
	// For builtin scalar base types, keep encoded pointer types.
	if (base_ty > 0 && base_ty <= 255) {
		// But don't use encoded form if it's already a pointer (needs compound)
		if (tc_is_ptr(base_ty) == 0) {
			if (nullable == 1) { return TC_TY_PTR_NULLABLE_BASE + base_ty; }
			return TC_TY_PTR_BASE + base_ty;
		}
	}
	
	// Allow pointers to any type (structs, pointers, etc).
	// Intern: reuse if already created.
	if (tc_ptr_types != 0) {
		var n = vec_len(tc_ptr_types);
		var i = 0;
		while (i < n) {
			var pt = vec_get(tc_ptr_types, i);
			if (ptr64[pt + 0] == TC_COMPOUND_PTR) {
				if (ptr64[pt + 8] == base_ty) {
					if (ptr64[pt + 16] == nullable) { return pt; }
				}
			}
			i = i + 1;
		}
	}
	var t = heap_alloc(24);
	if (t == 0) { return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_PTR;
	ptr64[t + 8] = base_ty;
	ptr64[t + 16] = nullable;
	vec_push(tc_ptr_types, t);
	return t;
}

func tc_is_slice(ty) {
	if (ty >= TC_TY_SLICE_BASE && ty < (TC_TY_SLICE_BASE + 256)) { return 1; }
	return 0;
}

func tc_slice_elem(ty) {
	return ty - TC_TY_SLICE_BASE;
}

func tc_make_slice(elem_ty) {
	// Disallow slices of pointers/slices for now (MVP simplification).
	if (tc_is_ptr(elem_ty) == 1) { return TC_TY_INVALID; }
	if (tc_is_slice(elem_ty) == 1) { return TC_TY_INVALID; }
	if (elem_ty <= 0 || elem_ty > 255) { return TC_TY_INVALID; }
	return TC_TY_SLICE_BASE + elem_ty;
}

// Phase 6.7: Function pointer type support
func tc_is_func_ptr(ty) {
	if (ty == 0) { return 0; }
	if (ty == TC_TY_INVALID) { return 0; }
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_FUNC_PTR) { return 1; }
	return 0;
}

func tc_func_ptr_param_types(ty) {
	// Returns Vec* of param TC types
	return ptr64[ty + 8];
}

func tc_func_ptr_ret_type(ty) {
	// Returns TC type id (0 = void)
	return ptr64[ty + 16];
}

func tc_func_ptr_param_count(ty) {
	var params = tc_func_ptr_param_types(ty);
	if (params == 0) { return 0; }
	return vec_len(params);
}

func tc_make_func_ptr(param_types_vec, ret_ty) {
	// Intern: check existing func ptr types for match
	if (tc_func_ptr_types != 0) {
		var n = vec_len(tc_func_ptr_types);
		var i = 0;
		while (i < n) {
			var fp = vec_get(tc_func_ptr_types, i);
			if (ptr64[fp + 0] == TC_COMPOUND_FUNC_PTR) {
				if (ptr64[fp + 16] == ret_ty) {
					// Check param types match
					var existing_params = ptr64[fp + 8];
					var match = 1;
					var pcount = 0;
					if (param_types_vec != 0) { pcount = vec_len(param_types_vec); }
					var ecount = 0;
					if (existing_params != 0) { ecount = vec_len(existing_params); }
					if (pcount != ecount) { match = 0; }
					if (match == 1) {
						var j = 0;
						while (j < pcount) {
							var pt = vec_get(param_types_vec, j);
							var et = vec_get(existing_params, j);
							if (tc_type_eq(pt, et) == 0) { match = 0; break; }
							j = j + 1;
						}
					}
					if (match == 1) { return fp; }
				}
			}
			i = i + 1;
		}
	}
	// Create new func ptr type
	var t = heap_alloc(32);
	if (t == 0) { return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_FUNC_PTR;
	ptr64[t + 8] = param_types_vec;  // Vec* of param types (may be 0)
	ptr64[t + 16] = ret_ty;
	ptr64[t + 24] = 0;  // reserved
	if (tc_func_ptr_types != 0) {
		vec_push(tc_func_ptr_types, t);
	}
	return t;
}

func tc_is_compound(ty) {
	// Heuristic: all builtin scalar/encoded types are small.
	if (ty >= 4096) { return 1; }
	return 0;
}

func tc_is_array(ty) {
	if (tc_is_compound(ty) == 0) { return 0; }
	if (ptr64[ty + 0] == TC_COMPOUND_ARRAY) { return 1; }
	return 0;
}

func tc_array_elem(ty) {
	return ptr64[ty + 8];
}

func tc_array_len(ty) {
	return ptr64[ty + 16];
}

func tc_array_new(elem_ty, len) {
	var t = heap_alloc(24);
	if (t == 0) { return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_ARRAY;
	ptr64[t + 8] = elem_ty;
	ptr64[t + 16] = len;
	return t;
}

func tc_type_eq(a, b) {
	if (a == b) { return 1; }
	if (a == TC_TY_INVALID || b == TC_TY_INVALID) { return 0; }
	// Phase 2.6: distinct는 기반 타입과 암묵 동치가 아니다.
	if (tc_is_distinct(a) == 1 || tc_is_distinct(b) == 1) { return 0; }
	if (tc_is_array(a) == 1 && tc_is_array(b) == 1) {
		if (tc_array_len(a) != tc_array_len(b)) { return 0; }
		return tc_type_eq(tc_array_elem(a), tc_array_elem(b));
	}
	if (tc_is_tuple2(a) == 1 && tc_is_tuple2(b) == 1) {
		if (tc_type_eq(tc_tuple2_a(a), tc_tuple2_a(b)) == 0) { return 0; }
		return tc_type_eq(tc_tuple2_b(a), tc_tuple2_b(b));
	}
	// Phase 6.7: function pointer type equality
	if (tc_is_func_ptr(a) == 1 && tc_is_func_ptr(b) == 1) {
		// Compare return types
		if (tc_type_eq(tc_func_ptr_ret_type(a), tc_func_ptr_ret_type(b)) == 0) { return 0; }
		// Compare param counts
		var pa = tc_func_ptr_param_types(a);
		var pb = tc_func_ptr_param_types(b);
		var ca = 0;
		var cb = 0;
		if (pa != 0) { ca = vec_len(pa); }
		if (pb != 0) { cb = vec_len(pb); }
		if (ca != cb) { return 0; }
		// Compare param types
		var i = 0;
		while (i < ca) {
			var pta = vec_get(pa, i);
			var ptb = vec_get(pb, i);
			if (tc_type_eq(pta, ptb) == 0) { return 0; }
			i = i + 1;
		}
		return 1;
	}
	return 0;
}

func tc_parse_u64_literal(p, n) {
	// Returns: rax=value, rdx=ok
	var i = 0;
	var base = 10;
	if (n >= 2) {
		if (ptr8[p + 0] == 48) {
			var c1 = ptr8[p + 1];
			if (c1 == 120 || c1 == 88) {
				base = 16;
				i = 2;
			}
		}
	}

	var v = 0;
	var any = 0;
	while (i < n) {
		var ch = ptr8[p + i];
		var digit = 18446744073709551615; // -1
		if (ch >= 48) { if (ch <= 57) { digit = ch - 48; } }
		if (base == 16) {
			if (digit == 18446744073709551615) {
				if (ch >= 65) { if (ch <= 70) { digit = (ch - 65) + 10; } }
			}
			if (digit == 18446744073709551615) {
				if (ch >= 97) { if (ch <= 102) { digit = (ch - 97) + 10; } }
			}
		}
		if (digit == 18446744073709551615) { break; }
		if (digit >= base) { break; }
		any = 1;
		v = (v * base) + digit;
		i = i + 1;
	}

	alias rdx : ok;
	ok = any;
	return v;
}

func tc_pow2_nonneg(bits) {
	// Computes 2^bits for bits small enough that the result stays non-negative.
	var r = 1;
	var i = 0;
	while (i < bits) {
		r = r * 2;
		i = i + 1;
	}
	return r;
}

func tc_pow2_wrap(bits) {
	// Computes 2^bits in signed wraparound arithmetic (used for 2^63).
	var r = 1;
	var i = 0;
	while (i < bits) {
		r = r * 2;
		i = i + 1;
	}
	return r;
}

func tc_check_int_literal_range_unsigned(v, bits) {
	if (bits == 0) { return 0; }
	// Hosted v3 runs on v2 runtime integers (signed). For u64, accept all parsed values.
	if (bits == 64) { return 1; }
	if (v < 0) { return 0; }
	var limit = tc_pow2_nonneg(bits);
	if (limit <= 0) { return 0; }
	if (v >= limit) { return 0; }
	return 1;
}

func tc_check_int_literal_range_signed_pos(v, bits) {
	// v is non-negative magnitude.
	if (bits == 0) { return 0; }
	if (v < 0) { return 0; }
	if (bits == 64) {
		// i64 max is 2^63-1; overflowing parse flips sign.
		return 1;
	}
	var limit = tc_pow2_nonneg(bits - 1);
	if (limit <= 0) { return 0; }
	if (v >= limit) { return 0; }
	return 1;
}

func tc_check_int_literal_range_signed_neg(mag, bits) {
	// mag is positive magnitude for negative literal (e.g. -128 => mag=128).
	if (bits == 0) { return 0; }
	if (bits == 64) {
		// allow mag <= 2^63 (the i64 min magnitude). 2^63 overflows to a negative value.
		if (mag < 0) {
			var limit = tc_pow2_wrap(63);
			if (mag == limit) { return 1; }
			return 0;
		}
		return 1;
	}
	if (mag < 0) { return 0; }
	var limit2 = tc_pow2_nonneg(bits - 1);
	if (limit2 <= 0) { return 0; }
	if (mag > limit2) { return 0; }
	return 1;
}

func tc_expr_with_expected(env, e, expected) {
	// Like tc_expr, but uses `expected` for context-based literal typing.
	if (e == 0) { return TC_TY_INVALID; }
	var k = ptr64[e + 0];

	if (k == AstExprKind.NULL) {
		if (tc_is_ptr_nullable(expected) == 1) {
			return expected;
		}
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "null requires nullable pointer type");
		return TC_TY_INVALID;
	}

	if (k == AstExprKind.INT) {
		// INT tokens include full slice (decimal or 0x..).
		var tok_ptr = ptr64[e + 40];
		var tok_len = ptr64[e + 48];
		var v = tc_parse_u64_literal(tok_ptr, tok_len);
		alias rdx : ok;
		if (ok == 0) {
			return TC_TY_INVALID;
		}

		if (tc_is_int(expected) == 1) {
			var bits = tc_int_bits(expected);
			if (tc_is_signed_int(expected) == 1) {
				// Non-negative literal in signed context.
				if (tc_check_int_literal_range_signed_pos(v, bits) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "integer literal out of range");
					return TC_TY_INVALID;
				}
				return expected;
			}
			// Unsigned.
			if (tc_check_int_literal_range_unsigned(v, bits) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "integer literal out of range");
				return TC_TY_INVALID;
			}
			return expected;
		}
		// Allow integer 0 as null for nullable pointers.
		if (tc_is_ptr_nullable(expected) == 1) {
			if (v == 0) { return expected; }
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "only 0 is allowed for nullable pointer");
			return TC_TY_INVALID;
		}
		// Default: u64 for now.
		return TC_TY_U64;
	}

	// Phase 6.6: floating-point literal
	if (k == AstExprKind.FLOAT) {
		// Default to f64, accept f32 or f64 context.
		if (expected == TC_TY_F32) { return TC_TY_F32; }
		if (expected == TC_TY_F64) { return TC_TY_F64; }
		// Default without context.
		return TC_TY_F64;
	}

	if (k == AstExprKind.UNARY) {
		var op = ptr64[e + 8];
		// Handle negative integer literals in signed context: -<int>
		if (op == TokKind.MINUS && tc_is_signed_int(expected) == 1) {
			var rhs = ptr64[e + 16];
			if (rhs != 0 && ptr64[rhs + 0] == AstExprKind.INT) {
				var tok_ptr2 = ptr64[rhs + 40];
				var tok_len2 = ptr64[rhs + 48];
				var mag = tc_parse_u64_literal(tok_ptr2, tok_len2);
				alias rdx : ok2;
				if (ok2 == 0) { return TC_TY_INVALID; }
				var bits2 = tc_int_bits(expected);
				if (tc_check_int_literal_range_signed_neg(mag, bits2) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "integer literal out of range");
					return TC_TY_INVALID;
				}
				// Treat as expected signed int.
				return expected;
			}
		}
		if (op == TokKind.DOLLAR) {
			// Phase 4.1: unsafe deref/load: $ptr
			// Allows nullable pointers (no implicit null check).
			var rhs_ty2 = tc_expr(env, ptr64[e + 16]);
			if (tc_is_ptr(rhs_ty2) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'$' expects pointer");
				return TC_TY_INVALID;
			}
			var base_ty = tc_ptr_base(rhs_ty2);
			var sz = tc_sizeof(base_ty);
			ptr64[e + 32] = sz; // for codegen: 1 or 8 supported
			return base_ty;
		}
		if (op == TokKind.AMP) {
			// Address-of should not push expected into operand; it creates a pointer.
			var rhs2 = ptr64[e + 16];
			var rhs_ty3 = tc_expr(env, rhs2);
			if (rhs2 == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'&' expects lvalue");
				return TC_TY_INVALID;
			}
			var rk2 = ptr64[rhs2 + 0];
			// Allow &identifier, &field, &array[index]
			if (rk2 != AstExprKind.IDENT && rk2 != AstExprKind.FIELD && rk2 != AstExprKind.INDEX) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'&' expects lvalue");
				return TC_TY_INVALID;
			}
			if (rk2 == AstExprKind.IDENT) {
				var nm_ptr = ptr64[rhs2 + 40];
				var nm_len = ptr64[rhs2 + 48];
				if (tc_is_nospill_name(nm_ptr, nm_len) == 1) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "cannot take address of nospill local");
					return TC_TY_INVALID;
				}
			}
			var pty2 = tc_make_ptr(rhs_ty3, 0);
			if (pty2 == TC_TY_INVALID) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "cannot take address of this type");
				return TC_TY_INVALID;
			}
			return pty2;
		}
		if (op == TokKind.STAR) {
			// Deref should not push expected into operand; it consumes a pointer.
			var rhs_ty4 = tc_expr(env, ptr64[e + 16]);
			if (tc_is_ptr(rhs_ty4) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "deref expects pointer");
				return TC_TY_INVALID;
			}
			if (tc_is_ptr_nullable(rhs_ty4) == 1) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "cannot deref nullable pointer");
				return TC_TY_INVALID;
			}
			return tc_ptr_base(rhs_ty4);
		}
		// Fallback: type-check rhs normally.
		var rhs_ty = tc_expr_with_expected(env, ptr64[e + 16], expected);
		if (op == TokKind.BANG) {
			if (rhs_ty != TC_TY_BOOL) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'!' expects bool");
				return TC_TY_INVALID;
			}
			return TC_TY_BOOL;
		}
		if (op == TokKind.PLUS || op == TokKind.MINUS || op == TokKind.TILDE) {
			if (tc_is_int(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "unary op expects integer");
				return TC_TY_INVALID;
			}
			return rhs_ty;
		}
		return rhs_ty;
	}

	if (k == AstExprKind.BRACE_INIT) {
		// Phase 3.6: typed brace init (struct literal) has an AstType in a.
		if (ptr64[e + 16] != 0) {
			var ty0 = tc_expr(env, e);
			if (expected != 0 && expected != TC_TY_INVALID) {
				if (tc_type_eq(ty0, expected) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "brace-init type mismatch");
					return TC_TY_INVALID;
				}
			}
			return ty0;
		}
		if (tc_is_array(expected) == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "brace-init requires array type context");
			return TC_TY_INVALID;
		}
		var elems = ptr64[e + 32];
		var n = 0;
		if (elems != 0) { n = vec_len(elems); }
		var want = tc_array_len(expected);
		if (n != want) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "array init element count mismatch");
			return TC_TY_INVALID;
		}
		var elem_ty = tc_array_elem(expected);
		var i = 0;
		while (i < n) {
			var et = tc_expr_with_expected(env, vec_get(elems, i), elem_ty);
			if (tc_type_eq(et, elem_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "array init element type mismatch");
				return TC_TY_INVALID;
			}
			i = i + 1;
		}
		return expected;
	}

	// For all other node kinds, use tc_expr and then do any context-based INT range checks
	// via propagation in BINOP below.
	return tc_expr(env, e);
}

func tc_type_from_asttype(t) {
	if (t == 0) { return TC_TY_INVALID; }
	var kind = ptr64[t + 0];
	if (kind == AstTypeKind.COMPTIME_EXPR) {
		// Lowered comptime type expression. MVP: __typefn$Name(...) calls.
		var e = ptr64[t + 8];
		if (e == 0) { return TC_TY_INVALID; }
		ct_eval_failed = 0;
		ct_eval_steps = 0;
		if (ct_eval_step_limit == 0) { ct_eval_step_limit = 100000; }
		if (ct_eval_step() != 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: step limit exceeded");
			return TC_TY_INVALID;
		}
		if (ptr64[e + 0] != AstExprKind.CALL) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: expected typefn call");
			ct_eval_failed = 1;
			return TC_TY_INVALID;
		}
		var callee = ptr64[e + 16];
		if (callee == 0 || ptr64[callee + 0] != AstExprKind.IDENT) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: unsupported call target");
			ct_eval_failed = 1;
			return TC_TY_INVALID;
		}
		var np = ptr64[callee + 40];
		var nl = ptr64[callee + 48];
		if (nl < 9 || slice_eq_parts(np, 9, "__typefn$", 9) == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: only __typefn$ calls are supported");
			ct_eval_failed = 1;
			return TC_TY_INVALID;
		}
		var name_ptr = np + 9;
		var name_len = nl - 9;

		var args = ptr64[e + 32];
		var args_mixed = vec_new(4);
		if (args_mixed == 0) { ct_eval_failed = 1; return TC_TY_INVALID; }
		var type_args_tc = vec_new(4);
		if (type_args_tc == 0) { ct_eval_failed = 1; return TC_TY_INVALID; }
		var argc = 0;
		if (args != 0) { argc = vec_len(args); }
		var i = 0;
		while (i < argc) {
			if (ct_eval_step() != 0) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: step limit exceeded");
				ct_eval_failed = 1;
				return TC_TY_INVALID;
			}
			var ae = vec_get(args, i);
			if (ae == 0) { ct_eval_failed = 1; return TC_TY_INVALID; }
			if (ptr64[ae + 0] == AstExprKind.TYPE_LIT) {
				var ty = tc_type_from_asttype(ptr64[ae + 16]);
				if (ty == TC_TY_INVALID) { ct_eval_failed = 1; return TC_TY_INVALID; }
				var mix = ty * 2;
				vec_push(args_mixed, mix);
				vec_push(type_args_tc, ty);
			} else {
				ct_eval_failed = 0;
				var v = ct_eval_u64_expr(ae);
				if (ct_eval_failed != 0) { return TC_TY_INVALID; }
				var mixv = (v * 2) + 1;
				vec_push(args_mixed, mixv);
				vec_push(type_args_tc, TC_TY_INVALID);
			}
			i = i + 1;
		}

		var ent = lw_find_generic_struct_typefn_entry(tc_cur_ast_prog, name_ptr, name_len);
		if (ent == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: unknown typefn");
			ct_eval_failed = 1;
			return TC_TY_INVALID;
		}
		var templ = lw_typefn_entry_templ_decl(ent);
		var new_name_ptr = tc_mangle_generic_inst_name_mixed(name_ptr, name_len, args_mixed);
		alias rdx : new_name_len_reg;
		var new_name_len = new_name_len_reg;
		if (new_name_ptr == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime: failed to mangle instantiation name");
			ct_eval_failed = 1;
			return TC_TY_INVALID;
		}
		var ty2 = tc_instantiate_generic_struct_decl(templ, new_name_ptr, new_name_len, args_mixed, type_args_tc, tc_cur_mod);
		if (ty2 == TC_TY_INVALID) { ct_eval_failed = 1; return TC_TY_INVALID; }
		ct_eval_failed = 0;
		return ty2;
	}
	if (kind == AstTypeKind.GENERIC) {
		// Phase 5.1+ direction: treat generic type instantiation as a comptime
		// "type evaluation" step. MVP: only supports generic struct types.
		return ct_eval_type_from_asttype(t);
	}
	if (kind == AstTypeKind.NAME) {
		var name_ptr = ptr64[t + 8];
		var name_len = ptr64[t + 16];
		// Optional alias: `str` == `[]u8`.
		if (slice_eq_parts(name_ptr, name_len, "str", 3) == 1) {
			return TC_TY_SLICE_BASE + TC_TY_U8;
		}
		// Phase 2.6: type alias / distinct
		var a0 = tc_type_alias_lookup(name_ptr, name_len);
		if (a0 != 0) { return ptr64[a0 + 32]; }
		var ty = tc_type_from_name(name_ptr, name_len);
		if (ty == TC_TY_INVALID) {
			var st = tc_struct_lookup(name_ptr, name_len);
			if (st != 0) { return st; }
				var en = tc_enum_lookup(name_ptr, name_len);
				if (en != 0) { return en; }
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown name");
		}
		return ty;
	}
	if (kind == AstTypeKind.PTR) {
		var inner = ptr64[t + 8];
		var nullable = ptr64[t + 16];
		var inner_ty = tc_type_from_asttype(inner);
		var ptr_ty = tc_make_ptr(inner_ty, nullable);
		if (ptr_ty == TC_TY_INVALID) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unsupported pointer base");
			return TC_TY_INVALID;
		}
		return ptr_ty;
	}
	if (kind == AstTypeKind.SLICE) {
		var inner2 = ptr64[t + 8];
		var elem_ty = tc_type_from_asttype(inner2);
		var slice_ty = tc_make_slice(elem_ty);
		if (slice_ty == TC_TY_INVALID) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unsupported slice element");
			return TC_TY_INVALID;
		}
		return slice_ty;
	}
	if (kind == AstTypeKind.ARRAY) {
		var inner3 = ptr64[t + 8];
		var len = ptr64[t + 16];
		var len_expr = ptr64[t + 48];
		if (len_expr != 0) {
			ct_eval_failed = 0;
			ct_eval_steps = 0;
			len = ct_eval_u64_expr(len_expr);
			if (ct_eval_failed != 0) { return TC_TY_INVALID; }
		}
		var elem_ty2 = tc_type_from_asttype(inner3);
		if (elem_ty2 == TC_TY_INVALID) { return TC_TY_INVALID; }
		return tc_array_new(elem_ty2, len);
	}
	if (kind == AstTypeKind.QUAL_NAME) {
		var mod_ptr = ptr64[t + 8];
		var mod_len = ptr64[t + 16];
		var name_ptr = ptr64[t + 48];
		var name_len = ptr64[t + 56];
		if (tc_modules == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: module-qualified name not supported here");
			return TC_TY_INVALID;
		}
		var mod_id = tc_module_lookup(mod_ptr, mod_len);
		if (mod_id == 18446744073709551615) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown module");
			return TC_TY_INVALID;
		}
		if (mod_id != tc_cur_mod && tc_imports_contains(tc_cur_imports, mod_ptr, mod_len) == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: module not imported");
			return TC_TY_INVALID;
		}
		var st = tc_struct_lookup_mod(mod_id, name_ptr, name_len);
		if (st != 0) {
			if (mod_id != tc_cur_mod && tc_struct_is_public(st) == 0) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "type is private");
				return TC_TY_INVALID;
			}
			return st;
		}
		var en = tc_enum_lookup_mod(mod_id, name_ptr, name_len);
		if (en != 0) {
			if (mod_id != tc_cur_mod && tc_enum_is_public(en) == 0) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "type is private");
				return TC_TY_INVALID;
			}
			return en;
		}
		var a1 = tc_type_alias_lookup_mod(mod_id, name_ptr, name_len);
		if (a1 != 0) {
			if (mod_id != tc_cur_mod && ptr64[a1 + 24] == 0) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "type is private");
				return TC_TY_INVALID;
			}
			return ptr64[a1 + 32];
		}
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown name");
		return TC_TY_INVALID;
	}
	if (kind == AstTypeKind.TUPLE) {
		var elems = ptr64[t + 48];
		if (elems == 0 || vec_len(elems) != 2) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: tuple must have 2 elements");
			return TC_TY_INVALID;
		}
		var t0 = tc_type_from_asttype(vec_get(elems, 0));
		var t1 = tc_type_from_asttype(vec_get(elems, 1));
		if (t0 == TC_TY_INVALID || t1 == TC_TY_INVALID) { return TC_TY_INVALID; }
		// MVP: only allow tuple elements that fit in a return register.
		var sz0 = tc_sizeof(t0);
		var sz1 = tc_sizeof(t1);
		if (sz0 == 0 || sz1 == 0 || sz0 > 8 || sz1 > 8) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: tuple return elements must be <= 8 bytes");
			return TC_TY_INVALID;
		}
		if (tc_is_slice(t0) == 1 || tc_is_slice(t1) == 1) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: tuple return elements cannot be slices");
			return TC_TY_INVALID;
		}
		if (tc_is_struct(t0) == 1 || tc_is_struct(t1) == 1) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: tuple return elements cannot be structs");
			return TC_TY_INVALID;
		}
		if (tc_is_array(t0) == 1 || tc_is_array(t1) == 1) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: tuple return elements cannot be arrays");
			return TC_TY_INVALID;
		}
		return tc_tuple2_new(t0, t1);
	}
	// Phase 6.7: Function pointer type
	if (kind == AstTypeKind.FUNC_PTR) {
		var param_types_ast = ptr64[t + 8];  // Vec* of AstType*
		var ret_type_ast = ptr64[t + 16];    // AstType* or 0
		// Convert AST param types to TC types
		var param_types_tc = 0;
		if (param_types_ast != 0) {
			var pcount = vec_len(param_types_ast);
			if (pcount > 0) {
				param_types_tc = vec_new(pcount);
				if (param_types_tc == 0) { return TC_TY_INVALID; }
				var i = 0;
				while (i < pcount) {
					var pat = vec_get(param_types_ast, i);
					var pty = tc_type_from_asttype(pat);
					if (pty == TC_TY_INVALID) {
						tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: invalid function pointer param type");
						return TC_TY_INVALID;
					}
					vec_push(param_types_tc, pty);
					i = i + 1;
				}
			}
		}
		// Convert return type
		var ret_ty = 0;
		if (ret_type_ast != 0) {
			ret_ty = tc_type_from_asttype(ret_type_ast);
			if (ret_ty == TC_TY_INVALID) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: invalid function pointer return type");
				return TC_TY_INVALID;
			}
		}
		return tc_make_func_ptr(param_types_tc, ret_ty);
	}
	tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unsupported kind");
	return TC_TY_INVALID;
}
func ct_eval_type_from_asttype(t) {
	// MVP: comptime type-evaluator.
	// Today it only covers AstTypeKind.GENERIC (generic struct instantiation).
	if (t == 0) { return TC_TY_INVALID; }
	if (ptr64[t + 0] != AstTypeKind.GENERIC) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "comptime type eval: unsupported kind");
		return TC_TY_INVALID;
	}

	// AstType.GENERIC: name_ptr=base AstType*, qual_ptr=args Vec(AstType*).
	var base_ast = ptr64[t + 8];
	var args_ast = ptr64[t + 48];
	if (base_ast == 0 || args_ast == 0) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: malformed generic type");
		return TC_TY_INVALID;
	}
	var base_kind = ptr64[base_ast + 0];
	var mod_id = tc_cur_mod;
	var name_ptr = 0;
	var name_len = 0;
	var templ_prog = tc_cur_ast_prog;
	if (base_kind == AstTypeKind.NAME) {
		name_ptr = ptr64[base_ast + 8];
		name_len = ptr64[base_ast + 16];
	} else if (base_kind == AstTypeKind.QUAL_NAME) {
		var mod_ptr = ptr64[base_ast + 8];
		var mod_len = ptr64[base_ast + 16];
		name_ptr = ptr64[base_ast + 48];
		name_len = ptr64[base_ast + 56];
		if (tc_modules == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: module-qualified name not supported here");
			return TC_TY_INVALID;
		}
		mod_id = tc_module_lookup(mod_ptr, mod_len);
		if (mod_id == 18446744073709551615) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown module");
			return TC_TY_INVALID;
		}
		if (mod_id != tc_cur_mod && tc_imports_contains(tc_cur_imports, mod_ptr, mod_len) == 0) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: module not imported");
			return TC_TY_INVALID;
		}
		var m = vec_get(tc_modules, mod_id);
		if (m != 0) { templ_prog = ptr64[m + 16]; }
	} else {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: generic base must be a name");
		return TC_TY_INVALID;
	}

	// Convert args (mixed type/value) into:
	//  - args_mixed: Vec(u64) where each entry is either (tc_ty<<1) for type args,
	//    or (value_u64<<1)|1 for value args.
	//  - ta_tc: Vec(u64) aligned to type_params arity; value args use TC_TY_INVALID.
	ct_eval_steps = 0;
	ct_tmp_args_mixed = vec_new(4);
	if (ct_tmp_args_mixed == 0) { return TC_TY_INVALID; }
	ct_tmp_type_args_tc = vec_new(4);
	if (ct_tmp_type_args_tc == 0) { return TC_TY_INVALID; }
	var an = vec_len(args_ast);
	var ai = 0;
	while (ai < an) {
		var raw = vec_get(args_ast, ai);
		var tag = raw & 1;
		if (tag == 0) {
			// Type argument: raw is AstType*
			var aty = tc_type_from_asttype(raw);
			if (aty == TC_TY_INVALID) { return TC_TY_INVALID; }
			var p = tc_builtin_name_ptr_for_tctype(aty);
			alias rdx : tl;
			if (p == 0 || tl == 0) {
				tc_err_at(ptr64[t + 32], ptr64[t + 40], "generic type arg: unsupported (MVP builtin-only)");
				return TC_TY_INVALID;
			}
			var mix = aty * 2;
			vec_push(ct_tmp_args_mixed, mix);
			vec_push(ct_tmp_type_args_tc, aty);
		} else {
			// Value argument: raw is (AstExpr* | 1)
			var expr_ptr = raw - 1;
			ct_eval_failed = 0;
			var v = ct_eval_u64_expr(expr_ptr);
			if (ct_eval_failed != 0) { return TC_TY_INVALID; }
			var mixv = (v * 2) + 1;
			vec_push(ct_tmp_args_mixed, mixv);
			vec_push(ct_tmp_type_args_tc, TC_TY_INVALID);
		}
		ai = ai + 1;
	}

	// Conceptual comptime call:
	//   __typefn$<name><args...>() -> type
	// MVP: perform instantiation directly, but consult lowering registry entry
	// to align with the final "generics -> comptime" model.
	var argc_total = vec_len(ct_tmp_args_mixed);
	var ent = lw_find_generic_struct_typefn_entry(templ_prog, name_ptr, name_len);
	if (ent != 0) {
		var want = lw_typefn_entry_arity(ent);
		if (want != argc_total) {
			tc_err_at(ptr64[t + 32], ptr64[t + 40], "generic struct: type arg count mismatch");
			return TC_TY_INVALID;
		}
		// Keep the synthetic decl reachable for future evaluator integration.
		var d = lw_typefn_entry_typefn_decl(ent);
		d = d;
	}

	// Mangle instantiated type name and return existing instance if present.
	var new_name_ptr = tc_mangle_generic_inst_name_mixed(name_ptr, name_len, ct_tmp_args_mixed);
	alias rdx : new_name_len_reg;
	var new_name_len = new_name_len_reg;
	if (new_name_ptr == 0) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "generic struct: failed to mangle instantiation name (ptr)");
		return TC_TY_INVALID;
	}
	if (new_name_len == 0) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "generic struct: failed to mangle instantiation name (len)");
		return TC_TY_INVALID;
	}
	var existing = tc_struct_lookup_mod(mod_id, new_name_ptr, new_name_len);
	if (existing != 0) { return existing; }

	var templ = 0;
	if (ent != 0) { templ = lw_typefn_entry_templ_decl(ent); }
	if (templ == 0) { templ = tc_find_generic_struct_template_decl(templ_prog, name_ptr, name_len); }
	if (templ == 0) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown generic struct template");
		return TC_TY_INVALID;
	}
	var is_public = ptr64[templ + 72];
	if (mod_id != tc_cur_mod && is_public == 0) {
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type is private");
		return TC_TY_INVALID;
	}
	return tc_instantiate_generic_struct_decl(templ, new_name_ptr, new_name_len, ct_tmp_args_mixed, ct_tmp_type_args_tc, mod_id);
}

func tc_find_generic_struct_template_decl(prog, name_ptr, name_len) {
	// Prefer the lowering registry (canonical type-function view).
	var ent = lw_find_generic_struct_typefn_entry(prog, name_ptr, name_len);
	var d0 = lw_typefn_entry_templ_decl(ent);
	if (d0 != 0) { return d0; }

	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.STRUCT) {
			if (slice_eq_parts(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) {
				var flags = ptr64[d + 80];
				var tflag0 = flags & TC_DECL_FLAG_GENERIC_TEMPLATE;
				var tparams = ptr64[d + 96];
				if (tflag0 != 0 || tparams != 0) {
					return d;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_instantiate_generic_struct_decl(templ, new_name_ptr, new_name_len, args_mixed, type_args_tc, mod_id) {
	// Returns instantiated TC_COMPOUND_STRUCT type pointer (or TC_TY_INVALID on error).
	if (templ == 0) { return TC_TY_INVALID; }
	var is_public = ptr64[templ + 72];
	var existing = tc_struct_lookup_mod(mod_id, new_name_ptr, new_name_len);
	if (existing != 0) { return existing; }

	var type_params = ptr64[templ + 96];
	if (type_params == 0 || args_mixed == 0 || type_args_tc == 0) { return TC_TY_INVALID; }
	var argc_total = vec_len(args_mixed);
	if (vec_len(type_params) != argc_total) {
		tc_err_at(ptr64[templ + 56], ptr64[templ + 64], "generic struct: type arg count mismatch");
		return TC_TY_INVALID;
	}

	// Bind value generic params into comptime environment.
	var saved_env = ct_value_env;
	ct_value_env = 0;
	var pi0 = 0;
	while (pi0 < argc_total) {
		var ent0 = vec_get(type_params, pi0);
		var ann = 0;
		if (ent0 != 0) { ann = ptr64[ent0 + 16]; }
		var arg0 = vec_get(args_mixed, pi0);
		var arg_tag = arg0 & 1;
		if (ann != 0) {
			// value param; currently only allow u64
			var ann_tc = tc_type_from_asttype(ann);
			if (ann_tc != TC_TY_U64) {
				tc_err_at(ptr64[templ + 56], ptr64[templ + 64], "generic struct: value params must be u64 (MVP)");
				ct_value_env = saved_env;
				return TC_TY_INVALID;
			}
			if (arg_tag == 0) {
				tc_err_at(ptr64[templ + 56], ptr64[templ + 64], "generic struct: expected value arg");
				ct_value_env = saved_env;
				return TC_TY_INVALID;
			}
			var v0 = arg0 / 2;
			ct_env_u64_push(ptr64[ent0 + 0], ptr64[ent0 + 8], v0);
		} else {
			// type param
			if (arg_tag != 0) {
				tc_err_at(ptr64[templ + 56], ptr64[templ + 64], "generic struct: expected type arg");
				ct_value_env = saved_env;
				return TC_TY_INVALID;
			}
		}
		pi0 = pi0 + 1;
	}

	var ast_fields = ptr64[templ + 24];
	var fields = vec_new(8);
	if (fields == 0) { ct_value_env = saved_env; return TC_TY_INVALID; }

	var cur = 0;
	var align = 1;
	var n = 0;
	if (ast_fields != 0) { n = vec_len(ast_fields); }
	var i = 0;
	while (i < n) {
		var st = vec_get(ast_fields, i);
		var fname_ptr = ptr64[st + 32];
		var fname_len = ptr64[st + 40];
		var fpublic = ptr64[st + 8];
		var fattr = ptr64[st + 16];
		var fattr_args = ptr64[st + 24];
		var fty_ast0 = ptr64[st + 48];
		var fty_ast = tc_clone_type_subst(fty_ast0, type_params, type_args_tc);
		var fty = tc_type_from_asttype(fty_ast);
		if (fty == TC_TY_INVALID) { i = i + 1; continue; }
		var f_align = tc_alignof(fty);
		var f_size = tc_sizeof(fty);
		if (f_size == 0) {
			tc_err_at(ptr64[st + 72], ptr64[st + 80], "struct field: unsupported type");
			i = i + 1;
			continue;
		}
		cur = tc_align_up(cur, f_align);
		var off = cur;
		cur = cur + f_size;
		if (f_align > align) { align = f_align; }

		var f = heap_alloc(96);
		if (f == 0) { ct_value_env = saved_env; return TC_TY_INVALID; }
		ptr64[f + 0] = fname_ptr;
		ptr64[f + 8] = fname_len;
		ptr64[f + 16] = fty;
		ptr64[f + 24] = off;
		ptr64[f + 32] = fpublic;
		ptr64[f + 40] = fattr;
		ptr64[f + 48] = 0;
		ptr64[f + 56] = 0;
		ptr64[f + 64] = 0;
		ptr64[f + 72] = 0;
		if (fattr_args != 0) {
			ptr64[f + 48] = ptr64[fattr_args + 0];
			ptr64[f + 56] = ptr64[fattr_args + 8];
			ptr64[f + 64] = ptr64[fattr_args + 16];
			ptr64[f + 72] = ptr64[fattr_args + 24];
		}
		ptr64[f + 80] = ptr64[st + 72];
		ptr64[f + 88] = ptr64[st + 80];
		vec_push(fields, f);
		i = i + 1;
	}

	// Restore value env.
	ct_value_env = saved_env;

	var size = tc_align_up(cur, align);
	var t = heap_alloc(64);
	if (t == 0) { ct_value_env = saved_env; return TC_TY_INVALID; }
	ptr64[t + 0] = TC_COMPOUND_STRUCT;
	ptr64[t + 8] = new_name_ptr;
	ptr64[t + 16] = new_name_len;
	ptr64[t + 24] = fields;
	ptr64[t + 32] = size;
	ptr64[t + 40] = align;
	ptr64[t + 48] = mod_id;
	ptr64[t + 56] = is_public;
	vec_push(tc_structs, t);
	// HashMap insert for O(1) lookup
	if (tc_structs_map != 0) {
		var key_ptr_s = tc_make_key(mod_id, new_name_ptr, new_name_len);
		alias rdx : key_len_s;
		hashmap_put(tc_structs_map, key_ptr_s, key_len_s, t);
	}
	return t;
}

func tc_register_struct_decl(d, mod_id, is_public) {
	// Returns 1 if an error occurred.
	var name_ptr = ptr64[d + 8];
	var name_len = ptr64[d + 16];
	if (tc_struct_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(ptr64[d + 56], ptr64[d + 64], "duplicate struct name");
		return 1;
	}

	var ast_fields = ptr64[d + 24]; // Vec of AstStmt(VAR)*
	var fields = vec_new(8);
	if (fields == 0) { return 1; }

	var cur = 0;
	var align = 1;
	var n = 0;
	if (ast_fields != 0) { n = vec_len(ast_fields); }
	var i = 0;
	while (i < n) {
		var st = vec_get(ast_fields, i);
		var fname_ptr = ptr64[st + 32];
		var fname_len = ptr64[st + 40];
		var fpublic = ptr64[st + 8];
		var fattr = ptr64[st + 16];
		var fattr_args = ptr64[st + 24];
		var fty_ast = ptr64[st + 48];
		var fty = tc_type_from_asttype(fty_ast);
		if (fty == TC_TY_INVALID) {
			// error already reported
			i = i + 1;
			continue;
		}
		var f_align = tc_alignof(fty);
		var f_size = tc_sizeof(fty);
		if (f_size == 0) {
			tc_err_at(ptr64[st + 72], ptr64[st + 80], "struct field: unsupported type");
			i = i + 1;
			continue;
		}
		cur = tc_align_up(cur, f_align);
		var off = cur;
		cur = cur + f_size;
		if (f_align > align) { align = f_align; }

		var f = heap_alloc(96);
		if (f == 0) { return 1; }
		ptr64[f + 0] = fname_ptr;
		ptr64[f + 8] = fname_len;
		ptr64[f + 16] = fty;
		ptr64[f + 24] = off;
		ptr64[f + 32] = fpublic;
		ptr64[f + 40] = fattr;
		// Optional property hook target functions from parser: @[getter(func)] / @[setter(func)]
		ptr64[f + 48] = 0;
		ptr64[f + 56] = 0;
		ptr64[f + 64] = 0;
		ptr64[f + 72] = 0;
		if (fattr_args != 0) {
			ptr64[f + 48] = ptr64[fattr_args + 0];
			ptr64[f + 56] = ptr64[fattr_args + 8];
			ptr64[f + 64] = ptr64[fattr_args + 16];
			ptr64[f + 72] = ptr64[fattr_args + 24];
		}
		// Store source location for diagnostics.
		ptr64[f + 80] = ptr64[st + 72];
		ptr64[f + 88] = ptr64[st + 80];
		vec_push(fields, f);
		i = i + 1;
	}

	var size = tc_align_up(cur, align);
	var t = heap_alloc(64);
	if (t == 0) { return 1; }
	ptr64[t + 0] = TC_COMPOUND_STRUCT;
	ptr64[t + 8] = name_ptr;
	ptr64[t + 16] = name_len;
	ptr64[t + 24] = fields;
	ptr64[t + 32] = size;
	ptr64[t + 40] = align;
	ptr64[t + 48] = mod_id;
	ptr64[t + 56] = is_public;
	vec_push(tc_structs, t);
	// HashMap insert for O(1) lookup
	if (tc_structs_map != 0) {
		var key_ptr_s = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len_s;
		hashmap_put(tc_structs_map, key_ptr_s, key_len_s, t);
	}
	return 0;
}

func tc_register_enum_decl(d, mod_id, is_public) {
	// Returns 1 if an error occurred.
	var name_ptr = ptr64[d + 8];
	var name_len = ptr64[d + 16];
	if (tc_enum_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(ptr64[d + 56], ptr64[d + 64], "duplicate enum name");
		return 1;
	}
	if (tc_struct_lookup_mod(mod_id, name_ptr, name_len) != 0) {
		tc_err_at(ptr64[d + 56], ptr64[d + 64], "enum name conflicts with struct");
		return 1;
	}
	var variants = ptr64[d + 24];
	var t = heap_alloc(48);
	if (t == 0) { return 1; }
	ptr64[t + 0] = TC_COMPOUND_ENUM;
	ptr64[t + 8] = name_ptr;
	ptr64[t + 16] = name_len;
	ptr64[t + 24] = variants;
	ptr64[t + 32] = mod_id;
	ptr64[t + 40] = is_public;
	vec_push(tc_enums, t);
	// HashMap insert for O(1) lookup
	if (tc_enums_map != 0) {
		var key_ptr_e = tc_make_key(mod_id, name_ptr, name_len);
		alias rdx : key_len_e;
		hashmap_put(tc_enums_map, key_ptr_e, key_len_e, t);
	}
	return 0;
}

func tc_env_new() {
	return vec_new(16);
}

func tc_env_push(env, name_ptr, name_len, ty) {
	// Copy args to locals before calls.
	var env2 = env;
	var name_ptr2 = name_ptr;
	var name_len2 = name_len;
	var ty2 = ty;

	var ent = heap_alloc(24);
	if (ent == 0) { return 0; }
	ptr64[ent + 0] = name_ptr2;
	ptr64[ent + 8] = name_len2;
	ptr64[ent + 16] = ty2;
	vec_push(env2, ent);
	return 0;
}

func tc_env_get(env, name_ptr, name_len) {
	// Returns: rax=ty (TC_TY_INVALID if not found)
	// NOTE(v2): vec_len/vec_get/slice_eq_parts 호출 경로에서 로컬/인자가 클로버되어
	// env 조회가 실패할 수 있다. 여기서는 Vec 레이아웃을 직접 읽고 비교도 인라인한다.
	if (env == 0) { return TC_TY_INVALID; }
	if (name_ptr == 0) { return TC_TY_INVALID; }
	var buf = ptr64[env + 0];
	var n = ptr64[env + 8];
	while (n != 0) {
		n = n - 1;
		var ent = ptr64[buf + (n * 8)];
		if (ent != 0) {
			var enp = ptr64[ent + 0];
			var enl = ptr64[ent + 8];
			if (enl == name_len && enp != 0) {
				var i = 0;
				var ok = 1;
				while (i < name_len) {
					if (ptr8[enp + i] != ptr8[name_ptr + i]) { ok = 0; break; }
					i = i + 1;
				}
				if (ok == 1) { return ptr64[ent + 16]; }
			}
		}
	}
	return TC_TY_INVALID;
}

func tc_is_discard_ident(name_ptr, name_len) {
	return slice_eq_parts(name_ptr, name_len, "_", 1);
}

// Phase 5.1 (MVP): generics monomorphization for functions.

func tc_builtin_name_ptr_for_tctype(ty) {
	// Returns: rax=ptr, rdx=len
	if (ty == TC_TY_U8) { alias rdx : l0; l0 = 2; return "u8"; }
	if (ty == TC_TY_U16) { alias rdx : l1; l1 = 3; return "u16"; }
	if (ty == TC_TY_U32) { alias rdx : l2; l2 = 3; return "u32"; }
	if (ty == TC_TY_U64) { alias rdx : l3; l3 = 3; return "u64"; }
	if (ty == TC_TY_I8) { alias rdx : l4; l4 = 2; return "i8"; }
	if (ty == TC_TY_I16) { alias rdx : l5; l5 = 3; return "i16"; }
	if (ty == TC_TY_I32) { alias rdx : l6; l6 = 3; return "i32"; }
	if (ty == TC_TY_I64) { alias rdx : l7; l7 = 3; return "i64"; }
	if (ty == TC_TY_BOOL) { alias rdx : l8; l8 = 4; return "bool"; }
	if (ty == TC_TY_CHAR) { alias rdx : l9; l9 = 4; return "char"; }
	// Phase 6.6: floating-point
	if (ty == TC_TY_F32) { alias rdx : l10; l10 = 3; return "f32"; }
	if (ty == TC_TY_F64) { alias rdx : l11; l11 = 3; return "f64"; }
	alias rdx : z;
	z = 0;
	return 0;
}

func ct_env_u64_push(name_ptr, name_len, value_u64) {
	if (ct_value_env == 0) { ct_value_env = vec_new(4); }
	if (ct_value_env == 0) { return 0; }
	var ent = heap_alloc(24);
	if (ent == 0) { return 0; }
	ptr64[ent + 0] = name_ptr;
	ptr64[ent + 8] = name_len;
	ptr64[ent + 16] = value_u64;
	vec_push(ct_value_env, ent);
	return 0;
}

func ct_env_u64_lookup(name_ptr, name_len) {
	// Returns: rax=value, rdx=ok
	var v = 0;
	var ok0 = 0;
	if (ct_value_env != 0) {
		var n = vec_len(ct_value_env);
		var i = 0;
		while (i < n) {
			var ent = vec_get(ct_value_env, i);
			if (ent != 0) {
				if (slice_eq_parts(ptr64[ent + 0], ptr64[ent + 8], name_ptr, name_len) == 1) {
					v = ptr64[ent + 16];
					ok0 = 1;
					break;
				}
			}
			i = i + 1;
		}
	}
	alias rdx : ok;
	ok = ok0;
	return v;
}

func ct_eval_u64_expr(e) {
	if (e == 0) {
		ct_eval_failed = 1;
		return 0;
	}
	if (ct_eval_step_limit == 0) { ct_eval_step_limit = 100000; }
	if (ct_eval_step() != 0) {
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: step limit exceeded");
		ct_eval_failed = 1;
		return 0;
	}
	var k = ptr64[e + 0];
	if (k == AstExprKind.INT) {
		ct_eval_failed = 0;
		return tc_parse_u64_literal(ptr64[e + 40], ptr64[e + 48]);
	}
	if (k == AstExprKind.IDENT) {
		var v0 = ct_env_u64_lookup(ptr64[e + 40], ptr64[e + 48]);
		alias rdx : ok0;
		if (ok0 == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: unknown identifier");
			ct_eval_failed = 1;
			return 0;
		}
		ct_eval_failed = 0;
		return v0;
	}
	if (k == AstExprKind.UNARY) {
		var op = ptr64[e + 8];
		var rhs = ct_eval_u64_expr(ptr64[e + 16]);
		if (ct_eval_failed != 0) { return 0; }
		if (op == TokKind.PLUS) { ct_eval_failed = 0; return rhs; }
		if (op == TokKind.MINUS) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: unary '-' not allowed for u64");
			ct_eval_failed = 1;
			return 0;
		}
		if (op == TokKind.TILDE) { ct_eval_failed = 0; return ~rhs; }
		if (op == TokKind.BANG) {
			if (rhs == 0) { ct_eval_failed = 0; return 1; }
			ct_eval_failed = 0;
			return 0;
		}
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: unsupported unary op");
		ct_eval_failed = 1;
		return 0;
	}
	if (k == AstExprKind.BINARY) {
		var op2 = ptr64[e + 8];
		var lhs = ct_eval_u64_expr(ptr64[e + 16]);
		if (ct_eval_failed != 0) { return 0; }
		var rhs2 = ct_eval_u64_expr(ptr64[e + 24]);
		if (ct_eval_failed != 0) { return 0; }
		// Boolean-y operators return 0/1.
		if (op2 == TokKind.EQEQ) { ct_eval_failed = 0; if (lhs == rhs2) { return 1; } return 0; }
		if (op2 == TokKind.NEQ) { ct_eval_failed = 0; if (lhs != rhs2) { return 1; } return 0; }
		if (op2 == TokKind.LT) { ct_eval_failed = 0; if (lhs < rhs2) { return 1; } return 0; }
		if (op2 == TokKind.LTE) { ct_eval_failed = 0; if (lhs <= rhs2) { return 1; } return 0; }
		if (op2 == TokKind.GT) { ct_eval_failed = 0; if (lhs > rhs2) { return 1; } return 0; }
		if (op2 == TokKind.GTE) { ct_eval_failed = 0; if (lhs >= rhs2) { return 1; } return 0; }
		if (op2 == TokKind.ANDAND) { ct_eval_failed = 0; if (lhs != 0 && rhs2 != 0) { return 1; } return 0; }
		if (op2 == TokKind.OROR) { ct_eval_failed = 0; if (lhs != 0 || rhs2 != 0) { return 1; } return 0; }
		if (op2 == TokKind.PLUS) { ct_eval_failed = 0; return lhs + rhs2; }
		if (op2 == TokKind.MINUS) {
			if (lhs < rhs2) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: u64 underflow");
				ct_eval_failed = 1;
				return 0;
			}
			ct_eval_failed = 0;
			return lhs - rhs2;
		}
		if (op2 == TokKind.STAR) { ct_eval_failed = 0; return lhs * rhs2; }
		if (op2 == TokKind.SLASH) {
			if (rhs2 == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: division by zero");
				ct_eval_failed = 1;
				return 0;
			}
			ct_eval_failed = 0;
			return lhs / rhs2;
		}
		if (op2 == TokKind.PERCENT) {
			if (rhs2 == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: mod by zero");
				ct_eval_failed = 1;
				return 0;
			}
			ct_eval_failed = 0;
			return lhs % rhs2;
		}
		if (op2 == TokKind.AMP) { ct_eval_failed = 0; return lhs & rhs2; }
		if (op2 == TokKind.PIPE) { ct_eval_failed = 0; return lhs | rhs2; }
		if (op2 == TokKind.CARET) { ct_eval_failed = 0; return lhs ^ rhs2; }
		if (op2 == TokKind.LSHIFT) {
			if (rhs2 >= 64) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: shift amount too large");
				ct_eval_failed = 1;
				return 0;
			}
			ct_eval_failed = 0;
			return lhs << rhs2;
		}
		if (op2 == TokKind.RSHIFT) {
			if (rhs2 >= 64) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: shift amount too large");
				ct_eval_failed = 1;
				return 0;
			}
			ct_eval_failed = 0;
			return lhs >> rhs2;
		}
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: unsupported binary op");
		ct_eval_failed = 1;
		return 0;
	}
	tc_err_at(ptr64[e + 64], ptr64[e + 72], "comptime: unsupported expression");
	ct_eval_failed = 1;
	return 0;
}

func tc_u64_dec_len(v) {
	if (v == 0) { return 1; }
	var n = 0;
	while (v != 0) {
		n = n + 1;
		v = v / 10;
	}
	return n;
}

func tc_write_u64_dec(buf, off, v) {
	var len = tc_u64_dec_len(v);
	var i = 0;
	while (i < len) {
		var digit = v % 10;
		v = v / 10;
		var pos = len - 1;
		pos = pos - i;
		ptr8[buf + off + pos] = 48 + digit;
		i = i + 1;
	}
	return len;
}

func tc_mangle_generic_inst_name_mixed(base_ptr, base_len, args_mixed) {
	// Returns: rax=ptr, rdx=len
	if (base_ptr == 0 || base_len == 0) {
		alias rdx : z;
		z = 0;
		return 0;
	}
	if (args_mixed == 0) {
		alias rdx : out0;
		out0 = base_len;
		return base_ptr;
	}
	var n = vec_len(args_mixed);
	var out_len = base_len;
	var i = 0;
	while (i < n) {
		var arg0 = vec_get(args_mixed, i);
		var tag0 = arg0 & 1;
		if (tag0 == 0) {
			var ty = arg0 / 2;
			var tptr = tc_builtin_name_ptr_for_tctype(ty);
			alias rdx : tlen;
			if (tptr == 0 || tlen == 0) {
				alias rdx : z2;
				z2 = 0;
				return 0;
			}
			out_len = out_len + 2 + tlen;
		} else {
			var v0 = arg0 / 2;
			out_len = out_len + 3 + tc_u64_dec_len(v0);
		}
		i = i + 1;
	}
	var alloc_len = out_len;
	if (alloc_len < 16) { alloc_len = 16; }
	var out_ptr = heap_alloc(alloc_len);
	if (out_ptr == 0) {
		alias rdx : z3;
		z3 = 0;
		return 0;
	}
	var j = 0;
	while (j < base_len) {
		ptr8[out_ptr + j] = ptr8[base_ptr + j];
		j = j + 1;
	}
	var off0 = base_len;
	i = 0;
	while (i < n) {
		var arg1 = vec_get(args_mixed, i);
		var tag1 = arg1 & 1;
		if (tag1 == 0) {
			ptr8[out_ptr + off0 + 0] = 95;
			ptr8[out_ptr + off0 + 1] = 95;
			off0 = off0 + 2;
			var ty2 = arg1 / 2;
			var tptr2 = tc_builtin_name_ptr_for_tctype(ty2);
			alias rdx : tlen2;
			var k = 0;
			while (k < tlen2) {
				ptr8[out_ptr + off0 + k] = ptr8[tptr2 + k];
				k = k + 1;
			}
			off0 = off0 + tlen2;
		} else {
			ptr8[out_ptr + off0 + 0] = 95;
			ptr8[out_ptr + off0 + 1] = 95;
			ptr8[out_ptr + off0 + 2] = 118; // 'v'
			off0 = off0 + 3;
			var v1 = arg1 / 2;
			off0 = off0 + tc_write_u64_dec(out_ptr, off0, v1);
		}
		i = i + 1;
	}
	alias rdx : out_len_ret;
	out_len_ret = out_len;
	return out_ptr;
}

func tc_find_generic_func_template_decl(prog, name_ptr, name_len) {
	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			var flags = ptr64[d + 80];
			var tflag0 = flags & TC_DECL_FLAG_GENERIC_TEMPLATE;
			var tparams0 = ptr64[d + 96];
			if (tflag0 != 0 || tparams0 != 0) {
				if (slice_eq_parts(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) {
					return d;
				}
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_ast_prog_has_func_name(prog, name_ptr, name_len) {
	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			if (slice_eq_parts(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) { return 1; }
		}
		i = i + 1;
	}
	return 0;
}

func tc_mangle_generic_inst_name(base_ptr, base_len, type_args_tc, type_argc) {
	// Returns: rax=ptr, rdx=len
	// MVP: only supports builtin scalar type args.
	var i = 0;
	var out_len = base_len;
	while (i < type_argc) {
		var ty = vec_get(type_args_tc, i);
		var tptr = tc_builtin_name_ptr_for_tctype(ty);
		alias rdx : tlen;
		if (tptr == 0 || tlen == 0) {
			alias rdx : z;
			z = 0;
			return 0;
		}
		out_len = out_len + 2 + tlen;
		i = i + 1;
	}
	var alloc_len = out_len;
	if (alloc_len < 16) { alloc_len = 16; }
	var out_ptr = heap_alloc(alloc_len);
	if (out_ptr == 0) {
		alias rdx : z2;
		z2 = 0;
		return 0;
	}
	var j = 0;
	while (j < base_len) { ptr8[out_ptr + j] = ptr8[base_ptr + j]; j = j + 1; }
	var off = base_len;
	i = 0;
	while (i < type_argc) {
		ptr8[out_ptr + off + 0] = 95;
		ptr8[out_ptr + off + 1] = 95;
		off = off + 2;
		var ty2 = vec_get(type_args_tc, i);
		var tptr2 = tc_builtin_name_ptr_for_tctype(ty2);
		alias rdx : tlen2;
		var k = 0;
		while (k < tlen2) { ptr8[out_ptr + off + k] = ptr8[tptr2 + k]; k = k + 1; }
		off = off + tlen2;
		i = i + 1;
	}
	alias rdx : out_len_ret;
	out_len_ret = out_len;
	return out_ptr;
}

func tc_clone_type_subst(t, type_params, type_args_tc) {
	// Clone AstType, substituting NAME matching type params with builtin scalar names.
	if (t == 0) { return 0; }
	var out = heap_alloc(64);
	if (out == 0) { return 0; }
	ptr64[out + 0] = ptr64[t + 0];
	ptr64[out + 8] = ptr64[t + 8];
	ptr64[out + 16] = ptr64[t + 16];
	ptr64[out + 24] = ptr64[t + 24];
	ptr64[out + 32] = ptr64[t + 32];
	ptr64[out + 40] = ptr64[t + 40];
	ptr64[out + 48] = ptr64[t + 48];
	ptr64[out + 56] = ptr64[t + 56];

	if (ptr64[t + 0] == AstTypeKind.NAME && type_params != 0 && type_args_tc != 0) {
		var n = vec_len(type_params);
		var i = 0;
		while (i < n) {
			var ent = vec_get(type_params, i);
			if (ent != 0) {
				if (slice_eq_parts(ptr64[t + 8], ptr64[t + 16], ptr64[ent + 0], ptr64[ent + 8]) == 1) {
					var ty = vec_get(type_args_tc, i);
					var np = tc_builtin_name_ptr_for_tctype(ty);
					alias rdx : nl;
					if (np != 0 && nl != 0) {
						ptr64[out + 8] = np;
						ptr64[out + 16] = nl;
					}
					return out;
				}
			}
			i = i + 1;
		}
	}
	if (ptr64[t + 0] == AstTypeKind.PTR) {
		ptr64[out + 8] = tc_clone_type_subst(ptr64[t + 8], type_params, type_args_tc);
		ptr64[out + 16] = ptr64[t + 16];
	}
	if (ptr64[t + 0] == AstTypeKind.SLICE) {
		ptr64[out + 8] = tc_clone_type_subst(ptr64[t + 8], type_params, type_args_tc);
		ptr64[out + 16] = 0;
	}
	if (ptr64[t + 0] == AstTypeKind.ARRAY) {
		ptr64[out + 8] = tc_clone_type_subst(ptr64[t + 8], type_params, type_args_tc);
		ptr64[out + 16] = ptr64[t + 16];
	}
	if (ptr64[t + 0] == AstTypeKind.GENERIC) {
		ptr64[out + 8] = tc_clone_type_subst(ptr64[t + 8], type_params, type_args_tc);
		var args0 = ptr64[t + 48];
		if (args0 != 0) {
			var out_args = vec_new(4);
			if (out_args != 0) {
				var n0 = vec_len(args0);
				var i0 = 0;
				while (i0 < n0) {
					var raw0 = vec_get(args0, i0);
					var tag0 = raw0 & 1;
					if (tag0 == 0) {
						vec_push(out_args, tc_clone_type_subst(raw0, type_params, type_args_tc));
					} else {
						// Value arg: keep tagged AstExpr* as-is (no type substitution for now).
						vec_push(out_args, raw0);
					}
					i0 = i0 + 1;
				}
			}
			ptr64[out + 48] = out_args;
		}
	}
	if (ptr64[t + 0] == AstTypeKind.TUPLE) {
		var elems = ptr64[t + 48];
		if (elems != 0) {
			var out_elems = vec_new(2);
			if (out_elems != 0) {
				var n1 = vec_len(elems);
				var i1 = 0;
				while (i1 < n1) {
					vec_push(out_elems, tc_clone_type_subst(vec_get(elems, i1), type_params, type_args_tc));
					i1 = i1 + 1;
				}
				ptr64[out + 48] = out_elems;
			}
		}
	}
	return out;
}

func tc_clone_expr_subst(e, type_params, type_args_tc) {
	if (e == 0) { return 0; }
	var out = heap_alloc(80);
	if (out == 0) { return 0; }
	var k = ptr64[e + 0];
	ptr64[out + 0] = k;
	ptr64[out + 8] = ptr64[e + 8];
	ptr64[out + 40] = ptr64[e + 40];
	ptr64[out + 48] = ptr64[e + 48];
	ptr64[out + 56] = ptr64[e + 56];
	ptr64[out + 64] = ptr64[e + 64];
	ptr64[out + 72] = ptr64[e + 72];

	if (k == AstExprKind.UNARY) {
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = 0;
		ptr64[out + 32] = 0;
		return out;
	}
	if (k == AstExprKind.BINARY) {
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = tc_clone_expr_subst(ptr64[e + 24], type_params, type_args_tc);
		ptr64[out + 32] = 0;
		return out;
	}
	if (k == AstExprKind.CALL) {
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[e + 16], type_params, type_args_tc);
		// Clone type args vector
		var ta = ptr64[e + 24];
		if (ta != 0) {
			var tavec = vec_new(2);
			if (tavec != 0) {
				var tn = vec_len(ta);
				var ti = 0;
				while (ti < tn) {
					var t0 = vec_get(ta, ti);
					vec_push(tavec, tc_clone_type_subst(t0, type_params, type_args_tc));
					ti = ti + 1;
				}
				ptr64[out + 24] = tavec;
			} else { ptr64[out + 24] = 0; }
		} else { ptr64[out + 24] = 0; }
		var args = ptr64[e + 32];
		if (args != 0) {
			var out_args = vec_new(4);
			if (out_args != 0) {
				var n = vec_len(args);
				var i = 0;
				while (i < n) {
					vec_push(out_args, tc_clone_expr_subst(vec_get(args, i), type_params, type_args_tc));
					i = i + 1;
				}
				ptr64[out + 32] = out_args;
			} else { ptr64[out + 32] = 0; }
		} else { ptr64[out + 32] = 0; }
		return out;
	}
	if (k == AstExprKind.CAST) {
		ptr64[out + 16] = tc_clone_type_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = tc_clone_expr_subst(ptr64[e + 24], type_params, type_args_tc);
		ptr64[out + 32] = 0;
		return out;
	}
	if (k == AstExprKind.INDEX) {
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = tc_clone_expr_subst(ptr64[e + 24], type_params, type_args_tc);
		ptr64[out + 32] = 0;
		return out;
	}
	if (k == AstExprKind.BRACE_INIT) {
		var elems = ptr64[e + 32];
		if (elems != 0) {
			var out_elems = vec_new(4);
			if (out_elems != 0) {
				var n2 = vec_len(elems);
				var i2 = 0;
				while (i2 < n2) {
					vec_push(out_elems, tc_clone_expr_subst(vec_get(elems, i2), type_params, type_args_tc));
					i2 = i2 + 1;
				}
				ptr64[out + 32] = out_elems;
			} else { ptr64[out + 32] = 0; }
		} else { ptr64[out + 32] = 0; }
		// Preserve typed init AstType (a) and any op metadata.
		var t0 = ptr64[e + 16];
		if (t0 != 0) { ptr64[out + 16] = tc_clone_type_subst(t0, type_params, type_args_tc); }
		else { ptr64[out + 16] = 0; }
		ptr64[out + 24] = 0;
		ptr64[out + 8] = ptr64[e + 8];
		return out;
	}
	if (k == AstExprKind.OFFSETOF) {
		ptr64[out + 16] = tc_clone_type_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = ptr64[e + 24];
		ptr64[out + 32] = ptr64[e + 32];
		return out;
	}
	if (k == AstExprKind.FIELD) {
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[e + 16], type_params, type_args_tc);
		ptr64[out + 24] = ptr64[e + 24];
		ptr64[out + 32] = ptr64[e + 32];
		return out;
	}
	// IDENT/INT/STRING/CHAR/NULL and fallback
	ptr64[out + 16] = ptr64[e + 16];
	ptr64[out + 24] = ptr64[e + 24];
	ptr64[out + 32] = ptr64[e + 32];
	return out;
}

func tc_clone_stmt_subst(s, type_params, type_args_tc) {
	if (s == 0) { return 0; }
	var out = heap_alloc(96);
	if (out == 0) { return 0; }
	var k = ptr64[s + 0];
	ptr64[out + 0] = k;
	ptr64[out + 8] = ptr64[s + 8];
	ptr64[out + 16] = ptr64[s + 16];
	ptr64[out + 24] = ptr64[s + 24];
	ptr64[out + 32] = ptr64[s + 32];
	ptr64[out + 40] = ptr64[s + 40];
	ptr64[out + 64] = ptr64[s + 64];
	ptr64[out + 72] = ptr64[s + 72];
	ptr64[out + 80] = ptr64[s + 80];
	ptr64[out + 88] = ptr64[s + 88];

	if (k == AstStmtKind.BLOCK) {
		var stmts = ptr64[s + 8];
		if (stmts != 0) {
			var out_stmts = vec_new(8);
			if (out_stmts != 0) {
				var n = vec_len(stmts);
				var i = 0;
				while (i < n) {
					vec_push(out_stmts, tc_clone_stmt_subst(vec_get(stmts, i), type_params, type_args_tc));
					i = i + 1;
				}
				ptr64[out + 8] = out_stmts;
			}
		}
		// zero unused
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.VAR) {
		ptr64[out + 48] = tc_clone_type_subst(ptr64[s + 48], type_params, type_args_tc);
		ptr64[out + 56] = tc_clone_expr_subst(ptr64[s + 56], type_params, type_args_tc);
		return out;
	}
	if (k == AstStmtKind.EXPR) {
		ptr64[out + 48] = 0;
		ptr64[out + 56] = tc_clone_expr_subst(ptr64[s + 56], type_params, type_args_tc);
		return out;
	}
	if (k == AstStmtKind.RETURN) {
		var es = ptr64[s + 8];
		if (es != 0) {
			var out_es = vec_new(2);
			if (out_es != 0) {
				var n0 = vec_len(es);
				var i0 = 0;
				while (i0 < n0) {
					vec_push(out_es, tc_clone_expr_subst(vec_get(es, i0), type_params, type_args_tc));
					i0 = i0 + 1;
				}
				ptr64[out + 8] = out_es;
			}
			ptr64[out + 48] = 0;
			ptr64[out + 56] = 0;
			return out;
		}
		ptr64[out + 48] = 0;
		ptr64[out + 56] = tc_clone_expr_subst(ptr64[s + 56], type_params, type_args_tc);
		return out;
	}
	if (k == AstStmtKind.DESTRUCT) {
		ptr64[out + 48] = 0;
		ptr64[out + 56] = tc_clone_expr_subst(ptr64[s + 56], type_params, type_args_tc);
		return out;
	}
	if (k == AstStmtKind.IF) {
		ptr64[out + 8] = tc_clone_expr_subst(ptr64[s + 8], type_params, type_args_tc);
		ptr64[out + 16] = tc_clone_stmt_subst(ptr64[s + 16], type_params, type_args_tc);
		ptr64[out + 24] = tc_clone_stmt_subst(ptr64[s + 24], type_params, type_args_tc);
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.WHILE) {
		ptr64[out + 8] = tc_clone_expr_subst(ptr64[s + 8], type_params, type_args_tc);
		ptr64[out + 16] = tc_clone_stmt_subst(ptr64[s + 16], type_params, type_args_tc);
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.FOREACH) {
		ptr64[out + 8] = ptr64[s + 8];
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[s + 16], type_params, type_args_tc);
		ptr64[out + 24] = tc_clone_stmt_subst(ptr64[s + 24], type_params, type_args_tc);
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.SWITCH) {
		ptr64[out + 8] = tc_clone_expr_subst(ptr64[s + 8], type_params, type_args_tc);
		var cases = ptr64[s + 16];
		if (cases != 0) {
			var out_cases = vec_new(4);
			if (out_cases != 0) {
				var n = vec_len(cases);
				var i = 0;
				while (i < n) {
					var c = vec_get(cases, i);
					if (c != 0) {
						var c2 = heap_alloc(40);
						if (c2 != 0) {
							ptr64[c2 + 0] = tc_clone_expr_subst(ptr64[c + 0], type_params, type_args_tc);
							ptr64[c2 + 8] = tc_clone_stmt_subst(ptr64[c + 8], type_params, type_args_tc);
							ptr64[c2 + 16] = ptr64[c + 16];
							ptr64[c2 + 24] = ptr64[c + 24];
							ptr64[c2 + 32] = ptr64[c + 32];
							vec_push(out_cases, c2);
						}
					}
					i = i + 1;
				}
				ptr64[out + 16] = out_cases;
			}
		}
		ptr64[out + 24] = tc_clone_stmt_subst(ptr64[s + 24], type_params, type_args_tc);
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.DEFER) {
		// st+8 = inner statement
		ptr64[out + 8] = tc_clone_stmt_subst(ptr64[s + 8], type_params, type_args_tc);
		ptr64[out + 16] = 0;
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	if (k == AstStmtKind.WIPE) {
		ptr64[out + 8] = tc_clone_expr_subst(ptr64[s + 8], type_params, type_args_tc);
		ptr64[out + 16] = tc_clone_expr_subst(ptr64[s + 16], type_params, type_args_tc);
		ptr64[out + 56] = tc_clone_expr_subst(ptr64[s + 56], type_params, type_args_tc);
		ptr64[out + 48] = 0;
		return out;
	}
	if (k == AstStmtKind.PRINT || k == AstStmtKind.PRINTLN) {
		// a = Vec* of AstExpr* args
		var old_args = ptr64[s + 8];
		var new_args = vec_new(4);
		if (new_args != 0 && old_args != 0) {
			var n = vec_len(old_args);
			var i = 0;
			while (i < n) {
				var old_e = vec_get(old_args, i);
				vec_push(new_args, tc_clone_expr_subst(old_e, type_params, type_args_tc));
				i = i + 1;
			}
		}
		ptr64[out + 8] = new_args;
		ptr64[out + 48] = 0;
		ptr64[out + 56] = 0;
		return out;
	}
	// default
	ptr64[out + 48] = ptr64[s + 48];
	ptr64[out + 56] = ptr64[s + 56];
	return out;
}

func tc_instantiate_generic_func_decl(templ, type_args_tc, type_argc, new_name_ptr, new_name_len) {
	if (tc_cur_ast_prog == 0 || templ == 0) { return 0; }
	var type_params = ptr64[templ + 96];
	var params0 = ptr64[templ + 24];
	var params2 = 0;
	if (params0 != 0) {
		params2 = vec_new(4);
		if (params2 != 0) {
			var pn = vec_len(params0);
			var pi = 0;
			while (pi < pn) {
				// Capture values across calls (v2 bootstrap may clobber args/register locals).
				var ps0 = vec_get(params0, pi);
				var tp2 = type_params;
				var ta2 = type_args_tc;
				var ps2 = tc_clone_stmt_subst(ps0, tp2, ta2);
				vec_push(params2, ps2);
				pi = pi + 1;
			}
		}
	}
	var ret2 = tc_clone_type_subst(ptr64[templ + 32], type_params, type_args_tc);
	var body2 = tc_clone_stmt_subst(ptr64[templ + 40], type_params, type_args_tc);

	var d = heap_alloc(104);
	if (d == 0) { return 0; }
	ptr64[d + 0] = AstDeclKind.FUNC;
	ptr64[d + 8] = new_name_ptr;
	ptr64[d + 16] = new_name_len;
	ptr64[d + 24] = params2;
	ptr64[d + 32] = ret2;
	ptr64[d + 40] = body2;
	ptr64[d + 48] = ptr64[templ + 48];
	ptr64[d + 56] = ptr64[templ + 56];
	ptr64[d + 64] = ptr64[templ + 64];
	ptr64[d + 72] = ptr64[templ + 72];
	var flags0 = ptr64[templ + 80];
	var tflag1 = flags0 & TC_DECL_FLAG_GENERIC_TEMPLATE;
	if (tflag1 != 0) { flags0 = flags0 - TC_DECL_FLAG_GENERIC_TEMPLATE; }
	ptr64[d + 80] = flags0;
	ptr64[d + 88] = 0;
	ptr64[d + 96] = 0;
	vec_push(ptr64[tc_cur_ast_prog + 0], d);
	return d;
}

func tc_try_monomorphize_call(env, call_expr) {
	if (call_expr == 0) { return 0; }
	if (tc_cur_ast_prog == 0) { return 0; }
	var callee = ptr64[call_expr + 16];
	if (callee == 0 || ptr64[callee + 0] != AstExprKind.IDENT) { return 0; }
	var name_ptr = ptr64[callee + 40];
	var name_len = ptr64[callee + 48];
	var templ = tc_find_generic_func_template_decl(tc_cur_ast_prog, name_ptr, name_len);
	if (templ == 0) { return 0; }
	var type_params = ptr64[templ + 96];
	var tp_n = 0;
	if (type_params != 0) { tp_n = vec_len(type_params); }
	if (tp_n == 0) { return 0; }

	// Determine concrete type args.
	var explicit_ta = ptr64[call_expr + 24];
	var type_args_tc = 0;
	if (explicit_ta != 0) {
		if (vec_len(explicit_ta) != tp_n) {
			tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "generic call: wrong number of type args");
			return 0;
		}
		type_args_tc = vec_new(tp_n);
		if (type_args_tc == 0) { return 0; }
		var i = 0;
		while (i < tp_n) {
			vec_push(type_args_tc, tc_type_from_asttype(vec_get(explicit_ta, i)));
			i = i + 1;
		}
	} else {
		// Infer from args: only supports param types that are a direct type param name.
		type_args_tc = vec_new(tp_n);
		if (type_args_tc == 0) { return 0; }
		var zi = 0;
		while (zi < tp_n) { vec_push(type_args_tc, TC_TY_INVALID); zi = zi + 1; }
		var params = ptr64[templ + 24];
		var args = ptr64[call_expr + 32];
		var pn = 0;
		var an = 0;
		if (params != 0) { pn = vec_len(params); }
		if (args != 0) { an = vec_len(args); }
		var nmin = pn;
		if (an < nmin) { nmin = an; }
		var pi = 0;
		while (pi < nmin) {
			var ps = vec_get(params, pi);
			var arg_e = vec_get(args, pi);
			var pty_ast = 0;
			if (ps != 0) { pty_ast = ptr64[ps + 48]; }
			if (pty_ast != 0 && ptr64[pty_ast + 0] == AstTypeKind.NAME) {
				var pnm_ptr = ptr64[pty_ast + 8];
				var pnm_len = ptr64[pty_ast + 16];
				var tpi = 0;
				while (tpi < tp_n) {
					var ent = vec_get(type_params, tpi);
					if (ent != 0) {
						if (slice_eq_parts(pnm_ptr, pnm_len, ptr64[ent + 0], ptr64[ent + 8]) == 1) {
							var aty = tc_expr(env, arg_e);
							var cur = vec_get(type_args_tc, tpi);
							if (cur == TC_TY_INVALID) {
								// Replace by rebuilding vec (no vec_set).
								var tmp = vec_new(tp_n);
								if (tmp == 0) { return 0; }
								var j = 0;
								while (j < tp_n) {
									if (j == tpi) { vec_push(tmp, aty); }
									else { vec_push(tmp, vec_get(type_args_tc, j)); }
									j = j + 1;
								}
								type_args_tc = tmp;
							} else {
								if (tc_type_eq(cur, aty) == 0) {
									tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "generic call: cannot infer consistent type args");
								}
							}
						}
					}
					tpi = tpi + 1;
				}
			} else {
				// Not a direct type parameter: still typecheck argument for errors.
				tc_expr(env, arg_e);
			}
			pi = pi + 1;
		}
		var k = 0;
		while (k < tp_n) {
			if (vec_get(type_args_tc, k) == TC_TY_INVALID) {
				tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "generic call: could not infer type args");
				return 0;
			}
			k = k + 1;
		}
	}

	var new_ptr = tc_mangle_generic_inst_name(name_ptr, name_len, type_args_tc, tp_n);
	alias rdx : new_len_reg;
	var new_len = new_len_reg;
	if (new_ptr == 0 || new_len == 0) {
		tc_err_at(ptr64[call_expr + 64], ptr64[call_expr + 72], "generic call: unsupported type args");
		return 0;
	}
	if (tc_ast_prog_has_func_name(tc_cur_ast_prog, new_ptr, new_len) == 0) {
		tc_instantiate_generic_func_decl(templ, type_args_tc, tp_n, new_ptr, new_len);
	}
	// Rewrite callee identifier to instantiated name.
	ptr64[callee + 40] = new_ptr;
	ptr64[callee + 48] = new_len;
	// Clear stored type args on call.
	ptr64[call_expr + 24] = 0;
	return 0;
}

func tc_find_func_decl_in_prog(prog, name_ptr, name_len) {
	if (prog == 0) { return 0; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			if (slice_eq_parts(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) {
				return d;
			}
		}
		i = i + 1;
	}
	return 0;
}

func tc_expr(env, e) {
	if (e == 0) { return TC_TY_INVALID; }
	var k = ptr64[e + 0];

	if (k == AstExprKind.INT) {
		return TC_TY_U64;
	}
	// Phase 6.6: floating-point literal (default f64)
	if (k == AstExprKind.FLOAT) {
		return TC_TY_F64;
	}
	if (k == AstExprKind.STRING) {
		// Phase 2.3: treat string literals as []u8 (ptr,len) conceptually.
		return TC_TY_SLICE_BASE + TC_TY_U8;
	}
	if (k == AstExprKind.CHAR) {
		return TC_TY_CHAR;
	}
	if (k == AstExprKind.NULL) {
		return TC_TY_NULL;
	}
	if (k == AstExprKind.IDENT) {
		var name_ptr = ptr64[e + 40];
		var name_len = ptr64[e + 48];
		// If this identifier refers to a global const with a simple constant initializer,
		// mark it as an immediate for codegen (only for rvalues).
		//
		// NOTE(v2): 아래 경로에서 여러 함수 호출이 발생하므로, 최종 타입(tc_env_get)은
		// 모든 호출 이후에 다시 로드해 반환한다(레지스터/로컬 클로버 회피).
		if (tc_cur_ast_prog != 0) {
			var idx0 = tc_env_find_index(env, name_ptr, name_len);
			alias rdx : ok_idx;
			if (ok_idx != 0) {
				if (idx0 < tc_env_global_len) {
					var cd0 = tc_find_const_decl_in_prog(tc_cur_ast_prog, name_ptr, name_len);
					if (cd0 != 0) {
						var init0 = ptr64[cd0 + 32];
						var cv0 = tc_const_eval_u64_expr_mvp(init0);
						alias rdx : ok_cv;
						if (ok_cv != 0) {
							ptr64[e + 8] = cv0;
							ptr64[e + 32] = (127 << 56);
						}
					}
				}
			}
		}
		var ty = tc_env_get(env, name_ptr, name_len);
		if (tc_debug_ident != 0) {
			if (name_len == 1 && name_ptr != 0 && ptr8[name_ptr] == 115) {
				print_str("DEBUG ident s: ty=");
				print_u64(ty);
				print_str(" env_len=");
				print_u64(vec_len(env));
				print_str("\n");
			}
		}
		if (ty == TC_TY_INVALID) {
			// Phase 6.7: Check if identifier is a function name
			var func_sig = tc_func_lookup(name_ptr, name_len);
			if (func_sig != 0) {
				// Found function signature - create function pointer type
				// TcFuncSig layout: +24=param_count, +32=p0_ty, +40=p1_ty, +48=ret_ty
				var pcount = ptr64[func_sig + 24];
				var ret_ty = ptr64[func_sig + 48];
				var param_types = 0;
				if (pcount > 0) {
					param_types = vec_new(pcount);
					if (pcount >= 1) { vec_push(param_types, ptr64[func_sig + 32]); }
					if (pcount >= 2) { vec_push(param_types, ptr64[func_sig + 40]); }
					// MVP: only support up to 2 params for function pointers
				}
				var fptr_ty = tc_make_func_ptr(param_types, ret_ty);
				// Mark this expr as function reference for codegen (use extra field +32)
				ptr64[e + 32] = func_sig;  // store func_sig for codegen in extra field
				return fptr_ty;
			}
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "unknown identifier");
			return TC_TY_INVALID;
		}
		return ty;
	}
	if (k == AstExprKind.UNARY) {
		var rhs_ty = tc_expr(env, ptr64[e + 16]);
		var op = ptr64[e + 8];
		if (op == TokKind.DOLLAR) {
			// Phase 4.1: unsafe deref/load/store operand.
			// Allows nullable pointers (no implicit null check).
			if (tc_is_ptr(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'$' expects pointer");
				return TC_TY_INVALID;
			}
			var base_ty = tc_ptr_base(rhs_ty);
			var sz0 = tc_sizeof(base_ty);
			ptr64[e + 32] = sz0; // for codegen: 1 or 8 supported
			return base_ty;
		}
		if (op == TokKind.STAR) {
			if (tc_is_ptr(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "deref expects pointer");
				return TC_TY_INVALID;
			}
			if (tc_is_ptr_nullable(rhs_ty) == 1) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "cannot deref nullable pointer");
				return TC_TY_INVALID;
			}
			var base_ty = tc_ptr_base(rhs_ty);
			var sz_star = tc_sizeof(base_ty);
			ptr64[e + 32] = sz_star; // for codegen: store size for *ptr = val
			return base_ty;
		}
		if (op == TokKind.BANG) {
			if (rhs_ty != TC_TY_BOOL) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'!' expects bool");
				return TC_TY_INVALID;
			}
			return TC_TY_BOOL;
		}
		if (op == TokKind.AMP) {
			var rhs = ptr64[e + 16];
			if (rhs == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'&' expects lvalue");
				return TC_TY_INVALID;
			}
			var rk = ptr64[rhs + 0];
			if (rk != AstExprKind.IDENT && rk != AstExprKind.FIELD) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'&' expects lvalue");
				return TC_TY_INVALID;
			}
			var pty = tc_make_ptr(rhs_ty, 0);
			if (pty == TC_TY_INVALID) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "cannot take address of this type");
				return TC_TY_INVALID;
			}
			return pty;
		}
		if (op == TokKind.PLUS || op == TokKind.MINUS || op == TokKind.TILDE) {
			if (tc_is_int(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "unary op expects integer");
				return TC_TY_INVALID;
			}
			return rhs_ty;
		}
		// Postfix ++ / -- (Phase 6.1)
		if (op == TokKind.PLUSPLUS || op == TokKind.MINUSMINUS) {
			var rhs = ptr64[e + 16];
			if (rhs == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "increment/decrement expects lvalue");
				return TC_TY_INVALID;
			}
			var rk = ptr64[rhs + 0];
			if (rk != AstExprKind.IDENT && rk != AstExprKind.FIELD) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "increment/decrement expects lvalue");
				return TC_TY_INVALID;
			}
			if (tc_is_int(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "increment/decrement expects integer");
				return TC_TY_INVALID;
			}
			return rhs_ty;
		}
		return rhs_ty;
	}
	if (k == AstExprKind.BINARY) {
		var op = ptr64[e + 8];

		// Assignment: lhs must be an identifier, field, array index, or $ptr.
		if (op == TokKind.EQ) {
			var lhs = ptr64[e + 16];
			var rhs = ptr64[e + 24];
			if (lhs == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "assignment lhs must be identifier or field");
				return TC_TY_INVALID;
			}
			var lk = ptr64[lhs + 0];
			if (lk != AstExprKind.IDENT) {
				if (lk != AstExprKind.FIELD) {
					// Allow array indexing: arr[i] = val
					if (lk != AstExprKind.INDEX) {
						// Phase 4.1: allow $ptr = v and *ptr = v stores.
						if (lk != AstExprKind.UNARY || (ptr64[lhs + 8] != TokKind.DOLLAR && ptr64[lhs + 8] != TokKind.STAR)) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "assignment lhs must be identifier, field, index, $ptr, or *ptr");
							return TC_TY_INVALID;
						}
					}
				}
			}
			var lhs_ty0 = tc_expr(env, lhs);
			var rhs_ty0 = tc_expr_with_expected(env, rhs, lhs_ty0);
			if (lhs_ty0 != TC_TY_INVALID && rhs_ty0 != TC_TY_INVALID && tc_type_eq(lhs_ty0, rhs_ty0) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "assignment type mismatch");
				return TC_TY_INVALID;
			}
			return lhs_ty0;
		}

		// Compound assignment (Phase 6.1): desugar to binary + assign.
		// x += y => x = x + y
		var is_compound = 0;
		var base_op = 0;
		if (op == TokKind.PLUSEQ) { is_compound = 1; base_op = TokKind.PLUS; }
		else if (op == TokKind.MINUSEQ) { is_compound = 1; base_op = TokKind.MINUS; }
		else if (op == TokKind.STAREQ) { is_compound = 1; base_op = TokKind.STAR; }
		else if (op == TokKind.SLASHEQ) { is_compound = 1; base_op = TokKind.SLASH; }
		else if (op == TokKind.PERCENTEQ) { is_compound = 1; base_op = TokKind.PERCENT; }
		else if (op == TokKind.AMPEQ) { is_compound = 1; base_op = TokKind.AMP; }
		else if (op == TokKind.PIPEEQ) { is_compound = 1; base_op = TokKind.PIPE; }
		else if (op == TokKind.CARETEQ) { is_compound = 1; base_op = TokKind.CARET; }
		else if (op == TokKind.LSHIFTEQ) { is_compound = 1; base_op = TokKind.LSHIFT; }
		else if (op == TokKind.RSHIFTEQ) { is_compound = 1; base_op = TokKind.RSHIFT; }

		if (is_compound == 1) {
			var lhs = ptr64[e + 16];
			var rhs = ptr64[e + 24];
			if (lhs == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "compound assignment lhs must be identifier or field");
				return TC_TY_INVALID;
			}
			var lk = ptr64[lhs + 0];
			if (lk != AstExprKind.IDENT && lk != AstExprKind.FIELD) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "compound assignment lhs must be identifier or field");
				return TC_TY_INVALID;
			}
			var lhs_ty0 = tc_expr(env, lhs);
			var rhs_ty0 = tc_expr_with_expected(env, rhs, lhs_ty0);
			// Check that the base operation is valid.
			// Phase 6.6: allow float for +=, -=, *=, /=
			var is_float_ok_compound = 0;
			if (base_op == TokKind.PLUS || base_op == TokKind.MINUS || base_op == TokKind.STAR || base_op == TokKind.SLASH) {
				is_float_ok_compound = 1;
			}
			if (tc_is_int(lhs_ty0) == 0 && (tc_is_float(lhs_ty0) == 0 || is_float_ok_compound == 0)) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "compound assignment expects numeric lhs");
				return TC_TY_INVALID;
			}
			if (tc_is_int(rhs_ty0) == 0 && tc_is_float(rhs_ty0) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "compound assignment expects numeric rhs");
				return TC_TY_INVALID;
			}
			if (lhs_ty0 != rhs_ty0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "compound assignment type mismatch");
				return TC_TY_INVALID;
			}
			// Store original op in extra for codegen to identify compound assignment.
			ptr64[e + 32] = op;
			// Store base_op in expr.op for codegen.
			ptr64[e + 8] = base_op;
			return lhs_ty0;
		}

		var lhs = ptr64[e + 16];
		var rhs = ptr64[e + 24];
		var lhs_ty = tc_expr(env, lhs);
		var rhs_ty = tc_expr_with_expected(env, rhs, lhs_ty);
		var op = ptr64[e + 8];

		// If lhs is untyped null, try to type it from rhs for ==/!=.
		if (lhs_ty == TC_TY_NULL) {
			if (op == TokKind.EQEQ || op == TokKind.NEQ) {
				var rhs_ty2 = tc_expr(env, rhs);
				if (tc_is_ptr_nullable(rhs_ty2) == 1) {
					// treat as (rhs == null)
					return TC_TY_BOOL;
				}
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "null compare requires nullable pointer");
				return TC_TY_INVALID;
			}
		}

		// Short-circuit logical ops.
		if (op == TokKind.ANDAND || op == TokKind.OROR) {
			if (lhs_ty != TC_TY_BOOL || rhs_ty != TC_TY_BOOL) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "logical op expects bool");
				return TC_TY_INVALID;
			}
			return TC_TY_BOOL;
		}

		// Comparisons produce bool; require identical operand types.
		var is_cmp = 0;
		if (op == TokKind.EQEQ) { is_cmp = 1; }
		else if (op == TokKind.NEQ) { is_cmp = 1; }
		else if (op == TokKind.EQEQEQ) { is_cmp = 1; }
		else if (op == TokKind.NEQEQ) { is_cmp = 1; }
		else if (op == TokKind.LT) { is_cmp = 1; }
		else if (op == TokKind.LTE) { is_cmp = 1; }
		else if (op == TokKind.GT) { is_cmp = 1; }
		else if (op == TokKind.GTE) { is_cmp = 1; }
		if (is_cmp == 1) {
			if (lhs_ty == TC_TY_INVALID || rhs_ty == TC_TY_INVALID) { return TC_TY_INVALID; }
			// Special-case comparisons against null on RHS: lhs must be nullable pointer.
			if (rhs_ty == TC_TY_NULL) {
				if (op == TokKind.EQEQ || op == TokKind.NEQ) {
					if (tc_is_ptr_nullable(lhs_ty) == 1) { return TC_TY_BOOL; }
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "null compare requires nullable pointer");
					return TC_TY_INVALID;
				}
			}
			if (lhs_ty != rhs_ty) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "comparison operands must match");
				return TC_TY_INVALID;
			}
			// Phase 4.6: constant-time eq operators.
			if (op == TokKind.EQEQEQ || op == TokKind.NEQEQ) {
				if (tc_is_int(lhs_ty) == 1) { return TC_TY_BOOL; }
				if (tc_is_slice(lhs_ty) == 1) {
					if (tc_slice_elem(lhs_ty) != TC_TY_U8) {
						tc_err_at(ptr64[e + 64], ptr64[e + 72], "constant-time eq expects []u8");
						return TC_TY_INVALID;
					}
					return TC_TY_BOOL;
				}
				if (tc_is_array(lhs_ty) == 1) {
					var elem_ty = tc_array_elem(lhs_ty);
					if (elem_ty != TC_TY_U8) {
						tc_err_at(ptr64[e + 64], ptr64[e + 72], "constant-time eq expects [N]u8");
						return TC_TY_INVALID;
					}
					return TC_TY_BOOL;
				}
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "constant-time eq expects integer or byte sequence");
				return TC_TY_INVALID;
			}
			return TC_TY_BOOL;
		}

		// Integer ops: require identical integer types.
		var is_int_op = 0;
		if (op == TokKind.PLUS) { is_int_op = 1; }
		else if (op == TokKind.MINUS) { is_int_op = 1; }
		else if (op == TokKind.STAR) { is_int_op = 1; }
		else if (op == TokKind.SLASH) { is_int_op = 1; }
		else if (op == TokKind.PERCENT) { is_int_op = 1; }
		else if (op == TokKind.AMP) { is_int_op = 1; }
		else if (op == TokKind.PIPE) { is_int_op = 1; }
		else if (op == TokKind.CARET) { is_int_op = 1; }
		else if (op == TokKind.LSHIFT) { is_int_op = 1; }
		else if (op == TokKind.RSHIFT) { is_int_op = 1; }
		else if (op == TokKind.ROTL) { is_int_op = 1; }
		else if (op == TokKind.ROTR) { is_int_op = 1; }
		// Pointer arithmetic (Phase 2.2): byte-wise.
		// - ptr +/- int -> ptr
		// - ptr - ptr -> u64
		if (op == TokKind.PLUS || op == TokKind.MINUS) {
			if (tc_is_ptr(lhs_ty) == 1) {
				if (tc_is_ptr_nullable(lhs_ty) == 1) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "pointer arithmetic requires non-null pointer");
					return TC_TY_INVALID;
				}
				if (op == TokKind.PLUS) {
					if (tc_is_int(rhs_ty) == 1) { return lhs_ty; }
				}
				if (op == TokKind.MINUS) {
					if (tc_is_int(rhs_ty) == 1) { return lhs_ty; }
					if (tc_is_ptr(rhs_ty) == 1) {
						if (tc_is_ptr_nullable(rhs_ty) == 1) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "pointer arithmetic requires non-null pointer");
							return TC_TY_INVALID;
						}
						if (lhs_ty != rhs_ty) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "pointer operands must match");
							return TC_TY_INVALID;
						}
						return TC_TY_U64;
					}
				}
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "pointer arithmetic expects integer offset");
				return TC_TY_INVALID;
			}
		}
		if (is_int_op == 1) {
			// Phase 6.6: floating-point arithmetic for +, -, *, /
			var is_float_arith = 0;
			if (op == TokKind.PLUS || op == TokKind.MINUS || op == TokKind.STAR || op == TokKind.SLASH) {
				is_float_arith = 1;
			}
			if (tc_is_float(lhs_ty) == 1 && tc_is_float(rhs_ty) == 1) {
				if (is_float_arith == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "float only supports +, -, *, /");
					return TC_TY_INVALID;
				}
				if (tc_type_eq(lhs_ty, rhs_ty) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "float operands must match");
					return TC_TY_INVALID;
				}
				return lhs_ty;
			}
			if (tc_is_int(lhs_ty) == 0 || tc_is_int(rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "integer op expects integer operands");
				return TC_TY_INVALID;
			}
			if (tc_type_eq(lhs_ty, rhs_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "integer operands must match");
				return TC_TY_INVALID;
			}
			return lhs_ty;
		}

		// Fallback: keep going.
		return lhs_ty;
	}
	if (k == AstExprKind.CALL) {
		// Phase 3.7: method call transformation - s.add(5) -> S_add(s, 5)
		tc_try_method_call(env, e);
		// Phase 5.2: normalize named args before monomorphization and typing.
		tc_normalize_named_call_args(env, e);
		// Phase 5.1: call-site monomorphization for generic templates.
		tc_try_monomorphize_call(env, e);
		// Builtin: unwrap_ptr(p: *T?) -> *T
		var callee = ptr64[e + 16];
		var args = ptr64[e + 32];
		if (callee != 0 && ptr64[callee + 0] == AstExprKind.IDENT) {
			var name_ptr = ptr64[callee + 40];
			var name_len = ptr64[callee + 48];
			if (slice_eq_parts(name_ptr, name_len, "unwrap_ptr", 10) == 1) {
				var n = 0;
				if (args != 0) { n = vec_len(args); }
				if (n != 1) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "unwrap_ptr expects 1 argument");
					return TC_TY_INVALID;
				}
				var arg0 = vec_get(args, 0);
				var arg_ty = tc_expr(env, arg0);
				if (tc_is_ptr_nullable(arg_ty) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "unwrap_ptr expects nullable pointer");
					return TC_TY_INVALID;
				}
				return TC_TY_PTR_BASE + tc_ptr_base(arg_ty);
			}
			if (slice_eq_parts(name_ptr, name_len, "slice_from_ptr_len", 18) == 1) {
				var n = 0;
				if (args != 0) { n = vec_len(args); }
				if (n != 2) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "slice_from_ptr_len expects 2 arguments");
					return TC_TY_INVALID;
				}
				var a0 = vec_get(args, 0);
				var a1 = vec_get(args, 1);
				var pty = tc_expr(env, a0);
				var lty = tc_expr_with_expected(env, a1, TC_TY_U64);
				if (tc_is_ptr(pty) == 0 || tc_is_ptr_nullable(pty) == 1) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "slice_from_ptr_len expects non-null pointer");
					return TC_TY_INVALID;
				}
				if (lty != TC_TY_U64) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "slice_from_ptr_len expects u64 length");
					return TC_TY_INVALID;
				}
				var elem = tc_ptr_base(pty);
				var sty = tc_make_slice(elem);
				if (sty == TC_TY_INVALID) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "slice_from_ptr_len unsupported element type");
					return TC_TY_INVALID;
				}
				return sty;
			}
		}

		// Phase 5.1 MVP: type simple calls to known functions in the current program.
		if (callee != 0 && ptr64[callee + 0] == AstExprKind.IDENT && tc_cur_ast_prog != 0) {
			var fn_name_ptr = ptr64[callee + 40];
			var fn_name_len = ptr64[callee + 48];
			var fd = tc_find_func_decl_in_prog(tc_cur_ast_prog, fn_name_ptr, fn_name_len);
			if (fd != 0) {
				var params = ptr64[fd + 24];
				var pn = 0;
				var an = 0;
				if (params != 0) { pn = vec_len(params); }
				if (args != 0) { an = vec_len(args); }
				var i2 = 0;
				var nmin = an;
				if (pn < nmin) { nmin = pn; }
				while (i2 < nmin) {
					var a0 = vec_get(args, i2);
					var ps0 = vec_get(params, i2);
					var pty = TC_TY_INVALID;
					if (ps0 != 0 && ptr64[ps0 + 48] != 0) { pty = tc_type_from_asttype(ptr64[ps0 + 48]); }
					if (pty != TC_TY_INVALID) { tc_expr_with_expected(env, a0, pty); }
					else { tc_expr(env, a0); }
					i2 = i2 + 1;
				}
				while (i2 < an) {
					tc_expr(env, vec_get(args, i2));
					i2 = i2 + 1;
				}
				var ret_ast = ptr64[fd + 32];
				if (ret_ast != 0) { return tc_type_from_asttype(ret_ast); }
				return 0;
			}
			// Phase 6.7: Check if callee is a function pointer variable
			var fptr_ty = tc_env_get(env, fn_name_ptr, fn_name_len);
			if (tc_is_func_ptr(fptr_ty) == 1) {
				// Capture e, fptr_ty, args before calling other functions (caller-save registers may be clobbered)
				var e_saved = e;
				var fptr_ty_saved = fptr_ty;
				var args_saved = args;
				
				// Type check arguments against function pointer param types
				var fptr_params = tc_func_ptr_param_types(fptr_ty_saved);
				var pn = 0;
				var an = 0;
				if (fptr_params != 0) { pn = vec_len(fptr_params); }
				if (args_saved != 0) { an = vec_len(args_saved); }
				if (an != pn) {
					tc_err_at(ptr64[e_saved + 64], ptr64[e_saved + 72], "func ptr call: argument count mismatch");
					return TC_TY_INVALID;
				}
				var env_saved = env;
				var i3 = 0;
				while (i3 < an) {
					var a0 = vec_get(args_saved, i3);
					var pty = vec_get(fptr_params, i3);
					if (pty != TC_TY_INVALID) { tc_expr_with_expected(env_saved, a0, pty); }
					else { tc_expr(env_saved, a0); }
					i3 = i3 + 1;
				}
				// Mark this call expr as indirect call for codegen
				ptr64[e_saved + 8] = fptr_ty_saved;  // store func ptr type for codegen
				return tc_func_ptr_ret_type(fptr_ty_saved);
			}
		}

		// Default: accept calls, return unknown.
		if (callee == 0 || ptr64[callee + 0] != AstExprKind.IDENT) {
			tc_expr(env, callee);
		}
		var i = 0;
		var n2 = 0;
		if (args != 0) { n2 = vec_len(args); }
		while (i < n2) {
			tc_expr(env, vec_get(args, i));
			i = i + 1;
		}
		return TC_TY_INVALID;
	}
	if (k == AstExprKind.INDEX) {
		var base = ptr64[e + 16];
		var idx = ptr64[e + 24];
		var base_ty = tc_expr(env, base);
		var idx_ty = tc_expr_with_expected(env, idx, TC_TY_U64);
		if (tc_is_int(idx_ty) == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "index expects integer");
			return TC_TY_INVALID;
		}
		var elem_ty = 0;
		if (tc_is_slice(base_ty) == 1) {
			elem_ty = tc_slice_elem(base_ty);
		} else if (tc_is_array(base_ty) == 1) {
			elem_ty = tc_array_elem(base_ty);
		} else {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "index expects slice or array");
			return TC_TY_INVALID;
		}
		// Store elem_sz in extra field (bits 0-7)
		var elem_sz = tc_sizeof(elem_ty);
		ptr64[e + 32] = elem_sz & 255;
		return elem_ty;
	}
	if (k == AstExprKind.BRACE_INIT) {
		// Phase 3.6: struct literal: Type{...} (a=AstType*), or array literal {..} (a=0).
		var t_ast = ptr64[e + 16];
		if (t_ast == 0) {
			// Without context, array brace-init cannot be typed.
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "brace-init requires array type context");
			return TC_TY_INVALID;
		}
		var ty = tc_type_from_asttype(t_ast);
		if (tc_is_struct(ty) == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal expects struct type");
			return TC_TY_INVALID;
		}
		var elems = ptr64[e + 32];
		var n = 0;
		if (elems != 0) { n = vec_len(elems); }
		var fields = tc_struct_fields(ty);
		var nf = 0;
		if (fields != 0) { nf = vec_len(fields); }
		var name_meta = ptr64[e + 8];
		if (name_meta != 0) {
			// Named form: Type{ a: expr, b: expr }
			if (vec_len(name_meta) != n) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: internal name/expr mismatch");
				return TC_TY_INVALID;
			}
			var used = vec_new(4);
			var metas = vec_new(4);
			if (used == 0 || metas == 0) { return TC_TY_INVALID; }
			var i = 0;
			while (i < n) {
				var rec = vec_get(name_meta, i);
				var fn_ptr = 0;
				var fn_len = 0;
				var fn_line = ptr64[e + 64];
				var fn_col = ptr64[e + 72];
				if (rec != 0) {
					fn_ptr = ptr64[rec + 0];
					fn_len = ptr64[rec + 8];
					fn_line = ptr64[rec + 16];
					fn_col = ptr64[rec + 24];
				}
				var f = tc_struct_find_field(ty, fn_ptr, fn_len);
				if (f == 0) {
					tc_err_at(fn_line, fn_col, "struct literal: unknown field");
					return TC_TY_INVALID;
				}
				// Cross-module access control.
				if (tc_modules != 0) {
					var smod = tc_struct_mod_id(ty);
					if (smod != tc_cur_mod) {
						if (tc_struct_field_is_public(f) == 0) {
							tc_err_at(fn_line, fn_col, "struct literal: field is private");
							return TC_TY_INVALID;
						}
					}
				}
				// Duplicate detection.
				var j = 0;
				while (j < vec_len(used)) {
					if (vec_get(used, j) == f) {
						tc_err_at(fn_line, fn_col, "struct literal: duplicate field");
						return TC_TY_INVALID;
					}
					j = j + 1;
				}
				vec_push(used, f);
				var fty = ptr64[f + 16];
				var et = tc_expr_with_expected(env, vec_get(elems, i), fty);
				if (tc_type_eq(et, fty) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: field type mismatch");
					return TC_TY_INVALID;
				}
				vec_push(metas, f);
				i = i + 1;
			}
			// Missing fields.
			var k2 = 0;
			while (k2 < nf) {
				var f2 = vec_get(fields, k2);
				var seen = 0;
				var j2 = 0;
				while (j2 < vec_len(used)) {
					if (vec_get(used, j2) == f2) { seen = 1; break; }
					j2 = j2 + 1;
				}
				if (seen == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: missing field");
					return TC_TY_INVALID;
				}
				k2 = k2 + 1;
			}
			// Annotate for codegen: op=Vec(field_meta*), b=struct ty.
			ptr64[e + 8] = metas;
			ptr64[e + 24] = ty;
			return ty;
		}
		// Positional form: Type{ expr0, expr1, ... }
		if (n != nf) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: field count mismatch");
			return TC_TY_INVALID;
		}
		var metas2 = vec_new(4);
		if (metas2 == 0) { return TC_TY_INVALID; }
		var i2 = 0;
		while (i2 < n) {
			var f3 = vec_get(fields, i2);
			if (f3 == 0) { return TC_TY_INVALID; }
			// Cross-module access control.
			if (tc_modules != 0) {
				var smod2 = tc_struct_mod_id(ty);
				if (smod2 != tc_cur_mod) {
					if (tc_struct_field_is_public(f3) == 0) {
						tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: field is private");
						return TC_TY_INVALID;
					}
				}
			}
			var fty2 = ptr64[f3 + 16];
			var et2 = tc_expr_with_expected(env, vec_get(elems, i2), fty2);
			if (tc_type_eq(et2, fty2) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "struct literal: field type mismatch");
				return TC_TY_INVALID;
			}
			vec_push(metas2, f3);
			i2 = i2 + 1;
		}
		ptr64[e + 8] = metas2;
		ptr64[e + 24] = ty;
		return ty;
	}
	if (k == AstExprKind.CAST) {
		var to_ty = tc_type_from_asttype(ptr64[e + 16]);
		// Evaluate inner expression; for INT literals, allow the destination type for range checking.
		tc_expr_with_expected(env, ptr64[e + 24], to_ty);
		return to_ty;
	}
	if (k == AstExprKind.OFFSETOF) {
		var ty_ast = ptr64[e + 16];
		var ty = tc_type_from_asttype(ty_ast);
		if (tc_is_struct(ty) == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "offsetof expects struct type");
			return TC_TY_INVALID;
		}
		var field_ptr = ptr64[e + 24];
		var field_len = ptr64[e + 32];
		var f = tc_struct_find_field(ty, field_ptr, field_len);
		if (f == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "offsetof: unknown field");
			return TC_TY_INVALID;
		}
		// Phase 3.2: cross-module access control.
		if (tc_modules != 0) {
			var smod = tc_struct_mod_id(ty);
			if (smod != tc_cur_mod) {
				if (tc_struct_is_public(ty) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "offsetof: struct type is private");
				}
				if (tc_struct_field_is_public(f) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "offsetof: field is private");
				}
			}
		}
		// Store computed offset into `op` for codegen.
		ptr64[e + 8] = ptr64[f + 24];
		return TC_TY_U64;
	}
	if (k == AstExprKind.FIELD) {
		// NOTE(v2): FIELD 노드는 typecheck 중 여러 번 방문될 수 있다(예: 대입 + 비교 등).
		// 그런데 typecheck는 e->extra(e+32)를 "pre-typecheck packing"에서
		// "post-typecheck extra" 포맷으로 덮어쓴다.
		// 다시 방문했을 때 이를 pre-pack으로 해석하면 via_ptr/raw/field_len이 깨져
		// codegen에서 dot 접근이 arrow처럼 처리되어 런타임 segfault가 날 수 있다.
		//
		// 따라서 extra에 size가 이미 들어있는 경우(>0) 빠르게 타입만 반환한다.
		var extra_fast = ptr64[e + 32];
		var sz_fast = (extra_fast >> 56) & 127;
		if (sz_fast != 0) {
			// enum member constant: size=127
			if (sz_fast == 127) {
				var en_ty = ptr64[e + 24];
				if (en_ty != 0) { return en_ty; }
				// best-effort fallback: treat as u64-like
				return TC_TY_U64;
			}
			var raw_fast = (extra_fast >> 55) & 1;
			var hook_fast = (extra_fast >> 54) & 1;
			if (hook_fast == 1 && raw_fast == 0) {
				var rec_fast = ptr64[e + 24];
				if (rec_fast != 0) {
					var fm_fast = ptr64[rec_fast + 8];
					if (fm_fast != 0) { return ptr64[fm_fast + 16]; }
				}
			}
			// non-hook: e+24에 field type을 저장해 둔다.
			var fty_fast = ptr64[e + 24];
			if (fty_fast != 0) { return fty_fast; }
			return TC_TY_INVALID;
		}

		var base = ptr64[e + 16];
		var packed0a = ptr64[e + 32];
		// Pre-typecheck packing from parser: [field_len<<2] | [via_ptr<<1] | raw
		var via_ptr0 = (packed0a >> 1) & 1;
		var raw0 = packed0a & 1;
		var field_len0 = packed0a >> 2;
		var field_ptr0 = ptr64[e + 24];

		// Phase 3.2: module-qualified symbol access: mod.sym
		if (tc_modules != 0 && via_ptr0 == 0) {
			if (base != 0 && ptr64[base + 0] == AstExprKind.IDENT) {
				var mod_ptr = ptr64[base + 40];
				var mod_len = ptr64[base + 48];
				// NOTE(v2): tc_env_get 호출이 로컬/인자를 클로버할 수 있어 인라인 조회로 대체.
				var base_ty0 = TC_TY_INVALID;
				if (env != 0 && mod_ptr != 0) {
					var bufm = ptr64[env + 0];
					var nm = ptr64[env + 8];
					while (nm != 0) {
						nm = nm - 1;
						var entm = ptr64[bufm + (nm * 8)];
						if (entm != 0) {
							var enpm = ptr64[entm + 0];
							var enlm = ptr64[entm + 8];
							if (enlm == mod_len && enpm != 0) {
								var im = 0;
								var okm = 1;
								while (im < mod_len) {
									if (ptr8[enpm + im] != ptr8[mod_ptr + im]) { okm = 0; break; }
									im = im + 1;
								}
								if (okm == 1) { base_ty0 = ptr64[entm + 16]; break; }
							}
						}
					}
				}
				if (base_ty0 == TC_TY_INVALID) {
					var mod_id = tc_module_lookup(mod_ptr, mod_len);
					if (mod_id != 18446744073709551615) {
						var ok = 0;
						if (mod_id == tc_cur_mod) { ok = 1; }
						else if (tc_imports_contains(tc_cur_imports, mod_ptr, mod_len) == 1) { ok = 1; }
						if (ok == 0) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "module not imported");
							return TC_TY_INVALID;
						}

						var mrec = vec_get(tc_modules, mod_id);
						var prog = 0;
						if (mrec != 0) { prog = ptr64[mrec + 16]; }
						var decls = 0;
						if (prog != 0) { decls = ptr64[prog + 0]; }
						var found = 0;
						var dk = 0;
						var sym_public = 0;
						var sym_ty = TC_TY_INVALID;
						if (decls != 0) {
							var ndecl = vec_len(decls);
							var j = 0;
							while (j < ndecl) {
								var d2 = vec_get(decls, j);
								if (d2 != 0) {
									var nk = ptr64[d2 + 0];
									if (nk != AstDeclKind.IMPORT) {
										if (slice_eq_parts(ptr64[d2 + 8], ptr64[d2 + 16], field_ptr0, field_len0) == 1) {
											found = 1;
											dk = nk;
											sym_public = ptr64[d2 + 72];
											// Resolve types where possible.
											if (dk == AstDeclKind.STRUCT) {
												sym_ty = tc_struct_lookup_mod(mod_id, field_ptr0, field_len0);
											} else if (dk == AstDeclKind.ENUM) {
												sym_ty = tc_enum_lookup_mod(mod_id, field_ptr0, field_len0);
											} else if (dk == AstDeclKind.VAR || dk == AstDeclKind.CONST) {
												var saved_mod = tc_cur_mod;
												tc_cur_mod = mod_id;
												if (ptr64[d2 + 24] != 0) {
													sym_ty = tc_type_from_asttype(ptr64[d2 + 24]);
												}
												tc_cur_mod = saved_mod;
											}
											break;
										}
									}
								}
								j = j + 1;
							}
						}

						if (found == 0) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "module: unknown symbol");
							return TC_TY_INVALID;
						}
						if (mod_id != tc_cur_mod && sym_public == 0) {
							tc_err_at(ptr64[e + 64], ptr64[e + 72], "module symbol is private");
							return TC_TY_INVALID;
						}
						// Functions have no type in this checker yet; accept.
						return sym_ty;
					}
				}
			}
		}
		// Phase 3.x: FIELD
		// NOTE(v2): v2 부트스트랩 환경에서 함수 호출이 로컬/인자를 클로버할 수 있어,
		// 가능한 한 호출을 피하고(특히 tc_env_get), 필요한 값은 먼저 계산해 둔다.
		var base2 = ptr64[e + 16];
		var field_ptr = ptr64[e + 24];
		var packed0 = ptr64[e + 32];
		var via_ptr = (packed0 >> 1) & 1;
		var raw = packed0 & 1;
		var field_len = packed0 >> 2;
		var base_ty = TC_TY_INVALID;

		// 1) base_ty 계산(IDENT면 env를 직접 스캔)
		if (base2 != 0 && ptr64[base2 + 0] == AstExprKind.IDENT && env != 0) {
			var np2 = ptr64[base2 + 40];
			var nl2 = ptr64[base2 + 48];
			var buf2 = ptr64[env + 0];
			var n2 = ptr64[env + 8];
			while (n2 != 0) {
				n2 = n2 - 1;
				var ent2 = ptr64[buf2 + (n2 * 8)];
				if (ent2 != 0) {
					var enp2 = ptr64[ent2 + 0];
					var enl2 = ptr64[ent2 + 8];
					if (enl2 == nl2 && enp2 != 0 && np2 != 0) {
						var i2 = 0;
						var ok2 = 1;
						while (i2 < nl2) {
							if (ptr8[enp2 + i2] != ptr8[np2 + i2]) { ok2 = 0; break; }
							i2 = i2 + 1;
						}
						if (ok2 == 1) { base_ty = ptr64[ent2 + 16]; break; }
					}
				}
			}
			// NOTE: env에서 못 찾더라도 여기서 tc_expr(IDENT)를 호출하지 않는다.
			// Color.Red 같은 enum 멤버 접근에서 base(Color)가 값 식별자가 아니기 때문.
		} else {
			base_ty = tc_expr(env, base2);
		}

		// 2) enum 멤버 특례(Color.Red): base가 env에 바인딩되지 않았을 때만 시도
		if (base_ty == TC_TY_INVALID) {
			if (ptr64[e + 8] == 0) {
				if (via_ptr == 0) {
					if (base2 != 0 && ptr64[base2 + 0] == AstExprKind.IDENT) {
						// v2 call-clobber 회피: 필요한 값은 전역에 저장
						tc_tmp_expr = e;
						tc_tmp_enum_base_ptr = ptr64[base2 + 40];
						tc_tmp_enum_base_len = ptr64[base2 + 48];
						tc_tmp_enum_field_ptr = field_ptr;
						tc_tmp_enum_field_len = field_len;

						var en = tc_enum_lookup(tc_tmp_enum_base_ptr, tc_tmp_enum_base_len);
						if (en != 0) {
							var v = tc_enum_find_variant(en, tc_tmp_enum_field_ptr, tc_tmp_enum_field_len);
							if (v == 0) {
								tc_err_at(ptr64[tc_tmp_expr + 64], ptr64[tc_tmp_expr + 72], "enum: unknown variant");
								return TC_TY_INVALID;
							}
							// Store computed value into op; mark FIELD as immediate via size=127.
							ptr64[tc_tmp_expr + 8] = ptr64[v + 16];
							ptr64[tc_tmp_expr + 32] = (127 << 56);
							// For idempotent re-visits: store enum type in e+24 (codegen doesn't use it).
							ptr64[tc_tmp_expr + 24] = en;
							return en;
						}
					}
				}
			}
			// enum lookup도 실패했다면, 이제야 base를 식으로 타입체크해서
			// "unknown identifier" 같은 정확한 에러를 내도록 한다.
			if (base2 != 0 && ptr64[base2 + 0] == AstExprKind.IDENT) {
				base_ty = tc_expr(env, base2);
			}
		}

		var struct_ty = base_ty;
		if (via_ptr == 1) {
			if (tc_is_ptr(base_ty) == 0) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access: '->' expects pointer");
				return TC_TY_INVALID;
			}
			if (tc_is_ptr_nullable(base_ty) == 1) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access: cannot use '->' on nullable pointer");
				return TC_TY_INVALID;
			}
			struct_ty = tc_ptr_base(base_ty);
		}
		// NOTE(v2): tc_is_struct(struct_ty) 호출이 레지스터/로컬 클로버로 오동작할 수 있어
		// 여기서는 함수를 호출하지 않고 인라인으로 판정한다.
		var is_struct0 = 0;
		if (struct_ty >= 4096) {
			if (ptr64[struct_ty + 0] == TC_COMPOUND_STRUCT) { is_struct0 = 1; }
		}
		if (is_struct0 == 0) {
			if (tc_debug_field != 0) {
				print_str("DEBUG field: base_ty=");
				print_u64(base_ty);
				print_str(" struct_ty=");
				print_u64(struct_ty);
				print_str(" base_kind=");
				if (base2 != 0) { print_u64(ptr64[base2 + 0]); }
				else { print_u64(0); }
				print_str(" env_len=");
				print_u64(vec_len(env));
				var ent0 = vec_get(env, 0);
				if (ent0 != 0) {
					var enp = ptr64[ent0 + 0];
					var enl = ptr64[ent0 + 8];
					print_str(" ent0_len=");
					print_u64(enl);
					print_str(" ent0_name0=");
					if (enp != 0 && enl != 0) { print_u64(ptr8[enp]); }
					else { print_u64(0); }
					print_str(" ent0_ty=");
					var ety = ptr64[ent0 + 16];
					print_u64(ety);
					if (ety >= 4096) {
						print_str(" ent0_ty_kind=");
						print_u64(ptr64[ety + 0]);
					}
				}
				if (base2 != 0 && ptr64[base2 + 0] == AstExprKind.IDENT) {
					var np = ptr64[base2 + 40];
					var nl = ptr64[base2 + 48];
					print_str(" name_len=");
					print_u64(nl);
					print_str(" name0=");
					if (np != 0 && nl != 0) { print_u64(ptr8[np]); }
					else { print_u64(0); }
				}
				print_str("\n");
			}
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access expects struct type");
			return TC_TY_INVALID;
		}
		var f = tc_struct_find_field(struct_ty, field_ptr, field_len);
		if (f == 0) {
			tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access: unknown field");
			return TC_TY_INVALID;
		}
		// Phase 3.2: cross-module access control.
		if (tc_modules != 0) {
			var smod2 = tc_struct_mod_id(struct_ty);
			if (smod2 != tc_cur_mod) {
				if (tc_struct_is_public(struct_ty) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access: struct type is private");
				}
				if (tc_struct_field_is_public(f) == 0) {
					tc_err_at(ptr64[e + 64], ptr64[e + 72], "field access: field is private");
				}
			}
		}
		// Store computed field offset for codegen.
		ptr64[e + 8] = ptr64[f + 24];
		var fty = ptr64[f + 16];
		// NOTE: codegen은 일반 FIELD에서 e+24를 사용하지 않으므로, 재방문 시를 위해
		// field type을 저장해 둔다. (hook가 켜지면 아래에서 rec로 덮어쓴다.)
		ptr64[e + 24] = fty;
		var fsz = tc_sizeof(fty);
		// Phase 3.5: property hooks.
		// Pack: [via_ptr:1][field_size:7][raw:1][hook:1][field_len:54]
		var hook = 0;
		var fattr2 = ptr64[f + 40];
		if (raw == 0) {
			var ha = fattr2 & 3;
			if (ha != 0) { hook = 1; }
		}
		if (hook == 1) {
			// Store a tiny record for codegen: { struct_ty, field_meta }
			var rec = heap_alloc(16);
			if (rec != 0) {
				ptr64[rec + 0] = struct_ty;
				ptr64[rec + 8] = f;
				ptr64[e + 24] = rec;
			}
		}
		var packed = 0;
		packed = packed | (via_ptr << 63);
		packed = packed | ((fsz & 127) << 56);
		packed = packed | ((raw & 1) << 55);
		packed = packed | ((hook & 1) << 54);
		packed = packed | (field_len & 18014398509481983);
		ptr64[e + 32] = packed;
		return fty;
	}

	tc_err_at(ptr64[e + 64], ptr64[e + 72], "expression: unsupported kind");
	return TC_TY_INVALID;
}

func tc_stmt(env, s) {
	if (s == 0) { return 0; }
	var k = ptr64[s + 0];
	if (k == AstStmtKind.BLOCK) {
		var saved = vec_len(env);
		var stmts = ptr64[s + 8];
		var i = 0;
		var n = 0;
		if (stmts != 0) { n = vec_len(stmts); }
		while (i < n) {
			tc_stmt(env, vec_get(stmts, i));
			i = i + 1;
		}
		ptr64[env + 8] = saved;
		return 0;
	}
	if (k == AstStmtKind.VAR) {
		var flags0 = ptr64[s + 8];
		var fns0 = flags0 & TC_STMT_FLAG_NOSPILL;
		var fs0 = flags0 & TC_STMT_FLAG_SECRET;
		// Capture name early; calls below may clobber `s`.
		var name_ptr = ptr64[s + 32];
		var name_len = ptr64[s + 40];
		var err_line = ptr64[s + 72];
		var err_col = ptr64[s + 80];

		if (fns0 != 0) {
			if (tc_nospill_count >= TC_NOSPILL_LIMIT) {
				if (tc_nospill_overflowed == 0) {
					tc_nospill_overflowed = 1;
					tc_nospill_overflow_line = err_line;
					tc_nospill_overflow_col = err_col;
				}
			} else {
				tc_nospill_count = tc_nospill_count + 1;
			}
		}

		var decl_ty = TC_TY_INVALID;
		if (ptr64[s + 48] != 0) {
			decl_ty = tc_type_from_asttype(ptr64[s + 48]);
		}

		var init_ty = TC_TY_INVALID;
		if (ptr64[s + 56] != 0) {
			if (decl_ty != TC_TY_INVALID) {
				init_ty = tc_expr_with_expected(env, ptr64[s + 56], decl_ty);
			} else {
				init_ty = tc_expr(env, ptr64[s + 56]);
			}
		}
		if (tc_is_tuple2(init_ty) == 1) {
			tc_err_at(err_line, err_col, "var init cannot be multi-return tuple; use destructuring");
		}

		if (decl_ty != TC_TY_INVALID && init_ty != TC_TY_INVALID && tc_type_eq(decl_ty, init_ty) == 0) {
			tc_err_at(err_line, err_col, "var init type mismatch");
		}

		var bind_ty = decl_ty;
		if (bind_ty == TC_TY_INVALID) { bind_ty = init_ty; }
		if (fns0 != 0) {
			// Phase 4.4: nospill locals must be register-sized scalars.
			if (fs0 != 0) {
				tc_err_at(err_line, err_col, "nospill: secret+nospill is not supported yet");
			}
			if (bind_ty == TC_TY_INVALID) {
				tc_err_at(err_line, err_col, "nospill: requires a concrete type");
			}
			// Disallow aggregates: they rely on addressable storage in current backend.
			if (tc_is_slice(bind_ty) == 1 || tc_is_array(bind_ty) == 1 || tc_is_struct(bind_ty) == 1 || tc_is_tuple2(bind_ty) == 1) {
				tc_err_at(err_line, err_col, "nospill: only scalar/pointer/enum types are allowed");
			}
			var sz0 = tc_sizeof(bind_ty);
			if (sz0 != 8) {
				tc_err_at(err_line, err_col, "nospill: only 8-byte values are supported");
			}
			tc_record_nospill_var(name_ptr, name_len, bind_ty);
		}
		tc_env_push(env, name_ptr, name_len, bind_ty);
		if (tc_debug_var != 0) {
			if (slice_eq_parts(name_ptr, name_len, "s", 1) == 1) {
				print_str("DEBUG var s: bind_ty=");
				print_u64(bind_ty);
				print_str(" env_get=");
				print_u64(tc_env_get(env, name_ptr, name_len));
				print_str(" env_len=");
				print_u64(vec_len(env));
				var ent0 = vec_get(env, 0);
				if (ent0 != 0) {
					var enp = ptr64[ent0 + 0];
					var enl = ptr64[ent0 + 8];
					print_str(" ent0_len=");
					print_u64(enl);
					print_str(" ent0_name0=");
					if (enp != 0 && enl != 0) { print_u64(ptr8[enp]); }
					else { print_u64(0); }
					print_str(" ent0_ty=");
					var ety = ptr64[ent0 + 16];
					print_u64(ety);
					if (ety >= 4096) {
						print_str(" ent0_ty_kind=");
						print_u64(ptr64[ety + 0]);
					}
				}
				print_str("\n");
			}
		}
		return 0;
	}
	if (k == AstStmtKind.DESTRUCT) {
		var names = ptr64[s + 8];
		var is_decl = ptr64[s + 16];
		var rhs = ptr64[s + 56];
		if (names == 0 || vec_len(names) != 4) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct: internal name vector mismatch");
			if (rhs != 0) { tc_expr(env, rhs); }
			return 0;
		}
		var name0_ptr = vec_get(names, 0);
		var name0_len = vec_get(names, 1);
		var name1_ptr = vec_get(names, 2);
		var name1_len = vec_get(names, 3);
		var rty = tc_expr(env, rhs);
		if (tc_is_tuple2(rty) == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct: rhs must be a 2-value return");
			return 0;
		}
		var t0 = tc_tuple2_a(rty);
		var t1 = tc_tuple2_b(rty);
		if (is_decl == 1) {
			if (tc_is_discard_ident(name0_ptr, name0_len) == 0) { tc_env_push(env, name0_ptr, name0_len, t0); }
			if (tc_is_discard_ident(name1_ptr, name1_len) == 0) { tc_env_push(env, name1_ptr, name1_len, t1); }
			return 0;
		}
		// assignment
		if (tc_is_discard_ident(name0_ptr, name0_len) == 0) {
			var cur0 = tc_env_get(env, name0_ptr, name0_len);
			if (cur0 == TC_TY_INVALID) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct assign: unknown lhs");
			} else if (tc_type_eq(cur0, t0) == 0) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct assign: lhs type mismatch");
			}
		}
		if (tc_is_discard_ident(name1_ptr, name1_len) == 0) {
			var cur1 = tc_env_get(env, name1_ptr, name1_len);
			if (cur1 == TC_TY_INVALID) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct assign: unknown rhs lhs");
			} else if (tc_type_eq(cur1, t1) == 0) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "destruct assign: lhs type mismatch");
			}
		}
		return 0;
	}
	if (k == AstStmtKind.EXPR) {
		tc_expr(env, ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.RETURN) {
		var want = tc_cur_ret_ty;
		var es = ptr64[s + 8];
		if (tc_is_tuple2(want) == 1) {
			if (es == 0 || vec_len(es) != 2) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "return: expected two values");
				// still typecheck single expr for recovery
				if (ptr64[s + 56] != 0) { tc_expr(env, ptr64[s + 56]); }
				return 0;
			}
			var a0 = vec_get(es, 0);
			var b0 = vec_get(es, 1);
			tc_expr_with_expected(env, a0, tc_tuple2_a(want));
			tc_expr_with_expected(env, b0, tc_tuple2_b(want));
			return 0;
		}
		// non-tuple return
		if (es != 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "return: unexpected multiple values");
			var i0 = 0;
			var n0 = vec_len(es);
			while (i0 < n0) { tc_expr(env, vec_get(es, i0)); i0 = i0 + 1; }
			return 0;
		}
		if (want == 0) {
			// Unspecified return type: allow return with or without a value.
			if (ptr64[s + 56] != 0) { tc_expr(env, ptr64[s + 56]); }
			return 0;
		}
		if (ptr64[s + 56] == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "return: expected value");
			return 0;
		}
		// Validate return expression type.
		tc_expr_with_expected(env, ptr64[s + 56], want);
		return 0;
	}
	if (k == AstStmtKind.BREAK) {
		var level = ptr64[s + 8];
		if (level == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "break: level must be >= 1");
			return 0;
		}
		if (tc_break_depth == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "break: not inside a loop or switch");
			return 0;
		}
		if (level > tc_break_depth) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "break: level exceeds break depth");
		}
		return 0;
	}
	if (k == AstStmtKind.CONTINUE) {
		var level2 = ptr64[s + 8];
		if (level2 == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "continue: level must be >= 1");
			return 0;
		}
		if (tc_switch_depth != 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "continue: not allowed inside switch");
			return 0;
		}
		if (tc_loop_depth == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "continue: not inside a loop");
			return 0;
		}
		if (level2 > tc_loop_depth) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "continue: level exceeds loop depth");
		}
		return 0;
	}
	if (k == AstStmtKind.IF) {
		tc_expr(env, ptr64[s + 8]);
		tc_stmt(env, ptr64[s + 16]);
		if (ptr64[s + 24] != 0) { tc_stmt(env, ptr64[s + 24]); }
		return 0;
	}
	if (k == AstStmtKind.WHILE) {
		tc_expr(env, ptr64[s + 8]);
		tc_loop_depth = tc_loop_depth + 1;
		tc_break_depth = tc_break_depth + 1;
		tc_stmt(env, ptr64[s + 16]);
		tc_break_depth = tc_break_depth - 1;
		tc_loop_depth = tc_loop_depth - 1;
		return 0;
	}
	if (k == AstStmtKind.FOR) {
		// Layout:
		//  s->a: init stmt (0 allowed)
		//  s->b: cond expr (0 means true)
		//  s->c: post expr (0 allowed)
		//  s->expr_ptr: body stmt
		var init0 = ptr64[s + 8];
		var cond0 = ptr64[s + 16];
		var post0 = ptr64[s + 24];
		var body0 = ptr64[s + 56];
		var saved = vec_len(env);
		if (init0 != 0) { tc_stmt(env, init0); }
		if (cond0 != 0) { tc_expr(env, cond0); }
		tc_loop_depth = tc_loop_depth + 1;
		tc_break_depth = tc_break_depth + 1;
		if (body0 != 0) { tc_stmt(env, body0); }
		if (post0 != 0) { tc_expr(env, post0); }
		tc_break_depth = tc_break_depth - 1;
		tc_loop_depth = tc_loop_depth - 1;
		ptr64[env + 8] = saved;
		return 0;
	}
	if (k == AstStmtKind.FOREACH) {
		// Layout:
		//  s->a: AstForeachBind*
		//  s->b: iter expr
		//  s->c: body stmt
		var bind = ptr64[s + 8];
		var iter_expr = ptr64[s + 16];
		var body = ptr64[s + 24];
		if (bind == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "foreach: missing binding");
			return 0;
		}

		var iter_ty = tc_expr(env, iter_expr);
		var elem_ty = TC_TY_INVALID;
		if (tc_is_slice(iter_ty) == 1) {
			elem_ty = tc_slice_elem(iter_ty);
		} else if (tc_is_array(iter_ty) == 1) {
			elem_ty = tc_array_elem(iter_ty);
		} else {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "foreach expects slice or array");
			// Still typecheck body for error recovery.
			tc_loop_depth = tc_loop_depth + 1;
			tc_stmt(env, body);
			tc_loop_depth = tc_loop_depth - 1;
			return 0;
		}

		var elem_sz = tc_sizeof(elem_ty);
		if (elem_sz == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "foreach: unsupported element type");
		} else {
			// Store element size for codegen.
			ptr64[bind + 40] = elem_sz;
		}

		var name0_ptr = ptr64[bind + 0];
		var name0_len = ptr64[bind + 8];
		var name1_ptr = ptr64[bind + 16];
		var name1_len = ptr64[bind + 24];
		var has_two = ptr64[bind + 32];

		var saved = vec_len(env);
		if (has_two == 1) {
			// foreach (var idx, val in expr)
			if (tc_is_discard_ident(name0_ptr, name0_len) == 0) {
				tc_env_push(env, name0_ptr, name0_len, TC_TY_U64);
			}
			if (tc_is_discard_ident(name1_ptr, name1_len) == 0) {
				tc_env_push(env, name1_ptr, name1_len, elem_ty);
			}
		} else {
			// foreach (var val in expr)
			if (tc_is_discard_ident(name0_ptr, name0_len) == 0) {
				tc_env_push(env, name0_ptr, name0_len, elem_ty);
			}
		}

		tc_loop_depth = tc_loop_depth + 1;
		tc_break_depth = tc_break_depth + 1;
		tc_stmt(env, body);
		tc_break_depth = tc_break_depth - 1;
		tc_loop_depth = tc_loop_depth - 1;
		ptr64[env + 8] = saved;
		return 0;
	}
	if (k == AstStmtKind.SWITCH) {
		// Layout (see ast.b):
		//  +8  scrutinee expr
		// +16  cases Vec(AstSwitchCase*)
		// +24  default body stmt or 0
		var scrut = ptr64[s + 8];
		var scrut_ty = tc_expr(env, scrut);
		if (tc_is_int(scrut_ty) == 0 && tc_is_enum(scrut_ty) == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "switch: scrutinee must be integer or enum");
		}
		var saved_switch = tc_switch_depth;
		var saved_break = tc_break_depth;
		tc_switch_depth = tc_switch_depth + 1;
		tc_break_depth = tc_break_depth + 1;

		var cases = ptr64[s + 16];
		if (cases != 0) {
			var n = vec_len(cases);
			var i = 0;
			while (i < n) {
				var c = vec_get(cases, i);
				if (c != 0) {
					var vexpr = ptr64[c + 0];
					var vty = TC_TY_INVALID;
					if (tc_is_int(scrut_ty) == 1) {
						vty = tc_expr_with_expected(env, vexpr, scrut_ty);
					} else {
						vty = tc_expr(env, vexpr);
					}
					if (scrut_ty != TC_TY_INVALID && vty != TC_TY_INVALID && tc_type_eq(scrut_ty, vty) == 0) {
						tc_err_at(ptr64[c + 24], ptr64[c + 32], "switch case: value type mismatch");
					}
					if (tc_switch_case_is_const(vexpr) == 0) {
						tc_err_at(ptr64[c + 24], ptr64[c + 32], "switch case: value must be constant");
					}
					var body = ptr64[c + 8];
					if (body != 0) { tc_stmt(env, body); }
				}
				i = i + 1;
			}
		}
		var defb = ptr64[s + 24];
		if (defb != 0) { tc_stmt(env, defb); }

		tc_break_depth = saved_break;
		tc_switch_depth = saved_switch;
		return 0;
	}
	if (k == AstStmtKind.DEFER) {
		// st+8 = inner statement
		var inner = ptr64[s + 8];
		if (inner != 0) { tc_stmt(env, inner); }
		return 0;
	}
	if (k == AstStmtKind.WIPE) {
		// Layout:
		//  s->a: expr0 (variable or ptr)
		//  s->b: expr1 (len) or 0
		var a0 = ptr64[s + 8];
		var b0 = ptr64[s + 16];
		if (b0 == 0) {
			// wipe variable;
			if (a0 == 0 || ptr64[a0 + 0] != AstExprKind.IDENT) {
				tc_err_at(ptr64[s + 72], ptr64[s + 80], "wipe variable: expected identifier");
				// Still typecheck for recovery.
				if (a0 != 0) { tc_expr(env, a0); }
				return 0;
			}
			tc_expr(env, a0);
			return 0;
		}
		// wipe ptr, len;
		var pty = tc_expr(env, a0);
		var lty = tc_expr(env, b0);
		if (tc_is_ptr(pty) == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "wipe ptr,len: ptr must be pointer");
			return 0;
		}
		if (tc_is_ptr_nullable(pty) == 1) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "wipe ptr,len: ptr must be non-null pointer");
			return 0;
		}
		if (tc_ptr_base(pty) != TC_TY_U8) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "wipe ptr,len: ptr must be *u8");
			return 0;
		}
		if (tc_is_int(lty) == 0) {
			tc_err_at(ptr64[s + 72], ptr64[s + 80], "wipe ptr,len: len must be integer");
			return 0;
		}
		return 0;
	}
	if (k == AstStmtKind.PRINT || k == AstStmtKind.PRINTLN) {
		// a = Vec* of args
		var args = ptr64[s + 8];
		if (args != 0) {
			var n = vec_len(args);
			var i = 0;
			while (i < n) {
				var arg = vec_get(args, i);
				if (arg != 0) { tc_expr(env, arg); }
				i = i + 1;
			}
		}
		return 0;
	}
	if (k == AstStmtKind.ASM) {
		// asm block: no type checking needed, just pass through
		return 0;
	}
	if (k == AstStmtKind.ALIAS) {
		// alias reg : name [= init];
		// Register the name in environment as u64 type
		var name_ptr = ptr64[s + 32];
		var name_len = ptr64[s + 40];
		var init_expr = ptr64[s + 56];
		if (init_expr != 0) {
			tc_expr(env, init_expr);
		}
		tc_env_push(env, name_ptr, name_len, TC_TY_U64);
		return 0;
	}

	tc_err_at(ptr64[s + 72], ptr64[s + 80], "statement: unsupported kind");
	return 0;
}

func typecheck_program(prog) {
	// Returns: number of type errors (u64)
	// Parse -> Lower -> Typecheck pipeline hook.
	lower_program(prog);
	tc_errors = 0;
	tc_modules = 0;
	tc_cur_mod = 0;
	tc_cur_imports = 0;
	tc_structs = vec_new(8);
	if (tc_structs == 0) {
		return 1;
	}
	tc_enums = vec_new(8);
	if (tc_enums == 0) {
		return 1;
	}
	tc_ptr_types = vec_new(8);
	if (tc_ptr_types == 0) {
		return 1;
	}
	// Phase 6.7: function pointer types
	tc_func_ptr_types = vec_new(8);
	if (tc_func_ptr_types == 0) {
		return 1;
	}
	tc_type_aliases = vec_new(8);
	if (tc_type_aliases == 0) { return 1; }
	// Phase 6.7: function signatures for function pointer support
	tc_funcs = vec_new(8);
	if (tc_funcs == 0) { return 1; }

	// Initialize HashMap tables for O(1) lookup
	tc_structs_map = hashmap_new(16);
	tc_enums_map = hashmap_new(16);
	tc_type_aliases_map = hashmap_new(16);
	tc_funcs_map = hashmap_new(16);

	// Pass 0: register enum and struct layouts.
	var decls0 = ptr64[prog + 0];
	var i0 = 0;
	var n0 = 0;
	if (decls0 != 0) { n0 = vec_len(decls0); }
	while (i0 < n0) {
		var d0 = vec_get(decls0, i0);
		if (ptr64[d0 + 0] == AstDeclKind.ENUM) {
			tc_register_enum_decl(d0, 0, ptr64[d0 + 72]);
		}
		if (ptr64[d0 + 0] == AstDeclKind.STRUCT) {
			// Phase 5.1: skip generic template structs
			var generic_params0 = ptr64[d0 + 88];
			if (generic_params0 == 0) {
				tc_register_struct_decl(d0, 0, ptr64[d0 + 72]);
			}
		}
		i0 = i0 + 1;
	}

	// Pass 0.6: register type aliases.
	i0 = 0;
	while (i0 < n0) {
		var d1 = vec_get(decls0, i0);
		if (d1 != 0 && ptr64[d1 + 0] == AstDeclKind.TYPE) {
			tc_register_type_alias_decl(d1, 0, ptr64[d1 + 72]);
		}
		i0 = i0 + 1;
	}

	// Pass 0.7: collect function signatures (for function pointer support)
	tc_collect_func_sigs_from_prog(prog, 0);

	// Pass 0.5 reserved for Phase 3.5 property hook validation.

	var env = tc_env_new();
	if (env == 0) {
		return 1;
	}

	tc_cur_ast_prog = prog;
	var decls = ptr64[prog + 0];
	var i = 0;
	while (decls != 0 && i < vec_len(decls)) {
		var d = vec_get(decls, i);
		var k = ptr64[d + 0];
		if (k == AstDeclKind.VAR || k == AstDeclKind.CONST) {
			// In global init expressions, everything in env is global.
			tc_env_global_len = vec_len(env);
			// Capture name early; calls below may clobber `d`.
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			var err_line = ptr64[d + 56];
			var err_col = ptr64[d + 64];

			var decl_ty = TC_TY_INVALID;
			if (ptr64[d + 24] != 0) {
				decl_ty = tc_type_from_asttype(ptr64[d + 24]);
			}
			var init_ty = TC_TY_INVALID;
			if (ptr64[d + 32] != 0) {
				if (decl_ty != TC_TY_INVALID) {
					init_ty = tc_expr_with_expected(env, ptr64[d + 32], decl_ty);
				} else {
					init_ty = tc_expr(env, ptr64[d + 32]);
				}
			}
			if (decl_ty != TC_TY_INVALID && init_ty != TC_TY_INVALID && decl_ty != init_ty) {
				tc_err_at(err_line, err_col, "global init type mismatch");
			}
			var bind_ty = decl_ty;
			if (bind_ty == TC_TY_INVALID) { bind_ty = init_ty; }
			tc_env_push(env, name_ptr, name_len, bind_ty);
		} else if (k == AstDeclKind.FUNC) {
			// Phase 5.1: skip generic templates; they are instantiated at call sites.
			var generic_params2 = ptr64[d + 88];
			if (generic_params2 != 0) { i = i + 1; continue; }
			// Phase 4.5: validate @reg annotations (extern-only).
			tc_validate_reg_anno_in_func(d);
			// New scope for each function.
			var saved = vec_len(env);
			tc_env_global_len = saved;
			var saved_ret = tc_cur_ret_ty;
			tc_cur_ret_ty = 0;
			// Phase 4.4: reset nospill tracking per function.
			tc_nospill_reset();
			// Bind params into the environment.
			var params = ptr64[d + 24];
			if (params != 0) {
				var pn = vec_len(params);
				var pi = 0;
				while (pi < pn) {
					var ps = vec_get(params, pi);
					if (ps != 0) {
						// Params are AstStmt(VAR)
						var pname_ptr = ptr64[ps + 32];
						var pname_len = ptr64[ps + 40];
						var pty = TC_TY_INVALID;
						if (ptr64[ps + 48] != 0) {
							pty = tc_type_from_asttype(ptr64[ps + 48]);
						}
						tc_env_push(env, pname_ptr, pname_len, pty);
					}
					pi = pi + 1;
				}
			}
			// Set expected return type for this function.
			var ret_ast = ptr64[d + 32];
			if (ret_ast != 0) { tc_cur_ret_ty = tc_type_from_asttype(ret_ast); }
			else { tc_cur_ret_ty = 0; }
			var body = ptr64[d + 40];
			if (body != 0) {
				var saved_loop = tc_loop_depth;
				tc_loop_depth = 0;
				tc_stmt(env, body);
				tc_loop_depth = saved_loop;
			}
			// NOTE: nospill checking disabled in v3 simplification (moved to v4)
			// if (tc_nospill_overflowed != 0) {
			// 	tc_err_at(tc_nospill_overflow_line, tc_nospill_overflow_col, "nospill: register pressure exceeded");
			// }
			ptr64[env + 8] = saved;
			tc_env_global_len = saved;
			tc_cur_ret_ty = saved_ret;
		}
		i = i + 1;
	}

	return tc_errors;
}

func tc_collect_imports_from_prog(prog) {
	var imports = vec_new(4);
	if (imports == 0) { return 0; }
	if (prog == 0) { return imports; }
	var decls = ptr64[prog + 0];
	if (decls == 0) { return imports; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.IMPORT) {
			var ent = heap_alloc(16);
			if (ent != 0) {
				ptr64[ent + 0] = ptr64[d + 8];
				ptr64[ent + 8] = ptr64[d + 16];
				vec_push(imports, ent);
			}
		}
		i = i + 1;
	}
	return imports;
}

func tc_typecheck_all_modules() {
	// Assumes tc_modules is populated.
	// Returns tc_errors.
	tc_errors = 0;
	tc_structs = vec_new(8);
	if (tc_structs == 0) { return 1; }
	tc_enums = vec_new(8);
	if (tc_enums == 0) { return 1; }
	tc_ptr_types = vec_new(8);
	if (tc_ptr_types == 0) { return 1; }
	// Phase 6.7: function pointer types
	tc_func_ptr_types = vec_new(8);
	if (tc_func_ptr_types == 0) { return 1; }
	tc_type_aliases = vec_new(8);
	if (tc_type_aliases == 0) { return 1; }

	// Initialize HashMap tables for O(1) lookup
	tc_structs_map = hashmap_new(16);
	tc_enums_map = hashmap_new(16);
	tc_type_aliases_map = hashmap_new(16);
	tc_funcs_map = hashmap_new(16);

	// Pass 0: register enum and struct layouts per module.
	var mcount = vec_len(tc_modules);
	var mi = 0;
	while (mi < mcount) {
		var m = vec_get(tc_modules, mi);
		var prog = 0;
		if (m != 0) { prog = ptr64[m + 16]; }
		tc_cur_mod = mi;
		tc_cur_imports = 0;
		if (m != 0) { tc_cur_imports = ptr64[m + 24]; }
		var decls0 = 0;
		if (prog != 0) { decls0 = ptr64[prog + 0]; }
		var i0 = 0;
		var n0 = 0;
		if (decls0 != 0) { n0 = vec_len(decls0); }
		while (i0 < n0) {
			var d0 = vec_get(decls0, i0);
			if (d0 != 0) {
				if (ptr64[d0 + 0] == AstDeclKind.ENUM) {
					tc_register_enum_decl(d0, mi, ptr64[d0 + 72]);
				}
				if (ptr64[d0 + 0] == AstDeclKind.STRUCT) {
					var tflag0 = ptr64[d0 + 80] & TC_DECL_FLAG_GENERIC_TEMPLATE;
					var tparams0 = ptr64[d0 + 96];
					if (tflag0 == 0 && tparams0 == 0) {
						tc_register_struct_decl(d0, mi, ptr64[d0 + 72]);
					}
				}
			}
			i0 = i0 + 1;
		}
		mi = mi + 1;
	}

	// Pass 0.6: register type aliases per module.
	mi = 0;
	while (mi < mcount) {
		var m0 = vec_get(tc_modules, mi);
		var prog0 = 0;
		if (m0 != 0) { prog0 = ptr64[m0 + 16]; }
		tc_cur_mod = mi;
		tc_cur_imports = 0;
		if (m0 != 0) { tc_cur_imports = ptr64[m0 + 24]; }
		var decls_t = 0;
		if (prog0 != 0) { decls_t = ptr64[prog0 + 0]; }
		var tn = 0;
		if (decls_t != 0) { tn = vec_len(decls_t); }
		var ti = 0;
		while (ti < tn) {
			var d_t = vec_get(decls_t, ti);
			if (d_t != 0 && ptr64[d_t + 0] == AstDeclKind.TYPE) {
				tc_register_type_alias_decl(d_t, mi, ptr64[d_t + 72]);
			}
			ti = ti + 1;
		}
		mi = mi + 1;
	}

	// Pass 0.5 reserved for Phase 3.5 property hook validation.
	tc_funcs = vec_new(8);
	if (tc_funcs == 0) { return 1; }
	mi = 0;
	while (mi < mcount) {
		var m05 = vec_get(tc_modules, mi);
		var prog05 = 0;
		if (m05 != 0) { prog05 = ptr64[m05 + 16]; }
		tc_collect_func_sigs_from_prog(prog05, mi);
		mi = mi + 1;
	}
	mi = 0;
	while (mi < mcount) {
		tc_cur_mod = mi;
		var m05b = vec_get(tc_modules, mi);
		tc_cur_imports = 0;
		if (m05b != 0) { tc_cur_imports = ptr64[m05b + 24]; }
		tc_validate_property_hooks_mod(mi);
		mi = mi + 1;
	}

	// Pass 1: typecheck each module in isolation.
	mi = 0;
	while (mi < mcount) {
		var m2 = vec_get(tc_modules, mi);
		var prog2 = 0;
		if (m2 != 0) { prog2 = ptr64[m2 + 16]; }
		tc_cur_ast_prog = prog2;
		tc_cur_mod = mi;
		tc_cur_imports = 0;
		if (m2 != 0) { tc_cur_imports = ptr64[m2 + 24]; }

		var env = tc_env_new();
		if (env == 0) { return 1; }

		var decls = 0;
		if (prog2 != 0) { decls = ptr64[prog2 + 0]; }
		var i = 0;
		while (decls != 0 && i < vec_len(decls)) {
			var d = vec_get(decls, i);
			if (d == 0) { i = i + 1; continue; }
			var k = ptr64[d + 0];
			if (k == AstDeclKind.VAR || k == AstDeclKind.CONST) {
				// In global init expressions, everything in env is global.
				tc_env_global_len = vec_len(env);
				// Capture name early; calls below may clobber `d`.
				var name_ptr = ptr64[d + 8];
				var name_len = ptr64[d + 16];
				var err_line = ptr64[d + 56];
				var err_col = ptr64[d + 64];

				var decl_ty = TC_TY_INVALID;
				if (ptr64[d + 24] != 0) {
					decl_ty = tc_type_from_asttype(ptr64[d + 24]);
				}
				var init_ty = TC_TY_INVALID;
				if (ptr64[d + 32] != 0) {
					if (decl_ty != TC_TY_INVALID) {
						init_ty = tc_expr_with_expected(env, ptr64[d + 32], decl_ty);
					} else {
						init_ty = tc_expr(env, ptr64[d + 32]);
					}
				}
				if (decl_ty != TC_TY_INVALID && init_ty != TC_TY_INVALID && decl_ty != init_ty) {
					tc_err_at(err_line, err_col, "global init type mismatch");
				}
				var bind_ty = decl_ty;
				if (bind_ty == TC_TY_INVALID) { bind_ty = init_ty; }
				tc_env_push(env, name_ptr, name_len, bind_ty);
			} else if (k == AstDeclKind.FUNC) {
				// Phase 5.1: skip generic templates; they are instantiated at call sites.
				var tflag3 = ptr64[d + 80] & TC_DECL_FLAG_GENERIC_TEMPLATE;
				var tparams3 = ptr64[d + 96];
				if (tflag3 != 0 || tparams3 != 0) { i = i + 1; continue; }
				// Phase 4.5: validate @reg annotations (extern-only).
				tc_validate_reg_anno_in_func(d);
				// New scope for each function.
				var saved = vec_len(env);
				tc_env_global_len = saved;
				var saved_ret = tc_cur_ret_ty;
				tc_cur_ret_ty = 0;
				// Phase 4.4: reset nospill tracking per function.
				tc_nospill_reset();
				// Bind params into the environment.
				var params = ptr64[d + 24];
				if (params != 0) {
					var pn = vec_len(params);
					var pi = 0;
					while (pi < pn) {
						var ps = vec_get(params, pi);
						if (ps != 0) {
							// Params are AstStmt(VAR)
							var pname_ptr = ptr64[ps + 32];
							var pname_len = ptr64[ps + 40];
							var pty = TC_TY_INVALID;
							if (ptr64[ps + 48] != 0) {
								pty = tc_type_from_asttype(ptr64[ps + 48]);
							}
							tc_env_push(env, pname_ptr, pname_len, pty);
						}
						pi = pi + 1;
					}
				}
				// Set expected return type for this function.
				var ret_ast = ptr64[d + 32];
				if (ret_ast != 0) { tc_cur_ret_ty = tc_type_from_asttype(ret_ast); }
				else { tc_cur_ret_ty = 0; }
				var body = ptr64[d + 40];
				if (body != 0) {
					tc_stmt(env, body);
				}
				// NOTE: nospill checking disabled in v3 simplification (moved to v4)
				// if (tc_nospill_overflowed != 0) {
				// 	tc_err_at(tc_nospill_overflow_line, tc_nospill_overflow_col, "nospill: register pressure exceeded");
				// }
				ptr64[env + 8] = saved;
				tc_env_global_len = saved;
				tc_cur_ret_ty = saved_ret;
			}
			i = i + 1;
		}
		mi = mi + 1;
	}

	return tc_errors;
}

func typecheck_entry_file(path) {
	// Returns: number of type errors (u64)
	var seen = vec_new(8);
	var order = vec_new(8);
	if (seen == 0 || order == 0) { return 1; }
	var scan_errs = v3h_build_module_order(path, seen, order);
	if (scan_errs != 0) {
		// driver already printed errors
		return 1;
	}

	tc_modules = vec_new(8);
	if (tc_modules == 0) { return 1; }

	var nmods = vec_len(order);
	var i = 0;
	while (i < nmods) {
		var mpath = vec_get(order, i);
		var src = read_file(mpath);
		alias rdx : n_reg;
		var n = n_reg;
		if (src == 0) {
			print_str("error: failed to read file\n");
			return 1;
		}

		var lex = heap_alloc(40);
		var tok = heap_alloc(48);
		var prs = heap_alloc(40);
		var prog = heap_alloc(16);
		if (lex == 0 || tok == 0 || prs == 0 || prog == 0) { return 1; }
		lexer_init(lex, src, n);
		parser_init(prs, lex, tok);
		parse_program(prs, prog);
		var parse_errors = ptr64[prog + 8];
		if (parse_errors != 0) {
			print_str("parse_errors=");
			print_u64(parse_errors);
			print_str("\n");
			return 1;
		}
		// Parse -> Lower -> Typecheck pipeline hook.
		lower_program(prog);

		var bp = v3h_path_basename_no_ext(mpath);
		alias rdx : bl_reg;
		var bl = bl_reg;

		var mrec = heap_alloc(32);
		if (mrec == 0) { return 1; }
		ptr64[mrec + 0] = bp;
		ptr64[mrec + 8] = bl;
		ptr64[mrec + 16] = prog;
		var imports = tc_collect_imports_from_prog(prog);
		ptr64[mrec + 24] = imports;
		vec_push(tc_modules, mrec);
		i = i + 1;
	}

	return tc_typecheck_all_modules();
}
