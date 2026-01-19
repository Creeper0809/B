// Test 01: Basic Arithmetic Operations
import std.io;
import std.emit;

func main(argc, argv) {
    var a;
    var b;
    var result;
    
    a = 10;
    b = 5;
    
    // Addition
    result = a + b;
    emit("10 + 5 = ", 9);
    emit_i64(result);
    emit_nl();
    
    // Subtraction
    result = a - b;
    emit("10 - 5 = ", 9);
    emit_i64(result);
    emit_nl();
    
    // Multiplication
    result = a * b;
    emit("10 * 5 = ", 9);
    emit_i64(result);
    emit_nl();
    
    // Division
    result = a / b;
    emit("10 / 5 = ", 9);
    emit_i64(result);
    emit_nl();
    
    // Modulo
    result = a % b;
    emit("10 % 5 = ", 9);
    emit_i64(result);
    emit_nl();
    
    return 0;
}
