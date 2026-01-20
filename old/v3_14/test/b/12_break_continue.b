// Test 12: Break and Continue
import io;
import util;

func main(argc, argv) {
    var i;
    
    emit("Testing break:\n", 15);
    i = 0;
    while (i < 10) {
        if (i == 5) {
            emit("Breaking at i=5\n", 16);
            break;
        }
        emit("i=", 2);
        emit_i64(i);
        emit_nl();
        i = i + 1;
    }
    
    emit("\nTesting continue:\n", 19);
    i = 0;
    while (i < 10) {
        i = i + 1;
        if (i % 2 == 0) {
            continue;
        }
        emit("Odd: i=", 7);
        emit_i64(i);
        emit_nl();
    }
    
    return 0;
}
