// Test 11: For Loop
import std.io;
import std.emit;

func main(argc, argv) {
    var i;
    var sum;
    
    emit("For loop test: sum of 1 to 10\n", 31);
    
    sum = 0;
    for (i = 1; i <= 10; i = i + 1) {
        emit("i=", 2);
        emit_i64(i);
        emit(", sum=", 6);
        sum = sum + i;
        emit_i64(sum);
        emit_nl();
    }
    
    emit("Final sum: ", 11);
    emit_i64(sum);
    emit_nl();
    
    return 0;
}
