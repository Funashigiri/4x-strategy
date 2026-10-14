package game

DEMO_ISLAND_RADIUS :: 9

// Временная ручная карта: остров в центре, чтобы увидеть все типы местности.
// В 0.008 её заменит процедурная генерация.
map_fill_demo_island :: proc(world: ^Map) {
	center_col, center_row := world.width / 2, world.height / 2
	center := hex_from_offset(center_col, center_row)

	for row in 0 ..< world.height {
		for col in 0 ..< world.width {
			h := hex_from_offset(col, row)
			d := hex_distance(h, center)
			dx := col - center_col
			tile := map_get(world^, h)

			switch {
			case d > DEMO_ISLAND_RADIUS + 1:  tile.terrain = .Ocean
			case d == DEMO_ISLAND_RADIUS + 1: tile.terrain = .Coast
			case d <= 1:                      tile.terrain = .Mountains
			case d <= 3:                      tile.terrain = .Hills
			case dx >= 4:                     tile.terrain = .Desert
			case dx <= -4:                    tile.terrain = .Forest
			case row < center_row:            tile.terrain = .Plains
			case:                             tile.terrain = .Grassland
			}
		}
	}
}
