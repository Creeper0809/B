// v3_hosted: token definitions (P0)

enum TokKind {
	EOF = 0,
	ERR = 1,

	IDENT = 10,
	INT = 11,
	STRING = 12,
	CHAR = 13,

	LPAREN = 30,
	RPAREN = 31,
	LBRACE = 32,
	RBRACE = 33,
	LBRACK = 34,
	RBRACK = 35,
	SEMI = 36,
	COMMA = 37,
	DOT = 38,
	COLON = 39,

	PLUS = 40,
	MINUS = 41,
	STAR = 42,
	SLASH = 43,
	PERCENT = 44,
	AMP = 45,
	PIPE = 46,
	CARET = 47,
	TILDE = 48,
	BANG = 49,

	EQ = 50,
	EQEQ = 51,
	NEQ = 52,
	LT = 53,
	GT = 54,
	LTE = 55,
	GTE = 56,

	ANDAND = 60,
	OROR = 61,

	LSHIFT = 70,
	RSHIFT = 71,
	ARROW = 72,
	QUESTION = 73,
	DOLLAR = 74,
	AT = 75,
	ROTL = 76,
	ROTR = 77,
	EQEQEQ = 78,
	NEQEQ = 79,

	// compound assignment (Phase 6.1)
	PLUSEQ = 80,
	MINUSEQ = 81,
	STAREQ = 82,
	SLASHEQ = 83,
	PLUSPLUS = 84,
	MINUSMINUS = 85,
	PERCENTEQ = 86,
	AMPEQ = 87,
	PIPEEQ = 88,
	CARETEQ = 89,
	LSHIFTEQ = 90,
	RSHIFTEQ = 91,

	// keywords (Phase 1.1)
	// NOTE: keep these distinct from IDENT to simplify parser.
	KW_IMPORT = 100,
	KW_ENUM = 101,
	KW_STRUCT = 102,
	KW_FUNC = 103,
	KW_VAR = 104,
	KW_CONST = 105,
	KW_IF = 106,
	KW_ELSE = 107,
	KW_WHILE = 108,
	KW_FOR = 109,
	KW_FOREACH = 110,
	KW_SWITCH = 111,
	KW_BREAK = 112,
	KW_CONTINUE = 113,
	KW_RETURN = 114,
	KW_NULL = 115,
	KW_PUBLIC = 116,
	KW_PACKED = 117,
	KW_WIPE = 118,
	KW_SECRET = 119,
	KW_NOSPILL = 120,
	KW_EXTERN = 121,
	KW_TYPE = 122,
	KW_DISTINCT = 123,
	KW_CASE = 124,
	KW_DEFAULT = 125,
};

struct Token {
	kind: u64;
	ptr: u64;
	len: u64;
	line: u64;
	start_off: u64;
	col: u64;
};
