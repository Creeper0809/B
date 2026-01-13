// 62_linked_list_test.b - 연결 리스트 종합 테스트
// Expect exit code: 42

struct ListNode {
    value: i64;
    next: *ListNode;
}

struct LinkedList {
    head: *ListNode;
    tail: *ListNode;
    length: i64;
}

// 새 연결 리스트 생성
func list_new() -> *LinkedList {
    var list = heap_alloc(24);
    *(list) = 0;
    *(list + 8) = 0;
    *(list + 16) = 0;
    return list;
}

// 노드 생성
func list_make_node(value) -> *ListNode {
    var node = heap_alloc(16);
    *(node) = value;
    *(node + 8) = 0;
    return node;
}

// 리스트 길이 반환
func list_len(list) -> i64 {
    return *(list + 16);
}

// 맨 앞에 추가
func list_push(list, value) {
    var node = list_make_node(value);
    var old_head = *(list);
    
    *(node + 8) = old_head;
    *(list) = node;
    
    if (old_head == 0) {
        *(list + 8) = node;
    }
    
    var len = *(list + 16);
    *(list + 16) = len + 1;
}

// 맨 뒤에 추가
func list_append(list, value) {
    var node = list_make_node(value);
    var tail = *(list + 8);
    
    if (tail == 0) {
        *(list) = node;
        *(list + 8) = node;
    } else {
        *(tail + 8) = node;
        *(list + 8) = node;
    }
    
    var len = *(list + 16);
    *(list + 16) = len + 1;
}

// 인덱스로 값 가져오기
func list_get(list, index) -> i64 {
    var head = *(list);
    if (head == 0) { return 0; }
    
    var current = head;
    var i = 0;
    
    while (current != 0) {
        if (i == index) {
            return *(current);
        }
        current = *(current + 8);
        i = i + 1;
    }
    
    return 0;
}

// 맨 앞 값 제거 및 반환
func list_pop(list) -> i64 {
    var head = *(list);
    if (head == 0) { return 0; }
    
    var value = *(head);
    var next = *(head + 8);
    
    *(list) = next;
    
    if (next == 0) {
        *(list + 8) = 0;
    }
    
    var len = *(list + 16);
    *(list + 16) = len - 1;
    
    return value;
}

func main(argc, argv) {
    var list = list_new();
    
    // Test 1: append 테스트
    list_append(list, 10);
    list_append(list, 20);
    list_append(list, 12);
    
    // 길이 확인: 3
    var len = list_len(list);
    if (len != 3) { return 1; }
    
    // Test 2: get 테스트
    var v0 = list_get(list, 0);  // 10
    var v1 = list_get(list, 1);  // 20
    var v2 = list_get(list, 2);  // 12
    
    if (v0 != 10) { return 2; }
    if (v1 != 20) { return 3; }
    if (v2 != 12) { return 4; }
    
    // Test 3: push 테스트
    list_push(list, 5);
    
    len = list_len(list);
    if (len != 4) { return 5; }
    
    v0 = list_get(list, 0);  // 5 (새로 push된 값)
    if (v0 != 5) { return 6; }
    
    // Test 4: pop 테스트
    var popped = list_pop(list);  // 5
    if (popped != 5) { return 7; }
    
    len = list_len(list);
    if (len != 3) { return 8; }
    
    // Test 5: 합계 계산
    // list: 10 -> 20 -> 12
    var sum = list_get(list, 0) + list_get(list, 1) + list_get(list, 2);
    
    // 10 + 20 + 12 = 42
    return sum;
}
