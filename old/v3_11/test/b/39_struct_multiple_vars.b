// Test: Struct array simulation (manual pointer arithmetic)
// Expect exit code: 42

struct Point {
    x: u64;
    y: u64;
}

func main(argc, argv) {
    var p0: Point;
    var p1: Point;
    var p2: Point;
    
    // Set p0
    p0.x = 5;
    p0.y = 7;
    
    // Set p1
    p1.x = 10;
    p1.y = 12;
    
    // Set p2
    p2.x = 3;
    p2.y = 5;
    
    // Sum all: 5+7+10+12+3+5 = 42
    return p0.x + p0.y + p1.x + p1.y + p2.x + p2.y;
}
