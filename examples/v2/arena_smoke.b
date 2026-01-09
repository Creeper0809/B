// v2 example: Arena runtime smoke (compiled by v2 compiler)

import io;
import arena;

func main() {
	var a = arena_new(64);
	if (a == 0) { sys_exit(1); }

	var p1 = arena_alloc(a, 3, 1);
	if (p1 == 0) { sys_exit(1); }

	var p2 = arena_alloc(a, 8, 8);
	if (p2 == 0) { sys_exit(2); }
	var t2 = p2 & 7;
	if (t2 == 0) { } else { sys_exit(3); }

	var p3 = arena_alloc(a, 16, 16);
	if (p3 == 0) { sys_exit(4); }
	var t3 = p3 & 15;
	if (t3 == 0) { } else { sys_exit(5); }

	// basic write sanity
	ptr8[p1] = 0x11;
	ptr8[p1 + 1] = 0x22;
	ptr8[p1 + 2] = 0x33;

	arena_reset(a);
	var p4 = arena_alloc(a, 8, 8);
	if (p4 == 0) { sys_exit(6); }

	print_str("arena ok\n");
	return 0;
}
