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
test_ma__get_vec:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
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
    ; ERROR: Member access on non-identif    push rax
    ; ERROR: Member access on non-identif    mov rbx, rax
    pop rax
