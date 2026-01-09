var pn: *u8? = null;
var p: *u8 = unwrap_ptr(pn);
var s: []u8 = slice_from_ptr_len(p, 3);
