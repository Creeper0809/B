func main() {
  // Minimal P1 smoke: validate v1 memset + Stage1 builtins (heap_alloc/strlen/streq).
  // Note: this file is intended to be concatenated after src/v1/std/*.b.

  alias rax : tmp;
  alias r12 : p;
  alias r13 : v;
  alias rbx : addr;
  alias r14 : n;
  alias r15 : s;
  alias r11 : sl;
  // Use an actual register token for ptr8[...] in conditions.
  // Some Stage1 parsers are stricter about addr forms inside conditions.

  heap_alloc(4);
  p = tmp;

  memset(p, 65, 4);
  if (tmp != p) {
    panic("memset ret");
  }

  addr = p;
  addr += 0;
  tmp = ptr8[rbx];
  if (tmp != 65) {
    panic("b0");
  }

  addr = p;
  addr += 1;
  tmp = ptr8[rbx];
  if (tmp != 65) {
    panic("b1");
  }

  addr = p;
  addr += 2;
  tmp = ptr8[rbx];
  if (tmp != 65) {
    panic("b2");
  }

  addr = p;
  addr += 3;
  tmp = ptr8[rbx];
  if (tmp != 65) {
    panic("b3");
  }

  strlen("abc");
  if (tmp != 3) {
    panic("strlen");
  }

  streq("x", "x");
  if (tmp != 1) {
    panic("streq");
  }

  // itoa (u64 decimal) basics.
  itoa_u64_dec(0);
  s = tmp;
  n = rdx;
  if (n != 1) {
    panic("itoa len 0");
  }
  streq(s, "0");
  if (tmp != 1) {
    panic("itoa 0");
  }

  itoa_u64_dec(12345);
  s = tmp;
  n = rdx;
  if (n != 5) {
    panic("itoa len 12345");
  }
  streq(s, "12345");
  if (tmp != 1) {
    panic("itoa 12345");
  }

  // atoi basics (ptr,len).

  // "123" -> 123
  atoi_u64("123", 3);
  if (rdx != 1) {
    panic("atoi dec ok");
  }
  if (rax != 123) {
    panic("atoi dec val");
  }

  // "0x10" -> 16
  atoi_u64("0x10", 4);
  if (rdx != 1) {
    panic("atoi hex ok");
  }
  if (rax != 16) {
    panic("atoi hex val");
  }

  // "12z" -> fail
  atoi_u64("12z", 3);
  if (rdx != 0) {
    panic("atoi bad ok");
  }

  // atoi panic wrappers (success paths).
  atoi_u64_or_panic("123", 3);
  if (rax != 123) {
    panic("atoi_panic val");
  }

  // Slice wrapper: build a Slice from itoa result to avoid storing string literals.
  itoa_u64_dec(456);
  s = tmp;
  n = rdx;
  heap_alloc(16);
  sl = tmp;
  addr = sl;
  ptr64[addr] = s;
  addr += 8;
  ptr64[addr] = n;
  atoi_u64_slice_or_panic(sl);
  if (rax != 456) {
    panic("atoi_slice_panic val");
  }

  // slice_to_cstr / str_concat basics.
  slice_to_cstr("xy", 2);
  s = tmp;
  streq(s, "xy");
  if (tmp != 1) {
    panic("slice_to_cstr");
  }

  str_concat("ab", 2, "CD", 2);
  s = tmp;
  n = rdx;
  if (n != 4) {
    panic("str_concat len");
  }
  streq(s, "abCD");
  if (tmp != 1) {
    panic("str_concat val");
  }

  // Slice basics.
  slice_eq_parts("ab", 2, "ab", 2);
  if (tmp != 1) {
    panic("slice_eq eq");
  }
  slice_eq_parts("ab", 2, "ac", 2);
  if (tmp != 0) {
    panic("slice_eq ne");
  }

  // Vec basics.
  vec_new(2);
  v = tmp;

  vec_push(v, 10);
  vec_push(v, 20);
  vec_push(v, 30); // triggers grow

  vec_len(v);
  if (tmp != 3) {
    panic("vec_len");
  }

  vec_get(v, 0);
  if (tmp != 10) {
    panic("vec_get0");
  }

  vec_get(v, 2);
  if (tmp != 30) {
    panic("vec_get2");
  }

  // label_gen basics.
  label_next();
  sl = tmp;
  slice_parts(sl);
  s = rax;
  n = rdx;
  if (n != 3) {
    panic("label len1");
  }
  streq(s, "L_1");
  if (tmp != 1) {
    panic("label val1");
  }

  label_next();
  sl = tmp;
  slice_parts(sl);
  s = rax;
  n = rdx;
  if (n != 3) {
    panic("label len2");
  }
  streq(s, "L_2");
  if (tmp != 1) {
    panic("label val2");
  }

  print_str("OK\n");
  sys_exit(0);
}
