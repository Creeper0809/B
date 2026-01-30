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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 10
    mov [rbp-32], rax
    mov rax, 32
    mov [rbp-24], rax
    mov rax, [rbp-32]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-32]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    lea rax, [rbp-48]
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
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
    mov rax, 10
    mov [rbp-64], rax
    mov rax, 20
    mov [rbp-56], rax
    mov rax, [rbp-64]
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-64]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rax, 12
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-88]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-88]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
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
    mov rax, 5
    mov [rbp-104], rax
    mov rax, 10
    mov [rbp-96], rax
    mov rax, [rbp-104]
    push rax
    lea rax, [rbp-120]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-104]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rax, [rbp-120]
    push rax
    lea rax, [rbp-136]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-120]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rax, 20
    push rax
    lea rax, [rbp-136]
    pop rbx
    mov [rax], rbx
    mov rax, 22
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-104]
    mov rax, [rax]
    push rax
    lea rax, [rbp-96]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L4:
    lea rax, [rbp-136]
    mov rax, [rax]
    push rax
    lea rax, [rbp-128]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L6:
    mov rax, 5
    mov [rbp-176], rax
    mov rax, 10
    mov [rbp-168], rax
    mov rax, 7
    mov [rbp-160], rax
    mov rax, 15
    mov [rbp-152], rax
    mov rax, 5
    mov [rbp-144], rax
    mov rax, [rbp-176]
    push rax
    lea rax, [rbp-216]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-176]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rcx, [rax+16]
    mov [r8+16], rcx
    mov rcx, [rax+24]
    mov [r8+24], rcx
    mov rcx, [rax+32]
    mov [r8+32], rcx
    lea rax, [rbp-216]
    mov rax, [rax]
    push rax
    lea rax, [rbp-208]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-200]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-192]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-184]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, 10
    push rax
    lea rax, [rbp-240]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-240]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 12
    push rax
    lea rax, [rbp-224]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-240]
    push rax
    lea rax, [rbp-264]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-240]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rcx, [rax+16]
    mov [r8+16], rcx
    mov rax, 100
    push rax
    lea rax, [rbp-264]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 200
    push rax
    lea rax, [rbp-264]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 120
    push rax
    lea rax, [rbp-248]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-240]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-240]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-224]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L10:
    mov rax, 10
    mov [rbp-280], rax
    mov rax, 32
    mov [rbp-272], rax
    lea rax, [rbp-280]
    mov [rbp-304], rax
    lea rax, [rbp-296]
    mov [rbp-312], rax
    mov rax, [rbp-304]
    mov rax, [rax]
    push rax
    mov rax, [rbp-312]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    mov rax, [rbp-304]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    lea rax, [rbp-296]
    mov rax, [rax]
    push rax
    lea rax, [rbp-288]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, 21
    push rax
    lea rax, [rbp-320]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-320]
    push rax
    lea rax, [rbp-336]
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-328]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-336]
    mov rax, [rax]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-328]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 30
    push rax
    lea rax, [rbp-344]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-344]
    push rax
    lea rax, [rbp-360]
    pop rbx
    mov [rax], rbx
    mov rax, 12
    push rax
    lea rax, [rbp-352]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-360]
    push rax
    lea rax, [rbp-376]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-360]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    lea rax, [rbp-376]
    mov rax, [rax]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-368]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, 7
    push rax
    lea rax, [rbp-400]
    push rax
    pop rax
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 8
    push rax
    lea rax, [rbp-400]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-384]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-400]
    push rax
    lea rax, [rbp-424]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-400]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rcx, [rax+16]
    mov [r8+16], rcx
    mov rax, 100
    push rax
    lea rax, [rbp-424]
    push rax
    pop rax
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-400]
    push rax
    pop rax
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-400]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-384]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, 5
    mov [rbp-440], rax
    mov rax, 10
    mov [rbp-432], rax
    lea rax, [rbp-440]
    push rax
    lea rax, [rbp-448]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-448]
    push rax
    lea rax, [rbp-456]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-448]
    mov rcx, [rax]
    mov [r8], rcx
    mov rax, 20
    push rax
    lea rax, [rbp-456]
    mov rax, [rax]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 22
    push rax
    lea rax, [rbp-456]
    mov rax, [rax]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-440]
    mov rax, [rax]
    push rax
    lea rax, [rbp-432]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 5
    mov [rbp-464], rax
    mov rax, 10
    mov [rbp-472], rax
    mov rax, [rbp-464]
    push rax
    lea rax, [rbp-496]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-464]
    mov rcx, [rax]
    mov [r8], rcx
    lea rax, [rbp-472]
    push rax
    lea rax, [rbp-488]
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-480]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-496]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-480]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-488]
    mov rax, [rax]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-480]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-504], rax
    mov rax, [rbp-504]
    push rax
    mov rax, 12
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
