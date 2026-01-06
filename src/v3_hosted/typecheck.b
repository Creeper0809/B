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

import file;

import io;
import vec;

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

// Global error counter (avoid taking addresses of locals; v2 compiler limitation).
var tc_errors;

// Global struct registry (Vec of struct type pointers).
var tc_structs;
// Global enum registry (Vec of enum type pointers).
var tc_enums;

// Global pointer-type registry (Vec of compound ptr types).
var tc_ptr_types;

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

func tc_sizeof(ty) {
	if (ty == TC_TY_U8 || ty == TC_TY_I8 || ty == TC_TY_BOOL || ty == TC_TY_CHAR) { return 1; }
	if (ty == TC_TY_U16 || ty == TC_TY_I16) { return 2; }
	if (ty == TC_TY_U32 || ty == TC_TY_I32) { return 4; }
	if (ty == TC_TY_U64 || ty == TC_TY_I64) { return 8; }
	if (tc_is_ptr(ty) == 1) { return 8; }
	if (tc_is_slice(ty) == 1) { return 16; }
	if (tc_is_array(ty) == 1) {
		return tc_sizeof(tc_array_elem(ty)) * tc_array_len(ty);
	}
	if (tc_is_struct(ty) == 1) { return tc_struct_size(ty); }
	if (tc_is_enum(ty) == 1) { return 8; }
	return 0;
}

func tc_alignof(ty) {
	if (ty == TC_TY_U8 || ty == TC_TY_I8 || ty == TC_TY_BOOL || ty == TC_TY_CHAR) { return 1; }
	if (ty == TC_TY_U16 || ty == TC_TY_I16) { return 2; }
	if (ty == TC_TY_U32 || ty == TC_TY_I32) { return 4; }
	if (ty == TC_TY_U64 || ty == TC_TY_I64) { return 8; }
	if (tc_is_ptr(ty) == 1) { return 8; }
	if (tc_is_slice(ty) == 1) { return 8; }
	if (tc_is_array(ty) == 1) { return tc_alignof(tc_array_elem(ty)); }
	if (tc_is_struct(ty) == 1) { return tc_struct_align(ty); }
	if (tc_is_enum(ty) == 1) { return 8; }
	return 1;
}

