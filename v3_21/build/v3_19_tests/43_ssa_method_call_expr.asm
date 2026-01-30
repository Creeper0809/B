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
_43_ssa_method_call_expr__Pair_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    mov rcx, rdx
    mov [rax], rbx
    mov rbx, 8
    mov rax, rax
    add rax, rbx
    mov [rax], rcx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_43_ssa_method_call_expr__Pair_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rbx, [rax]
    mov rcx, 8
    mov rax, rax
    add rax, rcx
    mov rax, [rax]
    add rax, rbx
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
.Lssa_2_2:
    mov rax, rdi
    mov rax, rsi
    mov rax, 20
    mov rbx, 10
    lea rcx, [rbp-16]
    mov rdi, rax
    mov rsi, rbx
    mov rdx, rcx
    call _43_ssa_method_call_expr__Pair_init
    lea rax, [rbp-16]
    mov rdi, rax
    call _43_ssa_method_call_expr__Pair_sum
    mov rbx, 30
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_3
    jmp .Lssa_2_4
.Lssa_2_3:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_4
.Lssa_2_4:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
