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
_38_ssa_global_access__inc:
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
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar__38_ssa_global_access__g]
    lea rcx, [rel _gvar__38_ssa_global_access__g]
    mov rcx, [rcx]
    add rax, rcx
    mov [rbx], rax
    lea rax, [rel _gvar__38_ssa_global_access__g]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_38_ssa_global_access__bump_h:
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
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar__38_ssa_global_access__h]
    lea rcx, [rel _gvar__38_ssa_global_access__h]
    mov rcx, [rcx]
    add rax, rcx
    mov [rbx], rax
    lea rax, [rel _gvar__38_ssa_global_access__h]
    mov rax, [rax]
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
    lea rax, [rel _gvar__38_ssa_global_access__g]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rel _gvar__38_ssa_global_access__h]
    mov rbx, 1
    mov [rax], rbx
    mov rax, 5
    push rax
    pop rdi
    call _38_ssa_global_access__inc
    mov rbx, 5
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
    mov rax, 3
    push rax
    pop rdi
    call _38_ssa_global_access__inc
    mov rbx, 8
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_5
    jmp .Lssa_2_6
.Lssa_2_5:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_6
.Lssa_2_6:
    mov rax, 4
    push rax
    pop rdi
    call _38_ssa_global_access__bump_h
    mov rbx, 5
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_7
    jmp .Lssa_2_8
.Lssa_2_7:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_8
.Lssa_2_8:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar__38_ssa_global_access__g: resq 1
_gvar__38_ssa_global_access__h: resq 1
