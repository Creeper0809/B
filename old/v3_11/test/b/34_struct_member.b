// Test: Struct member access with . operator
// Expect exit code: 42

struct Point {
    x: u64;
    y: u64;
}

func main(argc, argv) {
    var p: Point;
    
    // Use . operator to access members
    p.x = 10;
    p.y = 32;
    
    // Read back and return
    return p.x + p.y;  // 10 + 32 = 42
}
