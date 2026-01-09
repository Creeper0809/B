packed struct H {
	a: u3,
	b: u5,
	c: u6,
	d: u2,
};

func main() {
	var h: H;
	h.a = 5;
	h.b = 17;
	h.c = 33;
	h.d = 3;

	if (h.a == 5) {
		if (h.b == 17) {
			if (h.c == 33) {
				if (h.d == 3) {
					print("ok\n");
					return 0;
				}
			}
		}
	}
	print("bad\n");
	return 0;
}
