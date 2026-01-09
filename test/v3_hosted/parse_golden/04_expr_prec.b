func g(a: i64, b: i64, c: i64) -> i64 {
	var x: i64 = a + b * 2 - 3 / 4 % 5;
	var y: i64 = (a << 1) >> 2;
	var z: i64 = (a == b) || (b != c);
	return x + y + z;
}
