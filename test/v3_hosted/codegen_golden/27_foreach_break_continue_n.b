func main() {
	var i = 0;
	var sum = 0;
	while (i < 3) {
		i = i + 1;
		foreach (var c in "ab") {
			c = c; // unused 방지
			sum = sum + 1;
			// i==1에서는 바깥 while을 continue해서 sum+=10을 스킵
			if (i == 1) { continue 2; }
			// i==2에서는 바깥 while을 break
			if (i == 2) { break 2; }
		}
		sum = sum + 10;
	}
	return sum;
}
