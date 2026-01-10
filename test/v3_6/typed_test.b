const NUM = 42;

func add_typed(x: i64, y: i64) -> i64 {
    return x + y;
}

func no_return_type(x: i64) {
    var temp: i64;
    temp = x + 10;
}

func with_var_type() -> i64 {
    var x: i64;
    var y: i64;
    x = 10;
    y = 20;
    return x + y;
}

func no_var_type() -> i64 {
    var a;
    var b;
    a = 5;
    b = 3;
    return a + b;
}

func main() -> i64 {
    var result: i64;
    result = 0;
    
    result = result + add_typed(10, 5);
    no_return_type(100);
    result = result + with_var_type();
    result = result + no_var_type();
    result = result + NUM;
    
    return result;
}
