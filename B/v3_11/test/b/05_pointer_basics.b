// Test 05: Pointer Basics
import io;
import util;

func main(argc, argv) {
    var x;
    var ptr;
    
    x = 42;
    ptr = &x;
    
    emit("x = ", 4);
    emit_i64(x);
    emit_nl();
    
    emit("&x = ", 5);
    emit_i64(ptr);
    emit_nl();
    
    emit("*ptr = ", 7);
    emit_i64(*ptr);
    emit_nl();
    
    // Modify through pointer
    *ptr = 100;
    
    emit("After *ptr = 100:\n", 18);
    emit("x = ", 4);
    emit_i64(x);
    emit_nl();
    
    return 0;
}
