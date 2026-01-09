func main() -> u64 {
	var x: u64 = 0;
	var y: u64 = 3;
	// no-fallthrough: case 0 must NOT execute case 1
	switch (x) {
		case 0:
			y = 1;
		case 1:
			y = 2;
		default:
			y = 9;
	}
	return y;
}
