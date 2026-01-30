// Test 09: Const Variables
// Mode: ssa
// Opt: O1
import std.io;
import std.emit;
import std.util;

const MAX_SIZE = 100;
const MIN_SIZE = 10;
const DEFAULT_VALUE = 42;

func main(argc, argv) {
    emit("Testing constants:\n", 19);
    
    emit("MAX_SIZE = ", 11);
    emit_i64(MAX_SIZE);
    emit_nl();
    
    emit("MIN_SIZE = ", 11);
    emit_i64(MIN_SIZE);
    emit_nl();
    
    emit("DEFAULT_VALUE = ", 16);
    emit_i64(DEFAULT_VALUE);
    emit_nl();
    
    var size;
    size = MAX_SIZE - MIN_SIZE;
    emit("MAX_SIZE - MIN_SIZE = ", 22);
    emit_i64(size);
    emit_nl();
    
    return 0;
}
