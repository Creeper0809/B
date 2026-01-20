// Expect exit code: 0

import std.io;

func main() -> i64 {
    var old: u64 = io_get_output_fd();
    io_set_output_fd(2);
    if (io_get_output_fd() != 2) { return 1; }
    io_set_output_fd(old);
    if (io_get_output_fd() != old) { return 2; }
    return 0;
}
