// os.b - System call implementations for v3_17
// 운영체제 호출 전용 모듈

const OS_O_WRONLY = 1;
const OS_O_CREAT = 64;
const OS_O_TRUNC = 512;

const OS_SYS_FORK = 57;
const OS_SYS_EXECVE = 59;
const OS_SYS_WAIT4 = 61;
const OS_SYS_EXIT = 60;
const OS_SYS_DUP2 = 33;

func os_sys_brk(addr) {
    var result;
    asm {
        mov rax, 12
        mov rdi, [rbp+16]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_write(fd, buf, count) {
    var result;
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

func os_sys_read(fd, buf, count) {
    var result;
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

func os_sys_open(path, flags, mode) {
    var result;
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

func os_sys_close(fd) {
    var result;
    asm {
        mov rax, 3
        mov rdi, [rbp+16]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_fstat(fd, statbuf) {
    var result;
    asm {
        mov rax, 5
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_fork() {
    var result;
    asm {
        mov rax, 57
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_execve(path, argv, envp) {
    var result;
    asm {
        mov rax, 59
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        mov rdx, [rbp+32]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_wait4(pid, status_ptr, options, rusage) {
    var result;
    asm {
        mov rax, 61
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        mov rdx, [rbp+32]
        mov r10, [rbp+40]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

func os_sys_exit(code) {
    asm {
        mov rax, 60
        mov rdi, [rbp+16]
        syscall
    }
    return 0;
}

func os_sys_dup2(oldfd, newfd) {
    var result;
    asm {
        mov rax, 33
        mov rdi, [rbp+16]
        mov rsi, [rbp+24]
        syscall
        mov [rbp-8], rax
    }
    return result;
}

// ============================================
// 외부 명령 실행 (fork/execve/wait4)
// ============================================

func os_execute(path: u64, argv: u64) -> i64 {
    var pid: i64 = (i64)os_sys_fork();
    if (pid < 0) { return -1; }

    if (pid == 0) {
        var ret: i64 = (i64)os_sys_execve(path, argv, 0);
        os_sys_exit(1);
        return ret;
    }

    var status: u64 = 0;
    os_sys_wait4((u64)pid, (u64)&status, 0, 0);
    return (i64)status;
}
