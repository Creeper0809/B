// v3.6 for와 switch 테스트

// ==========================================
// 1. for 루프 기본
// ==========================================
func test_for_basic() -> i64 {
    var sum: i64;
    sum = 0;
    
    var i: i64;
    for (i = 0; i < 10; i = i + 1) {
        sum = sum + i;
    }
    
    return sum;
}

// ==========================================
// 2. for 루프 - 변수 선언 포함
// ==========================================
func test_for_with_decl() -> i64 {
    var result: i64;
    result = 0;
    
    for (var i: i64; i < 5; i = i + 1) {
        result = result + i * 2;
    }
    
    return result;
}

// ==========================================
// 3. for 루프 - 초기화 없음
// ==========================================
func test_for_no_init() -> i64 {
    var i: i64;
    i = 0;
    var sum: i64;
    sum = 0;
    
    for (; i < 5; i = i + 1) {
        sum = sum + 1;
    }
    
    return sum;
}

// ==========================================
// 4. for 루프 - 조건 없음 (무한 루프 회피용)
// ==========================================
func test_for_no_cond() -> i64 {
    var cnt: i64;
    cnt = 0;
    
    var i: i64;
    for (i = 0; ; i = i + 1) {
        cnt = cnt + 1;
        if (i >= 3) {
            return cnt;
        }
    }
    
    return 0;
}

// ==========================================
// 5. for 루프 - update 없음
// ==========================================
func test_for_no_update() -> i64 {
    var sum: i64;
    sum = 0;
    
    var i: i64;
    for (i = 0; i < 5; ) {
        sum = sum + i;
        i = i + 1;
    }
    
    return sum;
}

// ==========================================
// 6. 중첩 for 루프
// ==========================================
func test_for_nested() -> i64 {
    var sum: i64;
    sum = 0;
    
    var i: i64;
    for (i = 0; i < 3; i = i + 1) {
        var j: i64;
        for (j = 0; j < 3; j = j + 1) {
            sum = sum + 1;
        }
    }
    
    return sum;
}

// ==========================================
// 7. switch 기본
// ==========================================
func get_name(x: i64) -> i64 {
    switch (x) {
        case 0:
            return 100;
        case 1:
            return 200;
        case 2:
            return 300;
        default:
            return 0 - 1;
    }
    return 0;
}

func test_switch_basic() -> i64 {
    if (get_name(0) != 100) { return 1; }
    if (get_name(1) != 200) { return 2; }
    if (get_name(2) != 300) { return 3; }
    if (get_name(5) != 0 - 1) { return 4; }
    return 0;
}

// ==========================================
// 8. switch - 여러 문장
// ==========================================
func calc_score(grade: i64) -> i64 {
    var score: i64;
    score = 0;
    
    switch (grade) {
        case 1:
            score = 90;
            score = score + 10;
        case 2:
            score = 80;
            score = score + 5;
        case 3:
            score = 70;
        default:
            score = 0;
    }
    
    return score;
}

func test_switch_multi_stmt() -> i64 {
    if (calc_score(1) != 100) { return 10; }
    if (calc_score(2) != 85) { return 11; }
    if (calc_score(3) != 70) { return 12; }
    if (calc_score(9) != 0) { return 13; }
    return 0;
}

// ==========================================
// 9. switch - 계산식
// ==========================================
func classify(x: i64) -> i64 {
    var y: i64;
    y = x / 10;
    
    switch (y) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 3;
        default:
            return 0;
    }
    return 0 - 1;
}

func test_switch_expr() -> i64 {
    if (classify(5) != 1) { return 20; }
    if (classify(15) != 2) { return 21; }
    if (classify(25) != 3) { return 22; }
    if (classify(100) != 0) { return 23; }
    return 0;
}

// ==========================================
// 10. for + switch 조합
// ==========================================
func test_for_switch_combo() -> i64 {
    var sum: i64;
    sum = 0;
    
    var i: i64;
    for (i = 0; i < 5; i = i + 1) {
        switch (i) {
            case 0:
                sum = sum + 1;
            case 1:
                sum = sum + 2;
            case 2:
                sum = sum + 3;
            case 3:
                sum = sum + 4;
            case 4:
                sum = sum + 5;
        }
    }
    
    return sum;
}

// ==========================================
// 메인
// ==========================================
func main() -> i64 {
    var r: i64;
    
    // test_for_basic: 0+1+...+9 = 45
    r = test_for_basic();
    if (r != 45) { return r; }
    
    // test_for_with_decl: (0*2)+(1*2)+...+(4*2) = 20
    r = test_for_with_decl();
    if (r != 20) { return 100 + r; }
    
    // test_for_no_init: 5
    r = test_for_no_init();
    if (r != 5) { return 200 + r; }
    
    // test_for_no_cond: 4
    r = test_for_no_cond();
    if (r != 4) { return r; }
    
    // test_for_no_update: 0+1+2+3+4 = 10
    r = test_for_no_update();
    if (r != 10) { return r; }
    
    // test_for_nested: 9
    r = test_for_nested();
    if (r != 9) { return r; }
    
    // switch tests
    r = test_switch_basic();
    if (r != 0) { return r; }
    
    r = test_switch_multi_stmt();
    if (r != 0) { return r; }
    
    r = test_switch_expr();
    if (r != 0) { return r; }
    
    // test_for_switch_combo: 1+2+3+4+5 = 15
    r = test_for_switch_combo();
    if (r != 15) { return r; }
    
    // 모든 테스트 통과
    return 0;
}
