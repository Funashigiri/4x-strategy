package game

import "core:testing"

@(test)
test_neighbor_count :: proc(t: ^testing.T) {
	m := map_make(10, 8)
	defer map_destroy(&m)

	buf: [6]Hex
	// Углы: чётные строки прижаты влево, нечётные сдвинуты вправо.
	testing.expect_value(t, len(map_neighbors(m, hex_from_offset(0, 0), &buf)), 2)
	testing.expect_value(t, len(map_neighbors(m, hex_from_offset(9, 0), &buf)), 3)
	testing.expect_value(t, len(map_neighbors(m, hex_from_offset(0, 7), &buf)), 3)
	testing.expect_value(t, len(map_neighbors(m, hex_from_offset(9, 7), &buf)), 2)
	// Середина карты.
	testing.expect_value(t, len(map_neighbors(m, hex_from_offset(5, 4), &buf)), 6)
}

@(test)
test_neighbors_symmetric :: proc(t: ^testing.T) {
	m := map_make(10, 8)
	defer map_destroy(&m)

	buf, back: [6]Hex
	for row in i32(0) ..< m.height {
		for col in i32(0) ..< m.width {
			h := hex_from_offset(col, row)
			for nb in map_neighbors(m, h, &buf) {
				found := false
				for x in map_neighbors(m, nb, &back) {
					if x == h do found = true
				}
				testing.expectf(t, found, "%v is a neighbor of %v, but not vice versa", nb, h)
			}
		}
	}
}

@(test)
test_demo_island :: proc(t: ^testing.T) {
	m := map_make(40, 24)
	defer map_destroy(&m)
	map_fill_demo_island(&m)

	// На демо-карте должен встретиться каждый тип местности.
	seen: bit_set[Terrain]
	for tile in m.tiles do seen += {tile.terrain}
	testing.expectf(t, seen == ~bit_set[Terrain]{}, "missing terrain: %v", ~seen)

	testing.expect_value(t, map_get(m, hex_from_offset(20, 12)).terrain, Terrain.Mountains)
	testing.expect_value(t, map_get(m, hex_from_offset(0, 0)).terrain, Terrain.Ocean)
	testing.expect_value(t, map_get(m, hex_from_offset(39, 23)).terrain, Terrain.Ocean)
}

@(test)
test_terrain_names :: proc(t: ^testing.T) {
	for name, terrain in TERRAIN_NAMES {
		testing.expectf(t, len(name) > 0, "%v has no name", terrain)
	}
}

@(test)
test_map_get :: proc(t: ^testing.T) {
	m := map_make(10, 8)
	defer map_destroy(&m)

	testing.expect(t, map_get(m, hex_from_offset(0, 0)) != nil)
	testing.expect(t, map_get(m, hex_from_offset(9, 7)) != nil)
	testing.expect(t, map_get(m, hex_from_offset(10, 0)) == nil)
	testing.expect(t, map_get(m, hex_from_offset(0, -1)) == nil)
	testing.expect(t, map_get(m, hex_from_offset(0, 8)) == nil)
	testing.expect_value(t, map_get(m, {0, 0}).terrain, Terrain.Ocean)
}
