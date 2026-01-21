// Test 07: Switch/Enum Suite
// Expect exit code: 0
// Mode: ssa
// Opt: O1

import std.str;

enum Color {
    Red,
    Green,
    Blue
}

enum Status {
    OK = 10,
    Error = 20,
    Pending
}

enum Direction {
    North,
    East,
    South,
    West
}

enum Permission {
    Read = 1,
    Write = 2,
    Execute = 4,
    Admin = 8
}

enum State {
    Idle,
    Running,
    Paused,
    Stopped,
}

func get_value(dir: i64) -> i64 {
    if (dir == Direction_North) { return 10; }
    if (dir == Direction_East) { return 20; }
    if (dir == Direction_South) { return 30; }
    if (dir == Direction_West) { return 40; }
    return 0;
}

func test_switch_int(x: i64) -> i64 {
    var out = 0;
    switch (x) {
        case 1:
            out = 100;
            break;
        case 2:
            out = 200;
            break;
        case 3:
            out = 300;
            break;
        default:
            out = 999;
    }
    return out;
}

func test_switch_enum(s: i64) -> i64 {
    var out = 0;
    switch (s) {
        case State_Idle:
            out = 1000;
            break;
        case State_Running:
            out = 2000;
            break;
        case State_Paused:
            out = 3000;
            break;
        case State_Stopped:
            out = 4000;
            break;
        default:
            out = 9999;
    }
    return out;
}

func test_switch_default_only(x: i64) -> i64 {
    var out = 0;
    switch (x) {
        default:
            out = 777;
    }
    return out;
}

func test_switch_nested(a: i64, b: i64) -> i64 {
    var out = 0;
    switch (a) {
        case 1:
            switch (b) {
                case 2:
                    out = 12;
                    break;
                default:
                    out = 10;
            }
            break;
        default:
            out = 99;
    }
    return out;
}

func test_switch_string(s: *u8) -> i64 {
    switch (s) {
        case "foo":
            return 100;
        case "bar":
            return 200;
        case "baz":
            return 300;
        default:
            return 999;
    }
}

func main(argc, argv) {
    var c1 = Color_Red;
    var c2 = Color_Green;
    var c3 = Color_Blue;
    var s1 = Status_OK;
    var s2 = Status_Error;
    var s3 = Status_Pending;
    if (c1 + c2 + c3 + s1 + s2 + s3 - 12 != 42) { return 1; }

    var n = get_value(Direction_North);
    var e = get_value(Direction_East);
    var s = get_value(Direction_South);
    var w = get_value(Direction_West);
    if (n + e + s + w - 58 != 42) { return 2; }

    var user_perms = Permission_Read | Permission_Write;
    var admin_perms = Permission_Read | Permission_Write | Permission_Execute | Permission_Admin;
    var has_read = user_perms & Permission_Read;
    var has_exec = user_perms & Permission_Execute;
    if (user_perms + admin_perms + has_read + has_exec + 23 != 42) { return 3; }

    if (test_switch_int(2) != 200) { return 4; }
    if (test_switch_int(1) != 100) { return 5; }
    if (test_switch_int(99) != 999) { return 6; }

    if (test_switch_enum(State_Running) != 2000) { return 7; }
    if (test_switch_enum(State_Idle) != 1000) { return 8; }

    if (test_switch_default_only(123) != 777) { return 9; }
    if (test_switch_nested(1, 2) != 12) { return 10; }

    if (test_switch_string("bar") != 200) { return 11; }

    return 0;
}
