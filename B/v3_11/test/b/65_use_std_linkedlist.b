// 65_use_std_linkedlist.b - std의 linked_list 사용 테스트
// Expect exit code: 42

import std.linked_list;

func main(argc, argv) {
    var list = list_new();
    
    // 값 추가: 10, 20, 12
    list_append(list, 10);
    list_append(list, 20);
    list_append(list, 12);
    
    // 길이 확인
    var len = list_len(list);
    if (len != 3) { return 1; }
    
    // 값 확인
    var v0 = list_get(list, 0);
    var v1 = list_get(list, 1);
    var v2 = list_get(list, 2);
    
    // 10 + 20 + 12 = 42
    return v0 + v1 + v2;
}
