// v3_hosted: minimal lowering + x86-64 codegen (Phase 1.5)

import vec;
import slice;
import string_builder;

import v3_hosted.ast;
import v3_hosted.token;
import v3_hosted.ir;
import v3_hosted.typecheck;

// Phase 6.7: Temporary global for function pointer calls (to survive function calls)
var cg_fptr_arg_bytes;
var cg_fptr_ctx;
var cg_fptr_offset;
var cg_fptr_local;
// Phase 6.7: Also save call name for regular function calls
var cg_call_name_ptr;
var cg_call_name_len;
var cg_call_decl;
var cg_call_args;

struct CgLocal {
	name_ptr: u64;
	name_len: u64;
	offset: u64; // [rbp-offset]
	size_bytes: u64; // low bits=size, high bit may store flags
};

// CgLocal.size_bytes packing
const CG_LOCAL_SIZE_MASK = 9223372036854775807; // (1<<63)-1
const CG_LOCAL_FLAG_NOSPILL = 9223372036854775808; // 1<<63

// CgLocal.offset encoding for register-backed locals.
// offset = CG_LOCAL_OFF_IS_REG | reg_id
// reg_id uses the x86-64 register number (rax=0, rcx=1, rdx=2, rbx=3, rsp=4, rbp=5, rsi=6, rdi=7, r8=8..r15=15)
const CG_LOCAL_OFF_IS_REG = 9223372036854775808; // 1<<63

func cg_local_size_bytes(l) {
	return ptr64[l + 24] & CG_LOCAL_SIZE_MASK;
}

func cg_local_is_slice(l) {
	return (ptr64[l + 24] & CG_LOCAL_SIZE_MASK) == 24;
}

func cg_local_has_nospill(l) {
	return (ptr64[l + 24] & CG_LOCAL_FLAG_NOSPILL) != 0;
}

func cg_local_mark_nospill(l) {
	ptr64[l + 24] = ptr64[l + 24] | CG_LOCAL_FLAG_NOSPILL;
	return 0;
}

func cg_local_off_is_reg(off) {
	return (off & CG_LOCAL_OFF_IS_REG) != 0;
}

func cg_local_off_reg_id(off) {
	return off & 255;
}

func cg_local_off_pack_reg(reg_id) {
	return CG_LOCAL_OFF_IS_REG | (reg_id & 255);
}

struct CodegenCtx {
	prog: u64; // IrProgram*
	fn: u64; // IrFunc*
	locals: u64; // Vec of CgLocal*
	label_next: u64;
	ret_label: u64;
	secret_locals: u64; // Vec of CgLocal* (len is mutated via ptr64)
	ast_prog: u64; // AstProgram*
	ret_reg: u64; // x86 reg id (0=rax)
	loop_start_stack: u64; // Vec of label ids
	loop_end_stack: u64; // Vec of label ids
	switch_end_stack: u64; // Vec of label ids
	loop_depth: u64; // Current loop nesting depth
};

// AstDecl.decl_flags (keep in sync with parser/typecheck)
const CG_DECL_FLAG_EXTERN = 1;
const CG_DECL_RETREG_SHIFT = 8;

func cg_decl_retreg(d) {
	return (ptr64[d + 80] >> CG_DECL_RETREG_SHIFT) & 255;
}

func cg_decl_is_extern(d) {
	return (ptr64[d + 80] & CG_DECL_FLAG_EXTERN) != 0;
}

func cg_ast_find_func_decl(ast_prog, name_ptr, name_len) {
	if (ast_prog == 0) { return 0; }
	var decls = ptr64[ast_prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			if (cg_slice_eq(ptr64[d + 8], ptr64[d + 16], name_ptr, name_len) == 1) { return d; }
		}
		i = i + 1;
	}
	return 0;
}

func cg_ast_find_struct_decl(ast_prog, name_ptr, name_len) {
	if (ast_prog == 0) { return 0; }
	if (name_ptr == 0) { return 0; }
	if (name_len == 0) { return 0; }
	var decls = ptr64[ast_prog + 0];
	if (decls == 0) { return 0; }
	var n = vec_len(decls);
	var i = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.STRUCT) {
			var dname_ptr = ptr64[d + 8];
			var dname_len = ptr64[d + 16];
			if (dname_ptr != 0 && dname_len != 0) {
				if (cg_slice_eq(dname_ptr, dname_len, name_ptr, name_len) == 1) { return d; }
			}
		}
		i = i + 1;
	}
	return 0;
}

func cg_struct_size_bytes(ast_prog, sd) {
	// Calculate struct size from field count. Assume all fields are 8 bytes (MVP).
	if (sd == 0) { return 8; }
	var fields = ptr64[sd + 24];
	if (fields == 0) { return 8; }
	var nf = vec_len(fields);
	if (nf == 0) { return 8; }
	return nf * 8;
}

func cg_type_size_bytes_prog(ast_prog, t) {
	if (t == 0) { return 8; }
	if (ast_prog == 0) { return 8; }
	// Guard against invalid pointer - check if t looks like a valid heap pointer
	if (t < 4096) { return 8; }
	var tkind = ptr64[t + 0];
	if (tkind == AstTypeKind.PTR) { return 8; }
	if (tkind == AstTypeKind.SLICE) { return 24; }
	if (tkind == AstTypeKind.NAME) {
		var tname_ptr = ptr64[t + 8];
		var tname_len = ptr64[t + 16];
		if (tname_ptr == 0 || tname_len == 0) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "str", 3) == 1) { return 24; }
		if (cg_slice_eq(tname_ptr, tname_len, "u8", 2) == 1) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "i8", 2) == 1) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "u64", 3) == 1) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "i64", 3) == 1) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "bool", 4) == 1) { return 8; }
		if (cg_slice_eq(tname_ptr, tname_len, "char", 4) == 1) { return 8; }
		// Check if it's a struct type
		var sd = cg_ast_find_struct_decl(ast_prog, tname_ptr, tname_len);
		if (sd != 0) {
			return cg_struct_size_bytes(ast_prog, sd);
		}
		return 8;
	}
	return 8;
}

// Check if a function returns a struct (needs sret)
func cg_func_returns_struct(ast_prog, decl) {
	if (decl == 0) { return 0; }
	var ret_type = ptr64[decl + 32];
	if (ret_type == 0) { return 0; }
	var sz = cg_type_size_bytes_prog(ast_prog, ret_type);
	if (sz > 8 && sz != 24) { return sz; }
	return 0;
}

func cg_wipe_scratch_ptr_local(ctx) {
	return cg_local_find(ctx, "__v3h_wipe_ptr", 14);
}

func cg_wipe_scratch_len_local(ctx) {
	return cg_local_find(ctx, "__v3h_wipe_len", 14);
}

func cg_emit_wipe_loop(ctx, ptr_off, len_off) {
	var f = ptr64[ctx + 8];
	var start_id = cg_label_alloc(ctx);
	var end_id = cg_label_alloc(ctx);
	ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);
	// if len == 0: break
	ir_emit(f, IrInstrKind.PUSH_LOCAL, len_off, 0, 0);
	ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);
	// *ptr = 0 (secure)
	ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr_off, 0, 0);
	ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
	ir_emit(f, IrInstrKind.SECURE_STORE_MEM8, 0, 0, 0);
	// ptr++
	ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr_off, 0, 0);
	ir_emit(f, IrInstrKind.PUSH_IMM, 1, 0, 0);
	ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
	ir_emit(f, IrInstrKind.STORE_LOCAL, ptr_off, 0, 0);
	// len--
	ir_emit(f, IrInstrKind.PUSH_LOCAL, len_off, 0, 0);
	ir_emit(f, IrInstrKind.PUSH_IMM, 1, 0, 0);
	ir_emit(f, IrInstrKind.BINOP, TokKind.MINUS, 0, 0);
	ir_emit(f, IrInstrKind.STORE_LOCAL, len_off, 0, 0);
	ir_emit(f, IrInstrKind.JMP, start_id, 0, 0);
	ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
	return 0;
}

func cg_emit_wipe_local(ctx, l) {
	if (l == 0) { return 0; }
	var f = ptr64[ctx + 8];
	var l_ptr = cg_wipe_scratch_ptr_local(ctx);
	var l_len = cg_wipe_scratch_len_local(ctx);
	if (l_ptr == 0 || l_len == 0) { return 0; }
	// ptr = &local
	ir_emit(f, IrInstrKind.PUSH_LOCAL_ADDR, ptr64[l + 16], 0, 0);
	ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_ptr + 16], 0, 0);
	// len = size_bytes
	ir_emit(f, IrInstrKind.PUSH_IMM, cg_local_size_bytes(l), 0, 0);
	ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_len + 16], 0, 0);
	cg_emit_wipe_loop(ctx, ptr64[l_ptr + 16], ptr64[l_len + 16]);
	return 0;
}

func cg_parse_u64_dec(p, n) {
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

// Phase 6.6: Parse floating-point literal and return IEEE 754 bit pattern.
// MVP: Very simple approximation for common cases.
// Returns f64 bit pattern. is_f32 is output via rdx alias.
func cg_parse_float_literal(p, n) {
	var i = 0;
	var int_part = 0;
	var frac_part = 0;
	var frac_digits = 0;
	var is_f32 = 0;

	// Integer part
	while (i < n) {
		var ch = ptr8[p + i];
		if (ch < 48 || ch > 57) { break; }
		int_part = int_part * 10 + (ch - 48);
		i = i + 1;
	}

	// Fractional part
	if (i < n && ptr8[p + i] == 46) {
		i = i + 1;
		while (i < n) {
			var ch2 = ptr8[p + i];
			if (ch2 < 48 || ch2 > 57) { break; }
			frac_part = frac_part * 10 + (ch2 - 48);
			frac_digits = frac_digits + 1;
			i = i + 1;
		}
	}

	// Skip exponent for MVP
	// f suffix
	while (i < n) {
		var c = ptr8[p + i];
		if (c == 102) { is_f32 = 1; }
		i = i + 1;
	}

	// MVP: Store raw bits as immediate value
	// For float support we just push the literal bits onto the stack.
	// This is a placeholder - real float support needs proper IEEE encoding.
	// For now, just return (int_part * 1000 + frac_part) as a simple encoding.
	var result = int_part;
	result = result << 32;
	result = result | frac_part;

	alias rdx : out_f32_2;
	out_f32_2 = is_f32;
	return result;
}

func cg_slice_eq(a_ptr, a_len, b_ptr, b_len) {
	return slice_eq(a_ptr, a_len, b_ptr, b_len);
}

func cg_is_discard_ident(name_ptr, name_len) {
	return cg_slice_eq(name_ptr, name_len, "_", 1);
}

func cg_tmp_name(prefix, prefix_len, id) {
	// Returns: rax=ptr (NUL-terminated), rdx=len
	var sb = sb_new(32);
	if (sb == 0) {
		alias rdx : out_len0;
		out_len0 = 0;
		return 0;
	}
	sb_append_bytes(sb, prefix, prefix_len);
	sb_append_u64_dec(sb, id);
	alias rdx : out_len;
	out_len = sb_len(sb);
	return sb_ptr(sb);
}

func cg_local_find(ctx, name_ptr, name_len) {
	// Reverse search for shadowing support: finds the most recently added binding
	if (name_ptr == 0) { return 0; }
	if (name_len == 0) { return 0; }
	var locals = ptr64[ctx + 16];
	if (locals == 0) { return 0; }
	var n = vec_len(locals);
	while (n != 0) {
		n = n - 1;
		var l = vec_get(locals, n);
		if (l != 0) {
			if (cg_slice_eq(ptr64[l + 0], ptr64[l + 8], name_ptr, name_len) == 1) {
				return l;
			}
		}
	}
	return 0;
}

// Push struct fields onto stack for by-value passing
// Returns 1 if successful, 0 if fallback needed
func cg_lower_struct_arg(ctx, e, sz) {
	if (e == 0) { return 0; }
	if (ptr64[e + 0] != AstExprKind.IDENT) { return 0; }
	var f = ptr64[ctx + 8];
	var name_ptr = ptr64[e + 40];
	var name_len = ptr64[e + 48];
	if (name_ptr == 0) { return 0; }
	if (name_len == 0) { return 0; }
	var l = cg_local_find(ctx, name_ptr, name_len);
	if (l == 0) { return 0; }
	var off = ptr64[l + 16];
	var nq = sz / 8;
	var qi = nq;
	while (qi != 0) {
		qi = qi - 1;
		ir_emit(f, IrInstrKind.PUSH_LOCAL, off - qi * 8, 0, 0);
	}
	return 1;
}

func cg_local_add(ctx, name_ptr, name_len) {
	var locals = ptr64[ctx + 16];
	// Shadowing: always add new local (no duplicate check)
	var l = heap_alloc(32);
	if (l == 0) { return 0; }
	ptr64[l + 0] = name_ptr;
	ptr64[l + 8] = name_len;
	ptr64[l + 16] = 0;
	ptr64[l + 24] = 8;
	vec_push(locals, l);
	// Update max_locals_len (high water mark for stack frame calculation)
	var cur_len = vec_len(locals);
	var max_len = ptr64[ctx + 104];
	if (cur_len > max_len) { ptr64[ctx + 104] = cur_len; }
	return l;
}

func cg_local_set_size_bytes(l, size_bytes) {
	// Only grow (collection may see partial info before typecheck-style inference).
	var cur = ptr64[l + 24];
	var flags = cur & (~CG_LOCAL_SIZE_MASK);
	var cur_sz = cur & CG_LOCAL_SIZE_MASK;
	if (cur_sz < size_bytes) {
		ptr64[l + 24] = flags | size_bytes;
	}
	return 0;
}

func cg_local_mark_slice(l) {
	// Distinguish slice locals from same-sized structs (e.g. two u64 fields).
	// Layout uses only the first 16 bytes: ptr at base, len at base-8.
	cg_local_set_size_bytes(l, 24);
	return 0;
}

func cg_type_is_slice_u8(t) {
	if (t == 0) { return 0; }
	// Optional alias: `str` == `[]u8`.
	if (ptr64[t + 0] == AstTypeKind.NAME) {
		return cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "str", 3);
	}
	if (ptr64[t + 0] != AstTypeKind.SLICE) { return 0; }
	var inner = ptr64[t + 8];
	if (inner == 0) { return 0; }
	if (ptr64[inner + 0] != AstTypeKind.NAME) { return 0; }
	return cg_slice_eq(ptr64[inner + 8], ptr64[inner + 16], "u8", 2);
}

func cg_expr_is_slice(ctx, e) {
	if (e == 0) { return 0; }
	var k = ptr64[e + 0];
	if (k == AstExprKind.STRING) { return 1; }
	if (k == AstExprKind.FIELD) {
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		return sz == 16;
	}
	if (k == AstExprKind.IDENT) {
		var name_ptr = ptr64[e + 40];
		var name_len = ptr64[e + 48];
		var l = cg_local_find(ctx, name_ptr, name_len);
		if (l == 0) { return 0; }
		return cg_local_is_slice(l);
	}
	if (k == AstExprKind.CALL) {
		var callee = ptr64[e + 16];
		if (ptr64[callee + 0] == AstExprKind.IDENT) {
			var name_ptr2 = ptr64[callee + 40];
			var name_len2 = ptr64[callee + 48];
			if (cg_slice_eq(name_ptr2, name_len2, "slice_from_ptr_len", 18) == 1) {
				return 1;
			}
		}
	}
	return 0;
}

func cg_type_size_bytes(t) {
	// Conservative size inference for locals/params.
	// Keep this minimal: enough for current codegen golden suite.
	if (t == 0) { return 8; }
	if (ptr64[t + 0] == AstTypeKind.PTR) { return 8; }
	if (ptr64[t + 0] == AstTypeKind.SLICE) { return 24; }
	if (ptr64[t + 0] == AstTypeKind.NAME) {
		// Optional alias: `str` == `[]u8`.
		if (cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "str", 3) == 1) { return 24; }
		// Scalars
		if (cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "u8", 2) == 1) { return 8; }
		if (cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "i8", 2) == 1) { return 8; }
		if (cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "bool", 4) == 1) { return 8; }
		if (cg_slice_eq(ptr64[t + 8], ptr64[t + 16], "char", 4) == 1) { return 8; }
		return 8;
	}
	return 8;
}

func cg_label_alloc(ctx) {
	var id = ptr64[ctx + 24];
	ptr64[ctx + 24] = id + 1;
	return id;
}

