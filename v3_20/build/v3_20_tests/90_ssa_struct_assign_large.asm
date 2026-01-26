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
_90_ssa_struct_assign_large__make_big:
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
    mov rbx, [rbp-1032]
    lea rcx, [rbp-40]
    mov [rcx], rax
    lea rcx, [rbp-40]
    mov rcx, rcx
    add rcx, 8
    mov rdx, rax
    add rdx, 1
    mov [rcx], rdx
    lea rcx, [rbp-40]
    mov rcx, rcx
    add rcx, 16
    mov rdx, rax
    add rdx, 2
    mov [rcx], rdx
    lea rcx, [rbp-40]
    mov rcx, rcx
    add rcx, 24
    mov rdx, rax
    add rdx, 3
    mov [rcx], rdx
    lea rcx, [rbp-40]
    mov rcx, rcx
    add rcx, 32
    mov rax, rax
    add rax, 4
    mov [rcx], rax
    lea rax, [rbp-40]
    mov rcx, [rax]
    mov [rbx], rcx
    mov rcx, rax
    add rcx, 8
    mov rdx, rbx
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rax
    add rcx, 16
    mov rdx, rbx
    add rdx, 16
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rax
    add rcx, 24
    mov rdx, rbx
    add rdx, 24
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rax, rax
    add rax, 32
    mov rbx, rbx
    add rbx, 32
    mov rax, [rax]
    mov [rbx], rax
    xor eax, eax
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_1_1:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rbp-40]
    mov rbx, 10
    push rbx
    push rax
    pop rdi
    pop rsi
    call _90_ssa_struct_assign_large__make_big
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 16
    mov rax, [rax]
    cmp rax, 12
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_2
    jmp .Lssa_1_3
.Lssa_1_2:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_3
.Lssa_1_3:
    lea rax, [rbp-80]
    lea rbx, [rbp-40]
    mov rcx, [rbx]
    mov [rax], rcx
    mov rcx, rbx
    add rcx, 8
    mov rdx, rax
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rbx
    add rcx, 16
    mov rdx, rax
    add rdx, 16
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rbx
    add rcx, 24
    mov rdx, rax
    add rdx, 24
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rbx, rbx
    add rbx, 32
    mov rax, rax
    add rax, 32
    mov rbx, [rbx]
    mov [rax], rbx
    lea rax, [rbp-80]
    mov rax, rax
    add rax, 32
    mov rax, [rax]
    cmp rax, 14
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_4
    jmp .Lssa_1_5
.Lssa_1_4:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_5
.Lssa_1_5:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
