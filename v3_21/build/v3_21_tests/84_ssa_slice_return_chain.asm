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
    mov r12, 2
    mov r8, 2
    mov r13, rax
    mov rax, 8
    imul r8, rax
    mov rax, [_gvar___cg_heap_brk]
    cmp rax, 0
    jne .L0
    mov rax, 12
    xor rdi, rdi
    syscall
    mov [_gvar___cg_heap_brk], rax
.L0:
    mov rbx, [_gvar___cg_heap_brk]
    mov rdi, rbx
    add rdi, r8
    mov rax, 12
    syscall
    cmp rax, rdi
    jb .L2
    mov [_gvar___cg_heap_brk], rax
    jmp .L1
.L2:
    xor rbx, rbx
.L1:
    mov rdx, r12
    mov rsi, r13
    mov rdi, rbx
    xor r9, r9
.L3:
    cmp r9, r8
    jge .L4
    mov r10b, [rsi+r9]
    mov [rdi+r9], r10b
    add r9, 1
    jmp .L3
.L4:
    mov rax, rbx
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

section .bss
_gvar___cg_heap_brk: resq 1
