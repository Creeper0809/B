// Test 03: Recursion - Factorial
import std.io;
import std.emit;

func factorial(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

func main(argc, argv) {
    var i;
    i = 0;
    
    emit("Factorial test:\n", 16);
    
    while (i <= 10) {
        emit("factorial(", 10);
        emit_i64(i);
        emit(") = ", 4);
        emit_i64(factorial(i));
        emit_nl();
        i = i + 1;
    }
    
    return 0;
}
