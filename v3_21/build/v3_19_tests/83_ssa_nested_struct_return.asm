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
_83_ssa_nested_struct_return__make_inner:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_83_ssa_nested_struct_return__make_outer:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rbx, rsi
    push rbx
    mov rdi, rax
    call _83_ssa_nested_struct_return__make_inner
    pop rbx
    push rax
    mov rdi, rbx
    call _83_ssa_nested_struct_return__make_inner
    mov rbx, rax
    pop rax
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
.Lssa_2_2:
    lea rax, [rbp-16]
    mov rbx, 40
    mov rdx, 30
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _83_ssa_nested_struct_return__make_outer
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
