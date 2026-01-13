// 59_struct_linked_list_copy.b - 연결 리스트 노드 복사
// Expect exit code: 42

struct Node {
    value: i64;
    next: *Node;
}

func main(argc, argv) {
    var n1: Node;
    var n2: Node;
    var n3: Node;
    
    n1.value = 10;
    n1.next = &n2;
    
    n2.value = 20;
    n2.next = &n3;
    
    n3.value = 12;
    n3.next = 0;
    
    // 첫 번째 노드 복사
    var n1_copy: Node;
    n1_copy = n1;
    
    // 복사본을 통해 순회 (포인터는 같은 노드들을 가리킴)
    // n1_copy.value + n1_copy.next->value + n1_copy.next->next->value
    // = 10 + 20 + 12 = 42
    return n1_copy.value + n1_copy.next->value + n1_copy.next->next->value;
}
