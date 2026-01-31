// types.b - Token and AST type constants for v3.8

// ============================================
// Token Types
// ============================================
const TOKEN_EOF = 0;
const TOKEN_IDENTIFIER = 10;
const TOKEN_NUMBER = 11;
const TOKEN_STRING = 12;

// Keywords
const TOKEN_FUNC = 20;
const TOKEN_VAR = 21;
const TOKEN_CONST = 22;
const TOKEN_RETURN = 23;
const TOKEN_IF = 24;
const TOKEN_ELSE = 25;
const TOKEN_WHILE = 26;
const TOKEN_IMPORT = 27;
const TOKEN_FOR = 28;
const TOKEN_SWITCH = 29;
const TOKEN_CASE = 30;
const TOKEN_DEFAULT = 31;
const TOKEN_BREAK = 32;
const TOKEN_CONTINUE = 33;
const TOKEN_ASM = 34;
const TOKEN_TRUE = 35;
const TOKEN_FALSE = 36;
const TOKEN_STRUCT = 37;
const TOKEN_ENUM = 38;
const TOKEN_IMPL = 39;
const TOKEN_STATIC = 47;

// Compiler macros
const TOKEN_LINE_MACRO = 45;
const TOKEN_SIZEOF = 46;

// Type keywords
const TOKEN_U8 = 40;
const TOKEN_U16 = 41;
const TOKEN_U32 = 42;
const TOKEN_U64 = 43;
const TOKEN_I64 = 44;
const TOKEN_CHAR = 48;
const TOKEN_TAGGED = 49;
const TOKEN_PACKED = 50;
const TOKEN_AS = 51;
const TOKEN_FROM = 52;

// Delimiters
const TOKEN_LPAREN = 100;
const TOKEN_RPAREN = 101;
const TOKEN_LBRACE = 102;
const TOKEN_RBRACE = 103;
const TOKEN_LBRACKET = 104;
const TOKEN_RBRACKET = 105;
const TOKEN_SEMICOLON = 106;
const TOKEN_COLON = 107;
const TOKEN_COMMA = 108;
const TOKEN_DOT = 109;
const TOKEN_ARROW = 110;

// Operators
const TOKEN_PLUS = 60;
const TOKEN_MINUS = 61;
const TOKEN_STAR = 62;
const TOKEN_SLASH = 63;
const TOKEN_PERCENT = 64;
const TOKEN_CARET = 65;
const TOKEN_AMPERSAND = 66;
const TOKEN_BANG = 67;
const TOKEN_EQ = 68;
const TOKEN_EQEQ = 69;
const TOKEN_BANGEQ = 70;
const TOKEN_LT = 71;
const TOKEN_GT = 72;
const TOKEN_LTEQ = 73;
const TOKEN_GTEQ = 74;
const TOKEN_PIPE = 75;
const TOKEN_LSHIFT = 76;
const TOKEN_RSHIFT = 77;
const TOKEN_ANDAND = 78;
const TOKEN_OROR = 79;
const TOKEN_PLUSPLUS = 80;
const TOKEN_MINUSMINUS = 81;
const TOKEN_PLUS_EQ = 82;
const TOKEN_MINUS_EQ = 83;
const TOKEN_STAR_EQ = 84;
const TOKEN_SLASH_EQ = 85;
const TOKEN_PERCENT_EQ = 86;
const TOKEN_TILDE = 87;

// ============================================
// AST Node Types
// ============================================

// Expressions
const AST_LITERAL = 100;
const AST_IDENT = 101;
const AST_BINARY = 102;
const AST_UNARY = 103;
const AST_CALL = 104;
const AST_ADDR_OF = 105;
const AST_DEREF = 106;
const AST_DEREF8 = 107;
const AST_CAST = 108;
const AST_STRING = 109;
const AST_MEMBER_ACCESS = 110;
const AST_STRUCT_LITERAL = 111;
const AST_SIZEOF = 112;
const AST_METHOD_CALL = 113;
const AST_INDEX = 114;
const AST_SLICE = 115;
const AST_CALL_PTR = 116;
const AST_SIZEOF_EXPR = 117;

