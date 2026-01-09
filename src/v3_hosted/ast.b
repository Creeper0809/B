// v3_hosted: AST definitions (Phase 1.2)
//
// Keep nodes minimal and heap-friendly for v2 output binaries.

enum AstTypeKind {
	NAME = 1,
	PTR = 2,
	SLICE = 3,
	ARRAY = 4,
	QUAL_NAME = 5,
	// Phase 5+: tuple types (used for multi-return)
	TUPLE = 6,
	// Phase 4+: generic instantiation wrapper
	GENERIC = 7,
	// Phase 3+: comptime type expression wrapper
	COMPTIME_EXPR = 8,
	// Phase 6.7: function pointer type func(T, U) -> R
	FUNC_PTR = 9,
};

struct AstType {
	kind: u64;
	// For NAME: name_ptr/name_len.
	// For QUAL_NAME: name_ptr/name_len = module, qual_ptr/qual_len = symbol.
	// For PTR:  a=inner AstType*, b=nullable(0/1).
	name_ptr: u64;
	name_len: u64;
	start_off: u64;
	line: u64;
	col: u64;
	qual_ptr: u64;
	qual_len: u64;
};

enum AstExprKind {
	IDENT = 1,
	INT = 2,
	STRING = 3,
	CHAR = 4,
	UNARY = 5,
	BINARY = 6,
	CALL = 7,
	CAST = 8,
	NULL = 9,
	INDEX = 10,
	BRACE_INIT = 11,
	OFFSETOF = 12,
	FIELD = 13,
	// Lowering-only expression: a=AstType*
	TYPE_LIT = 14,
	// Phase 6.6: floating-point literal
	FLOAT = 15,
};

struct AstExpr {
	kind: u64;
	op: u64; // TokKind for UNARY/BINARY, computed value for OFFSETOF
	a: u64;  // child or lhs
	b: u64;  // rhs
	extra: u64; // e.g. Vec* for CALL args
	tok_ptr: u64;
	tok_len: u64;
	start_off: u64;
	line: u64;
	col: u64;
};

// foreach binding list.
// - 1-binding: (var val in expr)
// - 2-binding: (var idx, val in expr)
// Typecheck fills elem_size_bytes for codegen.
struct AstForeachBind {
	name0_ptr: u64;
	name0_len: u64;
	name1_ptr: u64;
	name1_len: u64;
	has_two: u64;
	elem_size_bytes: u64;
};

enum AstStmtKind {
	BLOCK = 1,
	VAR = 2,
	EXPR = 3,
	RETURN = 4,
	IF = 5,
	WHILE = 6,
	FOREACH = 7,
	WIPE = 8,
	BREAK = 9,
	CONTINUE = 10,
	DESTRUCT = 11,
	FOR = 12,
	SWITCH = 13,
	DEFER = 14,
	PRINT = 15,
	PRINTLN = 16,
};

struct AstStmt {
	kind: u64;
	a: u64;
	b: u64;
	c: u64;
	name_ptr: u64;
	name_len: u64;
	type_ptr: u64; // AstType*
	expr_ptr: u64; // AstExpr*
	start_off: u64;
	line: u64;
	col: u64;
};

enum AstDeclKind {
	IMPORT = 1,
	FUNC = 2,
	VAR = 3,
	CONST = 4,
	ENUM = 5,
	STRUCT = 6,
	TYPE = 7,
};

struct AstDecl {
	kind: u64;
	name_ptr: u64;
	name_len: u64;
	a: u64;
	b: u64;
	c: u64;
	start_off: u64;
	line: u64;
	col: u64;
	is_public: u64;
	decl_flags: u64;
};

struct AstProgram {
	decls: u64; // Vec of AstDecl*
	errors: u64;
};
