// v2 library: string helpers for (ptr,len) + cstr
//
// Intended for v2-compiled output binaries.

import io;
import mem;

func slice_to_cstr(p, n) {
	var dst = heap_alloc(n + 1);
	if (dst == 0) {
		return 0;
	}
	memcpy(dst, p, n);
	ptr8[dst + n] = 0;
	return dst;
}

func str_concat(p1, n1, p2, n2) {
	// Returns: rax=ptr (NUL-terminated), rdx=len
	var total = n1 + n2;
	var dst = heap_alloc(total + 1);
	if (dst == 0) {
		alias rdx : out_len;
		out_len = 0;
		return 0;
	}

	memcpy(dst, p1, n1);
	memcpy(dst + n1, p2, n2);
	ptr8[dst + total] = 0;

	alias rdx : out_len;
	out_len = total;
	return dst;
}
