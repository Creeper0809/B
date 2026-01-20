// Test: Complex struct operations with loops
// Expect exit code: 42

struct Data {
    value: u64;
    flag: u64;
}

func main(argc, argv) {
    var d1: Data;
    var d2: Data;
    var d3: Data;
    
    // Initialize
    d1.value = 0;
    d1.flag = 1;
    
    d2.value = 0;
    d2.flag = 1;
    
    d3.value = 0;
    d3.flag = 1;
    
    // Accumulate values
    for (var i = 0; i < 10; i = i + 1) {
        if (d1.flag) {
            d1.value = d1.value + 1;
        }
    }
    
    for (var i = 0; i < 15; i = i + 1) {
        if (d2.flag) {
            d2.value = d2.value + 1;
        }
    }
    
    for (var i = 0; i < 17; i = i + 1) {
        if (d3.flag) {
            d3.value = d3.value + 1;
        }
    }
    
    // 10 + 15 + 17 = 42
    return d1.value + d2.value + d3.value;
}
