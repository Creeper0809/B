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
_59_ssa_slice_call_init__make_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    mov rdx, rbx
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
    lea rax, [rbp-3]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    mov rbx, 11
    mov byte [rax], bl
    lea rax, [rbp-3]
    mov rbx, 1
    mov rax, rax
    add rax, rbx
    mov rbx, 22
    mov byte [rax], bl
    lea rax, [rbp-3]
    mov rbx, 2
    mov rax, rax
    add rax, rbx
    mov rbx, 33
    mov byte [rax], bl
    lea rax, [rbp-19]
    mov rbx, 3
    lea rcx, [rbp-3]
    push rax
    push rbx
    push rcx
    call _59_ssa_slice_call_init__make_slice
    add rsp, 16
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-19]
    mov rax, [rax]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 11
    cmp rax, rbx
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
    lea rax, [rbp-19]
    mov rax, [rax]
    mov rbx, 2
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 33
    cmp rax, rbx
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
