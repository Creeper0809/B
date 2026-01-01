// P3 smoke: lexer tokenization

func main() {
  var lex;
  var count;
  var saw_asm;

  // load representative input from file
  read_file("test/v1/smoke/p3_input.txt");

  // lex = lexer_new(p,n)
  // Use (rax,rdx) directly; Stage1 stores can clobber caller-saved regs.
  rdi = rax;
  rsi = rdx;
  asm { "call lexer_new\n" };
  ptr64[lex] = rax;

  ptr64[count] = 0;
  ptr64[saw_asm] = 0;

  // Stage1 control-flow is picky; do the token loop in raw asm.
  // r12 = Lexer*, r13 = count, rbx = saw_asm
  r12 = ptr64[lex];
  asm {
    "xor r13, r13\n"
    "xor rbx, rbx\n"
    "P3_LOOP:\n"
    "mov rdi, r12\n"
    "call lexer_next\n"
    "test rax, rax\n"
    "je P3_DONE\n"
    "cmp rax, 19\n" // TOK_ASM_RAW
    "jne P3_NOASM\n"
    "mov rbx, 1\n"
    "P3_NOASM:\n"
    "inc r13\n"
    "jmp P3_LOOP\n"
    "P3_DONE:\n"
    "mov rax, r13\n"
    "mov rdx, rbx\n"
  };
  ptr64[count] = rax;
  ptr64[saw_asm] = rdx;

  rdi = ptr64[count];
  rsi = ptr64[saw_asm];
  if (rdi == 0) {
    die("P3 smoke: no tokens");
  }
  if (rsi == 0) {
    die("P3 smoke: no asm raw");
  }

  print_str("OK\n");
  sys_exit(0);
}
