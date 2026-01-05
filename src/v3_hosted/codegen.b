// v3_hosted: minimal lowering + x86-64 codegen (Phase 1.5)

import vec;
import slice;
import string_builder;

import v3_hosted.ast;
import v3_hosted.token;
import v3_hosted.ir;
import v3_hosted.typecheck;

struct CgLocal {
	name_ptr: u64;
	name_len: u64;
	offset: u64; // [rbp-offset]
	size_bytes: u64; // low bits=size, high bit may store flags
};

func cg_local_size_bytes(l) {
	return ptr64[l + 24];
}

func cg_local_is_slice(l) {
	return ptr64[l + 24] == 24;
}

struct CodegenCtx {
	prog: u64; // IrProgram*
	fn: u64; // IrFunc*
	locals: u64; // Vec of CgLocal*
	label_next: u64;
	ret_label: u64;
};

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
	var locals = ptr64[ctx + 16];
	var n = vec_len(locals);
	var i = 0;
	while (i < n) {
		var l = vec_get(locals, i);
		if (cg_slice_eq(ptr64[l + 0], ptr64[l + 8], name_ptr, name_len) == 1) {
			return l;
		}
		i = i + 1;
	}
	return 0;
}

func cg_local_add(ctx, name_ptr, name_len) {
	var locals = ptr64[ctx + 16];
	var existing = cg_local_find(ctx, name_ptr, name_len);
	if (existing != 0) { return existing; }

	var l = heap_alloc(32);
	if (l == 0) { return 0; }
	ptr64[l + 0] = name_ptr;
	ptr64[l + 8] = name_len;
	ptr64[l + 16] = 0;
	ptr64[l + 24] = 8;
	vec_push(locals, l);
	return l;
}

func cg_local_set_size_bytes(l, size_bytes) {
	// Only grow (collection may see partial info before typecheck-style inference).
	var cur = ptr64[l + 24];
	if (cur < size_bytes) {
		ptr64[l + 24] = size_bytes;
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

func cg_label_alloc(ctx) {
	var id = ptr64[ctx + 24];
	ptr64[ctx + 24] = id + 1;
	return id;
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
		var name_ptr = ptr64[st + 32];
		var name_len = ptr64[st + 40];
		var l = cg_local_add(ctx, name_ptr, name_len);
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
					cg_local_add(ctx, name0_ptr, name0_len);
				}
				if (cg_is_discard_ident(name1_ptr, name1_len) == 0) {
					cg_local_add(ctx, name1_ptr, name1_len);
				}
			} else {
				if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
					cg_local_add(ctx, name0_ptr, name0_len);
				}
			}
		}

		// Per-foreach internal locals (unique by start_off).
		var id = ptr64[st + 64];
		alias rdx : n_reg;
		var p_i = cg_tmp_name("__foreach_i_", 12, id);
		var n_i = n_reg;
		cg_local_add(ctx, p_i, n_i);
		var p_ptr = cg_tmp_name("__foreach_ptr_", 14, id);
		var n_ptr = n_reg;
		cg_local_add(ctx, p_ptr, n_ptr);
		var p_len = cg_tmp_name("__foreach_len_", 14, id);
		var n_len = n_reg;
		cg_local_add(ctx, p_len, n_len);

		cg_collect_locals_in_stmt(ctx, ptr64[st + 24]);
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
		var via_ptr = extra >> 63;
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

	if (ek == AstExprKind.OFFSETOF) {
		// Typecheck stores computed offset in e->op.
		ir_emit(f, IrInstrKind.PUSH_IMM, ptr64[e + 8], 0, 0);
		return 0;
	}

	if (ek == AstExprKind.FIELD) {
		var extra = ptr64[e + 32];
		var sz = (extra >> 56) & 127;
		if (sz == 127) {
			// enum member constant; typecheck stores value in op.
			ir_emit(f, IrInstrKind.PUSH_IMM, ptr64[e + 8], 0, 0);
			return 0;
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
		cg_lower_expr(ctx, ptr64[e + 16]);
		ir_emit(f, IrInstrKind.UNOP, op, 0, 0);
		return 0;
	}

	if (ek == AstExprKind.BINARY) {
		var op = ptr64[e + 8];
		var lhs = ptr64[e + 16];
		var rhs = ptr64[e + 24];
		if (op == TokKind.EQ) {
			// assignment
			if (ptr64[lhs + 0] == AstExprKind.FIELD) {
				// field assignment (scalar or u8)
				var extra = ptr64[lhs + 32];
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

			if (cg_slice_eq(name_ptr, name_len, "slice_from_ptr_len", 18) == 1) {
				if (vec_len(args) == 2) {
					// Lower to slice {ptr,len}
					cg_lower_expr(ctx, vec_get(args, 0));
					cg_lower_expr(ctx, vec_get(args, 1));
					return 0;
				}
			}
		}
		// Unsupported call: leave 0
		ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
		return 0;
	}

	// fallback
	ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0);
	return 0;
}

