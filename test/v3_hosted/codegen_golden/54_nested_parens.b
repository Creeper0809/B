// Test nested parentheses and operator precedence

func main() {
	// Test 1: Basic nested parentheses
	var a: i32 = 2;
	var b: i32 = 3;
	var c: i32 = 4;
	
	var result1: i32 = ((a + b) * c);  // (2+3)*4 = 20
	print(result1);
	print("\n");
	
	// Test 2: Multiple levels of nesting
	var result2: i32 = (((a + b) * c) - a);  // ((2+3)*4)-2 = 18
	print(result2);
	print("\n");
	
	// Test 3: Parentheses overriding precedence
	var result3: i32 = a + (b * c);  // 2+(3*4) = 14
	var result4: i32 = (a + b) * c;  // (2+3)*4 = 20
	print(result3);
	print("\n");
	print(result4);
	print("\n");
	
	// Test 4: Complex expression
	var result5: i32 = ((a * b) + (c * a)) - ((b + c) * a);  // (6+8)-(7*2) = 14-14 = 0
	print(result5);
	print("\n");
	
	// Test 5: Parentheses with comparisons
	var result6: i32 = 0;
	if ((a + b) > c && (c * a) < 10) {
		result6 = 1;
	}
	print(result6);  // (2+3)>4 && (4*2)<10 => 5>4 && 8<10 => true && true = true
	print("\n");
	
	// Test 6: Nested logical operations
	var result7: i32 = 0;
	if ((a < b || b > c) && (c > a)) {
		result7 = 1;
	}
	print(result7);  // (2<3 || 3>4) && (4>2) => (true || false) && true => true
	print("\n");
	
	return 0;
}
