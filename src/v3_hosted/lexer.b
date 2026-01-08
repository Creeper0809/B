// v3_hosted: lexer (P0)

import v3_hosted.token;

struct Lexer {
	base: u64;
	cur: u64;
	end: u64;
	line: u64;
	line_start: u64;
};

func slice_eq_parts(p1, n1, p2, n2) {
	if (n1 != n2) { return 0; }
	var i = 0;
	while (i < n1) {
		var a = ptr8[p1 + i];
		var b = ptr8[p2 + i];
		if (a != b) { return 0; }
		i = i + 1;
	}
	return 1;
}

func keyword_kind(p, n) {
	// Returns 0 if not a keyword.
	switch (n) {
		case 2: {
			if (slice_eq_parts(p, n, "if", 2) == 1) { return TokKind.KW_IF; }
			break;
		}
		case 3: {
			if (slice_eq_parts(p, n, "for", 3) == 1) { return TokKind.KW_FOR; }
			if (slice_eq_parts(p, n, "var", 3) == 1) { return TokKind.KW_VAR; }
			break;
		}
		case 4: {
			if (slice_eq_parts(p, n, "type", 4) == 1) { return TokKind.KW_TYPE; }
			if (slice_eq_parts(p, n, "else", 4) == 1) { return TokKind.KW_ELSE; }
			if (slice_eq_parts(p, n, "func", 4) == 1) { return TokKind.KW_FUNC; }
			if (slice_eq_parts(p, n, "enum", 4) == 1) { return TokKind.KW_ENUM; }
			if (slice_eq_parts(p, n, "null", 4) == 1) { return TokKind.KW_NULL; }
			if (slice_eq_parts(p, n, "wipe", 4) == 1) { return TokKind.KW_WIPE; }
			if (slice_eq_parts(p, n, "case", 4) == 1) { return TokKind.KW_CASE; }
			if (slice_eq_parts(p, n, "impl", 4) == 1) { return TokKind.KW_IMPL; }
			break;
		}
		case 5: {
			if (slice_eq_parts(p, n, "while", 5) == 1) { return TokKind.KW_WHILE; }
			if (slice_eq_parts(p, n, "const", 5) == 1) { return TokKind.KW_CONST; }
			if (slice_eq_parts(p, n, "break", 5) == 1) { return TokKind.KW_BREAK; }
			if (slice_eq_parts(p, n, "defer", 5) == 1) { return TokKind.KW_DEFER; }
			if (slice_eq_parts(p, n, "print", 5) == 1) { return TokKind.KW_PRINT; }
			break;
		}
		case 6: {
			if (slice_eq_parts(p, n, "import", 6) == 1) { return TokKind.KW_IMPORT; }
			if (slice_eq_parts(p, n, "packed", 6) == 1) { return TokKind.KW_PACKED; }
			if (slice_eq_parts(p, n, "public", 6) == 1) { return TokKind.KW_PUBLIC; }
			if (slice_eq_parts(p, n, "struct", 6) == 1) { return TokKind.KW_STRUCT; }
			if (slice_eq_parts(p, n, "switch", 6) == 1) { return TokKind.KW_SWITCH; }
			if (slice_eq_parts(p, n, "return", 6) == 1) { return TokKind.KW_RETURN; }
			if (slice_eq_parts(p, n, "secret", 6) == 1) { return TokKind.KW_SECRET; }
			if (slice_eq_parts(p, n, "extern", 6) == 1) { return TokKind.KW_EXTERN; }
			break;
		}
		case 7: {
			if (slice_eq_parts(p, n, "foreach", 7) == 1) { return TokKind.KW_FOREACH; }
			if (slice_eq_parts(p, n, "nospill", 7) == 1) { return TokKind.KW_NOSPILL; }
			if (slice_eq_parts(p, n, "default", 7) == 1) { return TokKind.KW_DEFAULT; }
			if (slice_eq_parts(p, n, "println", 7) == 1) { return TokKind.KW_PRINTLN; }
			break;
		}
		case 8: {
			if (slice_eq_parts(p, n, "distinct", 8) == 1) { return TokKind.KW_DISTINCT; }
			if (slice_eq_parts(p, n, "continue", 8) == 1) { return TokKind.KW_CONTINUE; }
			break;
		}
		default: {
			break;
		}
	}
	return 0;
}

