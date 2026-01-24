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
_41_ssa_method_call_basic__Counter_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rsi
    mov rbx, rdi
    mov [rbx], rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_41_ssa_method_call_basic__Counter_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rsi
    mov rbx, rdi
    mov rcx, [rbx]
    add rax, rcx
    mov [rbx], rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_41_ssa_method_call_basic__Counter_get:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_2_2:
    mov rax, rdi
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
    sub rsp, 1024
.Lssa_3_3:
    mov rax, rsi
    mov rax, rdi
    lea rax, [rbp-8]
    mov rbx, 3
    mov rdi, rax
    mov rsi, rbx
    call _41_ssa_method_call_basic__Counter_init
    lea rax, [rbp-8]
    mov rbx, 4
    mov rdi, rax
    mov rsi, rbx
    call _41_ssa_method_call_basic__Counter_add
    lea rax, [rbp-8]
    mov rdi, rax
    call _41_ssa_method_call_basic__Counter_get
    mov rbx, 7
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_3_4
    jmp .Lssa_3_5
.Lssa_3_4:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_3_5
.Lssa_3_5:
    lea rax, [rbp-8]
    mov rbx, 5
    mov rdi, rax
    mov rsi, rbx
    call _41_ssa_method_call_basic__Counter_add
    lea rax, [rbp-8]
    mov rdi, rax
    call _41_ssa_method_call_basic__Counter_get
    mov rbx, 12
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_3_6
    jmp .Lssa_3_7
.Lssa_3_6:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_3_7
.Lssa_3_7:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
