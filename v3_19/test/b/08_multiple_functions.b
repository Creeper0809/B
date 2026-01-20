// Test 08: Multiple Functions
import std.io;
import std.emit;
import std.str;
import std.util;

func add(a, b) {
    return a + b;
}

func subtract(a, b) {
    return a - b;
}

func multiply(a, b) {
    return a * b;
}

func divide(a, b) {
    if (b == 0) {
        emit("Error: Division by zero\n", 24);
        return 0;
    }
    return a / b;
}

func calculator(op, a, b) {
    emit_i64(a);
    emit(" ", 1);
    emit(op, str_len(op));
    emit(" ", 1);
    emit_i64(b);
    emit(" = ", 3);
    
    if (str_eq(op, str_len(op), "+", 1)) {
        emit_i64(add(a, b));
    } else {
        if (str_eq(op, str_len(op), "-", 1)) {
            emit_i64(subtract(a, b));
        } else {
            if (str_eq(op, str_len(op), "*", 1)) {
                emit_i64(multiply(a, b));
            } else {
                if (str_eq(op, str_len(op), "/", 1)) {
                    emit_i64(divide(a, b));
                }
            }
        }
    }
    emit_nl();
}

func main(argc, argv) {
    emit("Calculator test:\n", 17);
    
    calculator("+", 10, 5);
    calculator("-", 10, 5);
    calculator("*", 10, 5);
    calculator("/", 10, 5);
    calculator("/", 10, 0);
    
    return 0;
}
