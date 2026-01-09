// foreach over a slice (string literal)

func main() {
	var s: str;
	s = "hi\n";
	var sum: u64 = 0;
	foreach (var b in s) {
		sum = sum + cast(u64, b);
	}
	return sum;
}
