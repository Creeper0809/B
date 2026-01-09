// scratch: sys_write with args loaded from ptr64

import io;

func main() {
	var bytes = heap_alloc(16);
	var out_p = ptr64[bytes + 0];
	var out_n = ptr64[bytes + 8];
	sys_write(1, out_p, out_n);
	return 0;
}
