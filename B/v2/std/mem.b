// v2 library: memory/string helpers
//
// Intended for v2-compiled output binaries.

func memcpy(dst, src, n) {
	var i = 0;
	while (i < n) {
		ptr8[dst + i] = ptr8[src + i];
		i = i + 1;
	}
	return dst;
}

func memset(dst, byte, n) {
	var i = 0;
	while (i < n) {
		ptr8[dst + i] = byte;
		i = i + 1;
	}
	return dst;
}

func memeq(a, b, n) {
	var i = 0;
	while (i < n) {
		if (ptr8[a + i] != ptr8[b + i]) {
			return 0;
		}
		i = i + 1;
	}
	return 1;
}

func streq(a, b) {
	var i = 0;
	while (1) {
		var ca = ptr8[a + i];
		var cb = ptr8[b + i];
		if (ca != cb) {
			return 0;
		}
		if (ca == 0) {
			return 1;
		}
		i = i + 1;
	}
	return 0;
}
