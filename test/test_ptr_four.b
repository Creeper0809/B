// 포인터 4개 테스트
func test1() -> u64 {
    var arr: [3]u64;
    arr[$0] = 10;
    arr[$1] = 20;
    arr[$2] = 30;
    return arr[$0] + arr[$1] + arr[$2];  // 60
}

func test2() -> u64 {
    var val: u64 = 42;
    var p: *u64 = &val;
    *p = 100;
    return val;  // 100
}

func test3() -> u64 {
    var val: u64 = 42;
    var p1: *u64 = &val;
    var p2: **u64 = &p1;
    var temp_p: *u64 = *p2;
    *temp_p = 200;
    return val;  // 200
}

func test4() -> u64 {
    var arr: [3]u64;
    arr[$0] = 10;
    arr[$1] = 20;
    arr[$2] = 30;
    
    var p: *u64 = &arr[$1];
    return *p;  // 20
}

func main() -> u64 {
    var r1: u64 = test1();
    var r2: u64 = test2();
    var r3: u64 = test3();
    var r4: u64 = test4();
    return r1 + r2 + r3 + r4;  // 60+100+200+20 = 380
}
