// v1 token helpers
// Roadmap: docs/roadmap.md (5.1)
//
// NOTE(Stage1): layout/var/const declarations must appear before any function
// definitions in the merged build unit. Token kinds and `layout Token` are
// declared in std0_sys.b (included first in smoke builds).

func lexer_next_token(lex, tok_out) {
	// Convention:
	// - rdi = Lexer*
	// - rsi = Token* out
	// Returns: rax = kind
	var lex0;
	var out0;
	ptr64[lex0] = rdi;
	ptr64[out0] = rsi;

	rdi = ptr64[lex0];
	asm { "call lexer_next\n" };

	alias r9 : out;
	alias r10 : addr;
	out = ptr64[out0];

	addr = out;
	ptr64[addr] = rax;
	addr = out;
	addr += 8;
	ptr64[addr] = rdx;
	addr = out;
	addr += 16;
	ptr64[addr] = rcx;
	addr = out;
	addr += 24;
	ptr64[addr] = r8;
}
