package game

import rl "vendor:raylib"

HEX_SIZE   :: 16
MAP_ORIGIN :: rl.Vector2{40, 100} // где на экране центр гекса (0, 0); заменит камера в 0.004

HEX_OUTLINE_COLOR :: rl.Color{24, 56, 96, 255}

@(rodata)
TERRAIN_COLORS := [Terrain]rl.Color {
	.Ocean = {38, 84, 140, 255},
}

draw_map :: proc(world: Map) {
	for row in 0 ..< world.height {
		for col in 0 ..< world.width {
			h := hex_from_offset(col, row)
			tile := map_get(world, h)
			center := MAP_ORIGIN + hex_to_pixel(h, HEX_SIZE)

			// В raylib поворот 30° делает гекс "вершиной вверх".
			rl.DrawPoly(center, 6, HEX_SIZE, 30, TERRAIN_COLORS[tile.terrain])
			rl.DrawPolyLines(center, 6, HEX_SIZE, 30, HEX_OUTLINE_COLOR)
		}
	}
}
