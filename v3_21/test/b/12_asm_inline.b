// Test 12: Inline Assembly
// Mode: ssa
// Opt: O1
import std.io;
import std.emit;
import std.util;

func get_value_asm() {
    var result;
    result = 0;
    
    asm {
        mov rax, 42
        mov [rbp-8], rax
    }
    
    return result;
}

func add_asm(a, b) {
    var result;
    
    asm {
        mov rax, [rbp+16]
        add rax, [rbp+24]
        mov [rbp-8], rax
    }
    
    return result;
}

func main(argc, argv) {
    var x;
    var y;
    
    emit("Testing inline assembly:\n", 25);
    
    x = get_value_asm();
    emit("get_value_asm() = ", 18);
    emit_i64(x);
    emit_nl();
    
    y = add_asm(10, 32);
    emit("add_asm(10, 32) = ", 18);
    emit_i64(y);
    emit_nl();
    
    if (x == y) {
        emit("Results match!\n", 15);
    }
    
    return 0;
}
