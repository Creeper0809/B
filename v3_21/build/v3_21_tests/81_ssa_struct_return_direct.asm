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
_81_ssa_struct_return_direct__add_points:
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
    lea rax, [rbp-32]
    mov rbx, [rbp-1048]
    mov rcx, [rbp-1056]
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rbx, [rbp-1032]
    mov rcx, [rbp-1040]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_2:
    lea rax, [rbp-16]
    mov rbx, 10
    mov rdx, 20
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _81_ssa_struct_return_direct__make_point
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov rdx, 30
    mov r9, 30
    push rax
    push rbx
    push rcx
    push r9
    push rdx
    pop rdi
    pop rsi
    call _81_ssa_struct_return_direct__make_point
    mov rdx, rax
    mov r8, rdx
    pop rcx
    pop rbx
    pop rax
    push rax
    push r8
    push rdx
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    pop rcx
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
