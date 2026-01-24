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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, 2
    mov rbx, 0
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
    mov rax, rax
    add rax, 1
    push rax
    cmp rax, 3
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_3
    jmp .Lssa_0_4
.Lssa_0_3:
    mov rbx, 2
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_4
.Lssa_0_4:
    mov rax, rax
    sub rax, 1
    push rax
    cmp rax, 2
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_5
    jmp .Lssa_0_6
.Lssa_0_5:
    mov rbx, 3
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_6
.Lssa_0_6:
    mov rax, rax
    sub rax, 1
    cmp rax, 1
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_7
    jmp .Lssa_0_8
.Lssa_0_7:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_8
.Lssa_0_8:
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_0_9
.Lssa_0_9:
    cmp rbx, 3
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_10
    jmp .Lssa_0_12
.Lssa_0_10:
    jmp .Lssa_0_11
.Lssa_0_11:
    mov rax, rbx
    add rax, 1
    mov rbx, rax
    jmp .Lssa_0_9
.Lssa_0_12:
    cmp rbx, 3
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_13
    jmp .Lssa_0_14
.Lssa_0_13:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_14
.Lssa_0_14:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
