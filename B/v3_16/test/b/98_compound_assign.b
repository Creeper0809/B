// 98_compound_assign.b - Test compound assignment and increment/decrement operators
// Expect exit code: 42

import std.io;

func test_compound_assign() -> i64 {
    println("[TEST] Compound assignment operators");
    
    // += operator
    var a = 10;
    a += 5;  // a = a + 5 => 15
    if (a != 15) {
        println("FAIL: += operator");
        return 1;
    }
    
    // -= operator
    var b = 20;
    b -= 7;  // b = b - 7 => 13
    if (b != 13) {
        println("FAIL: -= operator");
        return 2;
    }
    
    // *= operator
    var c = 6;
    c *= 4;  // c = c * 4 => 24
    if (c != 24) {
        println("FAIL: *= operator");
        return 3;
    }
    
    // /= operator
    var d = 100;
    d /= 5;  // d = d / 5 => 20
    if (d != 20) {
        println("FAIL: /= operator");
        return 4;
    }
    
    // %= operator
    var e = 17;
    e %= 5;  // e = e % 5 => 2
    if (e != 2) {
        println("FAIL: %= operator");
        return 5;
    }
    
    println("PASS: All compound assignment operators");
    return 0;
}

func test_postfix_increment() -> i64 {
    println("[TEST] Postfix increment/decrement");
    
    // Postfix ++
    var x = 10;
    x++;  // x = x + 1 => 11
    if (x != 11) {
        println("FAIL: postfix ++");
        return 10;
    }
    
    // Postfix --
    var y = 20;
    y--;  // y = y - 1 => 19
    if (y != 19) {
        println("FAIL: postfix --");
        return 11;
    }
    
    // Multiple increments
    var z = 0;
    z++;
    z++;
    z++;
    if (z != 3) {
        println("FAIL: multiple postfix ++");
        return 12;
    }
    
    println("PASS: Postfix increment/decrement");
    return 0;
}

func test_prefix_increment() -> i64 {
    println("[TEST] Prefix increment/decrement");
    
    // Prefix ++
    var x = 10;
    ++x;  // x = x + 1 => 11
    if (x != 11) {
        println("FAIL: prefix ++");
        return 20;
    }
    
    // Prefix --
    var y = 20;
    --y;  // y = y - 1 => 19
    if (y != 19) {
        println("FAIL: prefix --");
        return 21;
    }
    
    // Multiple decrements
    var z = 10;
    --z;
    --z;
    --z;
    if (z != 7) {
        println("FAIL: multiple prefix --");
        return 22;
    }
    
    println("PASS: Prefix increment/decrement");
    return 0;
}

func test_mixed_operations() -> i64 {
    println("[TEST] Mixed compound operations");
    
    // Chained compound assignments
    var x = 5;
    x += 3;   // 8
    x *= 2;   // 16
    x -= 4;   // 12
    x /= 3;   // 4
    x %= 3;   // 1
    
    if (x != 1) {
        println("FAIL: chained compound assignments");
        return 30;
    }
    
    // Mix with increment
    var y = 10;
    y += 5;   // 15
    y++;      // 16
    y--;      // 15
    ++y;      // 16
    --y;      // 15
    
    if (y != 15) {
        println("FAIL: mixed compound and increment");
        return 31;
    }
    
    println("PASS: Mixed compound operations");
    return 0;
}

func test_complex_expressions() -> i64 {
    println("[TEST] Complex expressions");
    
    // Compound with expressions
    var a = 10;
    a += 2 * 3;  // a = a + 6 => 16
    if (a != 16) {
        println("FAIL: compound with expression");
        return 40;
    }
    
    var b = 100;
    b -= 5 * 4;  // b = b - 20 => 80
    if (b != 80) {
        println("FAIL: compound with multiply");
        return 41;
    }
    
    var c = 7;
    c *= 2 + 3;  // c = c * 5 => 35
    if (c != 35) {
        println("FAIL: compound multiply with expression");
        return 42;
    }
    
    println("PASS: Complex expressions");
    return 0;
}

func main() -> i64 {
    println("=== Compound Assignment & Increment Test ===");
    
    var result = 0;
    
    result = test_compound_assign();
    if (result != 0) { return result; }
    
    result = test_postfix_increment();
    if (result != 0) { return result; }
    
    result = test_prefix_increment();
    if (result != 0) { return result; }
    
    result = test_mixed_operations();
    if (result != 0) { return result; }
    
    result = test_complex_expressions();
    if (result != 0) { return result; }
    
    println("=== ALL TESTS PASSED ===");
    return 42;  // Success code
}
