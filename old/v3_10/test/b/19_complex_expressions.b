// Test 19: Complex Expressions
import io;
import util;

func main(argc, argv) {
    var a;
    var b;
    var c;
    var result;
    
    emit("Testing complex expressions:\n", 29);
    
    a = 5;
    b = 10;
    c = 3;
    
    // Nested arithmetic
    emit("\n1. Nested arithmetic:\n", 23);
    result = (a + b) * c;
    emit("(5 + 10) * 3 = ", 15);
    emit_i64(result);
    emit_nl();
    
    result = a + b * c;
    emit("5 + 10 * 3 = ", 13);
    emit_i64(result);
    emit_nl();
    
    result = (a + b) / (c - 1);
    emit("(5 + 10) / (3 - 1) = ", 21);
    emit_i64(result);
    emit_nl();
    
    // Complex conditions
    emit("\n2. Complex conditions:\n", 24);
    var cond1;
    var cond2;
    
    cond1 = a < b;
    cond2 = b > c;
    if (cond1) {
        if (cond2) {
            emit("(5 < 10) AND (10 > 3): true\n", 29);
        }
    }
    
    cond1 = a > b;
    cond2 = b > c;
    if (cond1) {
        emit("(5 > 10) OR (10 > 3): true\n", 28);
    } else {
        if (cond2) {
            emit("(5 > 10) OR (10 > 3): true\n", 28);
        }
    }
    
    // Nested function calls
    emit("\n3. Expression with multiple operations:\n", 41);
    result = ((a + b) * c) / (c + 1) + a;
    emit("((5 + 10) * 3) / (3 + 1) + 5 = ", 32);
    emit_i64(result);
    emit_nl();
    
    return 0;
}
