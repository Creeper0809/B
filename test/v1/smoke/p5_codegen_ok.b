// P5 smoke: expression codegen (precedence sanity)

func main() {
  var lex;
  var p;

  read_file("test/v1/smoke/p5_input.txt");
  rdi = rax;
  rsi = rdx;
  asm { "call lexer_new\n" };
  ptr64[lex] = rax;

  rdi = ptr64[lex];
  parser_new(rdi);
  ptr64[p] = rax;

  emit_init();
  emit_cstr("global _start\n");
  emit_cstr("section .text\n");
  emit_cstr("_start:\n");

  // Emit stack-based evaluation of the expression.
  rdi = ptr64[p];
  expr_parse_top_emit(rdi);

  // Pop result to rax and exit(0).
  emit_cstr("  pop rax\n");
  emit_cstr("  mov rax, 60\n");
  emit_cstr("  xor rdi, rdi\n");
  emit_cstr("  syscall\n");
  emit_to_file("build/p5_out.asm");

  print_str("OK\n");
  sys_exit(0);
}
