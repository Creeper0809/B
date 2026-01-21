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
    lea rax, [rbp-32]
    mov rbx, 0
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-32]
    mov rbx, 1
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rbx, 20
    mov [rax], rbx
    lea rax, [rbp-48]
    lea rbx, [rbp-32]
    mov rcx, 0
    mov rdx, 8
    mov rcx, rcx
    imul rcx, rdx
    mov rbx, rbx
    add rbx, rcx
    mov rbx, [rbx]
    mov [rax], rbx
    lea rax, [rbp-48]
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-32]
    mov rcx, 1
    mov rdx, 8
    mov rcx, rcx
    imul rcx, rdx
    mov rbx, rbx
    add rbx, rcx
    mov rbx, [rbx]
    mov [rax], rbx
    lea rax, [rbp-32]
    mov rbx, 1
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rax, [rax]
    lea rbx, [rbp-48]
    mov rbx, [rbx]
    lea rcx, [rbp-48]
    mov rdx, 8
    mov rcx, rcx
    add rcx, rdx
    mov rcx, [rcx]
    mov rbx, rbx
    add rbx, rcx
    add rax, rbx
    mov rbx, 50
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
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
