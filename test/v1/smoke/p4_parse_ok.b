// P4 smoke: minimal parser skeleton

func main() {
  var lex;

  // Load a tiny input program.
  read_file("test/v1/smoke/p4_input.txt");

  // lex = lexer_new(p,n)
  rdi = rax;
  rsi = rdx;
  asm { "call lexer_new\n" };
  ptr64[lex] = rax;

  // Parse: func <ident>() { }
  rdi = ptr64[lex];
  parse_program(rdi);

  // Emit a tiny asm file (just to validate emitter usage).
  emit_init();
  emit_str("global _start\n", 14);
  emit_str("section .text\n", 14);
  emit_str("_start:\n", 8);
  emit_str("  mov rax, 60\n", 15);
  emit_str("  xor rdi, rdi\n", 16);
  emit_str("  syscall\n", 10);
  emit_to_file("build/p4_out.asm");

  print_str("OK\n");
  sys_exit(0);
}
