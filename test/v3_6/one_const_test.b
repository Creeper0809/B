const TEST_VAL = 42;

func get_val() {
    return TEST_VAL;
}

func main() {
    var x;
    x = get_val();
    
    var rdi;
    var rax;
    rdi = x;
    rax = 60;
    asm_syscall();
}
