// parse golden: type alias / distinct

type MyU64 = u64;
public type Handle = distinct u64;

func main() {
	var x: MyU64 = 1;
	var h: Handle = cast(Handle, 2);
	print_u64(x);
	print_u64(cast(u64, h));
}
