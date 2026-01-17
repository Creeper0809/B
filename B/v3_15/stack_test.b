// Stack trace test

import std.util;

func level3() {
    push_trace("level3", 6, "stack_test.b", 12, 6);
    emit("About to panic...", 17);
    emit_nl();
    panic();
    pop_trace();
}

func level2() {
    push_trace("level2", 6, "stack_test.b", 12, 14);
    level3();
    pop_trace();
}

func level1() {
    push_trace("level1", 6, "stack_test.b", 12, 20);
    level2();
    pop_trace();
}

func main() {
    push_trace("main", 4, "stack_test.b", 12, 26);
    emit("=== Stack Trace Test ===", 24);
    emit_nl();
    level1();
    pop_trace();
}