func cg_lower_stmt(ctx, st) {
	var k = ptr64[st + 0];
	var f = ptr64[ctx + 8];

	if (k == AstStmtKind.VAR) {
		var name_ptr = ptr64[st + 32];
		var name_len = ptr64[st + 40];
		var init = ptr64[st + 56];
		var l = cg_local_find(ctx, name_ptr, name_len);
		if (l == 0) { l = cg_local_add(ctx, name_ptr, name_len); }
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
					return 0;
				}
				cg_lower_expr(ctx, init);
				ir_emit(f, IrInstrKind.STORE_LOCAL, ptr64[l + 16], 0, 0);
			}
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
		var e = ptr64[st + 56];
		if (e != 0) { cg_lower_expr(ctx, e); }
		else { ir_emit(f, IrInstrKind.PUSH_IMM, 0, 0, 0); }
		ir_emit(f, IrInstrKind.RET, 0, 0, 0);
		return 0;
	}

	if (k == AstStmtKind.BLOCK) {
		var ss = ptr64[st + 8];
		var n = vec_len(ss);
		var i = 0;
		while (i < n) {
			cg_lower_stmt(ctx, vec_get(ss, i));
			i = i + 1;
		}
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
		ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);
		cg_lower_expr(ctx, ptr64[st + 8]);
		ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);
		cg_lower_stmt(ctx, ptr64[st + 16]);
		ir_emit(f, IrInstrKind.JMP, start_id, 0, 0);
		ir_emit(f, IrInstrKind.LABEL, end_id, 0, 0);
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

		var l_i = cg_foreach_tmp_local(ctx, st, "__foreach_i_", 12);
		var l_ptr = cg_foreach_tmp_local(ctx, st, "__foreach_ptr_", 14);
		var l_len = cg_foreach_tmp_local(ctx, st, "__foreach_len_", 14);
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

		var start_id = cg_label_alloc(ctx);
		var end_id = cg_label_alloc(ctx);
		ir_emit(f, IrInstrKind.LABEL, start_id, 0, 0);

		// cond: i < len
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_i + 16], 0, 0);
		ir_emit(f, IrInstrKind.PUSH_LOCAL, ptr64[l_len + 16], 0, 0);
		ir_emit(f, IrInstrKind.BINOP, TokKind.LT, 0, 0);
		ir_emit(f, IrInstrKind.JZ, end_id, 0, 0);

		// Optional idx binding.
		if (has_two == 1) {
			if (cg_is_discard_ident(name0_ptr, name0_len) == 0) {
				var l_idx = cg_local_find(ctx, name0_ptr, name0_len);
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
				var l_val = cg_local_find(ctx, name1_ptr, name1_len);
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
				var l_val2 = cg_local_find(ctx, name0_ptr, name0_len);
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
	else if (op == TokKind.EQEQ) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsete al");
		cg_emit_line(sb, "\tmovzx rax, al");
	}
	else if (op == TokKind.NEQ) {
		cg_emit_line(sb, "\tcmp rax, rbx");
		cg_emit_line(sb, "\tsetne al");
		cg_emit_line(sb, "\tmovzx rax, al");
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

func cg_gen_asm(prog, ir_func) {
	var sb = sb_new(4096);
	cg_emit_rodata(sb, prog);
	cg_emit_text_prelude(sb);

	// Only main for now
	var ret_label = ptr64[ir_func + 24];

	cg_emit_line(sb, "main:");
	cg_emit_line(sb, "\tpush rbp");
	cg_emit_line(sb, "\tmov rbp, rsp");

	var frame = ptr64[ir_func + 16];
	if (frame != 0) {
		cg_emit(sb, "\tsub rsp, ");
		cg_emit_u64(sb, frame);
		cg_emit_nl(sb);
	}

	var instrs = ptr64[ir_func + 32];
	var n = vec_len(instrs);
	var i = 0;
	while (i < n) {
		var ins = vec_get(instrs, i);
		var k = ptr64[ins + 0];
		var a = ptr64[ins + 8];
		var b = ptr64[ins + 16];

		if (k == IrInstrKind.PUSH_IMM) {
			cg_emit(sb, "\tpush ");
			cg_emit_u64(sb, a);
			cg_emit_nl(sb);
		}
		else if (k == IrInstrKind.PUSH_LOCAL) {
			cg_emit(sb, "\tpush qword [rbp-");
			cg_emit_u64(sb, a);
			cg_emit_line(sb, "]");
		}
		else if (k == IrInstrKind.STORE_LOCAL) {
			cg_emit_line(sb, "\tpop rax");
			cg_emit(sb, "\tmov [rbp-");
			cg_emit_u64(sb, a);
			cg_emit_line(sb, "], rax");
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
		else if (k == IrInstrKind.PRINT_STR) {
			cg_emit_print_str(sb, a, b);
		}
		else if (k == IrInstrKind.PUSH_LOCAL_ADDR) {
			cg_emit(sb, "\tlea rax, [rbp-");
			cg_emit_u64(sb, a);
			cg_emit_line(sb, "]");
			cg_emit_line(sb, "\tpush rax");
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
		else if (k == IrInstrKind.PRINT_SLICE) {
			cg_emit_line(sb, "\t; print slice bytes");
			cg_emit_line(sb, "\tpop rdx\t; len");
			cg_emit_line(sb, "\tpop rsi\t; ptr");
			cg_emit_line(sb, "\tmov rax, 1");
			cg_emit_line(sb, "\tmov rdi, 1");
			cg_emit_line(sb, "\tsyscall");
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
			cg_emit(sb, "\tjmp .L");
			cg_emit_u64(sb, ret_label);
			cg_emit_nl(sb);
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

		i = i + 1;
	}

	cg_emit_label(sb, ret_label);
	cg_emit_line(sb, "\tmov rsp, rbp");
	cg_emit_line(sb, "\tpop rbp");
	cg_emit_line(sb, "\tret");

	// Common bounds failure path (does not return)
	cg_emit_line(sb, ".L__bounds_fail:");
	cg_emit_line(sb, "\tmov rdi, 1");
	cg_emit_line(sb, "\tmov rax, 60");
	cg_emit_line(sb, "\tsyscall");

	return sb;
}

func v3h_codegen_program(ast_prog) {
	// Find main, lower to IR, return asm (ptr,len packed in heap Bytes)
	var out = heap_alloc(16);
	if (out == 0) { return 0; }
	ptr64[out + 0] = 0;
	ptr64[out + 8] = 0;

	var irp = ir_prog_new();
	if (irp == 0) { return out; }

	// ctx for lowering
	var ctx = heap_alloc(40);
	if (ctx == 0) { return out; }
	ptr64[ctx + 0] = irp;
	ptr64[ctx + 8] = 0;
	ptr64[ctx + 16] = vec_new(16);
	ptr64[ctx + 24] = 0;
	ptr64[ctx + 32] = 0;

	var decls = ptr64[ast_prog + 0];
	var n = vec_len(decls);
	var i = 0;
	var main_decl = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (ptr64[d + 0] == AstDeclKind.FUNC) {
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			if (cg_slice_eq(name_ptr, name_len, "main", 4) == 1) {
				main_decl = d;
				break;
			}
		}
		i = i + 1;
	}
	if (main_decl == 0) { return out; }

	var fn = ir_func_new("main", 4);
	ptr64[ctx + 8] = fn;
	// Reserve a stable return label id (used by codegen).
	ptr64[ctx + 32] = cg_label_alloc(ctx);
	// Store ret_label on function for codegen.
	ptr64[fn + 24] = ptr64[ctx + 32];

	// collect locals
	var body = ptr64[main_decl + 40];
	cg_collect_locals_in_stmt(ctx, body);
	var locals = ptr64[ctx + 16];
	// assign offsets with correct widths (u64=8, slice=16)
	var off = 0;
	var ln = vec_len(locals);
	var li = 0;
	while (li < ln) {
		var l = vec_get(locals, li);
		var sz = cg_local_size_bytes(l);
		// align to 8 bytes
		if (off % 8 != 0) { off = off + (8 - (off % 8)); }
		off = off + sz;
		// Base offset is the start address of this local (contiguous block).
		ptr64[l + 16] = off;
		li = li + 1;
	}
	var frame = off;
	if (frame % 16 != 0) { frame = frame + 8; }
	ptr64[fn + 16] = frame;

	cg_lower_stmt(ctx, body);
	// implicit return 0 if not returned
	ir_emit(fn, IrInstrKind.PUSH_IMM, 0, 0, 0);
	ir_emit(fn, IrInstrKind.RET, 0, 0, 0);

	vec_push(ptr64[irp + 0], fn);

	var sb = cg_gen_asm(irp, fn);
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
	var ctx = heap_alloc(40);
	if (ctx == 0) { return 0; }
	ptr64[ctx + 0] = irp;
	ptr64[ctx + 8] = 0;
	ptr64[ctx + 16] = vec_new(16);
	ptr64[ctx + 24] = 0;
	ptr64[ctx + 32] = 0;

	var decls = ptr64[ast_prog + 0];
	var n = vec_len(decls);
	var i = 0;
	var main_decl = 0;
	while (i < n) {
		var d = vec_get(decls, i);
		if (ptr64[d + 0] == AstDeclKind.FUNC) {
			var name_ptr = ptr64[d + 8];
			var name_len = ptr64[d + 16];
			if (cg_slice_eq(name_ptr, name_len, "main", 4) == 1) {
				main_decl = d;
				break;
			}
		}
		i = i + 1;
	}
	if (main_decl == 0) { return 0; }

	var fn = ir_func_new("main", 4);
	ptr64[ctx + 8] = fn;
	// Reserve a stable return label id (used by codegen).
	ptr64[ctx + 32] = cg_label_alloc(ctx);
	// Store ret_label on function for dumps/codegen.
	ptr64[fn + 24] = ptr64[ctx + 32];

	// collect locals
	var body = ptr64[main_decl + 40];
	cg_collect_locals_in_stmt(ctx, body);
	var locals = ptr64[ctx + 16];
	// assign offsets with correct widths (u64=8, slice=16)
	var off = 0;
	var ln = vec_len(locals);
	var li = 0;
	while (li < ln) {
		var l = vec_get(locals, li);
		var sz = cg_local_size_bytes(l);
		if (off % 8 != 0) { off = off + (8 - (off % 8)); }
		off = off + sz;
		ptr64[l + 16] = off;
		li = li + 1;
	}
	var frame = off;
	if (frame % 16 != 0) { frame = frame + 8; }
	ptr64[fn + 16] = frame;

	cg_lower_stmt(ctx, body);
	// implicit return 0 if not returned
	ir_emit(fn, IrInstrKind.PUSH_IMM, 0, 0, 0);
	ir_emit(fn, IrInstrKind.RET, 0, 0, 0);

	vec_push(ptr64[irp + 0], fn);

	return ir_dump_program(irp);
}