// Phase 3.5: default property hook synthesis.
// If a struct field is annotated with @[getter]/@[setter] and no explicit
// target function is provided, lowering emits calls to:
//   Struct_get_field(self*) / Struct_set_field(self*, v)
// This creates small IR functions to satisfy those symbols.

func cg_ir_prog_has_func(irp0, name_ptr0, name_len0) {
	var fv = ptr64[irp0 + 0];
	var fnn = 0;
	if (fv != 0) { fnn = vec_len(fv); }
	var fi2 = 0;
	while (fi2 < fnn) {
		var f0 = vec_get(fv, fi2);
		if (f0 != 0) {
			if (cg_slice_eq(ptr64[f0 + 0], ptr64[f0 + 8], name_ptr0, name_len0) == 1) { return 1; }
		}
		fi2 = fi2 + 1;
	}
	return 0;
}

func cg_ast_has_func(ast_prog0, name_ptr0, name_len0) {
	var decls0 = ptr64[ast_prog0 + 0];
	var dn0 = 0;
	if (decls0 != 0) { dn0 = vec_len(decls0); }
	var di0 = 0;
	while (di0 < dn0) {
		var d0 = vec_get(decls0, di0);
		if (d0 != 0 && ptr64[d0 + 0] == AstDeclKind.FUNC) {
			if (cg_slice_eq(ptr64[d0 + 8], ptr64[d0 + 16], name_ptr0, name_len0) == 1) { return 1; }
		}
		di0 = di0 + 1;
	}
	return 0;
}