// Statements
const AST_RETURN = 200;
const AST_VAR_DECL = 201;
const AST_CONST_DECL = 206;
const AST_ASSIGN = 202;
const AST_EXPR_STMT = 203;
const AST_IF = 204;
const AST_WHILE = 205;
const AST_FOR = 207;
const AST_SWITCH = 208;
const AST_CASE = 209;
const AST_BREAK = 211;
const AST_CONTINUE = 212;
const AST_BLOCK = 210;
const AST_ASM = 213;

// Top-level
const AST_FUNC = 300;
const AST_PROGRAM = 301;
const AST_IMPORT = 302;
const AST_STRUCT_DEF = 303;

// ============================================
// Type Constants
// ============================================
const TYPE_VOID = 0;
const TYPE_U8 = 1;
const TYPE_U16 = 2;
const TYPE_U32 = 3;
const TYPE_U64 = 4;
const TYPE_I64 = 5;
const TYPE_PTR = 10;
const TYPE_STRUCT = 20;
const TYPE_ARRAY = 21;
const TYPE_SLICE = 22;

// ============================================
// Parser Data Structures
// ============================================

// Parser state (16 bytes)
const SIZEOF_PARSER = 16;
struct Parser {
    tokens_vec: u64;
    cur: u64;
}

// Type information (88 bytes)
const SIZEOF_TYPEINFO = 88;
struct TypeInfo {
    type_kind: u64;
    ptr_depth: u64;
    is_tagged: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    struct_def: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}

// Struct field descriptor (112 bytes)
const SIZEOF_FIELD_DESC = 112;
struct FieldDesc {
    name_ptr: u64;
    name_len: u64;
    type_kind: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    ptr_depth: u64;
    is_tagged: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    bit_width: u64;
    offset: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}

// Global variable info (16 bytes)
struct GlobalInfo {
    name_ptr: u64;
    name_len: u64;
}

// Name info (16 bytes)
const SIZEOF_NAME_INFO = 16;
struct NameInfo {
    ptr: u64;
    len: u64;
}

// Export entry (32 bytes)
const SIZEOF_EXPORT_ENTRY = 32;
struct ExportEntry {
    name_ptr: u64;
    name_len: u64;
    mangled_ptr: u64;
    mangled_len: u64;
}

// Constant info (24 bytes)
struct ConstInfo {
    name_ptr: u64;
    name_len: u64;
    value: u64;
}

// Constant lookup result (16 bytes)
const SIZEOF_CONST_RESULT = 16;
struct ConstResult {
    found: u64;
    value: u64;
}

// String literal entry (24 bytes)
struct StringEntry {
    str_ptr: u64;
    str_len: u64;
    label_id: u64;
}

// Symbol table (40 bytes)
const SIZEOF_SYMTAB = 40;
struct Symtab {
    names_vec: u64;
    offsets_vec: u64;
    types_vec: u64;
    count: u64;
    stack_offset: u64;
}

// ============================================
// Lexer Data Structures
// ============================================

// Token structure (40 bytes)
const SIZEOF_TOKEN = 40;
struct Token {
    kind: u64;
    ptr: u64;
    len: u64;
    line: u64;
    col: u64;
}

// Lexer structure (40 bytes)
const SIZEOF_LEXER = 40;
struct Lexer {
    src_ptr: u64;
    src_len: u64;
    pos: u64;
    line: u64;
    col: u64;
}

// ============================================
// Parser Data Structures
// ============================================

// Function parameter (96 bytes)
const SIZEOF_PARAM = 96;
struct Param {
    name_ptr: u64;
    name_len: u64;
    type_kind: u64;
    ptr_depth: u64;
    is_tagged: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}
