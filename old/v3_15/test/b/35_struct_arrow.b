// Test: Struct member access with -> operator (pointer)
// Expect exit code: 42

struct Point {
    x: u64;
    y: u64;
}

func main(argc, argv) {
    var p: Point;
    var ptr: *Point;
    
    // Set p values
    p.x = 10;
    p.y = 15;
    
    // Get pointer to p
    ptr = &p;
    
    // Access through pointer with ->
    ptr->x = 20;
    ptr->y = 22;
    
    // Return sum: 20 + 22 = 42
    return ptr->x + ptr->y;
}
