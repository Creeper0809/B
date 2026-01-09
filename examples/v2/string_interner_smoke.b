import io;
import mem;
import string_interner;

func main() {
	var si = string_interner_new(8);
	if (si == 0) {
		sys_exit(100);
	}

	var id1 = string_interner_intern(si, "abc", 3);
	var id2 = string_interner_intern(si, "abc", 3);
	var id3 = string_interner_intern(si, "def", 3);

	if (id1 != id2) {
		sys_exit(1);
	}
	if (id3 == id1) {
		sys_exit(2);
	}

	var p = string_interner_get(si, id1);
	alias rdx : n;
	if (n != 3) {
		sys_exit(3);
	}
	if (streq(p, "abc") == 0) {
		sys_exit(4);
	}

	sys_exit(0);
}
