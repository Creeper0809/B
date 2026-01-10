const NUM_TEN = 10;
const NUM_TWENTY = 20;
const NUM_FIVE = 5;

func test_plus(a: i64, b: i64) -> i64 {
    return a + b;
}

func test_minus(a: i64, b: i64) -> i64 {
    return a - b;
}

func test_star(a: i64, b: i64) -> i64 {
    return a * b;
}

func test_slash(a: i64, b: i64) -> i64 {
    return a / b;
}

func test_eqeq(a: i64, b: i64) -> i64 {
    if (a == b) {
        return 1;
    }
    return 0;
}

func test_bangeq(a: i64, b: i64) -> i64 {
    if (a != b) {
        return 1;
    }
    return 0;
}

func test_lt(a: i64, b: i64) -> i64 {
    if (a < b) {
        return 1;
    }
    return 0;
}

func test_gt(a: i64, b: i64) -> i64 {
    if (a > b) {
        return 1;
    }
    return 0;
}

func test_lteq(a: i64, b: i64) -> i64 {
    if (a <= b) {
        return 1;
    }
    return 0;
}

func test_gteq(a: i64, b: i64) -> i64 {
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
    while (i < 10) {
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

func test_var_types() -> i64 {
    var a: i64;
    var b: u64;
    var c: u32;
    var d: u16;
    var e: u8;
    
    a = 1;
    b = 2;
    c = 3;
    d = 4;
    e = 5;
    
    return a + b + c + d + e;
}

func test_lparen_rparen(x: i64) -> i64 {
    return (x + 5) * (x - 2);
}

func test_lbrace_rbrace() -> i64 {
    var result: i64;
    result = 0;
    if (1 == 1) {
        result = result + 10;
    }
    return result;
}

func test_semicolon_colon(x: i64, y: i64) -> i64 {
    var temp: i64;
    temp = x;
    return temp + y;
}

func test_comma(a: i64, b: i64, c: i64) -> i64 {
    return a + b + c;
}

func test_ampersand() -> i64 {
    var x: i64;
    var p: i64;
    x = 42;
    p = &x;
    if (p > 0) {
        return 1;
    }
    return 0;
}

func test_arrow(x: i64) -> i64 {
    return x + 1;
}

func main() -> i64 {
    var total: i64;
    total = 0;
    
    total = total + test_plus(10, 5);
    total = total + test_minus(20, 8);
    total = total + test_star(3, 4);
    total = total + test_slash(100, 10);
    
    total = total + test_eqeq(5, 5);
    total = total + test_bangeq(5, 3);
    total = total + test_lt(3, 5);
    total = total + test_gt(10, 5);
    total = total + test_lteq(5, 5);
    total = total + test_gteq(10, 10);
    
    total = total + test_while();
    total = total + test_if_else(0);
    total = total + test_if_else(1);
    
    total = total + test_var_types();
    total = total + test_lparen_rparen(5);
    total = total + test_lbrace_rbrace();
    total = total + test_semicolon_colon(7, 3);
    total = total + test_comma(1, 2, 3);
    total = total + test_ampersand();
    total = total + test_arrow(10);
    
    total = total + NUM_TEN + NUM_TWENTY + NUM_FIVE;
    
    return total;
}
