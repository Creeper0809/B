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
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rax, rsi
    mov rax, 0
    mov rax, 5
    mov rbx, 1
    push rax
    cmp rax, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_2
    jmp .Lssa_0_5
.Lssa_0_1:
    mov rax, 2
    cmp rbx, rax
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_9
    jmp .Lssa_0_10
.Lssa_0_2:
    lea rax, [rbp-8]
    mov rax, 1
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_3:
    lea rax, [rbp-8]
    mov rax, 2
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_4:
    lea rax, [rbp-8]
    mov rax, 3
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_5:
    mov rbx, 5
    cmp rax, rbx
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_3
    jmp .Lssa_0_6
.Lssa_0_6:
    jmp .Lssa_0_4
.Lssa_0_7:
.Lssa_0_8:
.Lssa_0_9:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_10
.Lssa_0_10:
    mov rax, 0
    jmp .Lssa_0_12
.Lssa_0_11:
    mov rbx, 4
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_13
    jmp .Lssa_0_14
.Lssa_0_12:
    lea rax, [rbp-8]
    mov rax, 4
    jmp .Lssa_0_11
.Lssa_0_13:
    mov rax, 2
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
