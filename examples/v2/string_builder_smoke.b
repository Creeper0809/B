import io;
import mem;
import string_builder;

func main() {
	var sb = sb_new(8);
	if (sb == 0) {
		sys_exit(100);
	}

	sb_append_cstr(sb, "ab");
	sb_append_cstr(sb, "cd");
	sb_append_u64_dec(sb, 12345);

	var p = sb_ptr(sb);
	if (streq(p, "abcd12345") == 0) {
		sys_exit(1);
	}

	var n = sb_len(sb);
	if (n != 9) {
		sys_exit(2);
	}

	sb_clear(sb);
	p = sb_ptr(sb);
	if (streq(p, "") == 0) {
		sys_exit(3);
	}

	sys_exit(0);
}
