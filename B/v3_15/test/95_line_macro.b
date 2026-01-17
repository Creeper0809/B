// Test __LINE__ macro

import util;

func main() {
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
    
    return __LINE__;
}
