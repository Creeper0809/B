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
_60_ssa_method_call_ptr_liveness__Counter_init:
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
    mov [rbx], rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_60_ssa_method_call_ptr_liveness__Counter_add:
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
    mov rbx, [rbp-1032]
    mov rcx, [rbx]
    add rax, rcx
    mov [rbx], rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_60_ssa_method_call_ptr_liveness__Counter_get:
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
    mov rax, [rbp-1032]
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
.Lssa_3_3:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rbp-8]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call _60_ssa_method_call_ptr_liveness__Counter_init
    lea rax, [rbp-8]
    push rax
    push rax
    pop rdi
    call _60_ssa_method_call_ptr_liveness__Counter_get
    mov rbx, rax
    pop rax
    mov rcx, 1
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_3_4
    jmp .Lssa_3_5
.Lssa_3_4:
    mov rbx, 1
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_3_5
.Lssa_3_5:
    mov rbx, 2
    push rax
    push rbx
    push rax
    pop rdi
    pop rsi
    call _60_ssa_method_call_ptr_liveness__Counter_add
    pop rax
    push rax
    push rax
    pop rdi
    call _60_ssa_method_call_ptr_liveness__Counter_get
    mov rbx, rax
    pop rax
    mov rcx, 3
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_3_6
    jmp .Lssa_3_7
.Lssa_3_6:
    mov rbx, 2
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_3_7
.Lssa_3_7:
    mov rbx, 4
    push rax
    push rbx
    push rax
    pop rdi
    pop rsi
    call _60_ssa_method_call_ptr_liveness__Counter_add
    pop rax
    push rax
    pop rdi
    call _60_ssa_method_call_ptr_liveness__Counter_get
    mov rbx, 7
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_3_8
    jmp .Lssa_3_9
.Lssa_3_8:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_3_9
.Lssa_3_9:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
