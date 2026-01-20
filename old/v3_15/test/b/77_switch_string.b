// Test 77: Switch with string - shows pointer comparison bug
// Expect exit code: 42

import std.io;

func get_bar() -> *u8 {
    return "bar";  // Different string literal address
}

func test_string_var(s: *u8) -> i64 {
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

func main() {
    // Direct literal - works (same address)
    var a = test_string_var("bar"); // 200
    
    // Via function - may not work (different address)
    var s = get_bar();
    var b = test_string_var(s); // Should be 200, might be 999
    
    // For now, assume it works with literals only
    // 200 + 200 - 358 = 42
    return a + b - 358;
}
