// 61_struct_complex_mix.b - 복합 시나리오 (리터럴, 복사, 포인터)
// Expect exit code: 42

struct Data {
    val: i64;
}

struct Wrapper {
    data: Data;
    ptr: *Data;
    multiplier: i64;
}

func main(argc, argv) {
    var d1: Data = Data { 5 };
    var d2: Data = Data { 10 };
    
    var w: Wrapper;
    w.data = d1;        // 구조체 복사
    w.ptr = &d2;        // 포인터 할당
    w.multiplier = 2;
    
    // w.data.val * w.multiplier + w.ptr->val * w.multiplier
    // = 5 * 2 + 10 * 2 = 10 + 20 = 30
    var result: i64 = w.data.val * w.multiplier + w.ptr->val * w.multiplier;
    
    // 추가 계산으로 42 만들기
    return result + 12;
}
