// Test 11: Edge Cases and Corner Cases
// Mode: ssa
// Opt: O1
import std.io;
import std.emit;
import std.str;
import std.util;

func main(argc, argv) {
    var x;
    var y;
    var z;
    
    emit("Testing edge cases:\n", 20);
    
    // Zero operations
    emit("\n1. Zero operations:\n", 21);
    x = 0;
    y = 10;
    emit("0 + 10 = ", 9);
    emit_i64(x + y);
    emit_nl();
    
    emit("0 * 10 = ", 9);
    emit_i64(x * y);
    emit_nl();
    
    emit("10 - 10 = ", 10);
    emit_i64(y - y);
    emit_nl();
    
    // Negative numbers
    emit("\n2. Negative numbers:\n", 22);
    x = 0 - 10;
    y = 0 - 5;
    emit("-10 + (-5) = ", 13);
    emit_i64(x + y);
    emit_nl();
    
    emit("-10 - (-5) = ", 13);
    emit_i64(x - y);
    emit_nl();
    
    emit("-10 * (-5) = ", 13);
    emit_i64(x * y);
    emit_nl();
    
    // Large numbers
    emit("\n3. Large numbers:\n", 19);
    x = 1000000;
    y = 2000000;
    emit("1000000 + 2000000 = ", 20);
    emit_i64(x + y);
    emit_nl();
    
    // Boundary conditions
    emit("\n4. Boundary conditions:\n", 25);
    x = 1;
    y = 0;
    if (x > y) {
        emit("1 > 0: true\n", 12);
    }
    
    x = 0;
    y = 0;
    if (x == y) {
        emit("0 == 0: true\n", 13);
    }
    
    // Empty string
    emit("\n5. String operations:\n", 23);
    var msg;
    msg = "test";
    emit("String length: ", 15);
    emit_i64(str_len(msg));
    emit_nl();
    
    return 0;
}