func cg_build_hook_name(struct_ty0, field_meta0, is_set0) {
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

func cg_emit_default_getter(ctx0, irp0, name_ptr0, name_len0, off0, size0) {
	var fn0 = ir_func_new(name_ptr0, name_len0);
	if (fn0 == 0) { return 0; }
	ptr64[fn0 + 16] = 0;
	ptr64[fn0 + 24] = cg_label_alloc(ctx0);
	// addr = self + off
	ir_emit(fn0, IrInstrKind.PUSH_ARG, 16, 0, 0);
	ir_emit(fn0, IrInstrKind.PUSH_IMM, off0, 0, 0);
	ir_emit(fn0, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
	if (size0 == 1) { ir_emit(fn0, IrInstrKind.LOAD_MEM8, 0, 0, 0); }
	else { ir_emit(fn0, IrInstrKind.LOAD_MEM64, 0, 0, 0); }
	ir_emit(fn0, IrInstrKind.RET, 0, 0, 0);
	vec_push(ptr64[irp0 + 0], fn0);
	return 0;
}

func cg_emit_default_setter(ctx0, irp0, name_ptr0, name_len0, off0, size0) {
	var fn0 = ir_func_new(name_ptr0, name_len0);
	if (fn0 == 0) { return 0; }
	ptr64[fn0 + 16] = 0;
	ptr64[fn0 + 24] = cg_label_alloc(ctx0);
	// addr = self + off
	ir_emit(fn0, IrInstrKind.PUSH_ARG, 16, 0, 0);
	ir_emit(fn0, IrInstrKind.PUSH_IMM, off0, 0, 0);
	ir_emit(fn0, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
	// store v
	ir_emit(fn0, IrInstrKind.PUSH_ARG, 24, 0, 0);
	if (size0 == 1) { ir_emit(fn0, IrInstrKind.STORE_MEM8, 0, 0, 0); }
	else { ir_emit(fn0, IrInstrKind.STORE_MEM64, 0, 0, 0); }
	// return v
	ir_emit(fn0, IrInstrKind.PUSH_ARG, 24, 0, 0);
	ir_emit(fn0, IrInstrKind.RET, 0, 0, 0);
	vec_push(ptr64[irp0 + 0], fn0);
	return 0;
}

func cg_emit_default_property_hooks(ast_prog, ctx, irp) {
	if (tc_structs == 0) { return 0; }
	var tsn = vec_len(tc_structs);
	var tsi = 0;
	while (tsi < tsn) {
		var st = vec_get(tc_structs, tsi);
		if (st != 0 && ptr64[st + 0] == TC_COMPOUND_STRUCT) {
			var fields0 = ptr64[st + 24];
			var fnn0 = 0;
			if (fields0 != 0) { fnn0 = vec_len(fields0); }
			var fi0 = 0;
			while (fi0 < fnn0) {
				var fm = vec_get(fields0, fi0);
				if (fm != 0) {
					var fattr0 = ptr64[fm + 40];
					var off0 = ptr64[fm + 24];
					var fty0 = ptr64[fm + 16];
					var size0 = tc_sizeof(fty0);
					// default getter
						var has_getter = fattr0 & 1;
						if (has_getter != 0) {
						var gptr = ptr64[fm + 48];
						var glen = ptr64[fm + 56];
						if (gptr == 0 || glen == 0) {
							cg_build_hook_name(st, fm, 0);
							alias rdx : glen2;
							gptr = rax;
							glen = glen2;
							if (gptr != 0 && glen != 0) {
								if (cg_ast_has_func(ast_prog, gptr, glen) == 0 && cg_ir_prog_has_func(irp, gptr, glen) == 0) {
									if (size0 == 1 || size0 == 8) { cg_emit_default_getter(ctx, irp, gptr, glen, off0, size0); }
								}
							}
						}
					}
					// default setter
						var has_setter = fattr0 & 2;
						if (has_setter != 0) {
						var sptr = ptr64[fm + 64];
						var slen = ptr64[fm + 72];
						if (sptr == 0 || slen == 0) {
							cg_build_hook_name(st, fm, 1);
							alias rdx : slen2;
							sptr = rax;
							slen = slen2;
							if (sptr != 0 && slen != 0) {
								if (cg_ast_has_func(ast_prog, sptr, slen) == 0 && cg_ir_prog_has_func(irp, sptr, slen) == 0) {
									if (size0 == 1 || size0 == 8) { cg_emit_default_setter(ctx, irp, sptr, slen, off0, size0); }
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

func cg_rodata_add_string(prog, bytes_ptr, bytes_len) {
	// Dedup exact bytes
	var rdv = ptr64[prog + 8];
	var n = vec_len(rdv);
	var i = 0;
	while (i < n) {
		var r = vec_get(rdv, i);
		if (ptr64[r + 8] == bytes_len) {
			if (slice_eq(ptr64[r + 0], bytes_len, bytes_ptr, bytes_len) == 1) {
				return r;
			}
		}
		i = i + 1;
	}

	var r = heap_alloc(24);
	if (r == 0) { return 0; }
	ptr64[r + 0] = bytes_ptr;
	ptr64[r + 8] = bytes_len;
	ptr64[r + 16] = n;
	vec_push(rdv, r);
	return r;
}

// We avoid globals by returning a tiny struct on heap: {ptr,len}
struct Bytes {
	ptr: u64;
	len: u64;
};

func cg_decode_string_literal(tok_ptr, tok_len) {
	// Token slice includes quotes.
	if (tok_len < 2) { return 0; }
	var out = heap_alloc(16);
	if (out == 0) { return 0; }

	// Worst-case length <= tok_len-2 (escapes shrink), allocate that.
	var cap = tok_len - 2;
	var buf = heap_alloc(cap);
	if (buf == 0) { return 0; }

	var i = 1;
	var o = 0;
	while (i + 1 < tok_len) {
		var ch = ptr8[tok_ptr + i];
		if (ch != 92) {
			ptr8[buf + o] = ch;
			o = o + 1;
			i = i + 1;
			continue;
		}
		// escape
		if (i + 2 >= tok_len) { break; }
		var esc = ptr8[tok_ptr + i + 1];
		var v = 0;
		if (esc == 110) { v = 10; }
		else if (esc == 116) { v = 9; }
		else if (esc == 114) { v = 13; }
		else if (esc == 48) { v = 0; }
		else if (esc == 92) { v = 92; }
		else if (esc == 34) { v = 34; }
		else { v = esc; }
		ptr8[buf + o] = v;
		o = o + 1;
		i = i + 2;
	}

	ptr64[out + 0] = buf;
	ptr64[out + 8] = o;
	return out;
}

func cg_collect_locals_in_stmt(ctx, st) {
	var k = ptr64[st + 0];
	if (k == AstStmtKind.VAR) {
		var flags0 = ptr64[st + 8];
		var name_ptr = ptr64[st + 32];
		var name_len = ptr64[st + 40];
		var l = cg_local_add(ctx, name_ptr, name_len);
		// Store local pointer in AST for lower phase (shadowing support)
		ptr64[st + 88] = l;
		var is_nospill = flags0 & 2; // TC_STMT_FLAG_NOSPILL
		if (is_nospill != 0) {
			cg_local_mark_nospill(l);
		}
		// If we can determine this is a []u8 local, reserve 16 bytes.
		var t = ptr64[st + 48];
		if (cg_type_is_slice_u8(t) == 1) {
			cg_local_mark_slice(l);
		}
		else {
			// If this is a struct-typed local, reserve its computed size.
			if (t != 0) {
				if (ptr64[t + 0] == AstTypeKind.NAME) {
					var tn_ptr = ptr64[t + 8];
					var tn_len = ptr64[t + 16];
					var sty = tc_struct_lookup(tn_ptr, tn_len);
					if (sty != 0) {
						var sz = tc_sizeof(sty);
						if (sz != 0) { cg_local_set_size_bytes(l, sz); }
					}
				}
			}

			var init = ptr64[st + 56];
			if (init != 0) {
				if (cg_expr_is_slice(ctx, init) == 1) {
					cg_local_mark_slice(l);
				}
			}
		}
		return 0;
	}
	if (k == AstStmtKind.BLOCK) {
		// Collect all locals in nested blocks (no truncate here -
		// we need all locals for stack frame size calculation)
		var ss = ptr64[st + 8];
		var n = vec_len(ss);
		var i = 0;
		while (i < n) {
			cg_collect_locals_in_stmt(ctx, vec_get(ss, i));
			i = i + 1;
		}
		return 0;
	}
	if (k == AstStmtKind.IF) {
		cg_collect_locals_in_stmt(ctx, ptr64[st + 16]);
		var els = ptr64[st + 24];
		if (els != 0) { cg_collect_locals_in_stmt(ctx, els); }
		return 0;
	}
	if (k == AstStmtKind.WHILE) {
		cg_collect_locals_in_stmt(ctx, ptr64[st + 16]);
		return 0;
	}
	if (k == AstStmtKind.FOREACH) {
		var bind = ptr64[st + 8];
		if (bind != 0) {
			var name0_ptr = ptr64[bind + 0];
			var name0_len = ptr64[bind + 8];
			var name1_ptr = ptr64[bind + 16];
			var name1_len = ptr64[bind + 24];
			var has_two = ptr64[bind + 32];

			// foreach bindings become locals.
			if (has_two == 1) {
				if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
					var l0 = cg_local_add(ctx, name0_ptr, name0_len);
					ptr64[st + 56] = l0;  // store idx binding local in FOREACH st
				}
				if (cg_is_discard_ident(name1_ptr, name1_len) == 0) {
					var l1 = cg_local_add(ctx, name1_ptr, name1_len);
					ptr64[st + 88] = l1;  // store val binding local in FOREACH st
				}
			} else {
				if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
					var l0 = cg_local_add(ctx, name0_ptr, name0_len);
					ptr64[st + 56] = l0;  // store binding local in FOREACH st
				}
			}
		}

		// Per-foreach internal locals (unique by start_off).
		var id = ptr64[st + 64];
		alias rdx : n_reg;
		var p_i = cg_tmp_name("__foreach_i_", 12, id);
		var n_i = n_reg;
		var l_i = cg_local_add(ctx, p_i, n_i);
		ptr64[st + 32] = l_i;  // store __foreach_i_ local
		var p_ptr = cg_tmp_name("__foreach_ptr_", 14, id);
		var n_ptr = n_reg;
		var l_ptr = cg_local_add(ctx, p_ptr, n_ptr);
		ptr64[st + 40] = l_ptr;  // store __foreach_ptr_ local
		var p_len = cg_tmp_name("__foreach_len_", 14, id);
		var n_len = n_reg;
		var l_len = cg_local_add(ctx, p_len, n_len);
		ptr64[st + 48] = l_len;  // store __foreach_len_ local

		cg_collect_locals_in_stmt(ctx, ptr64[st + 24]);
		return 0;
	}
	if (k == AstStmtKind.FOR) {
		var init0 = ptr64[st + 8];
		var body0 = ptr64[st + 56];
		if (init0 != 0) { cg_collect_locals_in_stmt(ctx, init0); }
		if (body0 != 0) { cg_collect_locals_in_stmt(ctx, body0); }
		return 0;
	}
	if (k == AstStmtKind.SWITCH) {
		var cases0 = ptr64[st + 16];
		var default0 = ptr64[st + 24];
		if (cases0 != 0) {
			var n0 = vec_len(cases0);
			var i0 = 0;
			while (i0 < n0) {
				var c0 = vec_get(cases0, i0);
				if (c0 != 0) {
					var body0 = ptr64[c0 + 8];
					if (body0 != 0) { cg_collect_locals_in_stmt(ctx, body0); }
				}
				i0 = i0 + 1;
			}
		}
		if (default0 != 0) { cg_collect_locals_in_stmt(ctx, default0); }
		return 0;
	}
	return 0;
}

func cg_foreach_tmp_local(ctx, st, prefix, prefix_len) {
	var id = ptr64[st + 64];
	var p = cg_tmp_name(prefix, prefix_len, id);
	alias rdx : n;
	return cg_local_find(ctx, p, n);
}

func cg_lower_lvalue_addr(ctx, e) {
	if (e == 0) { return 0; }
	var ek = ptr64[e + 0];
	var f = ptr64[ctx + 8];
	if (ek == AstExprKind.IDENT) {
		var name_ptr = ptr64[e + 40];
		var name_len = ptr64[e + 48];
		var l = cg_local_find(ctx, name_ptr, name_len);
		if (l == 0) { return 0; }
		ir_emit(f, IrInstrKind.PUSH_LOCAL_ADDR, ptr64[l + 16], 0, 0);
		return 1;
	}
	if (ek == AstExprKind.FIELD) {
		var base = ptr64[e + 16];
		var off = ptr64[e + 8];
		var extra = ptr64[e + 32];
		var via_ptr = (extra >> 63) & 1;
		if (via_ptr == 0) {
			if (cg_lower_lvalue_addr(ctx, base) == 0) { return 0; }
			ir_emit(f, IrInstrKind.PUSH_IMM, off, 0, 0);
				// Stack locals are contiguous; compute addr = base + off.
				ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
			return 1;
		}
		// pointer base: addr = ptr + off
		cg_lower_expr(ctx, base);
		ir_emit(f, IrInstrKind.PUSH_IMM, off, 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
		return 1;
	}
	return 0;
}

func cg_lower_struct_copy_locals(ctx, dst, src, size_bytes) {
	var f = ptr64[ctx + 8];
	var off = 0;
	while (off < size_bytes) {
		// Copy qword at [rbp-(base_off+off)]. base_off is the start; higher words use smaller offset.
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[src + 16] - off, 0, 0);
		ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[dst + 16] - off, 0, 0);
		off = off + 8;
	}
	return 0;
}

func cg_lower_expr(ctx, e) {
	var ek = ptr64[e + 0];
	var f = ptr64[ctx + 8];

	if (ek == AstExprKind.INT) {
		var v = cg_parse_u64_dec(ptr64[e + 40], ptr64[e + 48]);
		ir_emit(f, IrInstrKind.PUSH_IMM, v, 0, 0);
		return 0;
	}

	// Phase 6.6: floating-point literal
	if (ek == AstExprKind.FLOAT) {
		var bits = cg_parse_float_literal(ptr64[e + 40], ptr64[e + 48]);
		alias rdx : is_f32;
		// For now, push as immediate (same as INT but will be loaded into XMM)
		if (is_f32 == 1) {
			ir_emit(f, IrInstrKind.PUSH_IMM_F32, bits, 0, 0);
		} else {
			ir_emit(f, IrInstrKind.PUSH_IMM_F64, bits, 0, 0);
		}
		return 0;
	}

	if (ek == AstExprKind.OFFSETOF) {
		// Typecheck stores computed offset in e->op.
		ir_emit(f, IrInstrKind.PUSH_IMM, ptr64[e + 8], 0, 0);
		return 0;
	}

	if (ek == AstExprKind.FIELD) {
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		var raw = (extra >> 55) & 1;
		var hook = (extra >> 54) & 1;
		if (sz == 127) {
			// enum member constant; typecheck stores value in op.
			ir_emit(f, IrInstrKind.PUSH_IMM, ptr64[e + 8], 0, 0);
			return 0;
		}
		// Phase 3.5: property hooks. If hooked and not raw, lower to call.
		if (hook == 1 && raw == 0) {
			var rec = ptr64[e + 24];
			if (rec != 0) {
				var struct_ty = ptr64[rec + 0];
				var field_meta = ptr64[rec + 8];
				if (struct_ty != 0 && field_meta != 0) {
					var fattr = ptr64[field_meta + 40];
					var ga = fattr & 1;
					if (ga != 0) {
						// Build callee name: custom if provided else Struct_get_field.
						var callee_ptr = ptr64[field_meta + 48];
						var callee_len = ptr64[field_meta + 56];
						var callee_auto = 0;
						if (callee_ptr == 0 || callee_len == 0) {
							callee_auto = 1;
							var sn_ptr = ptr64[struct_ty + 8];
							var sn_len = ptr64[struct_ty + 16];
							var fn_ptr = ptr64[field_meta + 0];
							var fn_len = ptr64[field_meta + 8];
							var out_len = sn_len + 5 + fn_len;
							var out_ptr = heap_alloc(out_len);
							if (out_ptr != 0) {
								var i = 0;
								while (i < sn_len) { ptr8[out_ptr + i] = ptr8[sn_ptr + i]; i = i + 1; }
								ptr8[out_ptr + sn_len + 0] = 95; // '_'
								ptr8[out_ptr + sn_len + 1] = 103; // 'g'
								ptr8[out_ptr + sn_len + 2] = 101; // 'e'
								ptr8[out_ptr + sn_len + 3] = 116; // 't'
								ptr8[out_ptr + sn_len + 4] = 95; // '_'
								var j = 0;
								while (j < fn_len) { ptr8[out_ptr + sn_len + 5 + j] = ptr8[fn_ptr + j]; j = j + 1; }
								callee_ptr = out_ptr;
								callee_len = out_len;
							}
						}
						// Ensure the autogenerated hook body exists in IR.
						if (callee_auto == 1 && callee_ptr != 0 && callee_len != 0) {
							var irp0 = ptr64[ctx + 0];
							if (cg_ir_prog_has_func(irp0, callee_ptr, callee_len) == 0) {
								var off0 = ptr64[field_meta + 24];
								var fty0 = ptr64[field_meta + 16];
								var size0 = tc_sizeof(fty0);
								if (size0 == 1 || size0 == 8) { cg_emit_default_getter(ctx, irp0, callee_ptr, callee_len, off0, size0); }
							}
						}
						// arg0: &base (for dot) or base pointer (for arrow)
						var via_ptr = (extra >> 63) & 1;
						var base = ptr64[e + 16];
						if (via_ptr == 1) { cg_lower_expr(ctx, base); }
						else {
							if (cg_lower_lvalue_addr(ctx, base) == 0) {
								ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
								return 0;
							}
						}
						ir_emit(f, IrInstrKind.CALL, callee_ptr, callee_len, 8);
						return 0;
					}
				}
			}
			// If we couldn't build a call, fall through to normal access.
		}
		if (sz == 0) {
			ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			return 0;
		}
		if (sz == 1) {
			if (cg_lower_lvalue_addr(ctx, e) == 0) {
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			ir_emit(f, IrInstrKind.LOAD_MEM8, 0, 0, 0);
			return 0;
		}
		if (sz == 8) {
			if (cg_lower_lvalue_addr(ctx, e) == 0) {
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			ir_emit(f, IrInstrKind.LOAD_MEM64, 0, 0, 0);
			return 0;
		}
		if (sz == 16) {
			// slice {ptr,len}
			if (cg_lower_lvalue_addr(ctx, e) == 0) {
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			ir_emit(f, IrInstrKind.LOAD_MEM64, 0, 0, 0);
			if (cg_lower_lvalue_addr(ctx, e) == 0) {
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			ir_emit(f, IrInstrKind.PUSH_IMM, 8, 0, 0);
			ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
			ir_emit(f, IrInstrKind.LOAD_MEM64, 0, 0, 0);
			return 0;
		}
		// Fallback
		ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.IDENT) {
		var name_ptr = ptr64[e + 40];
		var name_len = ptr64[e + 48];
		var l = cg_local_find(ctx, name_ptr, name_len);
		if (l == 0) {
			// Phase 6.7: Check if identifier is a function name (for function pointer)
			if (cg_ast_has_func(ptr64[ctx + 48], name_ptr, name_len) == 1) {
				// Emit load of function address (lea)
				ir_emit(f, IrInstrKind.PUSH_FUNC_ADDR, name_ptr, name_len, 0);
				return 0;
			}
			// Unresolved ident: leave 0
			ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			return 0;
		}
		if (cg_local_is_slice(l) == 1) {
			// slice value: {ptr,len}
			ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
			ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16] - 8, 0, 0);
			return 0;
		}
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
		return 0;
	}

	if (ek == AstExprKind.CAST) {
		// Ignore type; lower inner
		cg_lower_expr(ctx, ptr64[e + 24]);
		return 0;
	}

	if (ek == AstExprKind.UNARY) {
		var op = ptr64[e + 8];
		var rhs = ptr64[e + 16];
		if (op == TokKind.AMP) {
			if (cg_lower_lvalue_addr(ctx, rhs) == 0) {
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			}
			return 0;
		}
		if (op == TokKind.DOLLAR) {
			// Phase 4.1: unsafe deref/load.
			cg_lower_expr(ctx, rhs);
			var sz = ptr64[e + 32];
			if (sz == 1) { ir_emit(f, IrInstrKind.LOAD_MEM8, 0, 0, 0); }
			else if (sz == 8) { ir_emit(f, IrInstrKind.LOAD_MEM64, 0, 0, 0); }
			else {
				// Unsupported load size.
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			}
			return 0;
		}
		// Postfix ++ / -- (Phase 6.1): increment/decrement and return new value.
		// Note: true postfix semantics (return old value) would require DUP or temp storage.
		// For now, implement as prefix for simplicity.
		if (op == TokKind.PLUSPLUS || op == TokKind.MINUSMINUS) {
			// Read current value.
			cg_lower_expr(ctx, rhs);
			// Increment/decrement.
			ir_emit(f, IrInstrKind.PUSH_IMM, 1, 0, 0);
			if (op == TokKind.PLUSPLUS) {
				ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
			} else {
				ir_emit(f, IrInstrKind.BINOP, TokKind.MINUS, 0, 0);
			}
			// Store back to lvalue.
			if (ptr64[rhs + 0] == AstExprKind.IDENT) {
				var l = cg_local_find(ctx, ptr64[rhs + 40], ptr64[rhs + 48]);
				if (l != 0) {
					var off = ptr64[l + 16];
					// For simplicity, treat all locals the same: store and reload.
					ir_emit(f, IrInstrKind.STORE_LOCAL, off, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_LOCAL, off, 0, 0);
				} else {
					// Unknown local: just pop and push 0.
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				}
			} else if (ptr64[rhs + 0] == AstExprKind.FIELD) {
				// field store - simplified version: just pop and push 0.
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			} else {
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			}
			return 0;
		}
		cg_lower_expr(ctx, rhs);
		ir_emit(f, IrInstrKind.UNOP, op, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.BINARY) {
		var op = ptr64[e + 8];
		var lhs = ptr64[e + 16];
		var rhs = ptr64[e + 24];
		if (op == TokKind.EQ) {
			// assignment
			if (ptr64[lhs + 0] == AstExprKind.UNARY && ptr64[lhs + 8] == TokKind.DOLLAR) {
				// $ptr = rhs
				var szp = ptr64[lhs + 32];
				if (szp != 1 && szp != 8) {
					// Unsupported store size; evaluate rhs and push 0.
					cg_lower_expr(ctx, rhs);
					if (cg_expr_is_slice(ctx, rhs) == 1) {
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					}
					else { ir_emit(f, IrInstrKind.POP, 0, 0, 0); }
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
				// push addr then value (STORE_MEM* pops value then addr)
				cg_lower_expr(ctx, ptr64[lhs + 16]);
				cg_lower_expr(ctx, rhs);
				if (cg_expr_is_slice(ctx, rhs) == 1) {
					// best-effort discard
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
				if (szp == 1) { ir_emit(f, IrInstrKind.STORE_MEM8, 0, 0, 0); }
				else { ir_emit(f, IrInstrKind.STORE_MEM64, 0, 0, 0); }
				// Return assigned value by re-loading.
				cg_lower_expr(ctx, lhs);
				return 0;
			}
			if (ptr64[lhs + 0] == AstExprKind.FIELD) {
				// field assignment (scalar or u8)
				var extra = ptr64[lhs + 32];
				var raw = (extra >> 55) & 1;
				var hook = (extra >> 54) & 1;
				if (hook == 1 && raw == 0) {
					var rec = ptr64[lhs + 24];
					if (rec != 0) {
						var struct_ty = ptr64[rec + 0];
						var field_meta = ptr64[rec + 8];
						if (struct_ty != 0 && field_meta != 0) {
							var fattr = ptr64[field_meta + 40];
							var sa = fattr & 2;
							if (sa != 0) {
								var callee_ptr = ptr64[field_meta + 64];
								var callee_len = ptr64[field_meta + 72];
									var callee_auto = 0;
								if (callee_ptr == 0 || callee_len == 0) {
										callee_auto = 1;
									var sn_ptr = ptr64[struct_ty + 8];
									var sn_len = ptr64[struct_ty + 16];
									var fn_ptr = ptr64[field_meta + 0];
									var fn_len = ptr64[field_meta + 8];
									var out_len = sn_len + 5 + fn_len;
									var out_ptr = heap_alloc(out_len);
									if (out_ptr != 0) {
										var i = 0;
										while (i < sn_len) { ptr8[out_ptr + i] = ptr8[sn_ptr + i]; i = i + 1; }
										ptr8[out_ptr + sn_len + 0] = 95; // '_'
										ptr8[out_ptr + sn_len + 1] = 115; // 's'
										ptr8[out_ptr + sn_len + 2] = 101; // 'e'
										ptr8[out_ptr + sn_len + 3] = 116; // 't'
										ptr8[out_ptr + sn_len + 4] = 95; // '_'
										var j = 0;
										while (j < fn_len) { ptr8[out_ptr + sn_len + 5 + j] = ptr8[fn_ptr + j]; j = j + 1; }
										callee_ptr = out_ptr;
										callee_len = out_len;
									}
								}
									// Ensure the autogenerated hook body exists in IR.
									if (callee_auto == 1 && callee_ptr != 0 && callee_len != 0) {
										var irp0 = ptr64[ctx + 0];
										if (cg_ir_prog_has_func(irp0, callee_ptr, callee_len) == 0) {
											var off0 = ptr64[field_meta + 24];
											var fty0 = ptr64[field_meta + 16];
											var size0 = tc_sizeof(fty0);
											if (size0 == 1 || size0 == 8) { cg_emit_default_setter(ctx, irp0, callee_ptr, callee_len, off0, size0); }
										}
									}
								// arg1 then arg0 (so arg0 is at rbp+16)
								cg_lower_expr(ctx, rhs);
								if (cg_expr_is_slice(ctx, rhs) == 1) {
									// unsupported setter arg; best-effort discard
									ir_emit(f, IrInstrKind.POP, 0, 0, 0);
									ir_emit(f, IrInstrKind.POP, 0, 0, 0);
									ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
									return 0;
								}
								var via_ptr = (extra >> 63) & 1;
								var base = ptr64[lhs + 16];
								if (via_ptr == 1) { cg_lower_expr(ctx, base); }
								else {
									if (cg_lower_lvalue_addr(ctx, base) == 0) {
										ir_emit(f, IrInstrKind.POP, 0, 0, 0);
										ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
										return 0;
									}
								}
								ir_emit(f, IrInstrKind.CALL, callee_ptr, callee_len, 16);
								return 0;
							}
						}
					}
				}
				var sz = (extra >> 56) & 127;
				if (sz != 1 && sz != 8) {
					// Unsupported field assignment size; evaluate rhs and push 0.
					cg_lower_expr(ctx, rhs);
					if (cg_expr_is_slice(ctx, rhs) == 1) {
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					}
					else { ir_emit(f, IrInstrKind.POP, 0, 0, 0); }
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
				if (cg_lower_lvalue_addr(ctx, lhs) == 0) {
					// cannot address: evaluate rhs and discard
					cg_lower_expr(ctx, rhs);
					if (cg_expr_is_slice(ctx, rhs) == 1) {
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					}
					else { ir_emit(f, IrInstrKind.POP, 0, 0, 0); }
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
				cg_lower_expr(ctx, rhs);
				if (cg_expr_is_slice(ctx, rhs) == 1) {
					// best-effort discard
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
				if (sz == 1) {
					ir_emit(f, IrInstrKind.STORE_MEM8, 0, 0, 0);
				}
				else {
					ir_emit(f, IrInstrKind.STORE_MEM64, 0, 0, 0);
				}
				// Return assigned value by re-loading lhs.
				cg_lower_expr(ctx, lhs);
				return 0;
			}
			if (ptr64[lhs + 0] != AstExprKind.IDENT) {
				return 0;
			}
			var name_ptr = ptr64[lhs + 40];
			var name_len = ptr64[lhs + 48];
			var l = cg_local_find(ctx, name_ptr, name_len);
			if (l == 0) {
				// Unresolved: evaluate rhs and discard.
				cg_lower_expr(ctx, rhs);
				if (cg_expr_is_slice(ctx, rhs) == 1) {
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				}
				else {
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				}
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			var rhs_is_slice = cg_expr_is_slice(ctx, rhs);
			if (cg_local_is_slice(l) == 1) {
				// slice assignment expects slice rhs: stack has {ptr,len}
				cg_lower_expr(ctx, rhs);
				// store len then ptr (len is at base+8 => offset-8)
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16] - 8, 0, 0);
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
				// push assigned value
				ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
				ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16] - 8, 0, 0);
				return 0;
			}
			// struct by-value assignment (IDENT-to-IDENT only)
			var lsz = cg_local_size_bytes(l);
			if (lsz > 8) {
				if (rhs != 0 && ptr64[rhs + 0] == AstExprKind.IDENT) {
					var rname_ptr = ptr64[rhs + 40];
					var rname_len = ptr64[rhs + 48];
					var rl = cg_local_find(ctx, rname_ptr, rname_len);
					if (rl != 0 && cg_local_is_slice(rl) == 0 && cg_local_size_bytes(rl) == lsz) {
						cg_lower_struct_copy_locals(ctx, l, rl, lsz);
						// assigned struct value not representable yet; push 0
						ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
						return 0;
					}
				}
				// Unsupported struct rhs; best-effort ignore.
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			// scalar assignment
			cg_lower_expr(ctx, rhs);
			if (rhs_is_slice == 1) {
				// Cannot assign slice to scalar; best-effort discard.
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
				return 0;
			}
			ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
			ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
			return 0;
		}

		// Compound assignment (Phase 6.1): x op= y => x = x op y
		// typecheck stores original op in extra (+32) and base_op in op (+8)
		var orig_op = ptr64[e + 32];
		if (orig_op >= TokKind.PLUSEQ && orig_op <= TokKind.RSHIFTEQ) {
			// compound assignment: lhs op= rhs => lhs = lhs op rhs
			if (ptr64[lhs + 0] == AstExprKind.IDENT) {
				var name_ptr = ptr64[lhs + 40];
				var name_len = ptr64[lhs + 48];
				var l = cg_local_find(ctx, name_ptr, name_len);
				if (l != 0) {
					// Load current value
					ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
					// Evaluate rhs
					cg_lower_expr(ctx, rhs);
					// Apply operation
					ir_emit(f, IrInstrKind.BINOP, op, 0, 0);
					// Store back
					ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
					ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l + 16], 0, 0);
					return 0;
				}
			}
			if (ptr64[lhs + 0] == AstExprKind.FIELD) {
				var extra = ptr64[lhs + 32];
				var sz = (extra >> 56) & 127;
				var off = ptr64[lhs + 8];
				var via_ptr = (extra >> 63) & 1;
				var base = ptr64[lhs + 16];
				if (via_ptr == 0) {
					// stack local field: load current, apply op, store back
					cg_lower_expr(ctx, lhs);  // load current value
					cg_lower_expr(ctx, rhs);  // evaluate rhs
					ir_emit(f, IrInstrKind.BINOP, op, 0, 0);  // apply op
					// Now store back to field
					if (cg_lower_lvalue_addr(ctx, base) == 0) {
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
						ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
						return 0;
					}
					ir_emit(f, IrInstrKind.PUSH_IMM, off, 0, 0);
					ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
					// Stack: new_val, addr. Swap needed, but no SWAP. Use STORE_MEM which pops val then addr
					// Actually STORE_MEM64 pops: val, addr in that order? Let's check order...
					// For now, simplified: pop result, do lhs assignment
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
			}
		}

		// Phase 4.6: constant-time eq for []u8 (lower to a dedicated IR op).
		if (op == TokKind.EQEQEQ || op == TokKind.NEQEQ) {
			if (cg_expr_is_slice(ctx, lhs) == 1 && cg_expr_is_slice(ctx, rhs) == 1) {
				cg_lower_expr(ctx, lhs);
				cg_lower_expr(ctx, rhs);
				var mismatch_id = cg_label_alloc(ctx);
				var loop_id = cg_label_alloc(ctx);
				var done_id = cg_label_alloc(ctx);
				ir_emit(f, IrInstrKind.CTEQ_SLICE_U8, mismatch_id, loop_id, done_id);
				if (op == TokKind.NEQEQ) { ir_emit(f, IrInstrKind.UNOP, TokKind.BANG, 0, 0); }
				return 0;
			}
		}
		cg_lower_expr(ctx, lhs);
		cg_lower_expr(ctx, rhs);
		ir_emit(f, IrInstrKind.BINOP, op, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.STRING) {
		var tok_ptr = ptr64[e + 40];
		var tok_len = ptr64[e + 48];
		var b = cg_decode_string_literal(tok_ptr, tok_len);
		if (b == 0) {
			ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
			return 0;
		}
		var r = cg_rodata_add_string(ptr64[ctx + 0], ptr64[b + 0], ptr64[b + 8]);
		// push slice {ptr,len}
		ir_emit(f, IrInstrKind.PUSH_RODATA_ADDR, ptr64[r + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_IMM, ptr64[b + 8], 0, 0);
		return 0;
	}

	if (ek == AstExprKind.NULL) {
		ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.INDEX) {
		// base[idx] where base is []u8
		var unsafe = ptr64[e + 8];
		var base = ptr64[e + 16];
		var idx = ptr64[e + 24];
		cg_lower_expr(ctx, base);
		cg_lower_expr(ctx, idx);
		var do_check = 1;
		if (unsafe == 1) { do_check = 0; }
		ir_emit(f, IrInstrKind.SLICE_INDEX_U8, do_check, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.CALL) {
		var callee = ptr64[e + 16];
		var args = ptr64[e + 32];
		// builtin print("...")
		if (ptr64[callee + 0] == AstExprKind.IDENT) {
			var name_ptr = ptr64[callee + 40];
			var name_len = ptr64[callee + 48];
			if (cg_slice_eq(name_ptr, name_len, "print", 5) == 1) {
				if (vec_len(args) == 1) {
					var a0 = vec_get(args, 0);
					cg_lower_expr(ctx, a0);
					if (cg_expr_is_slice(ctx, a0) == 1) {
						ir_emit(f, IrInstrKind.PRINT_SLICE, 0, 0, 0);
						ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
						return 0;
					}
					// Unsupported print arg type.
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
			}

			// builtin print_u64(n)
			if (cg_slice_eq(name_ptr, name_len, "print_u64", 9) == 1) {
				if (vec_len(args) == 1) {
					cg_lower_expr(ctx, vec_get(args, 0));
					ir_emit(f, IrInstrKind.PRINT_U64, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
			}

			// builtin panic(msg): print "panic: <msg>\n" to stderr and exit(1)
			if (cg_slice_eq(name_ptr, name_len, "panic", 5) == 1) {
				if (vec_len(args) == 1) {
					cg_lower_expr(ctx, vec_get(args, 0));
					ir_emit(f, IrInstrKind.PANIC, 0, 0, 0);
					ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
					return 0;
				}
			}

			if (cg_slice_eq(name_ptr, name_len, "slice_from_ptr_len", 18) == 1) {
				if (vec_len(args) == 2) {
					// Lower to slice {ptr,len}
					cg_lower_expr(ctx, vec_get(args, 0));
					cg_lower_expr(ctx, vec_get(args, 1));
					return 0;
				}
			}
		}
		// User call: only IDENT callee.
		if (callee != 0 && ptr64[callee + 0] == AstExprKind.IDENT) {
			var name_ptr2 = ptr64[callee + 40];
			var name_len2 = ptr64[callee + 48];
			// Phase 4.5: extern @reg call (args moved into registers).
			var ast_prog = ptr64[ctx + 48];
			var decl = cg_ast_find_func_decl(ast_prog, name_ptr2, name_len2);
			if (decl != 0 && cg_decl_is_extern(decl) != 0) {
				var params2 = ptr64[decl + 24];
				var pn2 = 0;
				if (params2 != 0) { pn2 = vec_len(params2); }
				var narg2 = 0;
				if (args != 0) { narg2 = vec_len(args); }
				var ret_reg2 = cg_decl_retreg(decl);
				// Detect whether this extern uses @reg.
				var has_param_reg2 = 0;
				var pi2 = 0;
				while (pi2 < pn2) {
					var ps2 = vec_get(params2, pi2);
					if (ps2 != 0 && ptr64[ps2 + 16] != 0) { has_param_reg2 = 1; }
					pi2 = pi2 + 1;
				}
				if (has_param_reg2 != 0 || ret_reg2 != 0) {
					// Evaluate args right-to-left (so arg0 ends up on top).
					var idx2 = narg2;
					while (idx2 != 0) {
						idx2 = idx2 - 1;
						var a00 = vec_get(args, idx2);
						cg_lower_expr(ctx, a00);
						// MVP: only 8-byte args.
						if (cg_expr_is_slice(ctx, a00) == 1) {
							// Unsupported: pop the slice and push 0.
							ir_emit(f, IrInstrKind.POP, 0, 0, 0);
							ir_emit(f, IrInstrKind.POP, 0, 0, 0);
							ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
						}
					}
					// Pop args into their specified registers.
					var pi3 = 0;
					while (pi3 < pn2) {
						var ps3 = vec_get(params2, pi3);
						var rid3 = 0;
						if (ps3 != 0) { rid3 = ptr64[ps3 + 16]; }
						// rid3==0 should be rejected by typecheck for @reg functions.
						ir_emit(f, IrInstrKind.STORE_LOCAL, cg_local_off_pack_reg(rid3), 0, 0);
						pi3 = pi3 + 1;
					}
					// Call (no stack args to clean).
					ir_emit(f, IrInstrKind.CALL, name_ptr2, name_len2, 0);
					// If return reg is not rax, replace pushed rax with the annotated reg.
					if (ret_reg2 != 0) {
						ir_emit(f, IrInstrKind.POP, 0, 0, 0);
						ir_emit(f, IrInstrKind.PUSH_LOCAL, cg_local_off_pack_reg(ret_reg2), 0, 0);
					}
					return 0;
				}
			}
			// Phase 6.7: Save all variables to globals before any function calls
			// (to survive function call clobbering of local variables)
			cg_call_name_ptr = name_ptr2;
			cg_call_name_len = name_len2;
			cg_call_decl = decl;
			cg_call_args = args;
			cg_fptr_ctx = ctx;
			
			// Check if callee is a function pointer local variable BEFORE processing args
			cg_fptr_local = 0;
			cg_fptr_offset = 0;
			if (cg_call_decl == 0) {
				var l0 = cg_local_find(cg_fptr_ctx, cg_call_name_ptr, cg_call_name_len);
				if (l0 != 0) {
					cg_fptr_local = l0;
					cg_fptr_offset = ptr64[l0 + 16];
				}
			}
			
			var narg = 0;
			if (cg_call_args != 0) { narg = vec_len(cg_call_args); }
			// Get param types from decl to handle struct by-value
			var params_decl = 0;
			var pn_decl = 0;
			if (cg_call_decl != 0) {
				params_decl = ptr64[cg_call_decl + 24];
				if (params_decl != 0) { pn_decl = vec_len(params_decl); }
			}
			var ast_prog_saved = ptr64[cg_fptr_ctx + 48];
			var idx = narg;
			cg_fptr_arg_bytes = 0;  // Use global for arg_bytes
			while (idx != 0) {
				idx = idx - 1;
				var a0 = vec_get(cg_call_args, idx);
				// Check if param is struct type (by-value)
				var param_sz = 8;
				if (params_decl != 0 && idx < pn_decl) {
					var pst0 = vec_get(params_decl, idx);
					if (pst0 != 0) {
						var pty0 = ptr64[pst0 + 48];
						param_sz = cg_type_size_bytes_prog(ast_prog_saved, pty0);
					}
				}
				if (param_sz > 8 && param_sz != 24) {
					// Struct by-value: for now, use the cg_lower_struct_by_value helper
					var pushed = cg_lower_struct_arg(cg_fptr_ctx, a0, param_sz);
					if (pushed != 0) {
						cg_fptr_arg_bytes = cg_fptr_arg_bytes + param_sz;
					} else {
						cg_lower_expr(cg_fptr_ctx, a0);
						cg_fptr_arg_bytes = cg_fptr_arg_bytes + 8;
					}
				}
				else if (cg_expr_is_slice(cg_fptr_ctx, a0) == 1) {
					cg_lower_expr(cg_fptr_ctx, a0);
					cg_fptr_arg_bytes = cg_fptr_arg_bytes + 16;
				}
				else {
					cg_lower_expr(cg_fptr_ctx, a0);
					cg_fptr_arg_bytes = cg_fptr_arg_bytes + 8;
				}
			}
			// Phase 6.7: Check if callee is a function pointer local variable
			if (cg_fptr_local != 0) {
				// Function pointer indirect call: push function ptr value, then call indirect
				var f_s = ptr64[cg_fptr_ctx + 8];
				ir_emit(f_s, IrInstrKind.PUSH_LOCAL, cg_fptr_offset, 0, 0);
				// Re-read f from ctx after ir_emit (locals may be clobbered)
				var f_s2 = ptr64[cg_fptr_ctx + 8];
				ir_emit(f_s2, IrInstrKind.CALL_INDIRECT, cg_fptr_arg_bytes, 0, 0);
				return 0;
			}
			// Regular function call - use global variables since locals may have been clobbered
			var f_final = ptr64[cg_fptr_ctx + 8];
			ir_emit(f_final, IrInstrKind.CALL, cg_call_name_ptr, cg_call_name_len, cg_fptr_arg_bytes);
			return 0;
		}
		// Unsupported call: leave 0
		ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
		return 0;
	}

	// fallback
	ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
	return 0;
}

// Execute defers from defer_stack[to..from) in reverse order
func cg_emit_defers(ctx, from, to) {
	var ds = ptr64[ctx + 96];
	if (ds == 0) { return 0; }
	var i = from;
	while (i > to) {
		i = i - 1;
		var inner = vec_get(ds, i);
		if (inner != 0) { cg_lower_stmt(ctx, inner); }
	}
	return 0;
}

func cg_lower_print_args(ctx, args) {
	// Lower all print args. args = Vec* of AstExpr*
	if (args == 0) { return 0; }
	var f = ptr64[ctx + 8];
	var n = vec_len(args);
	var i = 0;
	while (i < n) {
		var arg = vec_get(args, i);
		if (arg != 0) {
			cg_lower_expr(ctx, arg);
			if (cg_expr_is_slice(ctx, arg) == 1) {
				ir_emit(f, IrInstrKind.PRINT_SLICE, 0, 0, 0);
			} else {
				ir_emit(f, IrInstrKind.PRINT_U64_NO_NL, 0, 0, 0);
			}
		}
		i = i + 1;
	}
	return 0;
}

func cg_lower_stmt(ctx, st) {
	var k = ptr64[st + 0];
	var f = ptr64[ctx + 8];

	if (k == AstStmtKind.VAR) {
		var flags = ptr64[st + 8];
		var name_ptr = ptr64[st + 32];
		var name_len = ptr64[st + 40];
		var init = ptr64[st + 56];
		// Get local from AST (stored by collect phase for shadowing support)
		var l = ptr64[st + 88];
		if (l == 0) {
			// Fallback: find or add
			l = cg_local_find(ctx, name_ptr, name_len);
			if (l == 0) { l = cg_local_add(ctx, name_ptr, name_len); }
		}
		else {
			// Add to active locals for name lookup (shadowing support)
			var locals = ptr64[ctx + 16];
			if (locals != 0) { vec_push(locals, l); }
		}
		// If init is CALL returning struct, set local size from return type
		if (init != 0 && ptr64[init + 0] == AstExprKind.CALL) {
			var ast_prog2 = ptr64[ctx + 48];
			var callee2 = ptr64[init + 16];
			if (callee2 != 0 && ptr64[callee2 + 0] == AstExprKind.IDENT) {
				var cn_ptr2 = ptr64[callee2 + 40];
				var cn_len2 = ptr64[callee2 + 48];
				var cdecl2 = cg_ast_find_func_decl(ast_prog2, cn_ptr2, cn_len2);
				var sret_sz2 = cg_func_returns_struct(ast_prog2, cdecl2);
				if (sret_sz2 != 0) {
					cg_local_set_size_bytes(l, sret_sz2);
				}
			}
		}
		if (init != 0) {
			if (cg_local_is_slice(l) == 1) {
				cg_lower_expr(ctx, init);
				// store len then ptr
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16] - 8, 0, 0);
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
			}
			else {
				var lsz2 = cg_local_size_bytes(l);
				if (lsz2 > 8) {
					// struct init from another local (IDENT only)
					if (ptr64[init + 0] == AstExprKind.IDENT) {
						var rname_ptr2 = ptr64[init + 40];
						var rname_len2 = ptr64[init + 48];
						var rl2 = cg_local_find(ctx, rname_ptr2, rname_len2);
						if (rl2 != 0 && cg_local_is_slice(rl2) == 0 && cg_local_size_bytes(rl2) == lsz2) {
							cg_lower_struct_copy_locals(ctx, l, rl2, lsz2);
							return 0;
						}
					}
					// struct init from function call (sret)
					if (ptr64[init + 0] == AstExprKind.CALL) {
						var ast_prog = ptr64[ctx + 48];
						var callee = ptr64[init + 16];
						if (callee != 0 && ptr64[callee + 0] == AstExprKind.IDENT) {
							var cn_ptr = ptr64[callee + 40];
							var cn_len = ptr64[callee + 48];
							var cdecl = cg_ast_find_func_decl(ast_prog, cn_ptr, cn_len);
							var sret_sz = cg_func_returns_struct(ast_prog, cdecl);
							if (sret_sz != 0 && sret_sz == lsz2) {
								// Pass hidden sret pointer + args
								var c_args = ptr64[init + 32];
								var narg = 0;
								if (c_args != 0) { narg = vec_len(c_args); }
								// Push args in reverse order
								var idx = narg;
								var arg_bytes = 0;
								while (idx != 0) {
									idx = idx - 1;
									var a0 = vec_get(c_args, idx);
									cg_lower_expr(ctx, a0);
									arg_bytes = arg_bytes + 8;
								}
								// Push sret pointer (address of local l)
								ir_emit(f, IrInstrKind.PUSH_LOCAL_ADDR, ptr64[l + 16], 0, 0);
								arg_bytes = arg_bytes + 8;
								ir_emit(f, IrInstrKind.CALL, cn_ptr, cn_len, arg_bytes);
								// Result is in rax (sret pointer), discard it
								ir_emit(f, IrInstrKind.POP, 0, 0, 0);
								return 0;
							}
						}
					}
					return 0;
				}
				cg_lower_expr(ctx, init);
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
			}
		}
			// Phase 4.3: secret vars are zeroized on scope exit (and before return).
			var is_secret = flags & 1;
			if (is_secret != 0) {
				var sv = ptr64[ctx + 40];
				if (sv != 0 && l != 0) { vec_push(sv, l); }
			}
		return 0;
	}

	if (k == AstStmtKind.EXPR) {
		var e = ptr64[st + 56];
		cg_lower_expr(ctx, e);
		if (cg_expr_is_slice(ctx, e) == 1) {
			ir_emit(f, IrInstrKind.POP, 0, 0, 0);
			ir_emit(f, IrInstrKind.POP, 0, 0, 0);
		}
		else {
			ir_emit(f, IrInstrKind.POP, 0, 0, 0);
		}
		return 0;
	}

	if (k == AstStmtKind.RETURN) {
		// Execute all defers first
		var ds2 = ptr64[ctx + 96];
		if (ds2 != 0) {
			cg_emit_defers(ctx, vec_len(ds2), 0);
		}
		// Phase 4.3: zeroize all live secrets on early exit.
		var sv2 = ptr64[ctx + 40];
		if (sv2 != 0) {
			var sn2 = vec_len(sv2);
			var si2 = 0;
			while (si2 < sn2) {
				cg_emit_wipe_local(ctx, vec_get(sv2, si2));
				si2 = si2 + 1;
			}
		}
		var e = ptr64[st + 56];
		// Check for sret (struct return)
		var sret_l = cg_local_find(ctx, "__sret_ptr", 10);
		if (sret_l != 0 && e != 0 && ptr64[e + 0] == AstExprKind.IDENT) {
			// Copy struct to sret location
			var rname_ptr = ptr64[e + 40];
			var rname_len = ptr64[e + 48];
			var rl = cg_local_find(ctx, rname_ptr, rname_len);
			if (rl != 0) {
				var rsz = cg_local_size_bytes(rl);
				if (rsz > 8 && rsz != 24) {
					// Copy qwords from local to sret ptr
					var qw = rsz / 8;
					var qi = 0;
					while (qi < qw) {
						// Push addr first (sret_ptr + offset)
						ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[sret_l + 16], 0, 0);
						if (qi != 0) {
							ir_emit(f, IrInstrKind.PUSH_IMM, qi * 8, 0, 0);
							ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
						}
						// Push value from local (rl is struct, offset -qi*8 from base)
						ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[rl + 16] - qi * 8, 0, 0);
						// Store value to [sret + offset]
						ir_emit(f, IrInstrKind.STORE_MEM64, 0, 0, 0);
						qi = qi + 1;
					}
					// Return sret ptr in rax
					ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[sret_l + 16], 0, 0);
					ir_emit(f, IrInstrKind.RET, ptr64[ctx + 56], 0, 0);
					return 0;
				}
			}
		}
		if (e != 0) { cg_lower_expr(ctx, e); }
		else { ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0); }
		ir_emit(f, IrInstrKind.RET, ptr64[ctx + 56], 0, 0);
		return 0;
	}

	if (k == AstStmtKind.BLOCK) {
		// Save locals length for shadowing support
		var locals = ptr64[ctx + 16];
		var locals_saved = 0;
		if (locals != 0) { locals_saved = vec_len(locals); }
		// Phase 4.3: block-scoped secret vars.
		var sv3 = ptr64[ctx + 40];
		var saved = 0;
		if (sv3 != 0) { saved = vec_len(sv3); }
		// Save defer stack position
		var ds = ptr64[ctx + 96];
		var defer_saved = 0;
		if (ds != 0) { defer_saved = vec_len(ds); }
		var ss = ptr64[st + 8];
		var n = vec_len(ss);
		var i = 0;
		while (i < n) {
			cg_lower_stmt(ctx, vec_get(ss, i));
			i = i + 1;
		}
		// Execute defers in reverse order
		if (ds != 0) {
			var defer_now = vec_len(ds);
			cg_emit_defers(ctx, defer_now, defer_saved);
			ptr64[ds + 8] = defer_saved; // restore defer stack
		}
		// Wipe secrets declared in this block.
		if (sv3 != 0) {
			var sn3 = vec_len(sv3);
			var si3 = saved;
			while (si3 < sn3) {
				cg_emit_wipe_local(ctx, vec_get(sv3, si3));
				si3 = si3 + 1;
			}
			ptr64[sv3 + 8] = saved;
		}
		// Restore locals (shadowing support)
		if (locals != 0) { ptr64[locals + 8] = locals_saved; }
		return 0;
	}

	if (k == AstStmtKind.DEFER) {
		// st+8 = inner statement
		var inner = ptr64[st + 8];
		var ds = ptr64[ctx + 96];
		if (ds != 0 && inner != 0) {
			vec_push(ds, inner);
		}
		return 0;
	}

	if (k == AstStmtKind.WIPE) {
		// Layout:
		//  st->a: expr0 (IDENT or ptr)
		//  st->b: expr1 (len) or 0
		var a0 = ptr64[st + 8];
		var b0 = ptr64[st + 16];
		if (b0 == 0) {
			// wipe variable;
			if (a0 != 0 && ptr64[a0 + 0] == AstExprKind.IDENT) {
				var name_ptr = ptr64[a0 + 40];
				var name_len = ptr64[a0 + 48];
				var l0 = cg_local_find(ctx, name_ptr, name_len);
				cg_emit_wipe_local(ctx, l0);
			}
			return 0;
		}
		// wipe ptr, len;
		var l_ptr = cg_wipe_scratch_ptr_local(ctx);
		var l_len = cg_wipe_scratch_len_local(ctx);
		if (l_ptr == 0 || l_len == 0) { return 0; }
		cg_lower_expr(ctx, a0);
		ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_ptr + 16], 0, 0);
		cg_lower_expr(ctx, b0);
		ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_len + 16], 0, 0);
		cg_emit_wipe_loop(ctx, ptr64[l_ptr + 16], ptr64[l_len + 16]);
		return 0;
	}

	if (k == AstStmtKind.PRINT) {
		cg_lower_print_args(ctx, ptr64[st + 8]);
		return 0;
	}
	if (k == AstStmtKind.PRINTLN) {
		cg_lower_print_args(ctx, ptr64[st + 8]);
		ir_emit(f, IrInstrKind.PRINT_NL, 0, 0, 0);
		return 0;
	}

	if (k == AstStmtKind.IF) {
		var else_id = cg_label_alloc(ctx);
		var end_id = cg_label_alloc(ctx);

		cg_lower_expr(ctx, ptr64[st + 8]);
		ir_emit(f, IrInstrKind.JZ, else_id, 0, 0);
		cg_lower_stmt(ctx, ptr64[st + 16]);
		ir_emit(f, IrInstrKind.JMP, end_id, 0, 0);
		ir_emit(f, IrInstrKind.LABEL, else_id, 0, 0);
		var els = ptr64[st + 24];
		if (els != 0) { cg_lower_stmt(ctx, els); }
		ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
		return 0;
	}

	if (k == AstStmtKind.WHILE) {
		var start_id = cg_label_alloc(ctx);
		var end_id = cg_label_alloc(ctx);
		vec_push(ptr64[ctx + 64], start_id);
		vec_push(ptr64[ctx + 72], end_id);
		ptr64[ctx + 88] = ptr64[ctx + 88] + 1;
		ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);
		cg_lower_expr(ctx, ptr64[st + 8]);
		ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);
		cg_lower_stmt(ctx, ptr64[st + 16]);
		ir_emit(f, IrInstrKind.JMP, start_id, 0, 0);
		ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
		vec_pop(ptr64[ctx + 64]);
		vec_pop(ptr64[ctx + 72]);
		ptr64[ctx + 88] = ptr64[ctx + 88] - 1;
		return 0;
	}

	if (k == AstStmtKind.FOR) {
		// Layout: init(+8), cond(+16), post(+24), body(+56)
		var init0 = ptr64[st + 8];
		var cond0 = ptr64[st + 16];
		var post0 = ptr64[st + 24];
		var body0 = ptr64[st + 56];
		if (init0 != 0) { cg_lower_stmt(ctx, init0); }
		var start_id = cg_label_alloc(ctx);
		var end_id = cg_label_alloc(ctx);
		var post_id = cg_label_alloc(ctx);
		vec_push(ptr64[ctx + 64], post_id);
		vec_push(ptr64[ctx + 72], end_id);
		ptr64[ctx + 88] = ptr64[ctx + 88] + 1;
		ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);
		if (cond0 != 0) {
			cg_lower_expr(ctx, cond0);
			ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);
		}
		if (body0 != 0) { cg_lower_stmt(ctx, body0); }
		ir_emit(f, IrInstrKind.LABEL, post_id, 0, 0);
		if (post0 != 0) {
			cg_lower_expr(ctx, post0);
			ir_emit(f, IrInstrKind.POP, 0, 0, 0);
		}
		ir_emit(f, IrInstrKind.JMP, start_id, 0, 0);
		ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
		vec_pop(ptr64[ctx + 64]);
		vec_pop(ptr64[ctx + 72]);
		ptr64[ctx + 88] = ptr64[ctx + 88] - 1;
		return 0;
	}

	if (k == AstStmtKind.BREAK) {
		var level = ptr64[st + 8];
		if (level == 0) { level = 1; }
		var depth = ptr64[ctx + 88];
		if (level > depth) { return 0; }
		var end_stack = ptr64[ctx + 72];
		var end_len = vec_len(end_stack);
		if (end_len < level) { return 0; }
		var target_label = vec_get(end_stack, end_len - level);
		ir_emit(f, IrInstrKind.JMP, target_label, 0, 0);
		return 0;
	}

	if (k == AstStmtKind.CONTINUE) {
		var level2 = ptr64[st + 8];
		if (level2 == 0) { level2 = 1; }
		var depth2 = ptr64[ctx + 88];
		if (level2 > depth2) { return 0; }
		var start_stack = ptr64[ctx + 64];
		var start_len = vec_len(start_stack);
		if (start_len < level2) { return 0; }
		var target_label2 = vec_get(start_stack, start_len - level2);
		ir_emit(f, IrInstrKind.JMP, target_label2, 0, 0);
		return 0;
	}

	if (k == AstStmtKind.FOREACH) {
		var bind = ptr64[st + 8];
		var iter_expr = ptr64[st + 16];
		var body = ptr64[st + 24];
		if (bind == 0) { return 0; }

		var elem_sz = ptr64[bind + 40];
		if (elem_sz != 1) {
			if (elem_sz != 8) {
				// Unsupported element size.
				return 0;
			}
		}

		// Get internal locals from AST (stored by collect phase)
		var l_i = ptr64[st + 32];
		var l_ptr = ptr64[st + 40];
		var l_len = ptr64[st + 48];
		if (l_i == 0 || l_ptr == 0 || l_len == 0) { return 0; }

		// Evaluate iterable once: store ptr/len.
		if (cg_expr_is_slice(ctx, iter_expr) == 1) {
			cg_lower_expr(ctx, iter_expr);
			// stack: ptr, len
			ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_len + 16], 0, 0);
			ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_ptr + 16], 0, 0);
		}
		else {
			// Allow foreach over local arrays (IDENT with size>8).
			if (iter_expr == 0 || ptr64[iter_expr + 0] != AstExprKind.IDENT) { return 0; }
			var an_ptr = ptr64[iter_expr + 40];
			var an_len = ptr64[iter_expr + 48];
			var al = cg_local_find(ctx, an_ptr, an_len);
			if (al == 0) { return 0; }
			if (cg_local_is_slice(al) == 1) { return 0; }
			var total_bytes = cg_local_size_bytes(al);
			if (total_bytes <= 8) { return 0; }
			// ptr = &arr[0]
			ir_emit(f, IrInstrKind.PUSH_LOCAL_ADDR, ptr64[al + 16], 0, 0);
			ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_ptr + 16], 0, 0);
			// len = total_bytes / elem_sz
			var n = total_bytes / elem_sz;
			ir_emit(f, IrInstrKind.PUSH_IMM, n, 0, 0);
			ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_len + 16], 0, 0);
		}

		// i = 0
		ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
		ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_i + 16], 0, 0);

		var has_two = ptr64[bind + 32];
		var name0_ptr = ptr64[bind + 0];
		var name0_len = ptr64[bind + 8];
		var name1_ptr = ptr64[bind + 16];
		var name1_len = ptr64[bind + 24];

		// Add binding locals to active list for name lookup in body
		var locals = ptr64[ctx + 16];
		if (has_two == 1) {
			var l_bind0 = ptr64[st + 56];
			var l_bind1 = ptr64[st + 88];
			if (l_bind0 != 0 && locals != 0) { vec_push(locals, l_bind0); }
			if (l_bind1 != 0 && locals != 0) { vec_push(locals, l_bind1); }
		} else {
			var l_bind = ptr64[st + 56];
			if (l_bind != 0 && locals != 0) { vec_push(locals, l_bind); }
		}

		var start_id = cg_label_alloc(ctx);
		var end_id = cg_label_alloc(ctx);
		vec_push(ptr64[ctx + 64], start_id);
		vec_push(ptr64[ctx + 72], end_id);
		ptr64[ctx + 88] = ptr64[ctx + 88] + 1;
		ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);

		// cond: i < len
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_i + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_len + 16], 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.LT, 0, 0);
		ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);

		// Optional idx binding (stored in st+56 by collect phase).
		if (has_two == 1) {
			if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
				var l_idx = ptr64[st + 56];  // get from AST
				if (l_idx != 0) {
					ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_i + 16], 0, 0);
					ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_idx + 16], 0, 0);
				}
			}
		}

		// Load element: *(ptr + i*elem_sz)
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_ptr + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_i + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_IMM, elem_sz, 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.STAR, 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
		if (elem_sz == 1) {
			ir_emit(f, IrInstrKind.LOAD_MEM8, 0, 0, 0);
		} else {
			ir_emit(f, IrInstrKind.LOAD_MEM64, 0, 0, 0);
		}

		// Store to value binding if present.
		if (has_two == 1) {
			if (cg_is_discard_ident(name1_ptr, name1_len) == 0) {
				var l_val = ptr64[st + 88];  // get from AST
				if (l_val != 0) {
					ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_val + 16], 0, 0);
				} else {
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				}
			} else {
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
			}
		} else {
			if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
				var l_val2 = ptr64[st + 56];  // get from AST (single binding)
				if (l_val2 != 0) {
					ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_val2 + 16], 0, 0);
				} else {
					ir_emit(f, IrInstrKind.POP, 0, 0, 0);
				}
			} else {
				ir_emit(f, IrInstrKind.POP, 0, 0, 0);
			}
		}

		cg_lower_stmt(ctx, body);

		// i = i + 1
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_i + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_IMM, 1, 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.PLUS, 0, 0);
		ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l_i + 16], 0, 0);
		ir_emit(f, IrInstrKind.JMP, start_id, 0, 0);
		ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
		vec_pop(ptr64[ctx + 64]);
		vec_pop(ptr64[ctx + 72]);
		ptr64[ctx + 88] = ptr64[ctx + 88] - 1;
		return 0;
	}

	if (k == AstStmtKind.SWITCH) {
		// SWITCH: +8=cond, +16=cases, +24=default_body
		// AstSwitchCase: +0=value_expr, +8=body
		var sw_cond = ptr64[st + 8];
		var sw_cases = ptr64[st + 16];
		var sw_default = ptr64[st + 24];
		
		var end_lbl = cg_label_alloc(ctx);
		vec_push(ptr64[ctx + 72], end_lbl); // push to end_stack for break
		
		// Generate labels for each case and default
		var sw_n = 0;
		if (sw_cases != 0) { sw_n = vec_len(sw_cases); }
		var sw_lbls = vec_new(sw_n + 2);
		var sw_i = 0;
		while (sw_i < sw_n) {
			vec_push(sw_lbls, cg_label_alloc(ctx));
			sw_i = sw_i + 1;
		}
		var sw_def_lbl = cg_label_alloc(ctx);
		
		// Jump table: compare cond with each case value
		sw_i = 0;
		while (sw_i < sw_n) {
			var sw_c = vec_get(sw_cases, sw_i);
			var val_expr = ptr64[sw_c + 0];
			cg_lower_expr(ctx, sw_cond);
			cg_lower_expr(ctx, val_expr);
			ir_emit(f, IrInstrKind.BINOP, 51, 0, 0); // TokKind.EQEQ = 51
			ir_emit(f, IrInstrKind.JNZ, vec_get(sw_lbls, sw_i), 0, 0);
			sw_i = sw_i + 1;
		}
		// Jump to default (or end if no default)
		if (sw_default != 0) {
			ir_emit(f, IrInstrKind.JMP, sw_def_lbl, 0, 0);
		} else {
			ir_emit(f, IrInstrKind.JMP, end_lbl, 0, 0);
		}
		
		// Emit case bodies (NO fallthrough - each ends with JMP to end)
		sw_i = 0;
		while (sw_i < sw_n) {
			var sw_c = vec_get(sw_cases, sw_i);
			var sw_body = ptr64[sw_c + 8];
			ir_emit(f, IrInstrKind.LABEL, vec_get(sw_lbls, sw_i), 0, 0);
			if (sw_body != 0) { cg_lower_stmt(ctx, sw_body); }
			ir_emit(f, IrInstrKind.JMP, end_lbl, 0, 0);
			sw_i = sw_i + 1;
		}
		
		// Default body
		if (sw_default != 0) {
			ir_emit(f, IrInstrKind.LABEL, sw_def_lbl, 0, 0);
			cg_lower_stmt(ctx, sw_default);
			ir_emit(f, IrInstrKind.JMP, end_lbl, 0, 0);
		}
		
		ir_emit(f, IrInstrKind.LABEL, end_lbl, 0, 0);
		vec_pop(ptr64[ctx + 72]); // pop from end_stack
		return 0;
	}

	return 0;
}

