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
    lea rax, [rbp-16]
    mov rbx, 5
    mov [rax], rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov rbx, 7
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rcx, 8
    mov rbx, rbx
    add rbx, rcx
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    mov rbx, 12
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    lea rax, [rbp-16]
    mov rbx, 1
    mov [rax], rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov rbx, 2
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, 10
    mov rax, rax
    imul rax, rbx
    lea rbx, [rbp-16]
    mov rcx, 8
    mov rbx, rbx
    add rbx, rcx
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    mov rbx, 12
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_3
    jmp .Lssa_0_4
.Lssa_0_3:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_4
.Lssa_0_4:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
