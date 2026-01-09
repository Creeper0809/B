func main() -> u64 {
	var x: u64 = 0;
	while (x < 1) {
		switch (x) {
			case 0:
				x = 1;
				break;
			default:
				return 9;
		}
		// break must exit switch, not the while
		return 7;
	}
	return 8;
}
