default rel
section .text
global _start
_start:
    pop rdi          ; argc
    mov rsi, rsp     ; argv
    push rsi
    push rdi
    call main
    mov rdi, rax
    mov rax, 60
    syscall
_03_recursion_basic__factorial:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    push rax
    cmp rax, 1
    setle al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rbx, 1
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rbx, rax
    sub rbx, 1
    push rax
    mov rdi, rbx
    call _03_recursion_basic__factorial
    mov rbx, rax
    pop rax
    mov rax, rax
    imul rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_03_recursion_basic__fib:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_3:
    mov rax, rdi
    push rax
    cmp rax, 2
    setl al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_1_4
    jmp .Lssa_1_5
.Lssa_1_4:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_5
.Lssa_1_5:
    mov rbx, rax
    sub rbx, 1
    push rax
    mov rdi, rbx
    call _03_recursion_basic__fib
    mov rbx, rax
    pop rax
    mov rax, rax
    sub rax, 2
    push rbx
    mov rdi, rax
    call _03_recursion_basic__fib
    pop rbx
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_2_6:
    mov rax, rdi
    mov rax, rsi
    mov rax, 5
    mov rdi, rax
    call _03_recursion_basic__factorial
    cmp rax, 120
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_7
    jmp .Lssa_2_8
.Lssa_2_7:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_8
.Lssa_2_8:
    mov rax, 10
    mov rdi, rax
    call _03_recursion_basic__fib
    cmp rax, 55
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_9
    jmp .Lssa_2_10
.Lssa_2_9:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_10
.Lssa_2_10:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
