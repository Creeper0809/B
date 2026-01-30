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
std_os__os_sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_5_5:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_6_6:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_24_24:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_30_30:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_31_31:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_23_sizeof__print_result:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_33_33:
    mov rax, rdi
    mov rbx, rsi
    mov rcx, rdx
    push rcx
    mov rdi, rbx
    mov rsi, rax
    call std_io__println
    pop rcx
    mov rdi, rcx
    call std_io__print_u64
    mov rax, 1
    lea rbx, [rel _str0]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
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
    sub rsp, 1024
.Lssa_34_34:
    mov rax, 27
    lea rbx, [rel _str1]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 1
    mov rbx, 14
    lea rcx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    mov rdx, rcx
    call _23_sizeof__print_result
    mov rax, 2
    mov rbx, 15
    lea rcx, [rel _str3]
    push rax
    mov rdi, rax
    mov rsi, rbx
    mov rdx, rcx
    call _23_sizeof__print_result
    pop rax
    mov rbx, 4
    mov rcx, 15
    lea rdx, [rel _str4]
    push rax
    push rbx
    mov rdi, rbx
    mov rsi, rcx
    mov rdx, rdx
    call _23_sizeof__print_result
    pop rbx
    pop rax
    mov rcx, 8
    mov rdx, 15
    lea r8, [rel _str5]
    push rax
    push rbx
    push rcx
    mov rdi, rcx
    mov rsi, rdx
    mov rdx, r8
    call _23_sizeof__print_result
    pop rcx
    pop rbx
    pop rax
    mov rdx, 8
    mov r8, 15
    lea r9, [rel _str6]
    push rax
    push rbx
    push rcx
    push rdx
    mov rdi, rdx
    mov rsi, r8
    mov rdx, r9
    call _23_sizeof__print_result
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r8, 24
    lea r9, [rel _str7]
    push rax
    push rbx
    push rcx
    push rdx
    mov rdi, r8
    mov rsi, r9
    call std_io__println
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r8, 8
    mov r9, 15
    lea rax, [rel _str8]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    mov rdi, r8
    mov rsi, r9
    mov rdx, rax
    call _23_sizeof__print_result
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r9, 8
    mov rax, 16
    lea rax, [rel _str9]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, r9
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    mov rax, 17
    lea rax, [rel _str10]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 23
    lea rax, [rel _str11]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 16
    mov rax, 17
    lea rax, [rel _str12]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 32
    mov rax, 16
    lea rax, [rel _str13]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 2
    mov rax, 23
    lea rax, [rel _str14]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 28
    lea rax, [rel _str15]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    mov rax, 18
    lea rax, [rel _str16]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    mov rax, 17
    lea rax, [rel _str17]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    mov rdx, rax
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 21
    lea rax, [rel _str18]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 1
    mov rax, 0
    cmp rax, 0
    jne .Lssa_34_35
    jmp .Lssa_34_36
.Lssa_34_35:
    mov rax, 32
    lea rax, [rel _str19]
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_36
.Lssa_34_36:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_37
    jmp .Lssa_34_38
.Lssa_34_37:
    mov rax, 33
    lea rax, [rel _str20]
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rax
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_38
.Lssa_34_38:
    cmp rbx, 4
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_39
    jmp .Lssa_34_40
.Lssa_34_39:
    mov rax, 33
    lea rbx, [rel _str21]
    push rcx
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    pop r9
    pop r8
    pop rdx
    pop rcx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_40
.Lssa_34_40:
    cmp rcx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_41
    jmp .Lssa_34_42
.Lssa_34_41:
    mov rax, 33
    lea rbx, [rel _str22]
    push rdx
    push r8
    push r9
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    pop r9
    pop r8
    pop rdx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_42
.Lssa_34_42:
    cmp rdx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_43
    jmp .Lssa_34_44
.Lssa_34_43:
    mov rax, 33
    lea rbx, [rel _str23]
    push r8
    push r9
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    pop r9
    pop r8
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_44
.Lssa_34_44:
    cmp r8, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_45
    jmp .Lssa_34_46
.Lssa_34_45:
    mov rax, 34
    lea rbx, [rel _str24]
    push r9
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    pop r9
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_46
.Lssa_34_46:
    cmp r9, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_47
    jmp .Lssa_34_48
