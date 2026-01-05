// v2 library: Vec (push-only, u64 items)
//
// Intended for v2-compiled output binaries.

import io;
import mem;

struct Vec {
	ptr: u64;
	len: u64;
	cap: u64;
};

func vec_new(cap) {
	// Returns: Vec*
	var v = heap_alloc(24);
	if (v == 0) {
		return 0;
	}

	var bytes = cap * 8;
	var buf = heap_alloc(bytes);
	if (buf == 0) {
		return 0;
	}

	ptr64[v + 0] = buf;
	ptr64[v + 8] = 0;
	ptr64[v + 16] = cap;
	return v;
}

func vec_len(v) {
	return ptr64[v + 8];
}

func vec_get(v, i) {
	var buf = ptr64[v + 0];
	return ptr64[buf + i * 8];
}

func vec_push(v, item) {
	// Returns: new length (1-based count)
	var len = ptr64[v + 8];
	var cap = ptr64[v + 16];
	if (len >= cap) {
		var new_cap = cap;
		if (new_cap == 0) {
			new_cap = 1;
		}
		while (new_cap <= len) {
			new_cap = new_cap * 2;
		}

		var new_buf = heap_alloc(new_cap * 8);
		if (new_buf == 0) {
			return 0;
		}

		var old_buf = ptr64[v + 0];
		memcpy(new_buf, old_buf, len * 8);
		ptr64[v + 0] = new_buf;
		ptr64[v + 16] = new_cap;
	}

	var buf2 = ptr64[v + 0];
	ptr64[buf2 + len * 8] = item;
	len = len + 1;
	ptr64[v + 8] = len;
	return len;
}
