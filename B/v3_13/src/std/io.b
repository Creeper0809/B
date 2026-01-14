// io.b - System call implementations for v3.8
// Low-level I/O and memory allocation

var heap_inited;
var heap_brk;

func sys_brk(addr: u64) -> *u64 {
    var result: *u64;
    asm {
        mov rax, 12
        mov rdi, [rbp+16]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func sys_write(fd: u64, buf: *u64, count: u64) -> u64 {
    var result: u64;
    asm {
        mov rax, 1
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        mov rdx, [rbp+32]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func sys_read(fd: u64, buf: *u64, count: u64) -> u64 {
    var result: u64;
    asm {
        mov rax, 0
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        mov rdx, [rbp+32]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func sys_open(path: *u64, flags: u64, mode: u64) -> u64 {
    var result: u64;
    asm {
        mov rax, 2
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        mov rdx, [rbp+32]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func sys_close(fd: u64) -> u64 {
    var result: u64;
    asm {
        mov rax, 3
        mov rdi, [rbp+16]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func sys_fstat(fd: u64, statbuf: *u64) -> u64 {
    var result: u64;
    asm {
        mov rax, 5
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func heap_alloc(size: u64) -> *u64 {
    if (size == 0) {
        return 0;
    }
    
    if (heap_inited == 0) {
        heap_brk = sys_brk(0);
        heap_inited = 1;
    }
    
    var p: *u64 = heap_brk;
    var new_brk = p + size;
    var res = sys_brk(new_brk);
    if (res < new_brk) {
        return 0;
    }
    heap_brk = new_brk;
    return p;
}

func emit(s: *u64, len: u64) -> *u64 {
    sys_write(1, s, len);
}

func print(s: *u64, len: u64) -> *u64 {
    sys_write(1, s, len);
}

func print_nl() -> *u64 {
    sys_write(1, "\n", 1);
}

func println(s: *u64, len: u64) -> *u64 {
    sys_write(1, s, len);
    sys_write(1, "\n", 1);
}

func print_u64(n: u64) -> *u64 {
    if (n == 0) {
        sys_write(1, "0", 1);
        return;
    }
    var buf: *u64 = heap_alloc(32);
    var i: u64 = 0;
    var tmp: u64 = n;
    while (tmp > 0) {
        var digit: u64 = tmp % 10;
        *(*u8)(buf + i) = digit + 48;
        tmp = tmp / 10;
        i = i + 1;
    }
    var j: u64 = i - 1;
    while (j >= 0) {
        sys_write(1, buf + j, 1);
        j = j - 1;
    }
}

func print_i64(n: u64) -> *u64 {
    if (n < 0) {
        sys_write(1, "-", 1);
        print_u64(0 - n);
    } else {
        print_u64(n);
    }
}
