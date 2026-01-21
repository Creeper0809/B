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
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_60_ssa_method_call_ptr_liveness__Counter_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rbx, rsi
    mov rcx, [rax]
    add rbx, rcx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_60_ssa_method_call_ptr_liveness__Counter_get:
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
    mov rax, rdi
    mov rax, rsi
    mov rax, 1
    lea rbx, [rbp-8]
    mov rdi, rax
    mov rsi, rbx
    call _60_ssa_method_call_ptr_liveness__Counter_init
    lea rax, [rbp-8]
    push rax
    mov rdi, rax
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
    mov rdi, rbx
    mov rsi, rax
    call _60_ssa_method_call_ptr_liveness__Counter_add
    pop rax
    push rax
    mov rdi, rax
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
    mov rdi, rbx
    mov rsi, rax
    call _60_ssa_method_call_ptr_liveness__Counter_add
    pop rax
    mov rdi, rax
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
