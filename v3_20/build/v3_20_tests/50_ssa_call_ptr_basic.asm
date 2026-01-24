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
_50_ssa_call_ptr_basic__add:
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_1_1:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rel _50_ssa_call_ptr_basic__add]
    mov rbx, 7
    mov rcx, 8
    push rcx
    push rbx
    pop rdi
    pop rsi
    call rax
    mov rbx, 15
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
    lea rax, [rel _gvar__50_ssa_call_ptr_basic__g]
    mov rbx, 9
    mov [rax], rbx
    lea rax, [rel _gvar__50_ssa_call_ptr_basic__g]
    mov rax, [rax]
    mov rbx, 9
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
    lea rax, [rel _50_ssa_call_ptr_basic__add]
    mov rbx, 1
    mov rcx, 2
    push rcx
    push rbx
    pop rdi
    pop rsi
    call rax
    mov rbx, 3
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_6
    jmp .Lssa_1_7
.Lssa_1_6:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_7
.Lssa_1_7:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar__50_ssa_call_ptr_basic__g: resq 1
