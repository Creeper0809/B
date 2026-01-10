// simple_test.b
const MY_CONST = 42;

func test() {
    return MY_CONST;
}

func main() {
    var x;
    x = test();
    
    var rdi;
    var rax;
    rdi = x;
    rax = 60;
    asm_syscall();
}
