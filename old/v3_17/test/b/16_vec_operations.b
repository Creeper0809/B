// Test 16: Vec (Dynamic Array) Operations
import std.io;
import std.emit;
import std.vec;

func main(argc, argv) {
    var v;
    var i;
    var len;
    
    emit("Testing Vec:\n", 13);
    
    // Create vector
    v = vec_new(4);
    emit("Created vec with capacity 4\n", 29);
    
    // Push elements
    emit("Pushing elements...\n", 20);
    i = 0;
    while (i < 10) {
        vec_push(v, i * 10);
        i = i + 1;
    }
    
    // Get length
    len = vec_len(v);
    emit("Vec length: ", 12);
    emit_i64(len);
    emit_nl();
    
    // Get elements
    emit("Vec contents:\n", 14);
    i = 0;
    while (i < len) {
        emit("  v[", 4);
        emit_i64(i);
        emit("] = ", 4);
        emit_i64(vec_get(v, i));
        emit_nl();
        i = i + 1;
    }
    
    // Modify element
    vec_set(v, 5, 999);
    emit("After setting v[5] = 999:\n", 26);
    emit("  v[5] = ", 9);
    emit_i64(vec_get(v, 5));
    emit_nl();
    
    return 0;
}
