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
_84_ssa_slice_return_direct__make_slice:
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
_84_ssa_slice_return_direct__get_first:
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
    mov rax, [rax]
    mov rax, rax
    add rax, 0
    movzx rax, byte [rax]
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
    lea rax, [rbp-3]
    mov rax, rax
    add rax, 0
    mov rbx, 42
    mov byte [rax], bl
    lea rax, [rbp-3]
    mov rax, rax
    add rax, 1
    mov rbx, 43
    mov byte [rax], bl
    lea rax, [rbp-3]
    mov rax, rax
    add rax, 2
    mov rbx, 44
    mov byte [rax], bl
    lea rax, [rbp-3]
    mov rbx, 3
    push rbx
    push rax
    pop rdi
    pop rsi
    call _84_ssa_slice_return_direct__make_slice
    push rax
    pop rdi
    call _84_ssa_slice_return_direct__get_first
    cmp rax, 42
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
