const VAL_A = 10;
const VAL_B = 20;

func get_sum() {
    return VAL_A + VAL_B;
}

func main() {
    var x;
    x = get_sum();
    
    var rdi;
    var rax;
    rdi = x;
    rax = 60;
    asm_syscall();
}
