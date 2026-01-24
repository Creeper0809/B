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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    mov rax, 10
    mov rbx, 5
    mov rcx, 0
    cmp rcx, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rcx, 1
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rcx, rax
    sub rcx, rbx
    push rax
    cmp rcx, 5
    setne al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_0_3
    jmp .Lssa_0_4
.Lssa_0_3:
    mov rcx, 2
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_4
.Lssa_0_4:
    mov rcx, rax
    imul rcx, rbx
    push rax
    cmp rcx, 50
    setne al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_0_5
    jmp .Lssa_0_6
.Lssa_0_5:
    mov rcx, 3
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_6
.Lssa_0_6:
    push rax
    push rdx
    mov rax, rax
    cqo
    idiv rbx
    mov rcx, rax
    pop rdx
    pop rax
    push rax
    cmp rcx, 2
    setne al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_0_7
    jmp .Lssa_0_8
.Lssa_0_7:
    mov rcx, 4
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_8
.Lssa_0_8:
    push rdx
    mov rax, rax
    cqo
    idiv rbx
    mov rax, rdx
    pop rdx
    cmp rax, 0
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_9
    jmp .Lssa_0_10
.Lssa_0_9:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_10
.Lssa_0_10:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_11
    jmp .Lssa_0_12
.Lssa_0_11:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_12
.Lssa_0_12:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_13
    jmp .Lssa_0_14
.Lssa_0_13:
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_14
.Lssa_0_14:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_15
    jmp .Lssa_0_16
.Lssa_0_15:
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_16
.Lssa_0_16:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_17
    jmp .Lssa_0_18
.Lssa_0_17:
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_18
.Lssa_0_18:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_19
    jmp .Lssa_0_20
.Lssa_0_19:
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_20
.Lssa_0_20:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_21
    jmp .Lssa_0_22
.Lssa_0_21:
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_22
.Lssa_0_22:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_23
    jmp .Lssa_0_24
.Lssa_0_23:
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_24
.Lssa_0_24:
    mov rax, 8
    mov rbx, 0
    cmp rbx, 0
    jne .Lssa_0_25
    jmp .Lssa_0_26
.Lssa_0_25:
    mov rbx, 13
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_26
.Lssa_0_26:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_27
    jmp .Lssa_0_28
.Lssa_0_27:
    mov rax, 14
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_28
.Lssa_0_28:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_29
    jmp .Lssa_0_30
.Lssa_0_29:
    mov rax, 15
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_30
.Lssa_0_30:
    mov rax, 5
    mov rbx, 10
    mov rcx, 3
    mov rdx, 0
    cmp rdx, 0
    jne .Lssa_0_31
    jmp .Lssa_0_32
.Lssa_0_31:
    mov rdx, 16
    mov rax, rdx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_32
.Lssa_0_32:
    mov rdx, rbx
    imul rdx, rcx
    add rdx, rax
    push rax
    cmp rdx, 35
    setne al
    movzx rdx, al
    pop rax
    cmp rdx, 0
    jne .Lssa_0_33
    jmp .Lssa_0_34
.Lssa_0_33:
    mov rdx, 17
    mov rax, rdx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_34
.Lssa_0_34:
    mov rdx, rax
    add rdx, rbx
    mov r8, rcx
    sub r8, 1
    push rax
    mov rax, rdx
    cqo
    idiv r8
    mov rdx, rax
    pop rax
    push rax
    cmp rdx, 7
    setne al
    movzx rdx, al
    pop rax
    cmp rdx, 0
    jne .Lssa_0_35
    jmp .Lssa_0_36
.Lssa_0_35:
    mov rdx, 18
    mov rax, rdx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_36
.Lssa_0_36:
    add rbx, rax
    mov rbx, rbx
    imul rbx, rcx
    mov rcx, rcx
    add rcx, 1
    push rax
    push rdx
    mov rax, rbx
    cqo
    idiv rcx
    mov rbx, rax
    pop rdx
    pop rax
    add rax, rbx
    cmp rax, 16
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_37
    jmp .Lssa_0_38
.Lssa_0_37:
    mov rax, 19
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_38
.Lssa_0_38:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_39
    jmp .Lssa_0_40
.Lssa_0_39:
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_40
.Lssa_0_40:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_41
    jmp .Lssa_0_42
.Lssa_0_41:
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_42
.Lssa_0_42:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_43
    jmp .Lssa_0_44
.Lssa_0_43:
    mov rax, 22
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_44
.Lssa_0_44:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_45
    jmp .Lssa_0_46
.Lssa_0_45:
    mov rax, 23
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_46
.Lssa_0_46:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_47
    jmp .Lssa_0_48
.Lssa_0_47:
    mov rax, 24
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_48
.Lssa_0_48:
    mov rax, 11
    mov rbx, 0
    cmp rbx, 0
    jne .Lssa_0_49
    jmp .Lssa_0_50
.Lssa_0_49:
    mov rbx, 25
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_50
.Lssa_0_50:
    mov rax, rax
    sub rax, 1
    cmp rax, 10
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_51
    jmp .Lssa_0_52
.Lssa_0_51:
    mov rax, 26
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_52
.Lssa_0_52:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_0_53
    jmp .Lssa_0_54
.Lssa_0_53:
    mov rax, 27
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_54
.Lssa_0_54:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
