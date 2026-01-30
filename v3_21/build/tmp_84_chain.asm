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
_84_ssa_slice_return_chain__get_slice:
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
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 0
    mov rbx, 1
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov rbx, 2
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rbx, 2
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_84_ssa_slice_return_chain__pass_slice:
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
    lea rax, [rbp-16]
    mov rbx, [rbp-1032]
    mov [rax], rbx
    mov rbx, [rbp-1040]
    mov rax, rax
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_2:
    lea rax, [rbp-16]
    push rax
    call _84_ssa_slice_return_chain__get_slice
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-32]
    lea rbx, [rbp-16]
    mov rcx, [rbx]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    call _84_ssa_slice_return_chain__pass_slice
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-32]
    mov rax, [rax]
    mov rax, rax
    add rax, 0
    mov rax, [rax]
    lea rbx, [rbp-32]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-32]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 0
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-32]
    mov rbx, [rbx]
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
