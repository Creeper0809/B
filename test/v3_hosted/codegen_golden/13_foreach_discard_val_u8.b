// foreach 2-binding with discard value

func main() {
	var s: str;
	s = "hi\n";
	var sum: u64 = 0;
	foreach (var i, _ in s) {
		sum = sum + i;
	}
	return sum;
}