.Lssa_34_47:
    mov rax, 35
    lea rbx, [rel _str25]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_48
.Lssa_34_48:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_49
    jmp .Lssa_34_50
.Lssa_34_49:
    mov rax, 36
    lea rbx, [rel _str26]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_50
.Lssa_34_50:
    cmp rax, 16
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_51
    jmp .Lssa_34_52
.Lssa_34_51:
    mov rax, 37
    lea rbx, [rel _str27]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_52
.Lssa_34_52:
    cmp rax, 32
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_53
    jmp .Lssa_34_54
.Lssa_34_53:
    mov rax, 36
    lea rbx, [rel _str28]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_54
.Lssa_34_54:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_55
    jmp .Lssa_34_56
.Lssa_34_55:
    mov rax, 42
    lea rbx, [rel _str29]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_56
.Lssa_34_56:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_57
    jmp .Lssa_34_58
.Lssa_34_57:
    mov rax, 37
    lea rbx, [rel _str30]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_58
.Lssa_34_58:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_59
    jmp .Lssa_34_60
.Lssa_34_59:
    mov rax, 36
    lea rbx, [rel _str31]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    jmp .Lssa_34_60
.Lssa_34_60:
    cmp rax, 0
    jne .Lssa_34_61
    jmp .Lssa_34_63
.Lssa_34_61:
    mov rax, 27
    lea rbx, [rel _str32]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    jmp .Lssa_34_62
.Lssa_34_62:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_63:
    mov rax, 28
    lea rbx, [rel _str33]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    jmp .Lssa_34_62
.Lssa_34_64:
    mov rax, rax
.Lssa_34_65:
    mov rax, rax
.Lssa_34_66:
    mov rbx, rax
.Lssa_34_67:
.Lssa_34_68:
.Lssa_34_69:
.Lssa_34_70:
.Lssa_34_71:
.Lssa_34_72:
.Lssa_34_73:
.Lssa_34_74:
.Lssa_34_75:
.Lssa_34_76:
    mov rax, rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 10,0
_str1: db 61,61,61,32,80,114,105,109,105,116,105,118,101,32,84,121,112,101,115,32,61,61,61,10,0
_str2: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str3: db 115,105,122,101,111,102,40,117,49,54,41,32,61,32,0
_str4: db 115,105,122,101,111,102,40,117,51,50,41,32,61,32,0
_str5: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str6: db 115,105,122,101,111,102,40,105,54,52,41,32,61,32,0
_str7: db 10,61,61,61,32,80,111,105,110,116,101,114,32,84,121,112,101,115,32,61,61,61,10,0
_str8: db 115,105,122,101,111,102,40,42,117,56,41,32,61,32,0
_str9: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str10: db 115,105,122,101,111,102,40,42,42,117,54,52,41,32,61,32,0
_str11: db 10,61,61,61,32,83,116,114,117,99,116,32,84,121,112,101,115,32,61,61,61,10,0
_str12: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str13: db 115,105,122,101,111,102,40,82,101,99,116,41,32,61,32,0
_str14: db 115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,61,32,0
_str15: db 10,61,61,61,32,80,111,105,110,116,101,114,32,116,111,32,83,116,114,117,99,116,32,61,61,61,10,0
_str16: db 115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,61,32,0
_str17: db 115,105,122,101,111,102,40,42,82,101,99,116,41,32,61,32,0
_str18: db 10,61,61,61,32,86,97,108,105,100,97,116,105,111,110,32,61,61,61,10,0
_str19: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,56,41,32,115,104,111,117,108,100,32,98,101,32,49,10,0
_str20: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,49,54,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str21: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,51,50,41,32,115,104,111,117,108,100,32,98,101,32,52,10,0
_str22: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str23: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,105,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str24: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,56,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str25: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str26: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str27: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,49,54,10,0
_str28: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,51,50,10,0
_str29: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str30: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str31: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str32: db 65,108,108,32,115,105,122,101,111,102,32,116,101,115,116,115,32,80,65,83,83,69,68,33,10,0
_str33: db 83,111,109,101,32,115,105,122,101,111,102,32,116,101,115,116,115,32,70,65,73,76,69,68,33,10,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
