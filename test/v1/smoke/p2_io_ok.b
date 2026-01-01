// P2 smoke: read_file + emitter roundtrip

func main() {
  var p1;
  var n1;
  var p2;
  var n2;

  // read README.md
  read_file("README.md");
  ptr64[p1] = rax;
  ptr64[n1] = rdx;

  // emit to build/p2_roundtrip.txt
  emit_init();
  rdi = ptr64[p1];
  rsi = ptr64[n1];
  emit_str(rdi, rsi);
  emit_to_file("build/p2_roundtrip.txt");

  // read back and compare length
  read_file("build/p2_roundtrip.txt");
  ptr64[p2] = rax;
  ptr64[n2] = rdx;

  alias r8 : len1;
  alias r9 : len2;
  len1 = ptr64[n1];
  len2 = ptr64[n2];

  if (len1 != len2) {
    die("P2 smoke: len mismatch");
  }

  print_str("OK\n");
  sys_exit(0);
}
