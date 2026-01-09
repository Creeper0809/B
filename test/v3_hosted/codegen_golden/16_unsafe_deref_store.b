// Phase 4.1: unsafe `$` deref/load/store

func main() {
	var ch: u8 = 65;
	var p: *u8 = &ch;

	var a: u8 = $p;
	$p = a + 1; // 'B'
	print(slice_from_ptr_len(p, 1));

	$p = $p + 1; // 'C'
	print(slice_from_ptr_len(p, 1));

	print("\n");
}