func is_ident_start(c) {
	if (c == 95) { return 1; } // '_'
	if (c >= 65) { if (c <= 90) { return 1; } } // A-Z
	if (c >= 97) { if (c <= 122) { return 1; } } // a-z
	return 0;
}

func is_ident_cont(c) {
	if (is_ident_start(c) == 1) { return 1; }
	if (c >= 48) { if (c <= 57) { return 1; } }
	return 0;
}

func is_hex_digit(c) {
	if (c >= 48) { if (c <= 57) { return 1; } }
	if (c >= 65) { if (c <= 70) { return 1; } }
	if (c >= 97) { if (c <= 102) { return 1; } }
	return 0;
}

func lexer_init(lex, p, n) {
	ptr64[lex + 0] = p;
	ptr64[lex + 8] = p;
	ptr64[lex + 16] = p + n;
	ptr64[lex + 24] = 1;
	ptr64[lex + 32] = p;
	return 0;
}

func lexer_skip_ws_and_comments(lex) {
	var cur = ptr64[lex + 8];
	var end = ptr64[lex + 16];
	var line = ptr64[lex + 24];
	var line_start = ptr64[lex + 32];

	while (cur < end) {
		var ch = ptr8[cur];

		if (ch == 32) {
			cur = cur + 1;
		} else if (ch == 9) {
			cur = cur + 1;
		} else if (ch == 13) {
			cur = cur + 1;
		} else if (ch == 10) {
			line = line + 1;
			cur = cur + 1;
			line_start = cur;
		} else if (ch == 47) {
			if (cur + 1 < end) {
				if (ptr8[cur + 1] == 47) {
					cur = cur + 2;
					while (cur < end) {
						if (ptr8[cur] == 10) {
							break;
						}
						cur = cur + 1;
					}
				} else {
					break;
				}
			} else {
				break;
			}
		} else {
			break;
		}
	}

	ptr64[lex + 8] = cur;
	ptr64[lex + 24] = line;
	ptr64[lex + 32] = line_start;
	return 0;
}

