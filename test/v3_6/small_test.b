const PI = 3;
const MAX = 100;

func test_types(x: i64) -> i64 {
    var a: i64;
    var b: i64;
    a = 10;
    b = 20;
    return a + b;
}

func test_arithmetic(a: i64, b: i64) -> i64 {
    var sum: i64;
    var diff: i64;
    var prod: i64;
    var quot: i64;
    sum = a + b;
    diff = a - b;
    prod = a * b;
    quot = a / b;
    return sum + diff + prod + quot;
}

func main() -> i64 { return test_arithmetic(10, 2); }