func cg_emit(sb, s) {
	sb_append_cstr(sb, s);
	return 0;
}

func cg_emit_u64(sb, v) {
	sb_append_u64_dec(sb, v);
	return 0;
}

func cg_emit_nl(sb) {
	sb_append_cstr(sb, "\n");
	return 0;
}

func cg_emit_bytes(sb, p, n) {
	if (p == 0) { return 0; }
	if (n == 0) { return 0; }
	sb_append_bytes(sb, p, n);
	return 0;
}

func cg_emit_line(sb, s) {
	cg_emit(sb, s);
	cg_emit_nl(sb);
	return 0;
}

func cg_emit_label(sb, id) {
	cg_emit(sb, ".L");
	cg_emit_u64(sb, id);
	cg_emit(sb, ":");
	cg_emit_nl(sb);
	return 0;
}

func cg_emit_rodata(sb, prog) {
	cg_emit_line(sb, "section .rodata");
	// Panic helper strings
	cg_emit_line(sb, "__panic_prefix:");
	cg_emit_line(sb, "\tdb 112,97,110,105,99,58,32"); // "panic: "
	cg_emit_line(sb, "__panic_newline:");
	cg_emit_line(sb, "\tdb 10"); // "\n"
	// User string literals
	var rdv = ptr64[prog + 8];
	var n = vec_len(rdv);
	var i = 0;
	while (i < n) {
		var r = vec_get(rdv, i);
		cg_emit(sb, "S");
		cg_emit_u64(sb, ptr64[r + 16]);
		cg_emit_line(sb, ":");
		cg_emit(sb, "\tdb ");
		var p = ptr64[r + 0];
		var len = ptr64[r + 8];
		var j = 0;
		while (j < len) {
			if (j != 0) { cg_emit(sb, ","); }
			cg_emit_u64(sb, ptr8[p + j]);
			j = j + 1;
		}
		cg_emit_nl(sb);
		i = i + 1;
	}
	cg_emit_nl(sb);
	return 0;
}

