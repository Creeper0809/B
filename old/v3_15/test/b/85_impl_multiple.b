// 85_impl_multiple.b - Multiple impl blocks for different structs
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

struct Rect {
    width: i64;
    height: i64;
}

impl Point {
    func init(self: *Point, x: i64, y: i64) {
        self->x = x;
        self->y = y;
    }
    
    func sum(self: *Point) -> i64 {
        return self->x + self->y;
    }
}

impl Rect {
    func init(self: *Rect, w: i64, h: i64) {
        self->width = w;
        self->height = h;
    }
    
    func area(self: *Rect) -> i64 {
        return self->width * self->height;
    }
}

func main() -> i64 {
    var p: Point;
    Point_init(&p, 10, 20);
    
    var r: Rect;
    Rect_init(&r, 3, 7);
    
    var total = Point_sum(&p) + Rect_area(&r);
    // 30 + 21 = 51
    
    if (total == 51) {
        return 42;
    }
    return 1;
}
