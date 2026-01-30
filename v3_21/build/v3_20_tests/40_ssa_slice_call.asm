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
_40_ssa_slice_call__first_byte:
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
    mov rbx, [rbp-1032]
    mov [rax], rbx
    mov rbx, [rbp-1040]
    mov rcx, 8
    mov rax, rax
    add rax, rcx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_40_ssa_slice_call__last_byte:
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
    mov rax, [rbp-1048]
    lea rbx, [rbp-16]
    mov rcx, [rbp-1032]
    mov [rbx], rcx
    mov rcx, [rbp-1040]
    mov rdx, 8
    mov rbx, rbx
    add rbx, rdx
    mov [rbx], rcx
    lea rbx, [rbp-16]
    mov rbx, [rbx]
    mov rcx, 1
    mov rax, rax
    sub rax, rcx
    add rax, rbx
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
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rel _str0]
    mov rbx, 3
    push rbx
    push rax
    pop rdi
    pop rsi
    call _40_ssa_slice_call__first_byte
    mov rbx, 65
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
    lea rax, [rel _str1]
    mov rbx, 3
    mov rcx, 3
    push rcx
    push rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _40_ssa_slice_call__last_byte
    mov rbx, 90
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_5
    jmp .Lssa_2_6
.Lssa_2_5:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_6
.Lssa_2_6:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 65,66,67,0
_str1: db 88,89,90,0
