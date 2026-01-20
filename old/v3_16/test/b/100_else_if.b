// 100_else_if.b - Test else if chains
// Expect exit code: 42

func test_simple_else_if() -> i64 {
    var score = 85;
    var grade = 0;
    
    if (score >= 90) {
        grade = 1;  // A
    } else if (score >= 80) {
        grade = 2;  // B
    } else if (score >= 70) {
        grade = 3;  // C
    } else if (score >= 60) {
        grade = 4;  // D
    } else {
        grade = 5;  // F
    }
    
    if (grade != 2) {
        return 1;  // FAIL
    }
    return 0;  // PASS
}

func test_nested_else_if() -> i64 {
    var x = 5;
    var y = 10;
    var result = 0;
    
    if (x < 0) {
        result = 1;
    } else if (x == 0) {
        result = 2;
    } else if (x > 0) {
        if (y < 0) {
            result = 3;
        } else if (y == 0) {
            result = 4;
        } else if (y > 0) {
            result = 5;
        }
    }
    
    if (result != 5) {
        return 2;  // FAIL
    }
    return 0;  // PASS
}

func test_long_chain() -> i64 {
    var n = 7;
    var value = 0;
    
    if (n == 1) {
        value = 10;
    } else if (n == 2) {
        value = 20;
    } else if (n == 3) {
        value = 30;
    } else if (n == 4) {
        value = 40;
    } else if (n == 5) {
        value = 50;
    } else if (n == 6) {
        value = 60;
    } else if (n == 7) {
        value = 70;
    } else if (n == 8) {
        value = 80;
    } else if (n == 9) {
        value = 90;
    } else {
        value = 100;
    }
    
    if (value != 70) {
        return 3;  // FAIL
    }
    return 0;  // PASS
}

func test_without_final_else() -> i64 {
    var x = 15;
    var flag = 0;
    
    if (x < 10) {
        flag = 1;
    } else if (x < 20) {
        flag = 2;
    } else if (x < 30) {
        flag = 3;
    }
    
    if (flag != 2) {
        return 4;  // FAIL
    }
    return 0;  // PASS
}

func test_with_expressions() -> i64 {
    var a = 10;
    var b = 20;
    var result = 0;
    
    if (a + b == 20) {
        result = 1;
    } else if (a + b == 30) {
        result = 2;
    } else if (a * b == 200) {
        result = 3;
    } else {
        result = 4;
    }
    
    if (result != 2) {
        return 5;  // FAIL
    }
    return 0;  // PASS
}

func main() -> i64 {
    var result = 0;
    
    result = test_simple_else_if();
    if (result != 0) { return result; }
    
    result = test_nested_else_if();
    if (result != 0) { return result; }
    
    result = test_long_chain();
    if (result != 0) { return result; }
    
    result = test_without_final_else();
    if (result != 0) { return result; }
    
    result = test_with_expressions();
    if (result != 0) { return result; }
    
    return 42;  // All tests passed
}
