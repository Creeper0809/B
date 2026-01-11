// Test 15: Nested If Statements
import io;
import util;

func classify_number(n) {
    emit("Classifying ", 12);
    emit_i64(n);
    emit(": ", 2);
    
    if (n < 0) {
        emit("negative", 8);
        if (n < 0 - 100) {
            emit(", large", 7);
        } else {
            emit(", small", 7);
        }
    } else {
        if (n == 0) {
            emit("zero", 4);
        } else {
            emit("positive", 8);
            if (n > 100) {
                emit(", large", 7);
            } else {
                emit(", small", 7);
            }
        }
    }
    emit_nl();
}

func main(argc, argv) {
    emit("Nested if test:\n", 16);
    
    classify_number(0 - 200);
    classify_number(0 - 50);
    classify_number(0);
    classify_number(50);
    classify_number(200);
    
    return 0;
}
