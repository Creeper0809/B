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
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rbp-16]
    lea rbx, [rel _str0]
    mov rcx, 3
    mov [rax], rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, 2
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 90
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
    lea rax, [rbp-32]
    lea rbx, [rbp-16]
    mov rcx, [rbx]
    mov rdx, 8
    mov rbx, rbx
    add rbx, rdx
    mov rbx, [rbx]
    mov [rax], rcx
    mov rcx, 8
    mov rax, rax
    add rax, rcx
    mov [rax], rbx
    lea rax, [rbp-32]
    mov rax, [rax]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 88
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
_str0: db 88,89,90,0
