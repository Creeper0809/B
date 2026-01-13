// 63_linked_list_reverse.b - 연결 리스트 역순 테스트
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

func list_new() -> *LinkedList {
    var list = heap_alloc(24);
    *(list) = 0;
    *(list + 8) = 0;
    *(list + 16) = 0;
    return list;
}

func list_make_node(value) -> *ListNode {
    var node = heap_alloc(16);
    *(node) = value;
    *(node + 8) = 0;
    return node;
}

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

// 리스트 역순으로 만들기
func list_reverse(list) {
    var head = *(list);
    if (head == 0) { return; }
    
    var prev = 0;
    var current = head;
    var tail = head;
    
    while (current != 0) {
        var next = *(current + 8);
        *(current + 8) = prev;
        prev = current;
        current = next;
    }
    
    *(list) = prev;
    *(list + 8) = tail;
}

func main(argc, argv) {
    var list = list_new();
    
    // 리스트 생성: 5 -> 10 -> 15 -> 12
    list_append(list, 5);
    list_append(list, 10);
    list_append(list, 15);
    list_append(list, 12);
    
    // 역순으로 만들기
    list_reverse(list);
    
    // 이제 리스트: 12 -> 15 -> 10 -> 5
    var v0 = list_get(list, 0);  // 12
    var v1 = list_get(list, 1);  // 15
    var v2 = list_get(list, 2);  // 10
    var v3 = list_get(list, 3);  // 5
    
    // 12 + 15 + 10 + 5 = 42
    return v0 + v1 + v2 + v3;
}
