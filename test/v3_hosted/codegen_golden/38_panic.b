// Test: panic builtin function
// panic(msg) should print "panic: <msg>\n" to stderr and exit(1)
func main() {
	print_u64(42);
	panic("test error message");
	print_u64(999);  // should not reach here
	return 0;
}
