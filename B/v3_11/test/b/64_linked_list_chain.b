// 64_linked_list_chain.b - 여러 리스트 체인 테스트
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

func list_len(list) -> i64 {
    return *(list + 16);
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

// 리스트의 모든 값 합계
func list_sum(list) -> i64 {
    var sum = 0;
    var head = *(list);
    var current = head;
    
    while (current != 0) {
        sum = sum + *(current);
        current = *(current + 8);
    }
    
    return sum;
}

func main(argc, argv) {
    // 여러 개의 리스트 생성
    var list1 = list_new();
    var list2 = list_new();
    var list3 = list_new();
    
    // list1: 10, 5
    list_append(list1, 10);
    list_append(list1, 5);
    
    // list2: 12, 8
    list_append(list2, 12);
    list_append(list2, 8);
    
    // list3: 3, 4
    list_append(list3, 3);
    list_append(list3, 4);
    
    // 각 리스트의 합
    var sum1 = list_sum(list1);  // 15
    var sum2 = list_sum(list2);  // 20
    var sum3 = list_sum(list3);  // 7
    
    // 전체 합: 15 + 20 + 7 = 42
    return sum1 + sum2 + sum3;
}
