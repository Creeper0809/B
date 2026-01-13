// Test 02: Comparison Operations
import io;
import util;

func test_comparison(a, b) {
    emit("Testing ", 8);
    emit_i64(a);
    emit(" vs ", 4);
    emit_i64(b);
    emit_nl();
    
    if (a == b) {
        emit("  a == b: true\n", 16);
    } else {
        emit("  a == b: false\n", 17);
    }
    
    if (a != b) {
        emit("  a != b: true\n", 16);
    } else {
        emit("  a != b: false\n", 17);
    }
    
    if (a < b) {
        emit("  a < b: true\n", 15);
    } else {
        emit("  a < b: false\n", 16);
    }
    
    if (a > b) {
        emit("  a > b: true\n", 15);
    } else {
        emit("  a > b: false\n", 16);
    }
    
    if (a <= b) {
        emit("  a <= b: true\n", 16);
    } else {
        emit("  a <= b: false\n", 17);
    }
    
    if (a >= b) {
        emit("  a >= b: true\n", 16);
    } else {
        emit("  a >= b: false\n", 17);
    }
}

func main(argc, argv) {
    test_comparison(10, 5);
    test_comparison(5, 10);
    test_comparison(7, 7);
    return 0;
}
