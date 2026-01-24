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
_85_ssa_slice_return_modify__create_view:
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
    mov rdx, rax
    mov rax, rbx
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
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 0
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 8
    mov rbx, 20
    mov [rax], rbx
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 16
    mov rbx, 30
    mov [rax], rbx
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 24
    mov rbx, 40
    mov [rax], rbx
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 32
    mov rbx, 50
    mov [rax], rbx
    lea rax, [rbp-56]
    lea rbx, [rbp-40]
    mov rcx, 5
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call _85_ssa_slice_return_modify__create_view
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-56]
    mov rax, [rax]
    mov rax, rax
    add rax, 16
    mov rbx, 99
    mov [rax], rbx
    lea rax, [rbp-40]
    mov rax, rax
    add rax, 16
    mov rax, [rax]
    cmp rax, 99
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
    lea rax, [rbp-56]
    mov rax, [rax]
    mov rax, rax
    add rax, 16
    mov rax, [rax]
    cmp rax, 99
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
