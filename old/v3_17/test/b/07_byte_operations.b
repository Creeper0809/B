// Test 07: Byte Operations (*(*u8))
import std.io;
import std.emit;

func main(argc, argv) {
    var buf;
    var i;
    
    // Allocate buffer
    buf = heap_alloc(10);
    
    // Write bytes
    emit("Writing bytes:\n", 15);
    i = 0;
    while (i < 10) {
        *(*u8)(buf + i) = 65 + i;  // ASCII 'A', 'B', 'C', ...
        i = i + 1;
    }
    
    // Read bytes
    emit("Reading bytes:\n", 15);
    i = 0;
    while (i < 10) {
        emit("buf[", 4);
        emit_i64(i);
        emit("] = ", 4);
        emit_i64(*(*u8)(buf + i));
        emit(" (", 2);
        sys_write(1, buf + i, 1);
        emit(")\n", 2);
        i = i + 1;
    }
    
    return 0;
}
