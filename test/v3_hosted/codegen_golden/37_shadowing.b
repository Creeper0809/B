// Test: variable shadowing in nested scopes
// Variables in inner scopes with the same name shadow outer variables.
func main() {
	var x = 10;
	print_u64(x);    // 10
	{
		var x = 20;   // shadows outer x
		print_u64(x); // 20
		{
			var x = 30; // shadows middle x
			print_u64(x); // 30
		}
		print_u64(x); // 20 (back to middle x)
	}
	print_u64(x);    // 10 (back to outer x)
}