func cg_emit_text_prelude(sb) {
	cg_emit_line(sb, "global _start");
	cg_emit_line(sb, "section .text");
	cg_emit_line(sb, "_start:");
	cg_emit_line(sb, "\tcall main");
	cg_emit_line(sb, "\tmov rdi, rax");
	cg_emit_line(sb, "\tmov rax, 60");
	cg_emit_line(sb, "\tsyscall");
	cg_emit_nl(sb);
	return 0;
}

func cg_emit_print_str(sb, label_id, len) {
	cg_emit_line(sb, "\t; print string");
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit(sb, "\tlea rsi, [rel S");
	cg_emit_u64(sb, label_id);
	cg_emit_line(sb, "]");
	cg_emit(sb, "\tmov rdx, ");
	cg_emit_u64(sb, len);
	cg_emit_nl(sb);
	cg_emit_line(sb, "\tsyscall");
	return 0;
}

func cg_emit_binop(sb, op) {
	cg_emit_line(sb, "\tpop rbx");
	cg_emit_line(sb, "\tpop rax");

	if (op == TokKind.PLUS) {
		cg_emit_line(sb, "\tadd rax, rbx");
	}
	else if (op == TokKind.MINUS) {
		cg_emit_line(sb, "\tsub rax, rbx");
	}
	else if (op == TokKind.STAR) {
		cg_emit_line(sb, "\timul rax, rbx");
	}
	else if (op == TokKind.SLASH) {
		cg_emit_line(sb, "\txor rdx, rdx");
		cg_emit_line(sb, "\tdiv rbx");
	}
	else if (op == TokKind.PERCENT) {
		cg_emit_line(sb, "\txor rdx, rdx");
		cg_emit_line(sb, "\tdiv rbx");
		cg_emit_line(sb, "\tmov rax, rdx");
	}
	else if (op == TokKind.EQEQ || op == TokKind.EQEQEQ) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsete al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.NEQ || op == TokKind.NEQEQ) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.AMP) {
		cg_emit_line(sb, "\tand rax, rbx");
	}
	else if (op == TokKind.PIPE) {
		cg_emit_line(sb, "\tor rax, rbx");
	}
	else if (op == TokKind.CARET) {
		cg_emit_line(sb, "\txor rax, rbx");
	}
	else if (op == TokKind.LSHIFT) {
		cg_emit_line(sb, "\tmov rcx, rbx");
		cg_emit_line(sb, "\tshl rax, cl");
	}
	else if (op == TokKind.RSHIFT) {
		cg_emit_line(sb, "\tmov rcx, rbx");
		cg_emit_line(sb, "\tshr rax, cl");
	}
	else if (op == TokKind.ROTL) {
		cg_emit_line(sb, "\tmov rcx, rbx");
		cg_emit_line(sb, "\trol rax, cl");
	}
	else if (op == TokKind.ROTR) {
		cg_emit_line(sb, "\tmov rcx, rbx");
		cg_emit_line(sb, "\tror rax, cl");
	}
	else if (op == TokKind.LT) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsetb al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.LTE) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsetbe al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GT) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tseta al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GTE) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsetae al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.ANDAND) {
		// Logical AND: (rax != 0) && (rbx != 0)
		cg_emit_line(sb, "\ttest rax, rax");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\ttest rbx, rbx");
		cg_emit_line(sb, "\tsetne bl");
		cg_emit_line(sb, "\tand al, bl");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.OROR) {
		// Logical OR: (rax != 0) || (rbx != 0)
		cg_emit_line(sb, "\tor rax, rbx");
		cg_emit_line(sb, "\ttest rax, rax");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}

	cg_emit_line(sb, "\tpush rax");
	return 0;
}

