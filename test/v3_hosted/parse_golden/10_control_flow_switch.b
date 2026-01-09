const K: u64 = 2;

func main() -> u64 {
	var x: u64 = 0;
	while (x < 3) {
		switch (x) {
			case 0:
				x = x + 1;
				break;
			case K:
				continue;
			default:
				break;
		}
		x = x + 1;
	}
	return x;
}
