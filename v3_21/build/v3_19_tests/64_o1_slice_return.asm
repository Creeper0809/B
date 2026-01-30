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
_64_o1_slice_return__make_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    mov rax, rcx
    add rax, 8
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rbx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
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
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rax, rsi
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 0
    mov rbx, 65
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 1
    mov rbx, 66
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 2
    mov rbx, 67
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 3
    mov rbx, 68
    mov byte [rax], bl
    lea rax, [rbp-20]
    mov rbx, 4
    lea rcx, [rbp-4]
    push rax
    push rbx
    push rcx
    call _64_o1_slice_return__make_slice
    add rsp, 16
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-20]
    mov rax, [rax]
    mov rax, rax
    add rax, 0
    movzx rax, byte [rax]
    cmp rax, 65
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
    lea rax, [rbp-20]
    mov rax, [rax]
    mov rax, rax
    add rax, 3
    movzx rax, byte [rax]
    cmp rax, 68
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
