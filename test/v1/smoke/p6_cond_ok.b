// P6 smoke: condition codegen (&&/|| short-circuit + comparisons)

func main() {
  var lex;
  var p;
  var fail_ptr;
  var fail_sl;
  alias r8 : tmp;

  read_file("test/v1/smoke/p6_cond_input.txt");
  rdi = rax;
  rsi = rdx;
  asm { "call lexer_new\n" };
  ptr64[lex] = rax;

  rdi = ptr64[lex];
  parser_new(rdi);
  ptr64[p] = rax;

  // Build a Slice for a stable label name: "FAIL"
  slice_to_cstr("FAIL", 4);
  ptr64[fail_ptr] = rax;
  heap_alloc(16);
  ptr64[fail_sl] = rax;
  rdi = ptr64[fail_sl];
  tmp = ptr64[fail_ptr];
  ptr64[rdi] = tmp;
  rdi += 8;
  ptr64[rdi] = 4;

  emit_init();
  emit_cstr("global _start\n");
  emit_cstr("section .text\n");
  emit_cstr("_start:\n");

  // Emit conditional jump to FAIL when the condition is false.
  rdi = ptr64[p];
  rsi = ptr64[fail_sl];
  parse_cond_emit_jfalse(rdi, rsi);

  // True path: exit(0)
  emit_cstr("  mov rax, 60\n");
  emit_cstr("  xor rdi, rdi\n");
  emit_cstr("  syscall\n");

  // False path label + exit(1)
  rdi = ptr64[fail_sl];
  slice_parts(rdi);
  rdi = rax;
  rsi = rdx;
  emit_str(rdi, rsi);
  emit_cstr(":\n");
  emit_cstr("  mov rax, 60\n");
  emit_cstr("  mov rdi, 1\n");
  emit_cstr("  syscall\n");

  emit_to_file("build/p6_out.asm");

  print_str("OK\n");
  sys_exit(0);
}
