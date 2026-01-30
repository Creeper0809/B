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
    lea rax, [rbp-32]
    mov rbx, 1
    mov [rax], rbx
    mov rbx, 8
    add rbx, rax
    mov rcx, 2
    mov [rbx], rcx
    mov rcx, 8
    mov rbx, rbx
    add rbx, rcx
    mov rcx, 3
    mov [rbx], rcx
    mov rbx, 24
    mov rax, rax
    add rax, rbx
    mov rbx, 4
    mov [rax], rbx
    lea rax, [rbp-32]
    mov rax, [rax]
    mov rbx, 1
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
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov rax, [rax]
    mov rbx, 2
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
    lea rax, [rbp-32]
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov rax, [rax]
    mov rbx, 3
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_5
    jmp .Lssa_0_6
.Lssa_0_5:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_6
.Lssa_0_6:
    lea rax, [rbp-32]
    mov rbx, 24
    mov rax, rax
    add rax, rbx
    mov rax, [rax]
    mov rbx, 4
    cmp rax, rbx
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
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
