// 89_impl_mixed.b - impl blocks mixed with regular functions
// Expect exit code: 42

struct Data {
    value: i64;
}

impl Data {
    func init(self: *Data, val: i64) {
        self->value = val;
    }
    
    func get_value(self: *Data) -> i64 {
        return self->value;
    }
    
    func double(self: *Data) {
        self->value = self->value * 2;
    }
}

// Regular function not in impl block
func sum_array(arr: *Data, count: i64) -> i64 {
    var sum = 0;
    for (var i = 0; i < count; i++) {
        var ptr = arr + i * 8;  // Pointer arithmetic
        var d: *Data = (*Data)ptr;
        sum = sum + d->get_value();
    }
    return sum;
}

func main() -> i64 {
    var data1: Data;
    var data2: Data;
    var data3: Data;
    
    data1.init(10);
    data2.init(20);
    data3.init(12);
    
    var total = data1.get_value() + data2.get_value() + data3.get_value();
    
    if (total == 42) {
        return 42;
    }
    return 1;
}