func cg_emit_unop(sb, op) {
	cg_emit_line(sb, "\tpop rax");
	if (op == TokKind.MINUS) {
		cg_emit_line(sb, "\tneg rax");
	}
	else if (op == TokKind.BANG) {
		cg_emit_line(sb, "\tcmp rax, 0");
		cg_emit_line(sb, "\tsete al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	cg_emit_line(sb, "\tpush rax");
	return 0;
}

// Phase 6.6: emit f32 binary operation (xmm0=lhs, xmm1=rhs, result in xmm0 or rax)
func cg_emit_binop_f32(sb, op) {
	if (op == TokKind.PLUS) {
		cg_emit_line(sb, "\taddss xmm0, xmm1");
	}
	else if (op == TokKind.MINUS) {
		cg_emit_line(sb, "\tsubss xmm0, xmm1");
	}
	else if (op == TokKind.STAR) {
		cg_emit_line(sb, "\tmulss xmm0, xmm1");
	}
	else if (op == TokKind.SLASH) {
		cg_emit_line(sb, "\tdivss xmm0, xmm1");
	}
	else if (op == TokKind.EQEQ) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tsete al");
		cg_emit_line(sb, "\tsetnp cl");
		cg_emit_line(sb, "\tand al, cl");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.NEQ) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\tsetp cl");
		cg_emit_line(sb, "\tor al, cl");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.LT) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tsetb al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.LTE) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tsetbe al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GT) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tseta al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GTE) {
		cg_emit_line(sb, "\tcomiss xmm0, xmm1");
		cg_emit_line(sb, "\tsetae al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	return 0;
}

// Phase 6.6: emit f64 binary operation (xmm0=lhs, xmm1=rhs, result in xmm0 or rax)
func cg_emit_binop_f64(sb, op) {
	if (op == TokKind.PLUS) {
		cg_emit_line(sb, "\taddsd xmm0, xmm1");
	}
	else if (op == TokKind.MINUS) {
		cg_emit_line(sb, "\tsubsd xmm0, xmm1");
	}
	else if (op == TokKind.STAR) {
		cg_emit_line(sb, "\tmulsd xmm0, xmm1");
	}
	else if (op == TokKind.SLASH) {
		cg_emit_line(sb, "\tdivsd xmm0, xmm1");
	}
	else if (op == TokKind.EQEQ) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tsete al");
		cg_emit_line(sb, "\tsetnp cl");
		cg_emit_line(sb, "\tand al, cl");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.NEQ) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\tsetp cl");
		cg_emit_line(sb, "\tor al, cl");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.LT) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tsetb al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.LTE) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tsetbe al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GT) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tseta al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.GTE) {
		cg_emit_line(sb, "\tcomisd xmm0, xmm1");
		cg_emit_line(sb, "\tsetae al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	return 0;
}

func cg_gen_asm(prog, ir_func) {
	var sb = sb_new(4096);
	cg_emit_rodata(sb, prog);
	cg_emit_text_prelude(sb);

	var funcs = ptr64[prog + 0];
	var fnc = 0;
	if (funcs != 0) { fnc = vec_len(funcs); }
	var fi = 0;
	while (fi < fnc) {
		var ir_func2 = vec_get(funcs, fi);
		var ret_label = ptr64[ir_func2 + 24];
		var fn_ret_reg = ptr64[ir_func2 + 40]; // ret_reg for @reg return

		cg_emit_bytes(sb, ptr64[ir_func2 + 0], ptr64[ir_func2 + 8]);
		cg_emit_line(sb, ":");
		cg_emit_line(sb, "\tpush rbp");
		cg_emit_line(sb, "\tmov rbp, rsp");
		// Reserve callee-saved regs for nospill/@reg usage.
		// Skip push if ret_reg uses that register (will be clobbered for return).
		if (fn_ret_reg != 12) { cg_emit_line(sb, "\tpush r12"); }
		if (fn_ret_reg != 13) { cg_emit_line(sb, "\tpush r13"); }
		if (fn_ret_reg != 14) { cg_emit_line(sb, "\tpush r14"); }
		if (fn_ret_reg != 15) { cg_emit_line(sb, "\tpush r15"); }

		var frame = ptr64[ir_func2 + 16];
		if (frame != 0) {
			cg_emit(sb, "\tsub rsp, ");
			cg_emit_u64(sb, frame);
			cg_emit_nl(sb);
		}

		var instrs = ptr64[ir_func2 + 32];
		var n = vec_len(instrs);
		var i = 0;
		while (i < n) {
			var ins = vec_get(instrs, i);
			var k = ptr64[ins + 0];
			var a = ptr64[ins + 8];
			var b = ptr64[ins + 16];
			var c = ptr64[ins + 24];

			if (k == IrInstrKind.PUSH_IMM) {
				cg_emit(sb, "\tpush ");
				cg_emit_u64(sb, a);
				cg_emit_nl(sb);
			}
			else if (k == IrInstrKind.PUSH_LOCAL) {
				if (cg_local_off_is_reg(a) != 0) {
					var rid = cg_local_off_reg_id(a);
					cg_emit(sb, "\tpush ");
					if (rid == 0) { cg_emit_line(sb, "rax"); }
					else if (rid == 1) { cg_emit_line(sb, "rcx"); }
					else if (rid == 2) { cg_emit_line(sb, "rdx"); }
					else if (rid == 3) { cg_emit_line(sb, "rbx"); }
					else if (rid == 6) { cg_emit_line(sb, "rsi"); }
					else if (rid == 7) { cg_emit_line(sb, "rdi"); }
					else if (rid == 8) { cg_emit_line(sb, "r8"); }
					else if (rid == 9) { cg_emit_line(sb, "r9"); }
					else if (rid == 10) { cg_emit_line(sb, "r10"); }
					else if (rid == 11) { cg_emit_line(sb, "r11"); }
					else if (rid == 12) { cg_emit_line(sb, "r12"); }
					else if (rid == 13) { cg_emit_line(sb, "r13"); }
					else if (rid == 14) { cg_emit_line(sb, "r14"); }
					else if (rid == 15) { cg_emit_line(sb, "r15"); }
					else { cg_emit_line(sb, "rax"); }
				}
				else {
					cg_emit(sb, "\tpush qword [rbp-");
					cg_emit_u64(sb, a);
					cg_emit_line(sb, "]");
				}
			}
			else if (k == IrInstrKind.STORE_LOCAL) {
				cg_emit_line(sb, "\tpop rax");
				if (cg_local_off_is_reg(a) != 0) {
					var rid2 = cg_local_off_reg_id(a);
					cg_emit(sb, "\tmov ");
					if (rid2 == 0) { cg_emit_line(sb, "rax, rax"); }
					else if (rid2 == 1) { cg_emit_line(sb, "rcx, rax"); }
					else if (rid2 == 2) { cg_emit_line(sb, "rdx, rax"); }
					else if (rid2 == 3) { cg_emit_line(sb, "rbx, rax"); }
					else if (rid2 == 6) { cg_emit_line(sb, "rsi, rax"); }
					else if (rid2 == 7) { cg_emit_line(sb, "rdi, rax"); }
					else if (rid2 == 8) { cg_emit_line(sb, "r8, rax"); }
					else if (rid2 == 9) { cg_emit_line(sb, "r9, rax"); }
					else if (rid2 == 10) { cg_emit_line(sb, "r10, rax"); }
					else if (rid2 == 11) { cg_emit_line(sb, "r11, rax"); }
					else if (rid2 == 12) { cg_emit_line(sb, "r12, rax"); }
					else if (rid2 == 13) { cg_emit_line(sb, "r13, rax"); }
					else if (rid2 == 14) { cg_emit_line(sb, "r14, rax"); }
					else if (rid2 == 15) { cg_emit_line(sb, "r15, rax"); }
					else { cg_emit_line(sb, "rax, rax"); }
				}
				else {
					cg_emit(sb, "\tmov [rbp-");
					cg_emit_u64(sb, a);
					cg_emit_line(sb, "], rax");
				}
			}
			else if (k == IrInstrKind.BINOP) {
				cg_emit_binop(sb, a);
			}
			else if (k == IrInstrKind.UNOP) {
				cg_emit_unop(sb, a);
			}
			else if (k == IrInstrKind.POP) {
				cg_emit_line(sb, "\tpop rax");
			}
			else if (k == IrInstrKind.LABEL) {
				cg_emit_label(sb, a);
			}
			else if (k == IrInstrKind.JMP) {
				cg_emit(sb, "\tjmp .L");
				cg_emit_u64(sb, a);
				cg_emit_nl(sb);
			}
			else if (k == IrInstrKind.JZ) {
				cg_emit_line(sb, "\tpop rax");
				cg_emit_line(sb, "\tcmp rax, 0");
				cg_emit(sb, "\tje .L");
				cg_emit_u64(sb, a);
				cg_emit_nl(sb);
			}
			else if (k == IrInstrKind.JNZ) {
				cg_emit_line(sb, "\tpop rax");
				cg_emit_line(sb, "\tcmp rax, 0");
				cg_emit(sb, "\tjne .L");
				cg_emit_u64(sb, a);
				cg_emit_nl(sb);
			}
			else if (k == IrInstrKind.PRINT_STR) {
				cg_emit_print_str(sb, a, b);
			}
			else if (k == IrInstrKind.PUSH_LOCAL_ADDR) {
				if (cg_local_off_is_reg(a) != 0) {
					// nospill/@reg locals do not have an address.
					cg_emit_line(sb, "\t; ERROR: reg local has no address");
					cg_emit_line(sb, "\tpush 0");
				}
				else {
					cg_emit(sb, "\tlea rax, [rbp-");
					cg_emit_u64(sb, a);
					cg_emit_line(sb, "]");
					cg_emit_line(sb, "\tpush rax");
				}
			}
			else if (k == IrInstrKind.STORE_LOCAL_RODATA_ADDR) {
				cg_emit(sb, "\tlea rax, [rel S");
				cg_emit_u64(sb, b);
				cg_emit_line(sb, "]");
				cg_emit(sb, "\tmov [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "], rax");
			}
			else if (k == IrInstrKind.STORE_SLICE_LOCAL) {
				cg_emit_line(sb, "\tpop rbx\t; len");
				cg_emit_line(sb, "\tpop rax\t; ptr");
				cg_emit(sb, "\tmov [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "], rax");
				cg_emit(sb, "\tmov [rbp-");
				cg_emit_u64(sb, a - 8);
				cg_emit_line(sb, "], rbx");
			}
			else if (k == IrInstrKind.PUSH_RODATA_ADDR) {
				cg_emit(sb, "\tlea rax, [rel S");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "]");
				cg_emit_line(sb, "\tpush rax");
			}
			// Phase 6.7: Push function address for function pointers
			else if (k == IrInstrKind.PUSH_FUNC_ADDR) {
				cg_emit(sb, "\tlea rax, [rel ");
				cg_emit_bytes(sb, a, b);
				cg_emit_line(sb, "]");
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.PRINT_SLICE) {
				cg_emit_line(sb, "\t; print slice bytes");
				cg_emit_line(sb, "\tpop rdx\t; len");
				cg_emit_line(sb, "\tpop rsi\t; ptr");
				cg_emit_line(sb, "\tmov rax, 1");
				cg_emit_line(sb, "\tmov rdi, 1");
				cg_emit_line(sb, "\tsyscall");
			}
			else if (k == IrInstrKind.PRINT_U64) {
				// print_u64: pop value, convert to decimal string, print with newline
				cg_emit_line(sb, "\t; print_u64");
				cg_emit_line(sb, "\tpop rax");
				cg_emit_line(sb, "\tcall __print_u64");
			}
			else if (k == IrInstrKind.PRINT_U64_NO_NL) {
				// print_u64 without newline
				cg_emit_line(sb, "\t; print_u64_no_nl");
				cg_emit_line(sb, "\tpop rax");
				cg_emit_line(sb, "\tcall __print_u64_no_nl");
			}
			else if (k == IrInstrKind.PRINT_NL) {
				// print newline
				cg_emit_line(sb, "\t; print_nl");
				cg_emit_line(sb, "\tcall __print_nl");
			}
			else if (k == IrInstrKind.PANIC) {
				// panic: pop slice (ptr, len), print "panic: <msg>\n" to stderr, exit(1)
				cg_emit_line(sb, "\t; panic");
				cg_emit_line(sb, "\tpop rdx\t; len");
				cg_emit_line(sb, "\tpop rsi\t; ptr");
				cg_emit_line(sb, "\tcall __panic");
			}
			else if (k == IrInstrKind.SLICE_INDEX_U8) {
				// Stack: ptr, len, idx
				cg_emit_line(sb, "\tpop rcx\t; idx");
				cg_emit_line(sb, "\tpop rbx\t; len");
				cg_emit_line(sb, "\tpop rax\t; ptr");
				if (a != 0) {
					cg_emit_line(sb, "\tcmp rcx, rbx");
					cg_emit_line(sb, "\tjae .L__bounds_fail");
				}
				cg_emit_line(sb, "\tadd rax, rcx");
				cg_emit_line(sb, "\tmovzx eax, byte [rax]");
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.RET) {
				cg_emit_line(sb, "\tpop rax");
				if (a != 0) {
					// Copy return value from rax into the requested return reg.
					cg_emit(sb, "\tmov ");
					if (a == 1) { cg_emit_line(sb, "rcx, rax"); }
					else if (a == 2) { cg_emit_line(sb, "rdx, rax"); }
					else if (a == 3) { cg_emit_line(sb, "rbx, rax"); }
					else if (a == 6) { cg_emit_line(sb, "rsi, rax"); }
					else if (a == 7) { cg_emit_line(sb, "rdi, rax"); }
					else if (a == 8) { cg_emit_line(sb, "r8, rax"); }
					else if (a == 9) { cg_emit_line(sb, "r9, rax"); }
					else if (a == 10) { cg_emit_line(sb, "r10, rax"); }
					else if (a == 11) { cg_emit_line(sb, "r11, rax"); }
					else if (a == 12) { cg_emit_line(sb, "r12, rax"); }
					else if (a == 13) { cg_emit_line(sb, "r13, rax"); }
					else if (a == 14) { cg_emit_line(sb, "r14, rax"); }
					else if (a == 15) { cg_emit_line(sb, "r15, rax"); }
					else { cg_emit_line(sb, "rax, rax"); }
				}
				cg_emit(sb, "\tjmp .L");
				cg_emit_u64(sb, ret_label);
				cg_emit_nl(sb);
			}
			else if (k == IrInstrKind.PUSH_ARG) {
				cg_emit(sb, "\tpush qword [rbp+");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "]");
			}
			else if (k == IrInstrKind.CALL) {
				cg_emit(sb, "\tcall ");
				cg_emit_bytes(sb, a, b);
				cg_emit_nl(sb);
				if (c != 0) {
					cg_emit(sb, "\tadd rsp, ");
					cg_emit_u64(sb, c);
					cg_emit_nl(sb);
				}
				cg_emit_line(sb, "\tpush rax");
			}
			// Phase 6.7: Indirect call through function pointer
			else if (k == IrInstrKind.CALL_INDIRECT) {
				// Stack top has function pointer value
				cg_emit_line(sb, "\tpop rax\t; func ptr");
				cg_emit_line(sb, "\tcall rax");
				if (a != 0) {
					cg_emit(sb, "\tadd rsp, ");
					cg_emit_u64(sb, a);
					cg_emit_nl(sb);
				}
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.LOAD_MEM8) {
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmovzx eax, byte [rax]");
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.LOAD_MEM64) {
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmov rax, qword [rax]");
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.STORE_MEM8) {
				cg_emit_line(sb, "\tpop rbx\t; value");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmov byte [rax], bl");
			}
			else if (k == IrInstrKind.STORE_MEM64) {
				cg_emit_line(sb, "\tpop rbx\t; value");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmov qword [rax], rbx");
			}
			else if (k == IrInstrKind.SECURE_STORE_MEM8) {
				cg_emit_line(sb, "\tpop rbx\t; value");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmov byte [rax], bl");
			}
			else if (k == IrInstrKind.SECURE_STORE_MEM64) {
				cg_emit_line(sb, "\tpop rbx\t; value");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmov qword [rax], rbx");
			}
			else if (k == IrInstrKind.CTEQ_SLICE_U8) {
				// Stack (top..): b_len, b_ptr, a_len, a_ptr
				var mismatch_id = a;
				var loop_id = b;
				var done_id = c;
				cg_emit_line(sb, "\tpop rcx\t; b_len");
				cg_emit_line(sb, "\tpop rbx\t; b_ptr");
				cg_emit_line(sb, "\tpop rdx\t; a_len");
				cg_emit_line(sb, "\tpop rax\t; a_ptr");
				cg_emit_line(sb, "\tcmp rdx, rcx");
				cg_emit(sb, "\tjne .L");
				cg_emit_u64(sb, mismatch_id);
				cg_emit_nl(sb);
				cg_emit_line(sb, "\txor r8, r8\t; acc");
				cg_emit_line(sb, "\txor r9, r9\t; i");
				cg_emit_label(sb, loop_id);
				cg_emit_line(sb, "\tcmp r9, rdx");
				cg_emit(sb, "\tje .L");
				cg_emit_u64(sb, done_id);
				cg_emit_nl(sb);
				cg_emit_line(sb, "\tmovzx r10d, byte [rax + r9]");
				cg_emit_line(sb, "\tmovzx r11d, byte [rbx + r9]");
				cg_emit_line(sb, "\txor r10d, r11d");
				cg_emit_line(sb, "\tor r8d, r10d");
				cg_emit_line(sb, "\tinc r9");
				cg_emit(sb, "\tjmp .L");
				cg_emit_u64(sb, loop_id);
				cg_emit_nl(sb);
				cg_emit_label(sb, mismatch_id);
				cg_emit_line(sb, "\tmov r8, 1\t; acc!=0 => false");
				cg_emit(sb, "\tjmp .L");
				cg_emit_u64(sb, done_id);
				cg_emit_nl(sb);
				cg_emit_label(sb, done_id);
				cg_emit_line(sb, "\tcmp r8, 0");
				cg_emit_line(sb, "\tsete al");
				cg_emit_line(sb, "\tmovzx rax, al");
				cg_emit_line(sb, "\tpush rax");
			}
			// Phase 6.6: floating-point instructions
			else if (k == IrInstrKind.PUSH_IMM_F32) {
				// Push 32-bit float as 64-bit (zero-extended)
				cg_emit(sb, "\tpush ");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "\t; f32 imm");
			}
			else if (k == IrInstrKind.PUSH_IMM_F64) {
				// Push 64-bit float
				cg_emit(sb, "\tmov rax, ");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "\t; f64 imm");
				cg_emit_line(sb, "\tpush rax");
			}
			else if (k == IrInstrKind.PUSH_LOCAL_F32) {
				cg_emit(sb, "\tmovss xmm0, dword [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "]");
				cg_emit_line(sb, "\tsub rsp, 8");
				cg_emit_line(sb, "\tmovss dword [rsp], xmm0");
			}
			else if (k == IrInstrKind.PUSH_LOCAL_F64) {
				cg_emit(sb, "\tmovsd xmm0, qword [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "]");
				cg_emit_line(sb, "\tsub rsp, 8");
				cg_emit_line(sb, "\tmovsd qword [rsp], xmm0");
			}
			else if (k == IrInstrKind.STORE_LOCAL_F32) {
				cg_emit_line(sb, "\tmovss xmm0, dword [rsp]");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit(sb, "\tmovss dword [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "], xmm0");
			}
			else if (k == IrInstrKind.STORE_LOCAL_F64) {
				cg_emit_line(sb, "\tmovsd xmm0, qword [rsp]");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit(sb, "\tmovsd qword [rbp-");
				cg_emit_u64(sb, a);
				cg_emit_line(sb, "], xmm0");
			}
			else if (k == IrInstrKind.BINOP_F32) {
				// a = TokKind for op
				cg_emit_line(sb, "\tmovss xmm1, dword [rsp]\t; rhs");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit_line(sb, "\tmovss xmm0, dword [rsp]\t; lhs");
				cg_emit_binop_f32(sb, a);
				cg_emit_line(sb, "\tmovss dword [rsp], xmm0");
			}
			else if (k == IrInstrKind.BINOP_F64) {
				// a = TokKind for op
				cg_emit_line(sb, "\tmovsd xmm1, qword [rsp]\t; rhs");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit_line(sb, "\tmovsd xmm0, qword [rsp]\t; lhs");
				cg_emit_binop_f64(sb, a);
				cg_emit_line(sb, "\tmovsd qword [rsp], xmm0");
			}
			else if (k == IrInstrKind.LOAD_MEM_F32) {
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmovss xmm0, dword [rax]");
				cg_emit_line(sb, "\tsub rsp, 8");
				cg_emit_line(sb, "\tmovss dword [rsp], xmm0");
			}
			else if (k == IrInstrKind.LOAD_MEM_F64) {
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmovsd xmm0, qword [rax]");
				cg_emit_line(sb, "\tsub rsp, 8");
				cg_emit_line(sb, "\tmovsd qword [rsp], xmm0");
			}
			else if (k == IrInstrKind.STORE_MEM_F32) {
				cg_emit_line(sb, "\tmovss xmm0, dword [rsp]\t; value");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmovss dword [rax], xmm0");
			}
			else if (k == IrInstrKind.STORE_MEM_F64) {
				cg_emit_line(sb, "\tmovsd xmm0, qword [rsp]\t; value");
				cg_emit_line(sb, "\tadd rsp, 8");
				cg_emit_line(sb, "\tpop rax\t; addr");
				cg_emit_line(sb, "\tmovsd qword [rax], xmm0");
			}

			i = i + 1;
		}

		cg_emit_label(sb, ret_label);
		if (frame != 0) {
			cg_emit(sb, "\tadd rsp, ");
			cg_emit_u64(sb, frame);
			cg_emit_nl(sb);
		}
		// Pop in reverse order, skip if ret_reg uses that register.
		if (fn_ret_reg != 15) { cg_emit_line(sb, "\tpop r15"); }
		if (fn_ret_reg != 14) { cg_emit_line(sb, "\tpop r14"); }
		if (fn_ret_reg != 13) { cg_emit_line(sb, "\tpop r13"); }
		if (fn_ret_reg != 12) { cg_emit_line(sb, "\tpop r12"); }
		cg_emit_line(sb, "\tmov rsp, rbp");
		cg_emit_line(sb, "\tpop rbp");
		cg_emit_line(sb, "\tret");
		cg_emit_nl(sb);

		fi = fi + 1;
	}

	// Common bounds failure path (does not return)
	cg_emit_line(sb, ".L__bounds_fail:");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tmov rax, 60");
	cg_emit_line(sb, "\tsyscall");

	// __print_u64: print rax as decimal, then newline
	cg_emit_line(sb, "__print_u64:");
	cg_emit_line(sb, "\tpush rbp");
	cg_emit_line(sb, "\tmov rbp, rsp");
	cg_emit_line(sb, "\tsub rsp, 32");
	cg_emit_line(sb, "\tmov rcx, rsp");
	cg_emit_line(sb, "\tadd rcx, 31");
	cg_emit_line(sb, "\tmov byte [rcx], 10"); // newline at end
	cg_emit_line(sb, "\tmov r8, rcx");
	cg_emit_line(sb, "\ttest rax, rax");
	cg_emit_line(sb, "\tjnz .L__pu64_loop");
	cg_emit_line(sb, "\tdec rcx");
	cg_emit_line(sb, "\tmov byte [rcx], 48"); // '0'
	cg_emit_line(sb, "\tjmp .L__pu64_print");
	cg_emit_line(sb, ".L__pu64_loop:");
	cg_emit_line(sb, "\ttest rax, rax");
	cg_emit_line(sb, "\tjz .L__pu64_print");
	cg_emit_line(sb, "\txor rdx, rdx");
	cg_emit_line(sb, "\tmov r9, 10");
	cg_emit_line(sb, "\tdiv r9");
	cg_emit_line(sb, "\tadd dl, 48");
	cg_emit_line(sb, "\tdec rcx");
	cg_emit_line(sb, "\tmov [rcx], dl");
	cg_emit_line(sb, "\tjmp .L__pu64_loop");
	cg_emit_line(sb, ".L__pu64_print:");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tmov rsi, rcx");
	cg_emit_line(sb, "\tmov rdx, r8");
	cg_emit_line(sb, "\tsub rdx, rcx");
	cg_emit_line(sb, "\tinc rdx"); // include newline
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tsyscall");
	cg_emit_line(sb, "\tmov rsp, rbp");
	cg_emit_line(sb, "\tpop rbp");
	cg_emit_line(sb, "\tret");

	// __print_u64_no_nl: print rax as decimal, no newline
	cg_emit_line(sb, "__print_u64_no_nl:");
	cg_emit_line(sb, "\tpush rbp");
	cg_emit_line(sb, "\tmov rbp, rsp");
	cg_emit_line(sb, "\tsub rsp, 32");
	cg_emit_line(sb, "\tmov rcx, rsp");
	cg_emit_line(sb, "\tadd rcx, 31");
	cg_emit_line(sb, "\tmov r8, rcx");
	cg_emit_line(sb, "\ttest rax, rax");
	cg_emit_line(sb, "\tjnz .L__pu64nn_loop");
	cg_emit_line(sb, "\tdec rcx");
	cg_emit_line(sb, "\tmov byte [rcx], 48");
	cg_emit_line(sb, "\tjmp .L__pu64nn_print");
	cg_emit_line(sb, ".L__pu64nn_loop:");
	cg_emit_line(sb, "\ttest rax, rax");
	cg_emit_line(sb, "\tjz .L__pu64nn_print");
	cg_emit_line(sb, "\txor rdx, rdx");
	cg_emit_line(sb, "\tmov r9, 10");
	cg_emit_line(sb, "\tdiv r9");
	cg_emit_line(sb, "\tadd dl, 48");
	cg_emit_line(sb, "\tdec rcx");
	cg_emit_line(sb, "\tmov [rcx], dl");
	cg_emit_line(sb, "\tjmp .L__pu64nn_loop");
	cg_emit_line(sb, ".L__pu64nn_print:");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tmov rsi, rcx");
	cg_emit_line(sb, "\tmov rdx, r8");
	cg_emit_line(sb, "\tsub rdx, rcx");
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tsyscall");
	cg_emit_line(sb, "\tmov rsp, rbp");
	cg_emit_line(sb, "\tpop rbp");
	cg_emit_line(sb, "\tret");

	// __print_nl: print newline
	cg_emit_line(sb, "__print_nl:");
	cg_emit_line(sb, "\tpush rbp");
	cg_emit_line(sb, "\tmov rbp, rsp");
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tlea rsi, [rel __panic_newline]");
	cg_emit_line(sb, "\tmov rdx, 1");
	cg_emit_line(sb, "\tsyscall");
	cg_emit_line(sb, "\tmov rsp, rbp");
	cg_emit_line(sb, "\tpop rbp");
	cg_emit_line(sb, "\tret");

	// __panic: rsi=ptr, rdx=len. Print "panic: <msg>\n" to stderr, exit(1)
	cg_emit_line(sb, "__panic:");
	cg_emit_line(sb, "\tpush rsi");
	cg_emit_line(sb, "\tpush rdx");
	// Print "panic: " to stderr (fd=2)
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tmov rdi, 2");
	cg_emit_line(sb, "\tlea rsi, [rel __panic_prefix]");
	cg_emit_line(sb, "\tmov rdx, 7");
	cg_emit_line(sb, "\tsyscall");
	// Print the message
	cg_emit_line(sb, "\tpop rdx");
	cg_emit_line(sb, "\tpop rsi");
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tmov rdi, 2");
	cg_emit_line(sb, "\tsyscall");
	// Print newline
	cg_emit_line(sb, "\tmov rax, 1");
	cg_emit_line(sb, "\tmov rdi, 2");
	cg_emit_line(sb, "\tlea rsi, [rel __panic_newline]");
	cg_emit_line(sb, "\tmov rdx, 1");
	cg_emit_line(sb, "\tsyscall");
	// exit(1)
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tmov rax, 60");
	cg_emit_line(sb, "\tsyscall");

	return sb;
}

