// Test 04: Recursion - Fibonacci
import std.io;
import std.emit;

func fib(n) {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

func main(argc, argv) {
    var i;
    i = 0;
    
    emit("Fibonacci sequence:\n", 20);
    
    while (i <= 15) {
        emit("fib(", 4);
        emit_i64(i);
        emit(") = ", 4);
        emit_i64(fib(i));
        emit_nl();
        i = i + 1;
    }
    
    return 0;
}
