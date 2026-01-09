const K: u64 = 2;

func main() -> u64 {
	var x: u64 = 2;
	switch (x) {
		case K:
			return 7;
		default:
			return 9;
	}
}
