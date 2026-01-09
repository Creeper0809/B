import io;
import file;

func main() {
	// Just prove file IO works end-to-end.
	var p = read_file("./README.md");
	alias rdx : n;
	if (p == 0) {
		sys_exit(1);
	}
	if (n == 0) {
		sys_exit(2);
	}
	sys_exit(0);
}
