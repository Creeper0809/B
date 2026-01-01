// v1 prelude: declarations only (no function definitions)
//
// Stage1 basm constraint:
// - All `layout` / `const` / `var` declarations must appear before any `func`
//   definitions in the merged build unit.
//
// To keep the repository's file structure sane, we centralize declarations here
// and keep implementation files (std/core/lex/parse/emit) focused on functions.

layout Slice {
	ptr64 ptr;
	ptr64 len;
}

layout Vec {
	ptr64 ptr;
	ptr64 len;
	ptr64 cap;
}

layout Lexer {
	ptr64 cur;
	ptr64 end;
	ptr64 line;
}

layout Token {
	ptr64 kind;
	ptr64 ptr;
	ptr64 len;
	ptr64 line;
}

layout Parser {
	ptr64 lex;
	ptr64 kind;
	ptr64 ptr;
	ptr64 len;
	ptr64 line;
}

layout Symbol {
	ptr64 kind;
	ptr64 name_ptr;
	ptr64 name_len;
	ptr64 value;
}

// Token kinds (numeric const only)
const TOK_EOF = 0;
const TOK_IDENT = 1;
const TOK_INT = 2;
const TOK_STRING = 3;
const TOK_CHAR = 4;

const TOK_KW_FUNC = 10;
const TOK_KW_VAR = 11;
const TOK_KW_ALIAS = 12;
const TOK_KW_CONST = 20;
const TOK_KW_IF = 13;
const TOK_KW_ELSE = 14;
const TOK_KW_WHILE = 15;
const TOK_KW_BREAK = 16;
const TOK_KW_CONTINUE = 17;
const TOK_KW_RETURN = 18;
const TOK_ASM_RAW = 19;

const TOK_LPAREN = 30;
const TOK_RPAREN = 31;
const TOK_LBRACE = 32;
const TOK_RBRACE = 33;
const TOK_LBRACK = 34;
const TOK_RBRACK = 35;
const TOK_SEMI = 36;
const TOK_COMMA = 37;
const TOK_DOT = 38;
const TOK_COLON = 39;

const TOK_PLUS = 40;
const TOK_MINUS = 41;
const TOK_STAR = 42;
const TOK_SLASH = 43;
const TOK_PERCENT = 44;

const TOK_EQ = 50;
const TOK_EQEQ = 51;
const TOK_NE = 52;
const TOK_LT = 53;
const TOK_GT = 54;
const TOK_LE = 55;
const TOK_GE = 56;

const TOK_AND = 60;
const TOK_OR = 61;
const TOK_XOR = 62;
const TOK_TILDE = 63;
const TOK_BANG = 64;
const TOK_ANDAND = 65;
const TOK_OROR = 66;

const TOK_SHL = 70;
const TOK_SHR = 71;
const TOK_ARROW = 72;

// Symbol kinds
const SYM_VAR = 1;
const SYM_ALIAS = 2;
const SYM_CONST = 3;

// label generator global state
var label_counter;

// emitter (stage 4) global state
var emit_buf;
var emit_len;
var emit_cap;

// v1 simple variable declarations emitted on demand (Vec of Slice*)
var vars_emitted;

// v1.5 local variables (per-function) for recursion safety
// Locals are mapped to qword slots at [rbp - offset].
var locals_emitted;    // Vec of Local* (Local = {name_ptr,name_len,offset})
var locals_next_off;   // next offset in bytes (u64)
const LOCALS_FRAME_SIZE = 1024;

// v1.6 register aliases (per-function)
// Aliases map an identifier to a machine register id.
var aliases_emitted;   // Vec of Alias* (Alias = {name_ptr,name_len,reg_id})

// v1.7 constants (per-compilation-unit)
// Constants map an identifier to an immediate u64 value.
var consts_emitted;    // Vec of ConstSym* (ConstSym = {kind=SYM_CONST,name_ptr,name_len,value})
