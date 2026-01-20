// Test: Linked list with struct pointers
// Expect exit code: 42

struct Node {
    value: u64;
    next: u64;  // Will store pointer as u64
}

func main(argc, argv) {
    var n1: Node;
    var n2: Node;
    var n3: Node;
    
    // Set values
    n1.value = 10;
    n2.value = 15;
    n3.value = 17;
    
    // Link nodes using pointers stored as u64
    n1.next = &n2;
    n2.next = &n3;
    n3.next = 0;
    
    // Traverse and sum
    var sum: u64;
    sum = 0;
    
    var current: *Node;
    current = &n1;
    
    while (current != 0) {
        sum = sum + current->value;
        // Get next pointer
        var next_addr = current->next;
        current = next_addr;
    }
    
    return sum;  // 10 + 15 + 17 = 42
}
