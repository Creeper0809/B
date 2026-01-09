func main() {
	var i = 0;
	var sum = 0;
	while (i < 5) {
		i = i + 1;
		var j = 0;
		while (j < 5) {
			j = j + 1;
			if (j == 2) { continue 2; }
			sum = sum + 1;
			if (sum == 3) { break 2; }
		}
	}
	return sum;
}
