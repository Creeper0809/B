// Phase 6.6: Test floating-point comparison operators returning bool
func main() {
	var x: f64 = 3.14;
	var y: f64 = 2.0;
	
	// Test greater-than
	var gt: bool = x > y;
	print(gt);  // Should print 1
	print("\n");
	
	// Test less-than
	var lt: bool = x < y;
	print(lt);  // Should print 0
	print("\n");
	
	// Test equality
	var eq: bool = x == y;
	print(eq);  // Should print 0
	print("\n");
	
	// Test inequality
	var neq: bool = x != y;
	print(neq);  // Should print 1
	print("\n");
	
	// Test greater-than-or-equal
	var gte1: bool = x >= y;
	print(gte1);  // Should print 1
	print("\n");
	
	var gte2: bool = x >= x;
	print(gte2);  // Should print 1
	print("\n");
	
	// Test less-than-or-equal
	var lte1: bool = y <= x;
	print(lte1);  // Should print 1
	print("\n");
	
	var lte2: bool = x <= x;
	print(lte2);  // Should print 1
	print("\n");
	
	return 0;
}
