// Test 76: Basic impl block
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

impl Point {
    func init(self: *Point, x: i64, y: i64) {
        self->x = x;
        self->y = y;
    }
    
    func sum(self: *Point) -> i64 {
        return self->x + self->y;
    }
    
    func distance_squared(self: *Point, other: *Point) -> i64 {
        var dx = self->x - other->x;
        var dy = self->y - other->y;
        return dx * dx + dy * dy;
    }
}

func main() {
    var p1: Point;
    var p2: Point;
    
    Point_init(&p1, 10, 20);
    Point_init(&p2, 3, 4);
    
    // p1.sum() = 30
    var sum1 = Point_sum(&p1);
    
    // distance_squared = (10-3)^2 + (20-4)^2 = 49 + 256 = 305
    var dist = Point_distance_squared(&p1, &p2);
    
    // result = 30 + 305 - 293 = 42
    return sum1 + dist - 293;
}
