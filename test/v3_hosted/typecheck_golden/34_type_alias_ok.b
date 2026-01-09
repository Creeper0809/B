// typecheck golden: alias는 동일 타입

type MyU64 = u64;

type Handle = distinct u64;

func main() {
	var x: MyU64 = 1;
	var h: Handle = cast(Handle, 2);
	print_u64(x);
	print_u64(cast(u64, h));
}
