// P0 smoke test: sys_brk
// This file is meant to be concatenated after src/v1/std/std0_sys.b.

func main() {
  alias r12 : brk0;
  alias r13 : brk1;
  alias r14 : target;

  // Query current program break.
  sys_brk(0);
  brk0 = rax;

  if (brk0 == 0) {
    panic("brk0=0");
  }

  // Request +4096 bytes.
  target = brk0;
  target += 4096;
  sys_brk(target);
  brk1 = rax;

  if (brk1 < brk0) {
    panic("brk decreased");
  }

  // Print both values for manual inspection.
  rdi = brk0;
  print_dec(rdi);
  print_str("\n");
  rdi = brk1;
  print_dec(rdi);
  print_str("\n");

  sys_exit(0);
}
