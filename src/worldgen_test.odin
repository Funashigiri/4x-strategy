package game

import "core:slice"
import "core:testing"

@(test)
test_generate_deterministic :: proc(t: ^testing.T) {
	a := map_make(40, 24)
	defer map_destroy(&a)
	b := map_make(40, 24)
	defer map_destroy(&b)

	map_generate(&a, 123)
	map_generate(&b, 123)
	testing.expect(t, slice.equal(a.tiles, b.tiles), "same seed must give the same map")

	map_generate(&b, 124)
	testing.expect(t, !slice.equal(a.tiles, b.tiles), "different seeds should give different maps")
}

@(test)
test_generate_properties :: proc(t: ^testing.T) {
	m := map_make(40, 24)
	defer map_destroy(&m)

	buf: [6]Hex
	for seed in i64(1) ..= 30 {
		map_generate(&m, seed)

		land := 0
		seen: bit_set[Terrain]
		for tile in m.tiles {
			seen += {tile.terrain}
			if !terrain_is_water(tile.terrain) do land += 1
		}

		// Доля суши — ровно по LAND_SHARE (пороги по перцентилям).
		share := f32(land) / f32(len(m.tiles))
		testing.expectf(t, abs(share - LAND_SHARE) < 0.01, "seed %v: land share %v", seed, share)

		// Встречаются все типы местности.
		testing.expectf(t, seen == ~bit_set[Terrain]{}, "seed %v: missing %v", seed, ~seen)

		for &tile, i in m.tiles {
			col, row := i32(i) % m.width, i32(i) / m.width
			h := hex_from_offset(col, row)

			// По краям карты — только вода.
			if col == 0 || row == 0 || col == m.width - 1 || row == m.height - 1 {
				testing.expectf(t, terrain_is_water(tile.terrain), "seed %v: land on edge at %v", seed, h)
			}

			// Мелководье — ровно та вода, что граничит с сушей.
			if terrain_is_water(tile.terrain) {
				near_land := false
				for nb in map_neighbors(m, h, &buf) {
					if !terrain_is_water(map_get(m, nb).terrain) do near_land = true
				}
				testing.expectf(t, (tile.terrain == .Coast) == near_land, "seed %v: %v is %v, near land: %v", seed, h, tile.terrain, near_land)
			}
		}
	}
}
