// Test __LINE__ macro
// Mode: ssa
// Opt: O1

import std.io;
import std.emit;
import std.util;

func main(argc, argv) {
    emit("Line 6: ", 8);
    emit_i64(__LINE__);
    emit_nl();
    
    emit("Line 10: ", 9);
    emit_i64(__LINE__);
    emit_nl();
    
    var x = __LINE__;
    emit("Line 14 stored in var: ", 23);
    emit_i64(x);
    emit_nl();
    
    return 0;
}
