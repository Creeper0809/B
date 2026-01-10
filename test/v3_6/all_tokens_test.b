const TEN = 10;
const FIVE = 5;
const TWO = 2;

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

func test_var() -> i64 {
    var x: i64;
    var y: i64;
    x = 10;
    y = 20;
    return x + y;
}

func test_cmp(a: i64, b: i64) -> i64 {
    var r: i64;
    r = 0;
    if (a == b) { r = r + 1; }
    if (a != b) { r = r + 2; }
    if (a < b) { r = r + 4; }
    if (a > b) { r = r + 8; }
    if (a <= b) { r = r + 16; }
    if (a >= b) { r = r + 32; }
    return r;
}

func test_while() -> i64 {
    var s: i64;
    var i: i64;
    s = 0;
    i = 0;
    while (i < 5) {
        s = s + i;
        i = i + 1;
    }
    return s;
}

func main() -> i64 {
    var result: i64;
    result = 0;
    result = result + add(TEN, FIVE);
    result = result + sub(TEN, TWO);
    result = result + mul(TWO, TWO);
    result = result + div(TEN, FIVE);
    result = result + test_var();
    result = result + test_cmp(10, 20);
    result = result + test_while();
    return result;
}
