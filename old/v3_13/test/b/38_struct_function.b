// Test: Struct with function
// Expect exit code: 42

struct Point {
    x: u64;
    y: u64;
}

func set_point(p: *Point, x_val: u64, y_val: u64) {
    p->x = x_val;
    p->y = y_val;
}

func get_sum(p: *Point) -> u64 {
    return p->x + p->y;
}

func main(argc, argv) {
    var p: Point;
    var ptr: *Point;
    ptr = &p;
    
    set_point(ptr, 20, 22);
    
    return get_sum(ptr);  // 20 + 22 = 42
}
