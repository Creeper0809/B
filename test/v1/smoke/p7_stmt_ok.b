// P7 smoke: statement parsing/codegen (if/while/break/continue/return)

func main() {
  var lex;
  var p;
  var ret_ptr;
  var ret_sl;
  var loop_starts;
  var loop_ends;
  var vars;

  alias r8 : tmp;
  alias r9 : addr;

  read_file("test/v1/smoke/p7_stmt_input.txt");
  rdi = rax;
  rsi = rdx;
  asm { "call lexer_new\n" };
  ptr64[lex] = rax;

  rdi = ptr64[lex];
  parser_new(rdi);
  ptr64[p] = rax;

  // Build a Slice for a stable return label: "RET"
  slice_to_cstr("RET", 3);
  ptr64[ret_ptr] = rax;
  heap_alloc(16);
  ptr64[ret_sl] = rax;
  addr = ptr64[ret_sl];
  tmp = ptr64[ret_ptr];
  ptr64[addr] = tmp;
  addr += 8;
  ptr64[addr] = 3;

  // Loop label stacks (Vec of Slice*).
  vec_new(8);
  ptr64[loop_starts] = rax;
  vec_new(8);
  ptr64[loop_ends] = rax;

  emit_init();
  emit_cstr("global _start\n");
  emit_cstr("section .text\n");
  emit_cstr("_start:\n");

  // On-demand .bss variable declarations (Vec of Slice*).
  vec_new(8);
  ptr64[vars_emitted] = rax;

  // Parse statement list until EOF and emit control-flow asm.
  rdi = ptr64[p];
  rsi = ptr64[loop_starts];
  rdx = ptr64[loop_ends];
  rcx = ptr64[ret_sl];
  r8 = 0; // TOK_EOF
  asm { "call stmt_parse_list\n" };

  // Return label: exit with code in rax.
  rdi = ptr64[ret_sl];
  slice_parts(rdi);
  rdi = rax;
  rsi = rdx;
  emit_str(rdi, rsi);
  emit_cstr(":\n");
  emit_cstr("  mov rdi, rax\n");
  emit_cstr("  mov rax, 60\n");
  emit_cstr("  syscall\n");

  emit_to_file("build/p7_out.asm");

  print_str("OK\n");
  sys_exit(0);
}
