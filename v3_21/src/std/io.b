// io.b - I/O helpers and memory allocation
// Low-level I/O + heap helpers
import std.str;
import std.os;

var heap_inited;
var heap_brk;
var g_out_fd;

func sys_brk(addr) { return os_sys_brk(addr); }
func sys_write(fd, buf, count) { return os_sys_write(fd, buf, count); }
func sys_read(fd, buf, count) { return os_sys_read(fd, buf, count); }
func sys_open(path, flags, mode) { return os_sys_open(path, flags, mode); }
func sys_close(fd) { return os_sys_close(fd); }
func sys_fstat(fd, statbuf) { return os_sys_fstat(fd, statbuf); }

func io_set_output_fd(fd: u64) -> u64 {
    g_out_fd = fd;
    return 0;
}

func io_get_output_fd() -> u64 {
    if (g_out_fd == 0) { return 1; }
    return g_out_fd;
}

func heap_alloc(size) {
    if (size == 0) {
        return 0;
    }

    // Align allocation size to 8 bytes to keep u64 stores within mapped pages.
    var align_mask: u64 = 0;
    align_mask = align_mask - 8; // ~7 via wrap-around
    var aligned_size: u64 = size + 7;
    aligned_size = aligned_size & align_mask;
    
    if (heap_inited == 0) {
        heap_brk = os_sys_brk(0);
        heap_inited = 1;
    }
    
    var aligned_brk: u64 = heap_brk + 7;
    aligned_brk = aligned_brk & align_mask;

    var p = aligned_brk;
    var new_brk = p + aligned_size;
    var res = os_sys_brk(new_brk);
    if (res < new_brk) {
        return 0;
    }
    heap_brk = new_brk;
    return p;
}

func emitln(s: u64) {
    var len: u64 = str_len(s);
    var fd: u64 = io_get_output_fd();
    os_sys_write(fd, s, len);
    os_sys_write(fd, "\n", 1);
}

func emit(s: u64, len: u64) {
    for (var i: u64 = 0; i < len; i++) {
        if (*(*u8)(s + i) == 0) { len = i; break; }
    }
    var fd2: u64 = io_get_output_fd();
    os_sys_write(fd2, s, len);
}

func print(s, len) {
    var fd3: u64 = io_get_output_fd();
    os_sys_write(fd3, s, len);
}

func print_nl() {
    var fd4: u64 = io_get_output_fd();
    os_sys_write(fd4, "\n", 1);
}

func println(s, len) {
    var fd5: u64 = io_get_output_fd();
    os_sys_write(fd5, s, len);
    os_sys_write(fd5, "\n", 1);
}

func print_u64(n) {
    if (n == 0) {
        var fd6: u64 = io_get_output_fd();
        os_sys_write(fd6, "0", 1);
        return;
    }
    var buf = heap_alloc(32 * sizeof(u8));
    var i: u64 = 0;
    var value: u64 = n;
    for (; value > 0; ) {
        var digit: u64 = value % 10;
        *(*u8)(buf + i) = digit + 48;
        value = value / 10;
        i = i + 1;
    }
    var j: i64 = (i64)i - 1;
    for (; j >= 0; j = j - 1) {
        var fd7: u64 = io_get_output_fd();
        os_sys_write(fd7, buf + (u64)j, 1);
    }
}

func print_i64(n) {
    if (n < 0) {
        var fd8: u64 = io_get_output_fd();
        os_sys_write(fd8, "-", 1);
        print_u64(0 - n);
    } else {
        print_u64(n);
    }
}
