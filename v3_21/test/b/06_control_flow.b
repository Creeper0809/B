// Test 06: Control Flow Suite
// Expect exit code: 0

func classify_number(n) -> i64 {
    if (n < 0) {
        if (n < 0 - 100) { return 1; }
        return 2;
    }
    if (n == 0) { return 3; }
    if (n > 100) { return 4; }
    return 5;
}

func test_else_if() -> i64 {
    var score = 85;
    var grade = 0;
    if (score >= 90) {
        grade = 1;
    } else if (score >= 80) {
        grade = 2;
    } else if (score >= 70) {
        grade = 3;
    } else if (score >= 60) {
        grade = 4;
    } else {
        grade = 5;
    }
    if (grade != 2) { return 1; }

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
    if (result != 5) { return 2; }

    var n = 7;
    var value = 0;
    if (n == 1) { value = 10; }
    else if (n == 2) { value = 20; }
    else if (n == 3) { value = 30; }
    else if (n == 4) { value = 40; }
    else if (n == 5) { value = 50; }
    else if (n == 6) { value = 60; }
    else if (n == 7) { value = 70; }
    else if (n == 8) { value = 80; }
    else if (n == 9) { value = 90; }
    else { value = 100; }
    if (value != 70) { return 3; }

    var x2 = 15;
    var flag = 0;
    if (x2 < 10) { flag = 1; }
    else if (x2 < 20) { flag = 2; }
    else if (x2 < 30) { flag = 3; }
    if (flag != 2) { return 4; }

    var a = 10;
    var b = 20;
    var r = 0;
    if (a + b == 20) { r = 1; }
    else if (a + b == 30) { r = 2; }
    else if (a * b == 200) { r = 3; }
    else { r = 4; }
    if (r != 2) { return 5; }

    return 0;
}

func bump(p) {
    *p = *p + 1;
    return 1;
}

func crash() {
    *(*i64)0 = 123;
    return 1;
}

func main(argc, argv) {
    // Nested loops sum: (1..5) * (1..5) => 225
    var i = 1;
    var j = 1;
    var sum = 0;
    i = 1;
    while (i <= 5) {
        j = 1;
        while (j <= 5) {
            sum = sum + i * j;
            j = j + 1;
        }
        i = i + 1;
    }
    if (sum != 225) { return 1; }

    // for loop sum 1..10
    var total = 0;
    for (i = 1; i <= 10; i = i + 1) {
        total = total + i;
    }
    if (total != 55) { return 2; }

    // break/continue
    i = 0;
    var count = 0;
    while (i < 10) {
        if (i == 5) { break; }
        count = count + 1;
        i = i + 1;
    }
    if (count != 5) { return 3; }

    i = 0;
    var odd_sum = 0;
    while (i < 10) {
        i = i + 1;
        if (i % 2 == 0) { continue; }
        odd_sum = odd_sum + i;
    }
    if (odd_sum != 25) { return 4; }

    if (classify_number(0 - 200) != 1) { return 5; }
    if (classify_number(0 - 50) != 2) { return 6; }
    if (classify_number(0) != 3) { return 7; }
    if (classify_number(50) != 5) { return 8; }
    if (classify_number(200) != 4) { return 9; }

    var e = test_else_if();
    if (e != 0) { return 10; }

    var x = 0;
    if (0 && bump(&x)) { x = 99; }
    if (1 || bump(&x)) { }
    if (0 || bump(&x)) { }
    if (x != 1) { return 11; }

    x = 0;
    if (true) { x = x + 1; }
    if (false) { x = 99; }
    if (true && false) { x = 123; }
    if (false || true) { x = x + 0; }
    if (x != 1) { return 12; }

    if (false && crash()) { return 13; }
    if (true || crash()) { }

    return 0;
}