func v3h_codegen_program(ast_prog) {
	// Lower all funcs to IR, return asm (ptr,len packed in heap Bytes)
	var out = heap_alloc(16);
	if (out == 0) { return 0; }
	ptr64[out + 0] = 0;
	ptr64[out + 8] = 0;

	var irp = ir_prog_new();
	if (irp == 0) { return out; }

	// ctx for lowering
	var ctx = heap_alloc(112);
	if (ctx == 0) { return out; }
	ptr64[ctx + 0] = irp;
	ptr64[ctx + 8] = 0;
	ptr64[ctx + 16] = vec_new(16);
	ptr64[ctx + 24] = 0;
	ptr64[ctx + 32] = 0;
	ptr64[ctx + 40] = vec_new(16);
	ptr64[ctx + 48] = ast_prog;
	ptr64[ctx + 56] = 0;
	ptr64[ctx + 64] = vec_new(16);
	ptr64[ctx + 72] = vec_new(16);
	ptr64[ctx + 80] = vec_new(16);
	ptr64[ctx + 88] = 0; // loop_depth
	ptr64[ctx + 96] = vec_new(16); // defer_stack
	ptr64[ctx + 104] = 0; // scope_depth for shadowing

	// Phase 3.5: synthesize default property hook functions.
	cg_emit_default_property_hooks(ast_prog, ctx, irp);

	var decls = ptr64[ast_prog + 0];
	var n = 0;
	if (decls != 0) { n = vec_len(decls); }
	var i = 0;
	var have_main = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			if (cg_slice_eq(name_ptr, name_len, "main", 4) == 1) { have_main = 1; }

			var fn = ir_func_new(name_ptr, name_len);
			ptr64[ctx + 8] = fn;
			ptr64[ctx + 16] = vec_new(16);
			ptr64[ctx + 56] = cg_decl_retreg(d);
			ptr64[fn + 40] = ptr64[ctx + 56]; // Store ret_reg in IrFunc
			// Scratch locals for wipe/secret lowering.
			cg_local_add(ctx, "__v3h_wipe_ptr", 14);
			cg_local_add(ctx, "__v3h_wipe_len", 14);
			// Check if function returns struct (needs sret)
			var sret_sz = cg_func_returns_struct(ast_prog, d);
			if (sret_sz != 0) {
				cg_local_add(ctx, "__sret_ptr", 10);
			}
			// Reset secret tracking for this function.
			var sv0 = ptr64[ctx + 40];
			if (sv0 != 0) { ptr64[sv0 + 8] = 0; }
			// Reserve a stable return label id (used by codegen).
			ptr64[ctx + 32] = cg_label_alloc(ctx);
			ptr64[fn + 24] = ptr64[ctx + 32];

			// Add params as locals and copy args into locals (unless @reg param).
			var params = ptr64[d + 24];
			var pn = 0;
			if (params != 0) { pn = vec_len(params); }
			var pi = 0;
			while (pi < pn) {
				var pst = vec_get(params, pi);
				var pname_ptr = ptr64[pst + 32];
				var pname_len = ptr64[pst + 40];
				var ptype = ptr64[pst + 48];
				var l = cg_local_add(ctx, pname_ptr, pname_len);
				if (l != 0) {
					var psz = cg_type_size_bytes(ptype);
					cg_local_set_size_bytes(l, psz);
					if (cg_decl_is_extern(d) != 0) {
						var preg = ptr64[pst + 16];
						if (preg != 0) { ptr64[l + 16] = cg_local_off_pack_reg(preg); }
					}
				}
				pi = pi + 1;
			}

			// Save base locals count (scratch + params) for shadowing support
			var base_locals_count = vec_len(ptr64[ctx + 16]);

			// Collect locals from body.
			var body = ptr64[d + 40];
			cg_collect_locals_in_stmt(ctx, body);
			var locals = ptr64[ctx + 16];
			var ln = vec_len(locals);
			// Assign offsets (contiguous), align to 8.
			// Keep [rbp-8..-32] for r12..r15 spills.
			var base_off = 32;
			var off = base_off;
			var nospill_reg_next = 12; // r12..r15
			// Avoid collisions with fixed @reg locals.
			var used_mask = 0;
			var prei = 0;
			while (prei < ln) {
				var ll = vec_get(locals, prei);
				if (ll != 0) {
					var o0 = ptr64[ll + 16];
					if (cg_local_off_is_reg(o0) != 0) {
						var rid0 = cg_local_off_reg_id(o0);
						if (rid0 >= 12 && rid0 <= 15) { used_mask = used_mask | (1 << (rid0 - 12)); }
					}
				}
				prei = prei + 1;
			}
			var li = 0;
			while (li < ln) {
				var l2 = vec_get(locals, li);
				if (cg_local_off_is_reg(ptr64[l2 + 16]) != 0) {
					// Fixed reg local (e.g. extern @reg param)
				}
				else if (cg_local_has_nospill(l2) != 0) {
					// nospill locals live in callee-saved regs (no stack slot).
					while (nospill_reg_next <= 15) {
						var shift_amt = nospill_reg_next - 12;
						var bit_mask = 1 << shift_amt;
						var is_used = used_mask & bit_mask;
						if (is_used == 0) { break; }
						nospill_reg_next = nospill_reg_next + 1;
					}
					ptr64[l2 + 16] = cg_local_off_pack_reg(nospill_reg_next);
					used_mask = used_mask | (1 << (nospill_reg_next - 12));
					nospill_reg_next = nospill_reg_next + 1;
				}
				else {
					var sz = cg_local_size_bytes(l2);
					if (off % 8 != 0) { off = off + (8 - (off % 8)); }
					off = off + sz;
					ptr64[l2 + 16] = off;
				}
				li = li + 1;
			}
			var frame = 0;
			if (off > base_off) { frame = off - base_off; }
			if (frame % 16 != 0) { frame = frame + 8; }
			ptr64[fn + 16] = frame;

			// Prologue arg copy: param i at [rbp+16+8*i] (skip @reg params)
			// For struct params, copy all qwords
			// If sret, first arg is hidden sret pointer
			pi = 0;
			var arg_off = 16;
			if (sret_sz != 0) {
				var sret_l = cg_local_find(ctx, "__sret_ptr", 10);
				if (sret_l != 0) {
					ir_emit(fn, IrInstrKind.PUSH_ARG, arg_off, 0, 0);
					ir_emit(fn, IrInstrKind.STORE_LOCAL, ptr64[sret_l + 16], 0, 0);
					arg_off = arg_off + 8;
				}
			}
			while (pi < pn) {
				var pst2 = vec_get(params, pi);
				var pname_ptr2 = ptr64[pst2 + 32];
				var pname_len2 = ptr64[pst2 + 40];
				var ptype2 = ptr64[pst2 + 48];
				var psz2 = cg_type_size_bytes_prog(ast_prog, ptype2);
				var l3 = cg_local_find(ctx, pname_ptr2, pname_len2);
				if (l3 != 0) {
					if (cg_local_off_is_reg(ptr64[l3 + 16]) == 0) {
						if (psz2 > 8 && psz2 != 24) {
							// Struct param: copy all qwords
							var qw2 = psz2 / 8;
							var qi2 = 0;
							while (qi2 < qw2) {
								ir_emit(fn, IrInstrKind.PUSH_ARG, arg_off + qi2 * 8, 0, 0);
								ir_emit(fn, IrInstrKind.STORE_LOCAL, ptr64[l3 + 16] - qi2 * 8, 0, 0);
								qi2 = qi2 + 1;
							}
							arg_off = arg_off + psz2;
						} else {
							ir_emit(fn, IrInstrKind.PUSH_ARG, arg_off, 0, 0);
							ir_emit(fn, IrInstrKind.STORE_LOCAL, ptr64[l3 + 16], 0, 0);
							arg_off = arg_off + 8;
						}
					} else {
						arg_off = arg_off + 8;
					}
				} else {
					arg_off = arg_off + 8;
				}
				pi = pi + 1;
			}

			// Truncate locals to base (scratch + params) for shadowing support
			// Body vars will be re-added during lower as they are encountered
			ptr64[locals + 8] = base_locals_count;

			cg_lower_stmt(ctx, body);
			ir_emit(fn, IrInstrKind.PUSH_IMM, 0, 0, 0);
			ir_emit(fn, IrInstrKind.RET, ptr64[ctx + 56], 0, 0);
			vec_push(ptr64[irp + 0], fn);
		}
		i = i + 1;
	}
	if (have_main == 0) { return out; }

	var sb = cg_gen_asm(irp, 0);
	if (sb == 0) { return out; }
	ptr64[out + 0] = sb_ptr(sb);
	ptr64[out + 8] = sb_len(sb);
	return out;
}

