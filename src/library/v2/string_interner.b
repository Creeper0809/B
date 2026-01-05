// v2 library: StringInterner
//
// Intended for v2-compiled output binaries.

import io;
import mem;
import vec;
import hashmap;
import slice;

struct StringInterner {
	map: u64;   // HashMap*
	items: u64; // Vec* (u64 items: Slice*)
};

func string_interner_new(cap) {
	var si = heap_alloc(16);
	if (si == 0) {
		return 0;
	}

	var map = hashmap_new(cap);
	if (map == 0) {
		return 0;
	}

	var items = vec_new(cap);
	if (items == 0) {
		return 0;
	}

	ptr64[si + 0] = map;
	ptr64[si + 8] = items;
	return si;
}

func string_interner_intern(si, p, n) {
	var map = ptr64[si + 0];
	var existing = hashmap_get(map, p, n);
	alias rdx : ok;
	if (ok != 0) {
		return existing;
	}

	var dst = heap_alloc(n + 1);
	if (dst == 0) {
		return 0;
	}
	memcpy(dst, p, n);
	ptr8[dst + n] = 0;

	var slice = heap_alloc(16);
	if (slice == 0) {
		return 0;
	}
	ptr64[slice + 0] = dst;
	ptr64[slice + 8] = n;

	var items = ptr64[si + 8];
	vec_push(items, slice);
	var id = vec_push(items, slice);
	if (id == 0) {
		return 0;
	}

	hashmap_put(map, dst, n, id);
	return id;
}

func string_interner_get(si, id) {
	// Returns: rax=ptr, rdx=len (0/0 if invalid)
	if (id == 0) {
		alias rdx : out_len;
		out_len = 0;
		return 0;
	}

	var items = ptr64[si + 8];
	var i = id - 1;
	var len = vec_len(items);
	if (i >= len) {
		alias rdx : out_len;
		out_len = 0;
		return 0;
	}

	var slice = vec_get(items, i);
	alias rdx : out_len;
	out_len = ptr64[slice + 8];
	return ptr64[slice + 0];
}
