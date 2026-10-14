package game

Unit_Kind :: enum u8 {
	Warrior,
}

@(rodata)
UNIT_NAMES := [Unit_Kind]string {
	.Warrior = "Воин",
}

Unit :: struct {
	kind: Unit_Kind,
	pos:  Hex,
}

// Юнит на гексе или nil.
unit_at :: proc(units: []Unit, h: Hex) -> ^Unit {
	for &u in units {
		if u.pos == h do return &u
	}
	return nil
}

// Стартовая клетка: проходимая суша, ближайшая к центру карты.
// ok = false, если суши нет вовсе.
find_start_position :: proc(world: Map) -> (pos: Hex, ok: bool) {
	center := hex_from_offset(world.width / 2, world.height / 2)
	best := max(i32)
	for tile, i in world.tiles {
		if !terrain_is_passable(tile.terrain) do continue
		h := hex_from_offset(i32(i) % world.width, i32(i) / world.width)
		if d := hex_distance(h, center); d < best {
			best, pos, ok = d, h, true
		}
	}
	return
}
