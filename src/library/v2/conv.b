// v2 library: number formatting helpers
//
// Intended for v2-compiled output binaries.

import io;

func itoa_u64_dec(x) {
	// Returns:
	// - rax = ptr (NUL-terminated)
	// - rdx = len (excluding NUL)
	var buf = heap_alloc(32);
	if (buf == 0) {
		alias rdx : out_len;
		out_len = 0;
		return 0;
	}

	var end = 31;
	ptr8[buf + end] = 0;

	var i = end;
	var len = 0;
	if (x == 0) {
		i = i - 1;
		ptr8[buf + i] = 48;
		len = 1;
	} else {
		while (x > 0) {
			i = i - 1;
			var digit = x % 10;
			ptr8[buf + i] = digit + 48;
			x = x / 10;
			len = len + 1;
		}
	}

	alias rdx : out_len;
	out_len = len;
	return buf + i;
}
