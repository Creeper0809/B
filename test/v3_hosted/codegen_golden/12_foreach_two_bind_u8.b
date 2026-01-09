// foreach 2-binding: index + value over a []u8 slice

func main() {
	var s: str;
	s = "hi\n";
	var sum: u64 = 0;
	foreach (var i, b in s) {
		sum = sum + i;
		sum = sum + cast(u64, b);
	}
	return sum;
}
