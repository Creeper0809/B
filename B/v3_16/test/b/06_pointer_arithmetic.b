// Test 06: Pointer Arithmetic
import std.io;
import std.emit;

func main(argc, argv) {
    var arr;
    var i;
    
    // Allocate array of 5 integers (8 bytes each)
    arr = heap_alloc(40);
    
    // Initialize array
    emit("Initializing array:\n", 20);
    i = 0;
    while (i < 5) {
        *(arr + i * 8) = (i + 1) * 10;
        i = i + 1;
    }
    
    // Read array
    emit("Reading array:\n", 15);
    i = 0;
    while (i < 5) {
        emit("arr[", 4);
        emit_i64(i);
        emit("] = ", 4);
        emit_i64(*(arr + i * 8));
        emit_nl();
        i = i + 1;
    }
    
    return 0;
}
