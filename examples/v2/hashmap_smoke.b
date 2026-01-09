import io;
import hashmap;

func main() {
	var m = hashmap_new(8);
	if (m == 0) {
		sys_exit(100);
	}

	hashmap_put(m, "abc", 3, 7);

	var v = hashmap_get(m, "abc", 3);
	alias rdx : ok;
	if (ok != 1) {
		sys_exit(1);
	}
	if (v != 7) {
		sys_exit(2);
	}

	hashmap_put(m, "abc", 3, 9);
	v = hashmap_get(m, "abc", 3);
	if (ok != 1) {
		sys_exit(3);
	}
	if (v != 9) {
		sys_exit(4);
	}

	v = hashmap_get(m, "zzz", 3);
	if (ok != 0) {
		sys_exit(5);
	}

	sys_exit(0);
}
