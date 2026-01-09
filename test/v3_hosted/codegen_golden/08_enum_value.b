// Enum member access: Color.Red

enum Color {
	Red,
	Green = 5,
	Blue,
};

func main() {
	return Color.Red + Color.Green + Color.Blue;
}
