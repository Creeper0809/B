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
_83_ssa_slice_return_basic__get_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 3
    mov r12, rax
    mov r8, rax
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
    lea rax, [rbp-24]
    mov rsi, rax
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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    call _83_ssa_slice_return_basic__get_slice
    mov [rbp-16], rax
    mov [rbp-8], rdx
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
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

section .bss
_gvar___cg_heap_brk: resq 1
