// v3_hosted: minimal IR (Phase 1.5)
//
// Simple stack-machine IR suitable for direct x86-64 codegen.

import vec;
import string_builder;

enum IrInstrKind {
	PUSH_IMM = 1,
	PUSH_LOCAL = 2,
	STORE_LOCAL = 3,
	BINOP = 4,
	UNOP = 5,
	POP = 6,
	LABEL = 7,
	JMP = 8,
	JZ = 9,
	JNZ = 28,
	RET = 10,
	PRINT_STR = 11,
	PUSH_LOCAL_ADDR = 12,
	STORE_LOCAL_RODATA_ADDR = 13,
	STORE_SLICE_LOCAL = 14,
	PRINT_SLICE = 15,
	SLICE_INDEX_U8 = 16,
	PUSH_RODATA_ADDR = 17,
	LOAD_MEM8 = 18,
	LOAD_MEM64 = 19,
	STORE_MEM8 = 20,
	STORE_MEM64 = 21,
	PUSH_ARG = 22,
	CALL = 23,
	SECURE_STORE_MEM8 = 24,
	SECURE_STORE_MEM64 = 25,
	CTEQ_SLICE_U8 = 26,
	PRINT_U64 = 27,
	PANIC = 29
};

struct IrInstr {
	kind: u64;
	a: u64;
	b: u64;
	c: u64;
};

struct IrFunc {
	name_ptr: u64;
	name_len: u64;
	frame_size: u64;
	ret_label: u64;
	instrs: u64; // Vec of IrInstr*
	ret_reg: u64; // 0=rax (default), or reg_id for @reg return
};

struct IrProgram {
	funcs: u64; // Vec of IrFunc*
	rodata: u64; // Vec of Rodata*
};

// Rodata entry for string literals (bytes)
struct Rodata {
	bytes_ptr: u64;
	bytes_len: u64;
	label_id: u64;
};

func ir_prog_new() {
	var p = heap_alloc(16);
	if (p == 0) { return 0; }
	ptr64[p + 0] = vec_new(4);
	ptr64[p + 8] = vec_new(8);
	return p;
}

func ir_func_new(name_ptr, name_len) {
	var f = heap_alloc(48);
	if (f == 0) { return 0; }
	ptr64[f + 0] = name_ptr;
	ptr64[f + 8] = name_len;
	ptr64[f + 16] = 0;
	ptr64[f + 24] = 0;
	ptr64[f + 32] = vec_new(64);
	ptr64[f + 40] = 0; // ret_reg: 0=rax (default)
	return f;
}

func ir_instr_new(kind, a, b, c) {
	var i = heap_alloc(32);
	if (i == 0) { return 0; }
	ptr64[i + 0] = kind;
	ptr64[i + 8] = a;
	ptr64[i + 16] = b;
	ptr64[i + 24] = c;
	return i;
}

func ir_emit(f, kind, a, b, c) {
	var instrs = ptr64[f + 32];
	var i = ir_instr_new(kind, a, b, c);
	if (i == 0) { return 0; }
	vec_push(instrs, i);
	return 0;
}

// Debug: dump IR to a textual format.
// Returns a heap blob with layout: { ptr:u64, len:u64 }.

func ir_dump_emit(sb, s) {
	sb_append_cstr(sb, s);
	return 0;
}

func ir_dump_emit_u64(sb, v) {
	sb_append_u64_dec(sb, v);
	return 0;
}

func ir_dump_emit_nl(sb) {
	sb_append_cstr(sb, "\n");
	return 0;
}

func ir_dump_emit_bytes(sb, p, n) {
	if (p == 0) { return 0; }
	if (n == 0) { return 0; }
	sb_append_bytes(sb, p, n);
	return 0;
}

func ir_dump_instr(sb, idx, ins) {
	// Format: "  <idx>: k=<kind> a=<a> b=<b> c=<c>\n"
	ir_dump_emit(sb, "  ");
	ir_dump_emit_u64(sb, idx);
	ir_dump_emit(sb, ": k=");
	ir_dump_emit_u64(sb, ptr64[ins + 0]);
	ir_dump_emit(sb, " a=");
	ir_dump_emit_u64(sb, ptr64[ins + 8]);
	ir_dump_emit(sb, " b=");
	ir_dump_emit_u64(sb, ptr64[ins + 16]);
	ir_dump_emit(sb, " c=");
	ir_dump_emit_u64(sb, ptr64[ins + 24]);
	ir_dump_emit_nl(sb);
	return 0;
}

func ir_dump_func(sb, f) {
	ir_dump_emit(sb, "func ");
	ir_dump_emit_bytes(sb, ptr64[f + 0], ptr64[f + 8]);
	ir_dump_emit(sb, " frame=");
	ir_dump_emit_u64(sb, ptr64[f + 16]);
	ir_dump_emit(sb, " ret_label=");
	ir_dump_emit_u64(sb, ptr64[f + 24]);
	ir_dump_emit_nl(sb);

	var instrs = ptr64[f + 32];
	var n = 0;
	if (instrs != 0) { n = vec_len(instrs); }
	var i = 0;
	while (i < n) {
		ir_dump_instr(sb, i, vec_get(instrs, i));
		i = i + 1;
	}
	ir_dump_emit_nl(sb);
	return 0;
}

func ir_dump_program(prog) {
	var out = heap_alloc(16);
	if (out == 0) { return 0; }
	ptr64[out + 0] = 0;
	ptr64[out + 8] = 0;

	var sb = sb_new(4096);
	if (sb == 0) { return out; }

	ir_dump_emit(sb, "IR\n");
	ir_dump_emit(sb, "===\n\n");

	// Rodata
	ir_dump_emit(sb, "rodata\n");
	ir_dump_emit(sb, "------\n");
	var rd = ptr64[prog + 8];
	var rn = 0;
	if (rd != 0) { rn = vec_len(rd); }
	var ri = 0;
	while (ri < rn) {
		var r = vec_get(rd, ri);
		ir_dump_emit(sb, "  S");
		ir_dump_emit_u64(sb, ptr64[r + 16]);
		ir_dump_emit(sb, " len=");
		ir_dump_emit_u64(sb, ptr64[r + 8]);
		ir_dump_emit_nl(sb);
		ri = ri + 1;
	}
	ir_dump_emit_nl(sb);

	// Funcs
	ir_dump_emit(sb, "funcs\n");
	ir_dump_emit(sb, "-----\n\n");
	var fs = ptr64[prog + 0];
	var fn = 0;
	if (fs != 0) { fn = vec_len(fs); }
	var fi = 0;
	while (fi < fn) {
		ir_dump_func(sb, vec_get(fs, fi));
		fi = fi + 1;
	}

	ptr64[out + 0] = sb_ptr(sb);
	ptr64[out + 8] = sb_len(sb);
	return out;
}
