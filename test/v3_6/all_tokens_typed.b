const NUM = 42;

func test_ops(a: i64, b: i64) -> i64 {
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

func test_cmp(x: i64, y: i64) -> i64 {
    var result: i64;
    result = 0;
    
    if (x == y) {
        result = result + 1;
    }
    if (x != y) {
        result = result + 1;
    }
    if (x < y) {
        result = result + 1;
    }
    if (x > y) {
        result = result + 1;
    }
    if (x <= y) {
        result = result + 1;
    }
    if (x >= y) {
        result = result + 1;
    }
    
    return result;
}

func test_loop() -> i64 {
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

func main() -> i64 {
    var result: i64;
    
    result = test_ops(10, 2);
    result = result + test_cmp(5, 10);
    result = result + test_loop();
    result = result + NUM;
    
    return result;
}
