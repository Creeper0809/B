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
_81_ssa_struct_return_direct__make_point:
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
_81_ssa_struct_return_direct__add_points:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    lea rax, [rbp-16]
    mov rbx, rdi
    mov rcx, rsi
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-32]
    mov rbx, rdx
    mov rcx, rcx
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-32]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    lea rcx, [rbp-32]
    mov rcx, rcx
    add rcx, 8
    mov rcx, [rcx]
    mov rbx, rbx
    add rbx, rcx
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
    mov rbx, 10
    mov rdx, 20
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _81_ssa_struct_return_direct__make_point
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov rdx, 30
    mov r9, 30
    push rax
    push rbx
    push rcx
    mov rdi, rdx
    mov rsi, r9
    call _81_ssa_struct_return_direct__make_point
    mov rdx, rax
    mov r8, rdx
    pop rcx
    pop rbx
    pop rax
    push rax
    mov rdi, rbx
    mov rsi, rcx
    mov rdx, rdx
    mov rcx, r8
    call _81_ssa_struct_return_direct__add_points
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
