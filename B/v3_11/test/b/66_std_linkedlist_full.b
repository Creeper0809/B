// 66_std_linkedlist_full.b - std 연결 리스트 전체 기능 테스트
// Expect exit code: 42

import std.linked_list;

func main(argc, argv) {
    var list = list_new();
    
    // Test 1: append
    list_append(list, 5);
    list_append(list, 10);
    list_append(list, 7);
    
    // Test 2: push (맨 앞에 추가)
    list_push(list, 3);
    
    // 현재 리스트: 3 -> 5 -> 10 -> 7
    
    // Test 3: contains
    var has5 = list_contains(list, 5);
    var has99 = list_contains(list, 99);
    
    if (has5 != 1) { return 1; }
    if (has99 != 0) { return 2; }
    
    // Test 4: pop
    var popped = list_pop(list);  // 3
    if (popped != 3) { return 3; }
    
    // 현재 리스트: 5 -> 10 -> 7
    
    // Test 5: reverse
    list_reverse(list);
    
    // 현재 리스트: 7 -> 10 -> 5
    var v0 = list_get(list, 0);
    var v1 = list_get(list, 1);
    var v2 = list_get(list, 2);
    
    if (v0 != 7) { return 4; }
    if (v1 != 10) { return 5; }
    if (v2 != 5) { return 6; }
    
    // Test 6: 길이
    var len = list_len(list);
    if (len != 3) { return 7; }
    
    // 7 + 10 + 5 = 22
    var sum = v0 + v1 + v2;
    
    // 22 + 20 = 42
    return sum + 20;
}
