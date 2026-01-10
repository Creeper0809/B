const VAL_TEN = 10;
const VAL_FIVE = 5;

func add(a: i64, b: i64) -> i64 {
    return a + b;
}

func sub(a: i64, b: i64) -> i64 {
    return a - b;
}

func mul(a: i64, b: i64) -> i64 {
    return a * b;
}

func div(a: i64, b: i64) -> i64 {
    return a / b;
}

func check_eq(a: i64, b: i64) -> i64 {
    if (a == b) {
        return 1;
    }
    return 0;
}

func check_ne(a: i64, b: i64) -> i64 {
    if (a != b) {
        return 1;
    }
    return 0;
}

func check_lt(a: i64, b: i64) -> i64 {
    if (a < b) {
        return 1;
    }
    return 0;
}

func check_gt(a: i64, b: i64) -> i64 {
    if (a > b) {
        return 1;
    }
    return 0;
}

func check_le(a: i64, b: i64) -> i64 {
    if (a <= b) {
        return 1;
    }
    return 0;
}

func check_ge(a: i64, b: i64) -> i64 {
    if (a >= b) {
        return 1;
    }
    return 0;
}

func test_while() -> i64 {
    var i: i64;
    var sum: i64;
    i = 0;
    sum = 0;
    while (i < 5) {
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}

func test_if_else(n: i64) -> i64 {
    if (n == 0) {
        return 100;
    } else {
        return 200;
    }
}

func test_ampersand() -> i64 {
    var x: i64;
    x = 42;
    var p: i64;
    p = &x;
    if (p > 0) {
        return 1;
    }
    return 0;
}

func main() -> i64 {
    var result: i64;
    
    result = add(VAL_TEN, VAL_FIVE);
    result = result + sub(20, 5);
    result = result + mul(3, 2);
    result = result + div(10, 2);
    result = result + check_eq(5, 5);
    result = result + check_ne(3, 5);
    result = result + check_lt(3, 10);
    result = result + check_gt(10, 5);
    result = result + check_le(5, 5);
    result = result + check_ge(10, 10);
    result = result + test_while();
    result = result + test_if_else(0);
    result = result + test_if_else(1);
    result = result + test_ampersand();
    
    return result;
}
