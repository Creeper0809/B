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
_81_ssa_struct_return_chain__make_point:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_81_ssa_struct_return_chain__pass_through:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    lea rax, [rbp-8]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
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
    mov rax, 22
    push rax
    mov rax, 20
    push rax
    pop rdi
    pop rsi
    call _81_ssa_struct_return_chain__make_point
    mov [rbp-16], rax
    mov [rbp-8], rdx
    mov rax, [rbp-16]
    push rax
    pop rdi
    call _81_ssa_struct_return_chain__pass_through
    mov [rbp-32], rax
    mov [rbp-24], rdx
    lea rax, [rbp-32]
    mov rax, [rax]
    push rax
    lea rax, [rbp-24]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
