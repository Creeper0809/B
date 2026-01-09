// Phase 3.5: property hooks @[getter]/@[setter] + raw access self->$field

struct Player {
	@[getter]
	@[setter]
	hp: u64;
};

func main() {
	var p: Player;
	p.hp = 7;
	if (p.hp == 7) {
		print("ok\n");
		return 0;
	}
	print("bad\n");
	return 1;
}
