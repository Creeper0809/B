// Test 74: Switch with enum values
enum State {
    Idle,
    Running,
    Paused,
    Stopped,
}

func main() {
    var current_state = State_Running;
    
    switch (current_state) {
        case State_Idle:
            print_i64(1000);
            print_nl();
            break;
        case State_Running:
            print_i64(2000);
            print_nl();
            break;
        case State_Paused:
            print_i64(3000);
            print_nl();
            break;
        case State_Stopped:
            print_i64(4000);
            print_nl();
            break;
        default:
            print_i64(9999);
            print_nl();
    }
    
    // Test multiple cases
    current_state = State_Idle;
    switch (current_state) {
        case State_Idle:
            print_i64(100);
            print_nl();
            break;
        case State_Stopped:
            print_i64(400);
            print_nl();
            break;
        default:
            print_i64(999);
            print_nl();
    }
    
    return 0;
}
