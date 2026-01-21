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
_07_switch_statement__get_value:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_33_33:
    mov rax, rdi
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_34
    jmp .Lssa_33_35
.Lssa_33_34:
    mov rbx, 10
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_35
.Lssa_33_35:
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_36
    jmp .Lssa_33_37
.Lssa_33_36:
    mov rbx, 20
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_37
.Lssa_33_37:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_38
    jmp .Lssa_33_39
.Lssa_33_38:
    mov rbx, 30
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_39
.Lssa_33_39:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_33_40
    jmp .Lssa_33_41
.Lssa_33_40:
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_41
.Lssa_33_41:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_int:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_34_42:
    mov rax, rdi
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_44
    jmp .Lssa_34_48
.Lssa_34_43:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_44:
    mov rax, 100
    jmp .Lssa_34_43
.Lssa_34_45:
    mov rax, 200
    jmp .Lssa_34_43
.Lssa_34_46:
    mov rax, 300
    jmp .Lssa_34_43
.Lssa_34_47:
    mov rax, 999
    jmp .Lssa_34_43
.Lssa_34_48:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_45
    jmp .Lssa_34_49
.Lssa_34_49:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_46
    jmp .Lssa_34_50
.Lssa_34_50:
    jmp .Lssa_34_47
.Lssa_34_51:
.Lssa_34_52:
.Lssa_34_53:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_enum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_35_54:
    mov rax, rdi
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_56
    jmp .Lssa_35_61
.Lssa_35_55:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_35_56:
    mov rax, 1000
    jmp .Lssa_35_55
.Lssa_35_57:
    mov rax, 2000
    jmp .Lssa_35_55
.Lssa_35_58:
    mov rax, 3000
    jmp .Lssa_35_55
.Lssa_35_59:
    mov rax, 4000
    jmp .Lssa_35_55
.Lssa_35_60:
    mov rax, 9999
    jmp .Lssa_35_55
.Lssa_35_61:
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_57
    jmp .Lssa_35_62
.Lssa_35_62:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_58
    jmp .Lssa_35_63
.Lssa_35_63:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_59
    jmp .Lssa_35_64
.Lssa_35_64:
    jmp .Lssa_35_60
.Lssa_35_65:
.Lssa_35_66:
.Lssa_35_67:
.Lssa_35_68:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_default_only:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_36_69:
    mov rax, rdi
    jmp .Lssa_36_71
.Lssa_36_70:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_36_71:
    mov rax, 777
    jmp .Lssa_36_70
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_nested:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_37_72:
    mov rax, rdi
    mov rbx, rsi
    cmp rax, 1
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_37_74
    jmp .Lssa_37_76
.Lssa_37_73:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_37_74:
    cmp rbx, 2
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_37_78
    jmp .Lssa_37_80
.Lssa_37_75:
    mov rax, 99
    jmp .Lssa_37_73
.Lssa_37_76:
    jmp .Lssa_37_75
.Lssa_37_77:
    jmp .Lssa_37_73
.Lssa_37_78:
    mov rax, 12
    jmp .Lssa_37_77
.Lssa_37_79:
    mov rax, 10
    jmp .Lssa_37_77
.Lssa_37_80:
    jmp .Lssa_37_79
.Lssa_37_81:
.Lssa_37_82:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_string:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_38_83:
    mov rax, rdi
    lea rbx, [rel _str0]
    push rax
    cmp rax, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_38_85
    jmp .Lssa_38_89
.Lssa_38_84:
.Lssa_38_85:
    mov rax, 100
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_86:
    mov rax, 200
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_87:
    mov rax, 300
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_88:
    mov rax, 999
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_89:
    lea rbx, [rel _str1]
    push rax
    cmp rax, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_38_86
    jmp .Lssa_38_90
.Lssa_38_90:
    lea rbx, [rel _str2]
    cmp rax, rbx
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_38_87
    jmp .Lssa_38_91
.Lssa_38_91:
    jmp .Lssa_38_88
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_39_92:
    mov rax, rdi
    mov rax, rsi
    mov rax, 0
    cmp rax, 0
    jne .Lssa_39_93
    jmp .Lssa_39_94
.Lssa_39_93:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_94
.Lssa_39_94:
    mov rax, 0
    mov rdi, rax
    call _07_switch_statement__get_value
    mov rbx, 1
    push rax
    mov rdi, rbx
    call _07_switch_statement__get_value
    mov rbx, rax
    pop rax
    mov rcx, 2
    push rax
    push rbx
    mov rdi, rcx
    call _07_switch_statement__get_value
    mov rcx, rax
    pop rbx
    pop rax
    mov rdx, 3
    push rax
    push rbx
    push rcx
    mov rdi, rdx
    call _07_switch_statement__get_value
    mov rdx, rax
    pop rcx
    pop rbx
    pop rax
    mov rax, rax
    add rax, rbx
    mov rax, rax
    add rax, rcx
    mov rax, rax
    add rax, rdx
    mov rax, rax
    sub rax, 58
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_95
    jmp .Lssa_39_96
.Lssa_39_95:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_96
.Lssa_39_96:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_39_97
    jmp .Lssa_39_98
.Lssa_39_97:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_98
.Lssa_39_98:
    mov rax, 2
    mov rdi, rax
    call _07_switch_statement__test_switch_int
    cmp rax, 200
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_99
    jmp .Lssa_39_100
.Lssa_39_99:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_100
.Lssa_39_100:
    mov rax, 1
    mov rdi, rax
    call _07_switch_statement__test_switch_int
    cmp rax, 100
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_101
    jmp .Lssa_39_102
.Lssa_39_101:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_102
.Lssa_39_102:
    mov rax, 99
    mov rdi, rax
    call _07_switch_statement__test_switch_int
    cmp rax, 999
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_103
    jmp .Lssa_39_104
.Lssa_39_103:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_104
.Lssa_39_104:
    mov rax, 1
    mov rdi, rax
    call _07_switch_statement__test_switch_enum
    cmp rax, 2000
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_105
    jmp .Lssa_39_106
.Lssa_39_105:
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_106
.Lssa_39_106:
    mov rax, 0
    mov rdi, rax
    call _07_switch_statement__test_switch_enum
    cmp rax, 1000
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_107
    jmp .Lssa_39_108
.Lssa_39_107:
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_108
.Lssa_39_108:
    mov rax, 123
    mov rdi, rax
    call _07_switch_statement__test_switch_default_only
    cmp rax, 777
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_109
    jmp .Lssa_39_110
.Lssa_39_109:
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_110
.Lssa_39_110:
    mov rax, 2
    mov rbx, 1
    mov rdi, rax
    mov rsi, rbx
    call _07_switch_statement__test_switch_nested
    cmp rax, 12
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_111
    jmp .Lssa_39_112
.Lssa_39_111:
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_112
.Lssa_39_112:
    lea rax, [rel _str1]
    mov rdi, rax
    call _07_switch_statement__test_switch_string
    cmp rax, 200
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_113
    jmp .Lssa_39_114
.Lssa_39_113:
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_114
.Lssa_39_114:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 102,111,111,0
_str1: db 98,97,114,0
_str2: db 98,97,122,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
