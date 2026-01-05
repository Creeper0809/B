// v3_hosted P0: CLI driver (hosted)
//
// This file is meant to be compiled by the v2 compiler.
// Usage:
//   v3h <file>
//   v3h -        (read source from stdin; capped)

import io;
import file;
import v3_hosted.lexer;
import v3_hosted.token;

func usage() {
  print_str("usage: v3h <file>|-\n");
  return 0;
}

func print_tok(tok) {
  print_str("line=");
  print_u64(ptr64[tok + 24]);
  print_str(":");
  print_u64(ptr64[tok + 40]);
  print_str(" kind=");
  print_u64(ptr64[tok + 0]);
  print_str(" off=");
  print_u64(ptr64[tok + 32]);
  print_str(" text=\"");
  print_str_len(ptr64[tok + 8], ptr64[tok + 16]);
  print_str("\"\n");
  return 0;
}

func run_lex_dump(p, n) {
  if (p == 0) { return 1; }

  var lex = heap_alloc(40);
  var tok = heap_alloc(48);
  if (lex == 0) { return 3; }
  if (tok == 0) { return 4; }

  lexer_init(lex, p, n);
  while (1) {
    var k = lexer_next(lex, tok);
    if (k == TokKind.EOF) { break; }
    if (k == TokKind.ERR) { return 2; }
    print_tok(tok);
  }

  return 0;
}

func run_lex_dump_stdin() {
  var p = read_stdin_cap(1048576);
  alias rdx : n_reg;
  var n = n_reg;
  return run_lex_dump(p, n);
}

func run_lex_dump_file(path) {
  var p = read_file(path);
  alias rdx : n_reg;
  var n = n_reg;
  return run_lex_dump(p, n);
}

func main(argc, argv) {
  if (argc < 2) {
    usage();
    return 1;
  }

  var path = ptr64[argv + 8];
  if (path == 0) {
    usage();
    return 1;
  }

  // Special-case dash for stdin.
  if (ptr8[path] == 45) {
    if (ptr8[path + 1] == 0) {
      return run_lex_dump_stdin();
    }
  }

  return run_lex_dump_file(path);
}
