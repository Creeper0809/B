section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_nested_loops:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L0:
    mov rax, [rbp-16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L1
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L2:
    mov rax, [rbp-24]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L3
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L2
.L3:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L0
.L1:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_nested_if:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, [rbp+32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .L9
.L8:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L9:
    jmp .L7
.L6:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L7:
    jmp .L5
.L4:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L5:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_complex_expr:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_ptr_chain:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 5
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
    lea rax, [rbp-24]
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
    sub rsp, 8
    mov rax, [rbp-40]
    mov rax, [rax]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-48]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
swap:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, [rbp+16]
    mov rax, [rax]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_swap:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-8]
    push rax
    call swap
    add rsp, 16
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
factorial:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L10:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call factorial
    add rsp, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_factorial:
    push rbp
    mov rbp, rsp
    mov rax, 5
    push rax
    call factorial
    add rsp, 8
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
fib:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call fib
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call fib
    add rsp, 8
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
test_fib:
    push rbp
    mov rbp, rsp
    mov rax, 10
    push rax
    call fib
    add rsp, 8
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
    call test_nested_loops
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    call test_nested_if
    add rsp, 24
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, 0
    push rax
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    call test_nested_if
    add rsp, 24
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, 1
    push rax
    mov rax, 0
    push rax
    mov rax, 1
    push rax
    call test_nested_if
    add rsp, 24
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    mov rax, 0
    push rax
    call test_nested_if
    add rsp, 24
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L22:
    call test_complex_expr
    push rax
    mov rax, 21
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L24:
    call test_ptr_chain
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L26
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L26:
    call test_swap
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L28:
    call test_factorial
    push rax
    mov rax, 120
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L30
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L30:
    call test_fib
    push rax
    mov rax, 55
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L32:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