func lexer_next(lex, tok_out) {
	var base = ptr64[lex + 0];
	var cur = ptr64[lex + 8];
	var end = ptr64[lex + 16];
	var line = ptr64[lex + 24];
	var line_start = ptr64[lex + 32];

	// skip whitespace + // comments
	while (cur < end) {
		var ch = ptr8[cur];
		if (ch == 32) {
			cur = cur + 1;
		} else if (ch == 9) {
			cur = cur + 1;
		} else if (ch == 13) {
			cur = cur + 1;
		} else if (ch == 10) {
			line = line + 1;
			cur = cur + 1;
			line_start = cur;
		} else if (ch == 47) {
			if (cur + 1 < end) {
				if (ptr8[cur + 1] == 47) {
					cur = cur + 2;
					while (cur < end) {
						if (ptr8[cur] == 10) { break; }
						cur = cur + 1;
					}
				} else {
					break;
				}
			} else {
				break;
			}
		} else {
			break;
		}
	}

	if (cur >= end) {
		ptr64[lex + 8] = cur;
		ptr64[lex + 24] = line;
		ptr64[lex + 32] = line_start;
		ptr64[tok_out + 0] = TokKind.EOF;
		ptr64[tok_out + 8] = cur;
		ptr64[tok_out + 16] = 0;
		ptr64[tok_out + 24] = line;
		ptr64[tok_out + 32] = cur - base;
		ptr64[tok_out + 40] = (cur - line_start) + 1;
		return TokKind.EOF;
	}

	var start = cur;
	var ch0 = ptr8[cur];

	// ident
	var is_start = 0;
	if (ch0 == 95) { is_start = 1; }
	if (is_start == 0) {
		if (ch0 >= 65) { if (ch0 <= 90) { is_start = 1; } }
	}
	if (is_start == 0) {
		if (ch0 >= 97) { if (ch0 <= 122) { is_start = 1; } }
	}

	if (is_start == 1) {
		cur = cur + 1;
		while (cur < end) {
			var c = ptr8[cur];
			var is_cont = 0;
			if (c == 95) { is_cont = 1; }
			if (is_cont == 0) {
				if (c >= 65) { if (c <= 90) { is_cont = 1; } }
			}
			if (is_cont == 0) {
				if (c >= 97) { if (c <= 122) { is_cont = 1; } }
			}
			if (is_cont == 0) {
				if (c >= 48) { if (c <= 57) { is_cont = 1; } }
			}
			if (is_cont == 1) {
				cur = cur + 1;
			} else {
				break;
			}
		}
		var kind = TokKind.IDENT;
		var kw = keyword_kind(start, cur - start);
		if (kw != 0) { kind = kw; }
		ptr64[lex + 8] = cur;
		ptr64[lex + 24] = line;
		ptr64[lex + 32] = line_start;
		ptr64[tok_out + 0] = kind;
		ptr64[tok_out + 8] = start;
		ptr64[tok_out + 16] = cur - start;
		ptr64[tok_out + 24] = line;
		ptr64[tok_out + 32] = start - base;
		ptr64[tok_out + 40] = (start - line_start) + 1;
		return kind;
	}

	// int (decimal or 0x..) or float
	var is_digit0 = 0;
	if (ch0 >= 48) { if (ch0 <= 57) { is_digit0 = 1; } }
	if (is_digit0 == 1) {
		cur = cur + 1;
		if (ch0 == 48) {
			if (cur < end) {
			var c1 = ptr8[cur];
			if (c1 == 120) {
				cur = cur + 1;
				while (cur < end) {
					var h = ptr8[cur];
					var ok = 0;
					if (h >= 48) { if (h <= 57) { ok = 1; } }
					if (ok == 0) { if (h >= 65) { if (h <= 70) { ok = 1; } } }
					if (ok == 0) { if (h >= 97) { if (h <= 102) { ok = 1; } } }
					if (ok == 1) { cur = cur + 1; } else { break; }
				}
				ptr64[lex + 8] = cur;
				ptr64[lex + 24] = line;
				ptr64[lex + 32] = line_start;
				ptr64[tok_out + 0] = TokKind.INT;
				ptr64[tok_out + 8] = start;
				ptr64[tok_out + 16] = cur - start;
				ptr64[tok_out + 24] = line;
				ptr64[tok_out + 32] = start - base;
				ptr64[tok_out + 40] = (start - line_start) + 1;
				return TokKind.INT;
			} else if (c1 == 88) {
				cur = cur + 1;
				while (cur < end) {
					var h = ptr8[cur];
					var ok = 0;
					if (h >= 48) { if (h <= 57) { ok = 1; } }
					if (ok == 0) { if (h >= 65) { if (h <= 70) { ok = 1; } } }
					if (ok == 0) { if (h >= 97) { if (h <= 102) { ok = 1; } } }
					if (ok == 1) { cur = cur + 1; } else { break; }
				}
				ptr64[lex + 8] = cur;
				ptr64[lex + 24] = line;
				ptr64[lex + 32] = line_start;
				ptr64[tok_out + 0] = TokKind.INT;
				ptr64[tok_out + 8] = start;
				ptr64[tok_out + 16] = cur - start;
				ptr64[tok_out + 24] = line;
				ptr64[tok_out + 32] = start - base;
				ptr64[tok_out + 40] = (start - line_start) + 1;
				return TokKind.INT;
			}
		}
		}

		// Consume integer part
		while (cur < end) {
			var d = ptr8[cur];
			if (d < 48) { break; }
			if (d > 57) { break; }
			cur = cur + 1;
		}

		// Phase 6.6: Check for floating-point (. or e/E)
		var is_float = 0;
		if (cur < end) {
			var ch_next = ptr8[cur];
			// Check for decimal point followed by digit
			if (ch_next == 46) {
				// '.'
				if (cur + 1 < end) {
					var ch_after_dot = ptr8[cur + 1];
					if (ch_after_dot >= 48) {
						if (ch_after_dot <= 57) {
							is_float = 1;
							cur = cur + 1;
							// Consume fractional digits
							while (cur < end) {
								var df = ptr8[cur];
								if (df < 48) { break; }
								if (df > 57) { break; }
								cur = cur + 1;
							}
						}
					}
				}
			}
			// Check for exponent (e/E)
			if (cur < end) {
				var ch_exp = ptr8[cur];
				if (ch_exp == 101 || ch_exp == 69) {
					// 'e' or 'E'
					is_float = 1;
					cur = cur + 1;
					// Optional sign
					if (cur < end) {
						var ch_sign = ptr8[cur];
						if (ch_sign == 43 || ch_sign == 45) {
							// '+' or '-'
							cur = cur + 1;
						}
					}
					// Exponent digits
					while (cur < end) {
						var de = ptr8[cur];
						if (de < 48) { break; }
						if (de > 57) { break; }
						cur = cur + 1;
					}
				}
			}
			// Check for 'f' suffix (e.g., 3.14f)
			if (cur < end) {
				var ch_suf = ptr8[cur];
				if (ch_suf == 102) {
					// 'f'
					is_float = 1;
					cur = cur + 1;
				}
			}
		}

		ptr64[lex + 8] = cur;
		ptr64[lex + 24] = line;
		ptr64[lex + 32] = line_start;
		if (is_float == 1) {
			ptr64[tok_out + 0] = TokKind.FLOAT;
		} else {
			ptr64[tok_out + 0] = TokKind.INT;
		}
		ptr64[tok_out + 8] = start;
		ptr64[tok_out + 16] = cur - start;
		ptr64[tok_out + 24] = line;
		ptr64[tok_out + 32] = start - base;
		ptr64[tok_out + 40] = (start - line_start) + 1;
		if (is_float == 1) {
			return TokKind.FLOAT;
		}
		return TokKind.INT;
	}

	// string
	if (ch0 == 34) {
		cur = cur + 1;
		while (cur < end) {
			var ch = ptr8[cur];
			if (ch == 10) { line = line + 1; cur = cur + 1; line_start = cur; continue; }
			if (ch == 92) {
				cur = cur + 1;
				if (cur < end) { cur = cur + 1; }
			} else if (ch == 34) {
				cur = cur + 1;
				ptr64[lex + 8] = cur;
				ptr64[lex + 24] = line;
				ptr64[lex + 32] = line_start;
				ptr64[tok_out + 0] = TokKind.STRING;
				ptr64[tok_out + 8] = start;
				ptr64[tok_out + 16] = cur - start;
				ptr64[tok_out + 24] = line;
				ptr64[tok_out + 32] = start - base;
				ptr64[tok_out + 40] = (start - line_start) + 1;
				return TokKind.STRING;
			} else {
				cur = cur + 1;
			}
		}
		ptr64[lex + 8] = cur;
		ptr64[lex + 24] = line;
		ptr64[lex + 32] = line_start;
		ptr64[tok_out + 0] = TokKind.ERR;
		ptr64[tok_out + 8] = start;
		ptr64[tok_out + 16] = cur - start;
		ptr64[tok_out + 24] = line;
		ptr64[tok_out + 32] = start - base;
		ptr64[tok_out + 40] = (start - line_start) + 1;
		return TokKind.ERR;
	}

	// char
	if (ch0 == 39) {
		cur = cur + 1;
		if (cur >= end) {
			ptr64[lex + 8] = cur;
			ptr64[lex + 24] = line;
			ptr64[lex + 32] = line_start;
			ptr64[tok_out + 0] = TokKind.ERR;
			ptr64[tok_out + 8] = start;
			ptr64[tok_out + 16] = cur - start;
			ptr64[tok_out + 24] = line;
			ptr64[tok_out + 32] = start - base;
			ptr64[tok_out + 40] = (start - line_start) + 1;
			return TokKind.ERR;
		}

		var ch = ptr8[cur];
		if (ch == 10) {
			ptr64[lex + 8] = cur;
			ptr64[lex + 24] = line;
			ptr64[lex + 32] = line_start;
			ptr64[tok_out + 0] = TokKind.ERR;
			ptr64[tok_out + 8] = start;
			ptr64[tok_out + 16] = cur - start;
			ptr64[tok_out + 24] = line;
			ptr64[tok_out + 32] = start - base;
			ptr64[tok_out + 40] = (start - line_start) + 1;
			return TokKind.ERR;
		}

		if (ch == 92) {
			// escape sequence
			cur = cur + 1;
			if (cur >= end) {
				ptr64[lex + 8] = cur;
				ptr64[lex + 24] = line;
				ptr64[lex + 32] = line_start;
				ptr64[tok_out + 0] = TokKind.ERR;
				ptr64[tok_out + 8] = start;
				ptr64[tok_out + 16] = cur - start;
				ptr64[tok_out + 24] = line;
				ptr64[tok_out + 32] = start - base;
				ptr64[tok_out + 40] = (start - line_start) + 1;
				return TokKind.ERR;
			}
			var esc = ptr8[cur];
			cur = cur + 1;
			if (esc == 120) {
				// \xHH
				if (cur + 1 >= end) {
					ptr64[lex + 8] = cur;
					ptr64[lex + 24] = line;
					ptr64[lex + 32] = line_start;
					ptr64[tok_out + 0] = TokKind.ERR;
					ptr64[tok_out + 8] = start;
					ptr64[tok_out + 16] = cur - start;
					ptr64[tok_out + 24] = line;
					ptr64[tok_out + 32] = start - base;
					ptr64[tok_out + 40] = (start - line_start) + 1;
					return TokKind.ERR;
				}
				var h0 = ptr8[cur];
				var h1 = ptr8[cur + 1];
				if (is_hex_digit(h0) == 0) { esc = 0; }
				if (is_hex_digit(h1) == 0) { esc = 0; }
				if (esc == 0) {
					ptr64[lex + 8] = cur;
					ptr64[lex + 24] = line;
					ptr64[lex + 32] = line_start;
					ptr64[tok_out + 0] = TokKind.ERR;
					ptr64[tok_out + 8] = start;
					ptr64[tok_out + 16] = cur - start;
					ptr64[tok_out + 24] = line;
					ptr64[tok_out + 32] = start - base;
					ptr64[tok_out + 40] = (start - line_start) + 1;
					return TokKind.ERR;
				}
				cur = cur + 2;
			}
		} else {
			// normal single byte
			cur = cur + 1;
		}

		if (cur >= end) {
			ptr64[lex + 8] = cur;
			ptr64[lex + 24] = line;
			ptr64[lex + 32] = line_start;
			ptr64[tok_out + 0] = TokKind.ERR;
			ptr64[tok_out + 8] = start;
			ptr64[tok_out + 16] = cur - start;
			ptr64[tok_out + 24] = line;
			ptr64[tok_out + 32] = start - base;
			ptr64[tok_out + 40] = (start - line_start) + 1;
			return TokKind.ERR;
		}
		if (ptr8[cur] != 39) {
			ptr64[lex + 8] = cur;
			ptr64[lex + 24] = line;
			ptr64[lex + 32] = line_start;
			ptr64[tok_out + 0] = TokKind.ERR;
			ptr64[tok_out + 8] = start;
			ptr64[tok_out + 16] = cur - start;
			ptr64[tok_out + 24] = line;
			ptr64[tok_out + 32] = start - base;
			ptr64[tok_out + 40] = (start - line_start) + 1;
			return TokKind.ERR;
		}
		cur = cur + 1;
		ptr64[lex + 8] = cur;
		ptr64[lex + 24] = line;
		ptr64[lex + 32] = line_start;
		ptr64[tok_out + 0] = TokKind.CHAR;
		ptr64[tok_out + 8] = start;
		ptr64[tok_out + 16] = cur - start;
		ptr64[tok_out + 24] = line;
		ptr64[tok_out + 32] = start - base;
		ptr64[tok_out + 40] = (start - line_start) + 1;
		return TokKind.CHAR;
	}

	// two-char ops
	var kind = 0;
	// three-char ops (Phase 4.6)
	if (cur + 2 < end) {
		var ch1_3 = ptr8[cur + 1];
		var ch2_3 = ptr8[cur + 2];
		if (ch0 == 60) { // '<'
			if (ch1_3 == 60 && ch2_3 == 60) { kind = TokKind.ROTL; cur = cur + 3; }
		}
		else if (ch0 == 62) { // '>'
			if (ch1_3 == 62 && ch2_3 == 62) { kind = TokKind.ROTR; cur = cur + 3; }
		}
		else if (ch0 == 61) { // '='
			if (ch1_3 == 61 && ch2_3 == 61) { kind = TokKind.EQEQEQ; cur = cur + 3; }
		}
		else if (ch0 == 33) { // '!'
			if (ch1_3 == 61 && ch2_3 == 61) { kind = TokKind.NEQEQ; cur = cur + 3; }
		}
	}
	if (cur + 1 < end) {
		var ch1 = ptr8[cur + 1];
		if (ch0 == 61) { if (ch1 == 61) { kind = TokKind.EQEQ; cur = cur + 2; } }
		else if (ch0 == 33) { if (ch1 == 61) { kind = TokKind.NEQ; cur = cur + 2; } }
		else if (ch0 == 60) {
			// Check <<= first (3-char)
			if (cur + 2 < end && ch1 == 60 && ptr8[cur + 2] == 61) { kind = TokKind.LSHIFTEQ; cur = cur + 3; }
			else if (ch1 == 61) { kind = TokKind.LTE; cur = cur + 2; }
			else if (ch1 == 60) { kind = TokKind.LSHIFT; cur = cur + 2; }
		}
		else if (ch0 == 62) {
			// Check >>= first (3-char)
			if (cur + 2 < end && ch1 == 62 && ptr8[cur + 2] == 61) { kind = TokKind.RSHIFTEQ; cur = cur + 3; }
			else if (ch1 == 61) { kind = TokKind.GTE; cur = cur + 2; }
			else if (ch1 == 62) { kind = TokKind.RSHIFT; cur = cur + 2; }
		}
		else if (ch0 == 38) {
			if (ch1 == 38) { kind = TokKind.ANDAND; cur = cur + 2; }
			else if (ch1 == 61) { kind = TokKind.AMPEQ; cur = cur + 2; }
		}
		else if (ch0 == 124) {
			if (ch1 == 124) { kind = TokKind.OROR; cur = cur + 2; }
			else if (ch1 == 61) { kind = TokKind.PIPEEQ; cur = cur + 2; }
		}
		else if (ch0 == 45) {
			if (ch1 == 62) { kind = TokKind.ARROW; cur = cur + 2; }
			else if (ch1 == 61) { kind = TokKind.MINUSEQ; cur = cur + 2; }
			else if (ch1 == 45) { kind = TokKind.MINUSMINUS; cur = cur + 2; }
		}
		// compound assignment (Phase 6.1)
		else if (ch0 == 43) {
			if (ch1 == 61) { kind = TokKind.PLUSEQ; cur = cur + 2; }
			else if (ch1 == 43) { kind = TokKind.PLUSPLUS; cur = cur + 2; }
		}
		else if (ch0 == 42) { if (ch1 == 61) { kind = TokKind.STAREQ; cur = cur + 2; } }
		else if (ch0 == 47) { if (ch1 == 61) { kind = TokKind.SLASHEQ; cur = cur + 2; } }
		else if (ch0 == 37) { if (ch1 == 61) { kind = TokKind.PERCENTEQ; cur = cur + 2; } }
		else if (ch0 == 94) { if (ch1 == 61) { kind = TokKind.CARETEQ; cur = cur + 2; } }
	}

	if (kind == 0) {
		kind = TokKind.ERR;
		if (ch0 == 40) { kind = TokKind.LPAREN; }
		else if (ch0 == 41) { kind = TokKind.RPAREN; }
		else if (ch0 == 123) { kind = TokKind.LBRACE; }
		else if (ch0 == 125) { kind = TokKind.RBRACE; }
		else if (ch0 == 91) { kind = TokKind.LBRACK; }
		else if (ch0 == 93) { kind = TokKind.RBRACK; }
		else if (ch0 == 59) { kind = TokKind.SEMI; }
		else if (ch0 == 44) { kind = TokKind.COMMA; }
		else if (ch0 == 46) { kind = TokKind.DOT; }
		else if (ch0 == 58) { kind = TokKind.COLON; }
		else if (ch0 == 63) { kind = TokKind.QUESTION; }
		else if (ch0 == 36) { kind = TokKind.DOLLAR; }
		else if (ch0 == 64) { kind = TokKind.AT; }
		else if (ch0 == 43) { kind = TokKind.PLUS; }
		else if (ch0 == 45) { kind = TokKind.MINUS; }
		else if (ch0 == 42) { kind = TokKind.STAR; }
		else if (ch0 == 47) { kind = TokKind.SLASH; }
		else if (ch0 == 37) { kind = TokKind.PERCENT; }
		else if (ch0 == 38) { kind = TokKind.AMP; }
		else if (ch0 == 124) { kind = TokKind.PIPE; }
		else if (ch0 == 94) { kind = TokKind.CARET; }
		else if (ch0 == 126) { kind = TokKind.TILDE; }
		else if (ch0 == 33) { kind = TokKind.BANG; }
		else if (ch0 == 61) { kind = TokKind.EQ; }
		else if (ch0 == 60) { kind = TokKind.LT; }
		else if (ch0 == 62) { kind = TokKind.GT; }
		cur = cur + 1;
	}

	ptr64[lex + 8] = cur;
	ptr64[lex + 24] = line;
	ptr64[lex + 32] = line_start;
	ptr64[tok_out + 0] = kind;
	ptr64[tok_out + 8] = start;
	ptr64[tok_out + 16] = cur - start;
	ptr64[tok_out + 24] = line;
	ptr64[tok_out + 32] = start - base;
	ptr64[tok_out + 40] = (start - line_start) + 1;
	return kind;
}
