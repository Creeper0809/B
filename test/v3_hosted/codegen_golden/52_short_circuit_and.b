// Test logical AND operator

func main() {
	// Test basic AND logic
	var result1: i32 = 0;
	if (1 == 1 && 2 == 2) {
		result1 = 1;
	}
	print(result1);  // 1
	print("\n");
	
	var result2: i32 = 0;
	if (1 == 1 && 0 == 1) {
		result2 = 1;
	}
	print(result2);  // 0
	print("\n");
	
	var result3: i32 = 0;
	if (0 == 1 && 2 == 2) {
		result3 = 1;
	}
	print(result3);  // 0
	print("\n");
	
	return 0;
}
