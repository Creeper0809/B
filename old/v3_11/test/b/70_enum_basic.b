// 70_enum_basic.b - 기본 enum 테스트
// Expect exit code: 42

enum Color {
    Red,      // 0
    Green,    // 1
    Blue      // 2
}

enum Status {
    OK = 10,
    Error = 20,
    Pending   // 21
}

func main(argc, argv) {
    var c1 = Color_Red;      // 0
    var c2 = Color_Green;    // 1
    var c3 = Color_Blue;     // 2
    
    var s1 = Status_OK;      // 10
    var s2 = Status_Error;   // 20
    var s3 = Status_Pending; // 21
    
    // 0 + 1 + 2 + 10 + 20 + 21 = 54
    // Need 42, so: 54 - 12 = 42
    return c1 + c2 + c3 + s1 + s2 + s3 - 12;  // 0 + 1 + 2 + 10 + 20 + 21 - 12 = 42
}
