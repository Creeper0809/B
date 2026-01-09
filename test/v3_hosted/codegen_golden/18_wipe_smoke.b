func main() {
	var x: u8 = 7;
	wipe x;
	if (x == 0) { print("V"); } else { print("v"); }

	var y: u8 = 9;
	var py: *u8 = &y;
	wipe py, 1;
	var z: u8 = $py;
	if (z == 0) { print("P\n"); } else { print("p\n"); }
}
