// Test 09: Nested Loops
import std.io;
import std.emit;

func main(argc, argv) {
    var i;
    var j;
    
    emit("Multiplication table (1-5):\n", 28);
    emit("   ", 3);
    
    // Header
    i = 1;
    while (i <= 5) {
        emit_i64(i);
        emit("  ", 2);
        i = i + 1;
    }
    emit_nl();
    
    // Body
    i = 1;
    while (i <= 5) {
        emit_i64(i);
        emit("  ", 2);
        
        j = 1;
        while (j <= 5) {
            var product;
            product = i * j;
            if (product < 10) {
                emit(" ", 1);
            }
            emit_i64(product);
            emit(" ", 1);
            j = j + 1;
        }
        emit_nl();
        i = i + 1;
    }
    
    return 0;
}
