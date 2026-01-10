section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_basic_cast:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 100
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L0:
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_pointer_cast:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 42
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
    mov rax, [rbp-16]
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
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_int_ptr_cast:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    mov rax, 111
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 222
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-32]
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
    push rax
    mov rax, 111
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L6:
    sub rsp, 8
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-48]
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-56]
    mov rax, [rax]
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-64]
    push rax
    mov rax, 222
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_cast_chain:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 50
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 30
    mov rsp, rbp
    pop rbp
    ret
.L10:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_expr_cast:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 20
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
.L12:
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 41
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 0
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
    call test_basic_cast
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L16:
    call test_pointer_cast
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L18:
    call test_int_ptr_cast
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L20:
    call test_cast_chain
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L22:
    call test_expr_cast
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L24:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
