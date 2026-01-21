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
    lea rbx, [rel _str0]
    mov rcx, 2
    mov [rax], rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 72
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
    mov rax, [rax]
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, 1
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 73
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_3
    jmp .Lssa_0_4
.Lssa_0_3:
    mov rax, 2
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

section .data
_str0: db 72,73,0
