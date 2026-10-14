package game

import "core:testing"

@(test)
test_start_position :: proc(t: ^testing.T) {
	m := map_make(40, 24)
	defer map_destroy(&m)
	center := hex_from_offset(m.width / 2, m.height / 2)

	for seed in i64(1) ..= 30 {
		map_generate(&m, seed)
		pos, ok := find_start_position(m)
		testing.expectf(t, ok, "seed %v: no start position", seed)
		testing.expectf(t, terrain_is_passable(map_get(m, pos).terrain), "seed %v: start on %v", seed, map_get(m, pos).terrain)

		// Ни одной проходимой клетки ближе к центру.
		best := hex_distance(pos, center)
		for tile, i in m.tiles {
			h := hex_from_offset(i32(i) % m.width, i32(i) / m.width)
			if terrain_is_passable(tile.terrain) {
				testing.expectf(t, hex_distance(h, center) >= best, "seed %v: %v is closer than %v", seed, h, pos)
			}
		}
	}
}

@(test)
test_start_position_no_land :: proc(t: ^testing.T) {
	m := map_make(10, 8) // по умолчанию всё — океан
	defer map_destroy(&m)
	_, ok := find_start_position(m)
	testing.expect(t, !ok)
}

@(test)
test_unit_at :: proc(t: ^testing.T) {
	units := []Unit{{.Warrior, {1, 2}}, {.Warrior, {3, 4}}}
	testing.expect(t, unit_at(units, {3, 4}) == &units[1])
	testing.expect(t, unit_at(units, {0, 0}) == nil)
}
