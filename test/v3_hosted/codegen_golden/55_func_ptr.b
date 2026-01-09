// Phase 6.7: Function pointer type test

func add(a: i64, b: i64) -> i64 {
	return a + b;
}

func sub(a: i64, b: i64) -> i64 {
	return a - b;
}

func main() {
	// Step 1: Test function pointer variable
	var f: func(i64, i64) -> i64 = add;
	
	// Step 2: Call through function pointer
	var r1 = f(10, 3);
	print(r1);  // 13
	
	// Step 3: Reassign function pointer
	f = sub;
	var r2 = f(10, 3);
	print(r2);  // 7
	
	return 0;
}
