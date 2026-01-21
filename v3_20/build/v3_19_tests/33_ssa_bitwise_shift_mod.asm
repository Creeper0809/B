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
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rax, rsi
    mov rax, 42
    mov rbx, 5
    push rax
    push rdx
    mov rax, rax
    cqo
    idiv rbx
    mov rbx, rdx
    pop rdx
    pop rax
    mov rcx, 7
    and rcx, rax
    mov rdx, 2
    push rax
    mov rax, rcx
    mov rcx, rdx
    shl rax, cl
    mov rcx, rax
    pop rax
    mov rbx, rbx
    add rbx, rcx
    mov rcx, 3
    or rcx, rax
    mov rdx, 1
    mov rcx, rcx
    xor rcx, rdx
    mov rbx, rbx
    add rbx, rcx
    mov rcx, 1
    push rcx
    mov rax, rax
    mov rcx, rcx
    shr rax, cl
    pop rcx
    add rax, rbx
    mov rbx, 73
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
