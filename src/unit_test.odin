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

@(test)
test_pick_unit :: proc(t: ^testing.T) {
	units := []Unit{{.Warrior, {1, 2}}, {.Warrior, {3, 4}}}
	testing.expect_value(t, pick_unit(units, Hex{3, 4}), Maybe(int)(1))
	testing.expect_value(t, pick_unit(units, Hex{1, 2}), Maybe(int)(0))
	testing.expect_value(t, pick_unit(units, Hex{0, 0}), Maybe(int)(nil)) // пустой гекс
	testing.expect_value(t, pick_unit(units, nil), Maybe(int)(nil))       // клик мимо карты
}

@(test)
test_new_map_clears_selection :: proc(t: ^testing.T) {
	game: Game
	game.world = map_make(40, 24)
	defer map_destroy(&game.world)
	defer delete(game.units)

	start_new_map(&game, 1)
	testing.expect_value(t, len(game.units), 1)
	game.selected = 0

	start_new_map(&game, 2)
	testing.expect_value(t, game.selected, Maybe(int)(nil))
	testing.expect_value(t, len(game.units), 1)
}
