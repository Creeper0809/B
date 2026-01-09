func main() {
	var x: u64 = 1;
	var y: u64 = x <<< 1;
	var z: u64 = y >>> 1;
	if (z == 1) { print("R"); } else { print("F"); }

	var a: []u8 = "ab";
	var b: []u8 = "ab";
	var c: []u8 = "ac";
	if (a === b) { print("T"); } else { print("F"); }
	if (a === c) { print("F"); } else { print("T"); }
	print("\n");
}
