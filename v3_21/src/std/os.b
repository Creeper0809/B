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

var g_syscall_arg0;
var g_syscall_arg1;
var g_syscall_arg2;
var g_syscall_arg3;
var g_syscall_ret;

func os_sys_brk(addr) {
    g_syscall_arg0 = addr;
    asm {
        mov rax, 12
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_write(fd, buf, count) {
    g_syscall_arg0 = fd;
    g_syscall_arg1 = buf;
    g_syscall_arg2 = count;
    asm {
        mov rax, 1
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        mov rdx, [rel _gvar_std_os__g_syscall_arg2]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_read(fd, buf, count) {
    g_syscall_arg0 = fd;
    g_syscall_arg1 = buf;
    g_syscall_arg2 = count;
    asm {
        mov rax, 0
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        mov rdx, [rel _gvar_std_os__g_syscall_arg2]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_open(path, flags, mode) {
    g_syscall_arg0 = path;
    g_syscall_arg1 = flags;
    g_syscall_arg2 = mode;
    asm {
        mov rax, 2
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        mov rdx, [rel _gvar_std_os__g_syscall_arg2]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_close(fd) {
    g_syscall_arg0 = fd;
    asm {
        mov rax, 3
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_fstat(fd, statbuf) {
    g_syscall_arg0 = fd;
    g_syscall_arg1 = statbuf;
    asm {
        mov rax, 5
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_fork() {
    asm {
        mov rax, 57
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_execve(path, argv, envp) {
    g_syscall_arg0 = path;
    g_syscall_arg1 = argv;
    g_syscall_arg2 = envp;
    asm {
        mov rax, 59
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        mov rdx, [rel _gvar_std_os__g_syscall_arg2]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_wait4(pid, status_ptr, options, rusage) {
    g_syscall_arg0 = pid;
    g_syscall_arg1 = status_ptr;
    g_syscall_arg2 = options;
    g_syscall_arg3 = rusage;
    asm {
        mov rax, 61
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        mov rdx, [rel _gvar_std_os__g_syscall_arg2]
        mov r10, [rel _gvar_std_os__g_syscall_arg3]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
}

func os_sys_exit(code) {
    g_syscall_arg0 = code;
    asm {
        mov rax, 60
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        syscall
    }
    return 0;
}

func os_sys_dup2(oldfd, newfd) {
    g_syscall_arg0 = oldfd;
    g_syscall_arg1 = newfd;
    asm {
        mov rax, 33
        mov rdi, [rel _gvar_std_os__g_syscall_arg0]
        mov rsi, [rel _gvar_std_os__g_syscall_arg1]
        syscall
        mov [rel _gvar_std_os__g_syscall_ret], rax
    }
    return g_syscall_ret;
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
