// P15: HashMap runtime smoke (library/v1)
// Goal: validate hashmap_new/put/get/has on Slice keys.

func main() {
	var m;

	hashmap_new(8);
	ptr64[m] = rax;

	// insert
	rdi = ptr64[m];
	hashmap_put(rdi, "abc", 3, 7);

	// get
	rdi = ptr64[m];
	hashmap_get(rdi, "abc", 3);
	if (rdx != 1) {
		sys_exit(1);
	}
	if (rax != 7) {
		sys_exit(2);
	}

	// update
	rdi = ptr64[m];
	hashmap_put(rdi, "abc", 3, 9);
	rdi = ptr64[m];
	hashmap_get(rdi, "abc", 3);
	if (rdx != 1) {
		sys_exit(3);
	}
	if (rax != 9) {
		sys_exit(4);
	}

	// missing
	rdi = ptr64[m];
	hashmap_get(rdi, "zzz", 3);
	if (rdx != 0) {
		sys_exit(5);
	}

	sys_exit(0);
}
