// 101_array_char.b - Test array indexing and char type
// Expect exit code: 42

import io;
import util;

func test_array_basic() -> i64 {
    // Stack array of 5 i64s
    var arr: [5]i64;
    
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    
    // Read with indexing
    var sum = arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
    
    if (sum != 150) {
        return 1;
    }
    
    // Modify
    arr[2] = 100;
    if (arr[2] != 100) {
        return 2;
    }
    
    return 0;
}

func test_char_type() -> i64 {
    var a: char = 65;  // 'A'
    var b: char = 66;  // 'B'
    
    if (a != 65) {
        return 10;
    }
    
    if (b != 66) {
        return 11;
    }
    
    var sum: i64 = a + b;  // 65 + 66 = 131
    if (sum != 131) {
        return 12;
    }
    
    return 0;
}

func test_char_array() -> i64 {
    // Stack char array
    var str: [6]char;
    
    str[0] = 72;   // 'H'
    str[1] = 101;  // 'e'
    str[2] = 108;  // 'l'
    str[3] = 108;  // 'l'
    str[4] = 111;  // 'o'
    str[5] = 0;    // null terminator
    
    if (str[0] != 72) {
        return 20;
    }
    
    if (str[4] != 111) {
        return 21;
    }
    
    // Calculate sum
    var sum: i64 = 0;
    var i = 0;
    for (i = 0; i < 5; i++) {
        sum = sum + str[i];
    }
    
    // H(72) + e(101) + l(108) + l(108) + o(111) = 500
    if (sum != 500) {
        return 22;
    }
    
    return 0;
}

func test_multidim_simulation() -> i64 {
    // Simulate 2D array: 3x3 matrix
    var matrix: [9]i64;
    
    // Fill matrix
    var val = 1;
    var i = 0;
    for (i = 0; i < 9; i++) {
        matrix[i] = val;
        val = val + 1;
    }
    
    // Access like matrix[1][2] = matrix[1*3 + 2]
    if (matrix[5] != 6) {
        return 30;
    }
    
    // Sum diagonal
    var diag_sum = matrix[0] + matrix[4] + matrix[8];  // 1 + 5 + 9 = 15
    if (diag_sum != 15) {
        return 31;
    }
    
    return 0;
}

func test_nested_array_access() -> i64 {
    var arr: [10]i64;
    
    var i = 0;
    for (i = 0; i < 10; i++) {
        arr[i] = i * 10;
    }
    
    // Test nested access
    var idx = 5;
    if (arr[idx] != 50) {
        return 40;
    }
    
    // Use array value as index
    arr[0] = 3;
    var nested_idx = arr[0];
    if (arr[nested_idx] != 30) {
        return 41;
    }
    
    return 0;
}

func main() -> i64 {
    var result = 0;
    
    result = test_array_basic();
    if (result != 0) { return result; }
    
    result = test_char_type();
    if (result != 0) { return result; }
    
    result = test_char_array();
    if (result != 0) { return result; }
    
    result = test_multidim_simulation();
    if (result != 0) { return result; }
    
    result = test_nested_array_access();
    if (result != 0) { return result; }
    
    return 42;
}