func v3h_codegen_program_dump_ir(ast_prog) {
	// Lower to IR and dump it (ptr,len packed in heap Bytes).
	var irp = ir_prog_new();
	if (irp == 0) { return 0; }

	// ctx for lowering
	var ctx = heap_alloc(112);
	if (ctx == 0) { return 0; }
	ptr64[ctx + 0] = irp;
	ptr64[ctx + 8] = 0;
	ptr64[ctx + 16] = vec_new(16);
	ptr64[ctx + 24] = 0;
	ptr64[ctx + 32] = 0;
	ptr64[ctx + 40] = vec_new(16);
	ptr64[ctx + 48] = ast_prog;
	ptr64[ctx + 56] = 0;
	ptr64[ctx + 64] = 0;
	ptr64[ctx + 72] = 0;
	ptr64[ctx + 80] = 0;
	ptr64[ctx + 88] = 0; // loop_depth
	ptr64[ctx + 96] = vec_new(16); // defer_stack
	ptr64[ctx + 104] = 0; // scope_depth for shadowing

	// Phase 3.5: synthesize default property hook functions.
	cg_emit_default_property_hooks(ast_prog, ctx, irp);

	var decls = ptr64[ast_prog + 0];
	var n = 0;
	if (decls != 0) { n = vec_len(decls); }
	var i = 0;
	var have_main = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (d != 0 && ptr64[d + 0] == AstDeclKind.FUNC) {
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			if (cg_slice_eq(name_ptr, name_len, "main", 4) == 1) { have_main = 1; }

			var fn = ir_func_new(name_ptr, name_len);
			ptr64[ctx + 8] = fn;
			ptr64[ctx + 16] = vec_new(16);
			ptr64[ctx + 56] = cg_decl_retreg(d);
			ptr64[fn + 40] = ptr64[ctx + 56]; // Store ret_reg in IrFunc
			// Scratch locals for wipe/secret lowering.
			cg_local_add(ctx, "__v3h_wipe_ptr", 14);
			cg_local_add(ctx, "__v3h_wipe_len", 14);
			var sv0 = ptr64[ctx + 40];
			if (sv0 != 0) { ptr64[sv0 + 8] = 0; }
			ptr64[ctx + 32] = cg_label_alloc(ctx);
			ptr64[fn + 24] = ptr64[ctx + 32];

			var params = ptr64[d + 24];
			var pn = 0;
			if (params != 0) { pn = vec_len(params); }
			var pi = 0;
			while (pi < pn) {
				var pst = vec_get(params, pi);
				var pname_ptr = ptr64[pst + 32];
				var pname_len = ptr64[pst + 40];
				var ptype = ptr64[pst + 48];
				var l = cg_local_add(ctx, pname_ptr, pname_len);
				if (l != 0) {
					var psz = cg_type_size_bytes(ptype);
					cg_local_set_size_bytes(l, psz);
					if (cg_decl_is_extern(d) != 0) {
						var preg = ptr64[pst + 16];
						if (preg != 0) { ptr64[l + 16] = cg_local_off_pack_reg(preg); }
					}
				}
				pi = pi + 1;
			}

			// Save base locals count (scratch + params) for shadowing support
			var base_locals_count = vec_len(ptr64[ctx + 16]);

			var body = ptr64[d + 40];
			cg_collect_locals_in_stmt(ctx, body);
			var locals = ptr64[ctx + 16];
			var base_off = 32;
			var off = base_off;
			var nospill_reg_next = 12;
			var ln = vec_len(locals);
			// Avoid collisions with fixed @reg locals.
			var used_mask = 0;
			var prei = 0;
			while (prei < ln) {
				var ll = vec_get(locals, prei);
				if (ll != 0) {
					var o0 = ptr64[ll + 16];
					if (cg_local_off_is_reg(o0) != 0) {
						var rid0 = cg_local_off_reg_id(o0);
						if (rid0 >= 12 && rid0 <= 15) { used_mask = used_mask | (1 << (rid0 - 12)); }
					}
				}
				prei = prei + 1;
			}
			var li = 0;
			while (li < ln) {
				var l2 = vec_get(locals, li);
				if (cg_local_off_is_reg(ptr64[l2 + 16]) != 0) {
					// Fixed reg local (e.g. extern @reg param)
				}
				else if (cg_local_has_nospill(l2) != 0) {
					while (nospill_reg_next <= 15) {
						var shift_amt = nospill_reg_next - 12;
						var bit_mask = 1 << shift_amt;
						var is_used = used_mask & bit_mask;
						if (is_used == 0) { break; }
						nospill_reg_next = nospill_reg_next + 1;
					}
					ptr64[l2 + 16] = cg_local_off_pack_reg(nospill_reg_next);
					var shift_amt2 = nospill_reg_next - 12;
					used_mask = used_mask | (1 << shift_amt2);
					nospill_reg_next = nospill_reg_next + 1;
				}
				else {
					var sz = cg_local_size_bytes(l2);
					if (off % 8 != 0) { off = off + (8 - (off % 8)); }
					off = off + sz;
					ptr64[l2 + 16] = off;
				}
				li = li + 1;
			}
			var frame = 0;
			if (off > base_off) { frame = off - base_off; }
			if (frame % 16 != 0) { frame = frame + 8; }
			ptr64[fn + 16] = frame;

			// Prologue arg copy (skip @reg params)
			pi = 0;
			while (pi < pn) {
				var pst2 = vec_get(params, pi);
				var pname_ptr2 = ptr64[pst2 + 32];
				var pname_len2 = ptr64[pst2 + 40];
				var l3 = cg_local_find(ctx, pname_ptr2, pname_len2);
				if (l3 != 0) {
					if (cg_local_off_is_reg(ptr64[l3 + 16]) == 0) {
						ir_emit(fn, IrInstrKind.PUSH_ARG, 16 + (pi * 8), 0, 0);
						ir_emit(fn, IrInstrKind.STORE_LOCAL, ptr64[l3 + 16], 0, 0);
					}
				}
				pi = pi + 1;
			}

			// Truncate locals to base (scratch + params) for shadowing support
			ptr64[locals + 8] = base_locals_count;

			cg_lower_stmt(ctx, body);
			ir_emit(fn, IrInstrKind.PUSH_IMM, 0, 0, 0);
			ir_emit(fn, IrInstrKind.RET, ptr64[ctx + 56], 0, 0);
			vec_push(ptr64[irp + 0], fn);
		}
		i = i + 1;
	}
	if (have_main == 0) { return 0; }
	return ir_dump_program(irp);
}
