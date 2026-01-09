func pair(a: u64, b: u64) -> (u64, u64) {
	return a, b;
}

func main() -> u64 {
	var x, y = pair(5, 7);
	x, y = pair(1, 2);
	return x + y;
}
