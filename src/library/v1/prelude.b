// library/v1 prelude: declarations only (no function definitions)
//
// Stage1 basm constraint:
// - All `layout` / `const` / `var` declarations must appear before any `func`
//   definitions in the merged build unit.

// HashMap (open addressing)
// layout HashMap { entries; cap; len; }
// layout HashMapEntry { key_ptr; key_len; value; hash; used; }
layout HashMapEntry {
	ptr64 key_ptr;
	ptr64 key_len;
	ptr64 value;
	ptr64 hash;
	ptr64 used;
}

layout HashMap {
	ptr64 entries;
	ptr64 cap;
	ptr64 len;
}

layout StringInterner {
	ptr64 map;   // HashMap*
	ptr64 items; // Vec* (u64 items = Slice* for id->(ptr,len))
}

layout Arena {
	ptr64 base; // backing buffer ptr
	ptr64 cap;  // total bytes
	ptr64 off;  // bump offset in bytes
}

layout StringBuilder {
	ptr64 ptr; // u8*
	ptr64 len; // bytes used
	ptr64 cap; // capacity in bytes (excluding trailing NUL)
}
