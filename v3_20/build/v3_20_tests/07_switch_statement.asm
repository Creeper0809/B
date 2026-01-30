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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_33_77:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_78
    jmp .Lssa_33_79
.Lssa_33_78:
    mov rbx, 10
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_79
.Lssa_33_79:
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_80
    jmp .Lssa_33_81
.Lssa_33_80:
    mov rbx, 20
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_81
.Lssa_33_81:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_82
    jmp .Lssa_33_83
.Lssa_33_82:
    mov rbx, 30
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_83
.Lssa_33_83:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_33_84
    jmp .Lssa_33_85
.Lssa_33_84:
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_85
.Lssa_33_85:
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_34_86:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_88
    jmp .Lssa_34_92
.Lssa_34_87:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_88:
    mov rax, 100
    jmp .Lssa_34_87
.Lssa_34_89:
    mov rax, 200
    jmp .Lssa_34_87
.Lssa_34_90:
    mov rax, 300
    jmp .Lssa_34_87
.Lssa_34_91:
    mov rax, 999
    jmp .Lssa_34_87
.Lssa_34_92:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_89
    jmp .Lssa_34_93
.Lssa_34_93:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_90
    jmp .Lssa_34_94
.Lssa_34_94:
    jmp .Lssa_34_91
.Lssa_34_95:
.Lssa_34_96:
.Lssa_34_97:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_enum:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_35_98:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_100
    jmp .Lssa_35_105
.Lssa_35_99:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_35_100:
    mov rax, 1000
    jmp .Lssa_35_99
.Lssa_35_101:
    mov rax, 2000
    jmp .Lssa_35_99
.Lssa_35_102:
    mov rax, 3000
    jmp .Lssa_35_99
.Lssa_35_103:
    mov rax, 4000
    jmp .Lssa_35_99
.Lssa_35_104:
    mov rax, 9999
    jmp .Lssa_35_99
.Lssa_35_105:
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_101
    jmp .Lssa_35_106
.Lssa_35_106:
    push rax
    cmp rax, 2
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_35_102
    jmp .Lssa_35_107
.Lssa_35_107:
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_103
    jmp .Lssa_35_108
.Lssa_35_108:
    jmp .Lssa_35_104
.Lssa_35_109:
.Lssa_35_110:
.Lssa_35_111:
.Lssa_35_112:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_default_only:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_36_113:
    mov rax, [rbp-1032]
    jmp .Lssa_36_115
.Lssa_36_114:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_36_115:
    mov rax, 777
    jmp .Lssa_36_114
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_nested:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_37_116:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    cmp rbx, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_37_118
    jmp .Lssa_37_120
.Lssa_37_117:
    mov rsp, rbp
    pop rbp
    ret
.Lssa_37_118:
    cmp rax, 2
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_37_122
    jmp .Lssa_37_124
.Lssa_37_119:
    mov rax, 99
    jmp .Lssa_37_117
.Lssa_37_120:
    jmp .Lssa_37_119
.Lssa_37_121:
    jmp .Lssa_37_117
.Lssa_37_122:
    mov rax, 12
    jmp .Lssa_37_121
.Lssa_37_123:
    mov rax, 10
    jmp .Lssa_37_121
.Lssa_37_124:
    jmp .Lssa_37_123
.Lssa_37_125:
.Lssa_37_126:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_07_switch_statement__test_switch_string:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_38_127:
    mov rax, [rbp-1032]
    lea rbx, [rel _str0]
    push rax
    cmp rax, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_38_129
    jmp .Lssa_38_133
.Lssa_38_128:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_129:
    mov rax, 100
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_130:
    mov rax, 200
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_131:
    mov rax, 300
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_132:
    mov rax, 999
    mov rsp, rbp
    pop rbp
    ret
.Lssa_38_133:
    lea rbx, [rel _str1]
    push rax
    cmp rax, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_38_130
    jmp .Lssa_38_134
.Lssa_38_134:
    lea rbx, [rel _str2]
    cmp rax, rbx
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_38_131
    jmp .Lssa_38_135
.Lssa_38_135:
    jmp .Lssa_38_132
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
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
.Lssa_39_136:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    mov rax, 0
    cmp rax, 0
    jne .Lssa_39_137
    jmp .Lssa_39_138
.Lssa_39_137:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_138
.Lssa_39_138:
    mov rax, 0
    push rax
    pop rdi
    call _07_switch_statement__get_value
    mov rbx, 1
    push rax
    push rbx
    pop rdi
    call _07_switch_statement__get_value
    mov rbx, rax
    pop rax
    mov rcx, 2
    push rax
    push rbx
    push rcx
    pop rdi
    call _07_switch_statement__get_value
    mov rcx, rax
    pop rbx
    pop rax
    mov rdx, 3
    push rax
    push rbx
    push rcx
    push rdx
    pop rdi
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
    jne .Lssa_39_139
    jmp .Lssa_39_140
.Lssa_39_139:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_140
.Lssa_39_140:
    mov rax, 0
    cmp rax, 0
    jne .Lssa_39_141
    jmp .Lssa_39_142
.Lssa_39_141:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_142
.Lssa_39_142:
    mov rax, 2
    push rax
    pop rdi
    call _07_switch_statement__test_switch_int
    cmp rax, 200
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_143
    jmp .Lssa_39_144
.Lssa_39_143:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_144
.Lssa_39_144:
    mov rax, 1
    push rax
    pop rdi
    call _07_switch_statement__test_switch_int
    cmp rax, 100
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_145
    jmp .Lssa_39_146
.Lssa_39_145:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_146
.Lssa_39_146:
    mov rax, 99
    push rax
    pop rdi
    call _07_switch_statement__test_switch_int
    cmp rax, 999
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_147
    jmp .Lssa_39_148
.Lssa_39_147:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_148
.Lssa_39_148:
    mov rax, 1
    push rax
    pop rdi
    call _07_switch_statement__test_switch_enum
    cmp rax, 2000
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_149
    jmp .Lssa_39_150
.Lssa_39_149:
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_150
.Lssa_39_150:
    mov rax, 0
    push rax
    pop rdi
    call _07_switch_statement__test_switch_enum
    cmp rax, 1000
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_151
    jmp .Lssa_39_152
.Lssa_39_151:
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_152
.Lssa_39_152:
    mov rax, 123
    push rax
    pop rdi
    call _07_switch_statement__test_switch_default_only
    cmp rax, 777
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_153
    jmp .Lssa_39_154
.Lssa_39_153:
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_154
.Lssa_39_154:
    mov rax, 1
    mov rbx, 2
    push rbx
    push rax
    pop rdi
    pop rsi
    call _07_switch_statement__test_switch_nested
    cmp rax, 12
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_155
    jmp .Lssa_39_156
.Lssa_39_155:
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_156
.Lssa_39_156:
    lea rax, [rel _str1]
    push rax
    pop rdi
    call _07_switch_statement__test_switch_string
    cmp rax, 200
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_39_157
    jmp .Lssa_39_158
.Lssa_39_157:
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_39_158
.Lssa_39_158:
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
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
