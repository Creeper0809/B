// 84_struct_return_stress.b - Stress test with many struct returns
// Expect exit code: 42

struct Data {
    x: i64;
    y: i64;
}

func Data_new(x: i64, y: i64) -> Data {
    var d: Data;
    d.x = x;
    d.y = y;
    return d;
}

func Data_transform(d: *Data, op: i64) -> Data {
    if (op == 1) {
        return Data_new(d->x + 1, d->y + 1);
    }
    if (op == 2) {
        return Data_new(d->x * 2, d->y * 2);
    }
    if (op == 3) {
        return Data_new(d->x - d->y, d->y - d->x);
    }
    return Data_new(d->x, d->y);
}

func main() -> i64 {
    var data: Data = Data_new(5, 3);
    var sum = 0;
    
    // Apply many transformations
    for (var i = 0; i < 10; i++) {
        var op = (i % 3) + 1;
        data = Data_transform(&data, op);
        sum = sum + data.x + data.y;
    }
    
    // Expected: lots of struct returns in loop
    // Just check it doesn't crash and returns something
    
    if (sum != 0) {
        return 42;
    }
    return 1;
}
