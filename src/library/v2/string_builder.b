// v2 library: StringBuilder (byte buffer, NUL-terminated)
//
// Intended for v2-compiled output binaries.

import io;
import mem;
import conv;

struct StringBuilder {
	ptr: u64;
	len: u64;
	cap: u64; // excluding trailing NUL
};

func sb_new(cap) {
	if (cap < 8) {
		cap = 8;
	}

	var sb = heap_alloc(24);
	if (sb == 0) {
		return 0;
	}

	var buf = heap_alloc(cap + 1);
	if (buf == 0) {
		return 0;
	}

	ptr64[sb + 0] = buf;
	ptr64[sb + 8] = 0;
	ptr64[sb + 16] = cap;
	ptr8[buf] = 0;
	return sb;
}

func sb_clear(sb) {
	ptr64[sb + 8] = 0;
	var p = ptr64[sb + 0];
	ptr8[p] = 0;
	return 0;
}

func sb_len(sb) {
	return ptr64[sb + 8];
}

func sb_ptr(sb) {
	return ptr64[sb + 0];
}

func sb_reserve(sb, add) {
	var len = ptr64[sb + 8];
	var cap = ptr64[sb + 16];
	var need = len + add;
	if (need <= cap) {
		return 0;
	}

	var new_cap = cap;
	if (new_cap == 0) {
		new_cap = 8;
	}
	while (new_cap < need) {
		new_cap = new_cap * 2;
	}

	var new_buf = heap_alloc(new_cap + 1);
	if (new_buf == 0) {
		return 0;
	}

	var old_buf = ptr64[sb + 0];
	memcpy(new_buf, old_buf, len);
	ptr8[new_buf + len] = 0;

	ptr64[sb + 0] = new_buf;
	ptr64[sb + 16] = new_cap;
	return 0;
}

func sb_append_bytes(sb, p, n) {
	sb_reserve(sb, n);

	var len = ptr64[sb + 8];
	var dst = ptr64[sb + 0] + len;
	memcpy(dst, p, n);
	len = len + n;
	ptr64[sb + 8] = len;
	ptr8[ptr64[sb + 0] + len] = 0;
	return 0;
}

func sb_append_cstr(sb, s) {
	var n = strlen(s);
	sb_append_bytes(sb, s, n);
	return 0;
}

func sb_append_u64_dec(sb, x) {
	var p = itoa_u64_dec(x);
	alias rdx : n;
	sb_append_bytes(sb, p, n);
	return 0;
}
