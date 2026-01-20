// Test 58: SSA inline asm smoke
// Mode: ssa
// Expect exit code: 0

func main() -> i64 {
    asm {
        nop
    }
    return 0;
}
