// 71_enum_if.b - enum과 if 조합
// Expect exit code: 42

enum Direction {
    North,
    East, 
    South,
    West
}

func get_value(dir: i64) -> i64 {
    if (dir == Direction_North) { return 10; }
    if (dir == Direction_East) { return 20; }
    if (dir == Direction_South) { return 30; }
    if (dir == Direction_West) { return 40; }
    return 0;
}

func main(argc, argv) {
    var n = get_value(Direction_North);  // 10
    var e = get_value(Direction_East);   // 20
    var s = get_value(Direction_South);  // 30
    var w = get_value(Direction_West);   // 40
    
    // 10 + 20 + 30 + 40 = 100
    // Need 42: 100 - 58 = 42
    return n + e + s + w - 58;
}
