// 80_struct_return_conditional.b - Conditional struct return
// Expect exit code: 42

struct Vec2 {
    x: i64;
    y: i64;
}

func Vec2_new(x: i64, y: i64) -> Vec2 {
    var v: Vec2;
    v.x = x;
    v.y = y;
    return v;
}

func get_vec(choice: i64) -> Vec2 {
    if (choice == 1) {
        return Vec2_new(10, 20);
    } else if (choice == 2) {
        return Vec2_new(30, 40);
    } else {
        return Vec2_new(5, 7);
    }
}

func main() -> i64 {
    var v1: Vec2 = get_vec(1);
    var v2: Vec2 = get_vec(2);
    var v3: Vec2 = get_vec(3);
    
    var sum = v1.x + v1.y + v2.x + v2.y + v3.x + v3.y;
    // 10 + 20 + 30 + 40 + 5 + 7 = 112
    
    if (sum == 112) {
        return 42;
    }
    return 1;
}
