// Test < vs generics

func test() {
	var a = 1;
	var b = 2;
	if (a < b) {
		return 1;
	}
	return 0;
}

func main() {
	return test();
}
