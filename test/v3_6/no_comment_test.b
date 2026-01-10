const CONST_A = 10;
const CONST_B = 20;

func test_add() {
    var x;
    x = 5 + 3;
    return x;
}

func main() {
    var result;
    result = test_add() + CONST_A + CONST_B;
    
    var rdi;
    var rax;
    rdi = result;
    rax = 60;
    asm_syscall();
}
