// 58_struct_deep_nested.b - 3단계 중첩 구조체
// Expect exit code: 42

struct Level3 {
    val: i64;
}

struct Level2 {
    l3: Level3;
    offset: i64;
}

struct Level1 {
    l2: Level2;
    multiplier: i64;
}

func main(argc, argv) {
    var s: Level1;
    s.l2.l3.val = 7;
    s.l2.offset = 8;
    s.multiplier = 3;
    
    // 복사
    var s2: Level1;
    s2 = s;
    
    // s2 수정
    s2.l2.l3.val = 100;
    
    // s는 원본 유지: (7 + 8) * 3 - 3 = 42
    return (s.l2.l3.val + s.l2.offset) * s.multiplier - 3;
}
