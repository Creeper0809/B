// Test: Multiple struct types
// Expect exit code: 42

struct Point {
    x: u64;
    y: u64;
}

struct Color {
    r: u64;
    g: u64;
    b: u64;
}

func main(argc, argv) {
    var p: Point;
    var c: Color;
    
    p.x = 10;
    p.y = 12;
    
    c.r = 5;
    c.g = 7;
    c.b = 8;
    
    // 10 + 12 + 5 + 7 + 8 = 42
    return p.x + p.y + c.r + c.g + c.b;
}