func tc_struct_lookup_mod(mod_id, name_ptr, name_len) {
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
	// Disallow pointers-to-pointers in Phase 2.2 MVP.
	if (tc_is_ptr(base_ty) == 1) { return TC_TY_INVALID; }
	// For builtin scalar base types, keep encoded pointer types.
	if (base_ty > 0 && base_ty <= 255) {
		if (nullable == 1) { return TC_TY_PTR_NULLABLE_BASE + base_ty; }
		return TC_TY_PTR_BASE + base_ty;
	}
	// Allow pointers to structs (compound types).
	if (tc_is_struct(base_ty) == 1) {
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
	return TC_TY_INVALID;
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
	if (tc_is_array(a) == 1 && tc_is_array(b) == 1) {
		if (tc_array_len(a) != tc_array_len(b)) { return 0; }
		return tc_type_eq(tc_array_elem(a), tc_array_elem(b));
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
			if (rk2 != AstExprKind.IDENT && rk2 != AstExprKind.FIELD) {
				tc_err_at(ptr64[e + 64], ptr64[e + 72], "'&' expects lvalue");
				return TC_TY_INVALID;
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
	if (kind == AstTypeKind.NAME) {
		var name_ptr = ptr64[t + 8];
		var name_len = ptr64[t + 16];
		// Optional alias: `str` == `[]u8`.
		if (slice_eq_parts(name_ptr, name_len, "str", 3) == 1) {
			return TC_TY_SLICE_BASE + TC_TY_U8;
		}
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
		tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unknown name");
		return TC_TY_INVALID;
	}
	tc_err_at(ptr64[t + 32], ptr64[t + 40], "type: unsupported kind");
	return TC_TY_INVALID;
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
	// Copy args to locals before calls.
	var env2 = env;
	var name_ptr2 = name_ptr;
	var name_len2 = name_len;

	var n = vec_len(env2);
	while (n != 0) {
		n = n - 1;
		var ent = vec_get(env2, n);
		if (slice_eq_parts(ptr64[ent + 0], ptr64[ent + 8], name_ptr2, name_len2) == 1) {
			return ptr64[ent + 16];
		}
	}
	return 0;
}

func tc_is_discard_ident(name_ptr, name_len) {
	return slice_eq_parts(name_ptr, name_len, "_", 1);
}

func tc_expr(env, e) {
	if (e == 0) { return TC_TY_INVALID; }
	var k = ptr64[e + 0];

	if (k == AstExprKind.INT) {
		return TC_TY_U64;
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
		var ty = tc_env_get(env, ptr64[e + 40], ptr64[e + 48]);
		if (ty == TC_TY_INVALID) {
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
			return tc_ptr_base(rhs_ty);
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
		return rhs_ty;
	}
	if (k == AstExprKind.BINARY) {
		var op = ptr64[e + 8];

		// Assignment: lhs must be an identifier and rhs must match lhs type.
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
					// Phase 4.1: allow $ptr = v stores.
					if (lk != AstExprKind.UNARY || ptr64[lhs + 8] != TokKind.DOLLAR) {
						tc_err_at(ptr64[e + 64], ptr64[e + 72], "assignment lhs must be identifier, field, or $ptr");
						return TC_TY_INVALID;
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
		if (tc_is_slice(base_ty) == 1) {
			return tc_slice_elem(base_ty);
		}
		if (tc_is_array(base_ty) == 1) {
			return tc_array_elem(base_ty);
		}
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "index expects slice or array");
		return TC_TY_INVALID;
	}
	if (k == AstExprKind.BRACE_INIT) {
		// Without context, brace-init cannot be typed.
		tc_err_at(ptr64[e + 64], ptr64[e + 72], "brace-init requires array type context");
		return TC_TY_INVALID;
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
				var base_ty0 = tc_env_get(env, mod_ptr, mod_len);
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
		// Special-case enum member access: Color.Red
		if (ptr64[e + 8] == 0) {
			if (base != 0 && ptr64[base + 0] == AstExprKind.IDENT) {
				var tn_ptr = ptr64[base + 40];
				var tn_len = ptr64[base + 48];
				var base_ty0 = tc_env_get(env, tn_ptr, tn_len);
				if (base_ty0 == TC_TY_INVALID) {
					if (via_ptr0 == 0) {
						var en = tc_enum_lookup(tn_ptr, tn_len);
						if (en != 0) {
							var v = tc_enum_find_variant(en, field_ptr0, field_len0);
							if (v == 0) {
								tc_err_at(ptr64[e + 64], ptr64[e + 72], "enum: unknown variant");
								return TC_TY_INVALID;
							}
							// Store computed value into op; mark FIELD as immediate via size=127.
							ptr64[e + 8] = ptr64[v + 16];
							var packed_im = (127 << 56) | (field_len0 & 36028797018963967);
							ptr64[e + 32] = packed_im;
							return en;
						}
					}
				}
			}
		}
		var base_ty = tc_expr(env, base);
		var field_ptr = ptr64[e + 24];
		var packed0 = ptr64[e + 32];
		var via_ptr = (packed0 >> 1) & 1;
		var raw = packed0 & 1;
		var field_len = packed0 >> 2;
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
		if (tc_is_struct(struct_ty) == 0) {
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
		// Capture name early; calls below may clobber `s`.
		var name_ptr = ptr64[s + 32];
		var name_len = ptr64[s + 40];
		var err_line = ptr64[s + 72];
		var err_col = ptr64[s + 80];

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

		if (decl_ty != TC_TY_INVALID && init_ty != TC_TY_INVALID && tc_type_eq(decl_ty, init_ty) == 0) {
			tc_err_at(err_line, err_col, "var init type mismatch");
		}

		var bind_ty = decl_ty;
		if (bind_ty == TC_TY_INVALID) { bind_ty = init_ty; }
		tc_env_push(env, name_ptr, name_len, bind_ty);
		return 0;
	}
	if (k == AstStmtKind.EXPR) {
		tc_expr(env, ptr64[s + 56]);
		return 0;
	}
	if (k == AstStmtKind.RETURN) {
		if (ptr64[s + 56] != 0) {
			tc_expr(env, ptr64[s + 56]);
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
		tc_stmt(env, ptr64[s + 16]);
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
			tc_stmt(env, body);
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

		tc_stmt(env, body);
		ptr64[env + 8] = saved;
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

	tc_err_at(ptr64[s + 72], ptr64[s + 80], "statement: unsupported kind");
	return 0;
}

func typecheck_program(prog) {
	// Returns: number of type errors (u64)
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
			tc_register_struct_decl(d0, 0, ptr64[d0 + 72]);
		}
		i0 = i0 + 1;
	}

	// Pass 0.5 reserved for Phase 3.5 property hook validation.

	var env = tc_env_new();
	if (env == 0) {
		return 1;
	}

	var decls = ptr64[prog + 0];
	var i = 0;
	var n = 0;
	if (decls != 0) { n = vec_len(decls); }
	while (i < n) {
		var d = vec_get(decls, i);
		var k = ptr64[d + 0];
		if (k == AstDeclKind.VAR || k == AstDeclKind.CONST) {
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
			// New scope for each function.
			var saved = vec_len(env);
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
			var body = ptr64[d + 40];
			if (body != 0) {
				tc_stmt(env, body);
			}
			ptr64[env + 8] = saved;
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
					tc_register_struct_decl(d0, mi, ptr64[d0 + 72]);
				}
			}
			i0 = i0 + 1;
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
		tc_cur_mod = mi;
		tc_cur_imports = 0;
		if (m2 != 0) { tc_cur_imports = ptr64[m2 + 24]; }

		var env = tc_env_new();
		if (env == 0) { return 1; }

		var decls = 0;
		if (prog2 != 0) { decls = ptr64[prog2 + 0]; }
		var n = 0;
		if (decls != 0) { n = vec_len(decls); }
		var i = 0;
		while (i < n) {
			var d = vec_get(decls, i);
			if (d == 0) { i = i + 1; continue; }
			var k = ptr64[d + 0];
			if (k == AstDeclKind.VAR || k == AstDeclKind.CONST) {
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
				// New scope for each function.
				var saved = vec_len(env);
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
				var body = ptr64[d + 40];
				if (body != 0) {
					tc_stmt(env, body);
				}
				ptr64[env + 8] = saved;
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
		var prs = heap_alloc(32);
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
