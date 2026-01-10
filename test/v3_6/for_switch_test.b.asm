section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_for_basic:
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
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L1
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
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
test_for_with_decl:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
.L2:
    mov rax, [rbp-16]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L3
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
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
    jmp .L2
.L3:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_for_no_init:
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
.L4:
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L5
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
    jmp .L4
.L5:
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_for_no_cond:
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
.L6:
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
    mov rax, [rbp-16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L8:
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
    jmp .L6
.L7:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_for_no_update:
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
.L10:
    mov rax, [rbp-16]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L11
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
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
    jmp .L10
.L11:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_for_nested:
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
.L12:
    mov rax, [rbp-16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L13
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L14:
    mov rax, [rbp-24]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L15
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
    jmp .L14
.L15:
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
    jmp .L12
.L13:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
get_name:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, [rsp]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L17
    mov rax, 100
    mov rsp, rbp
    pop rbp
    ret
    jmp .L16
.L17:
    mov rax, [rsp]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L18
    mov rax, 200
    mov rsp, rbp
    pop rbp
    ret
    jmp .L16
.L18:
    mov rax, [rsp]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L19
    mov rax, 300
    mov rsp, rbp
    pop rbp
    ret
    jmp .L16
.L19:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    add rsp, 8
.L16:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_switch_basic:
    push rbp
    mov rbp, rsp
    mov rax, 0
    push rax
    call get_name
    add rsp, 8
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 1
    push rax
    call get_name
    add rsp, 8
    push rax
    mov rax, 200
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, 2
    push rax
    call get_name
    add rsp, 8
    push rax
    mov rax, 300
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L24:
    mov rax, 5
    push rax
    call get_name
    add rsp, 8
    push rax
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L26
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L26:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
calc_score:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    mov rax, [rsp]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L29
    mov rax, 90
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L28
.L29:
    mov rax, [rsp]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L30
    mov rax, 80
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L28
.L30:
    mov rax, [rsp]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L31
    mov rax, 70
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L28
.L31:
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    add rsp, 8
.L28:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_switch_multi_stmt:
    push rbp
    mov rbp, rsp
    mov rax, 1
    push rax
    call calc_score
    add rsp, 8
    push rax
    mov rax, 100
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
    mov rax, 2
    push rax
    call calc_score
    add rsp, 8
    push rax
    mov rax, 85
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L34
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L34:
    mov rax, 3
    push rax
    call calc_score
    add rsp, 8
    push rax
    mov rax, 70
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L36
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L36:
    mov rax, 9
    push rax
    call calc_score
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L38
    mov rax, 13
    mov rsp, rbp
    pop rbp
    ret
.L38:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
classify:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, [rbp+16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rsp]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L41
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .L40
.L41:
    mov rax, [rsp]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L42
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .L40
.L42:
    mov rax, [rsp]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L43
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .L40
.L43:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    add rsp, 8
.L40:
    mov rax, 0
    push rax
    mov rax, 1
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
test_switch_expr:
    push rbp
    mov rbp, rsp
    mov rax, 5
    push rax
    call classify
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L44:
    mov rax, 15
    push rax
    call classify
    add rsp, 8
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L46
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
.L46:
    mov rax, 25
    push rax
    call classify
    add rsp, 8
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L48
    mov rax, 22
    mov rsp, rbp
    pop rbp
    ret
.L48:
    mov rax, 100
    push rax
    call classify
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, 23
    mov rsp, rbp
    pop rbp
    ret
.L50:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_for_switch_combo:
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
.L52:
    mov rax, [rbp-16]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L53
    mov rax, [rbp-16]
    push rax
    mov rax, [rsp]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L55
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
    jmp .L54
.L55:
    mov rax, [rsp]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L56
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L54
.L56:
    mov rax, [rsp]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L57
    mov rax, [rbp-8]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L54
.L57:
    mov rax, [rsp]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L58
    mov rax, [rbp-8]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L54
.L58:
    mov rax, [rsp]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    jne .L59
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L54
.L59:
    add rsp, 8
.L54:
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
    jmp .L52
.L53:
    mov rax, [rbp-8]
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
    call test_for_basic
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 45
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L60:
    call test_for_with_decl
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 100
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
.L62:
    call test_for_no_init
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L64
    mov rax, 200
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
.L64:
    call test_for_no_cond
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L66:
    call test_for_no_update
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L68:
    call test_for_nested
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L70:
    call test_switch_basic
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
    jz .L72
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L72:
    call test_switch_multi_stmt
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
    jz .L74
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L74:
    call test_switch_expr
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
    jz .L76
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L76:
    call test_for_switch_combo
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L78
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L78:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
