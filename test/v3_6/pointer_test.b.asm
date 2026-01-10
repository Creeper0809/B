section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_address:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_deref_read:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 20
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_deref_write:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_double_ptr:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 40
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-24]
    mov rax, [rax]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
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
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    call test_address
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    call test_deref_read
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    call test_deref_write
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    call test_double_ptr
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
