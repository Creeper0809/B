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
    lea rax, [rbp-24]
    mov rbx, 0
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rbx, 1
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rbx, 20
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rbx, 2
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rbx, 30
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rbx, 1
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    add rbx, rax
    mov rbx, [rbx]
    mov rcx, 20
    push rax
    cmp rbx, rcx
    setne al
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
    mov rbx, 2
    mov rcx, 8
    mov rbx, rbx
    imul rbx, rcx
    mov rax, rax
    add rax, rbx
    mov rax, [rax]
    mov rbx, 30
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
