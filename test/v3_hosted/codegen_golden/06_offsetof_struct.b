struct S {
	a: u8;
	b: u64;
};

func main() {
	return offsetof(S, b);
}
