// trace_test.b - 스택 트레이스 테스트

import std.io;
import std.diag;

func level3() {
    push_trace("level3", "trace_test.b", 7);
    emit("level3 called\n", 14);
    panic();  // 강제로 panic 발생 -> 스택 트레이스 출력됨
    pop_trace();
}

func level2() {
    push_trace("level2", "trace_test.b", 13);
    emit("level2 called\n", 14);
    level3();
    pop_trace()
}

func level1() {
    push_trace("level1", "trace_test.b", 20);
    emit("level1 called\n", 14);
    level2();
    pop_trace();
}

func main() {
    push_trace("main", "trace_test.b", 27);
    emit("Starting trace test...\n", 23);
    level1();
    pop_trace();
    return 0;
}
