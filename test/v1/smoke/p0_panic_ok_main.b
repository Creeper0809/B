// P0 smoke test: panic/panic_at
// This file is meant to be concatenated after src/v1/std/std0_sys.b.

func main() {
  // Expect: prints message and exits with code 1.
  panic("boom");
}
