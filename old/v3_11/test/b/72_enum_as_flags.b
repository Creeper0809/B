// 72_enum_as_flags.b - enum을 비트 플래그로 사용
// Expect exit code: 42

enum Permission {
    Read = 1,
    Write = 2,
    Execute = 4,
    Admin = 8
}

func main(argc, argv) {
    var user_perms = Permission_Read | Permission_Write;  // 1 | 2 = 3
    var admin_perms = Permission_Read | Permission_Write | Permission_Execute | Permission_Admin;  // 15
    
    // Check if has read permission
    var has_read = user_perms & Permission_Read;  // 3 & 1 = 1
    
    // Check if has execute permission
    var has_exec = user_perms & Permission_Execute;  // 3 & 4 = 0
    
    // 3 + 15 + 1 + 0 = 19
    // Need 42: 19 + 23 = 42
    return user_perms + admin_perms + has_read + has_exec + 23;
}
