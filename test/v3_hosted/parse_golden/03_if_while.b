func f(n: i64) -> i64 {
	var i: i64 = 0;
	while (i < n) {
		if (i == 2) { i = i + 1; }
		else { i = i + 2; }
	}
	return i;
}
