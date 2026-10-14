package game

import "core:math"
import rl "vendor:raylib"

HEX_SIZE :: 16 // радиус гекса в мировых пикселях

HEX_OUTLINE_COLOR   :: rl.Color{0, 0, 0, 45} // полупрозрачный — подходит к любой местности
HOVER_FILL_COLOR    :: rl.Color{255, 255, 255, 40}
HOVER_OUTLINE_COLOR :: rl.Color{255, 230, 120, 255}

@(rodata)
TERRAIN_COLORS := [Terrain]rl.Color {
	.Ocean     = {38, 84, 140, 255},
	.Coast     = {66, 130, 182, 255},
	.Grassland = {92, 156, 72, 255},
	.Plains    = {168, 168, 88, 255},
	.Desert    = {222, 200, 132, 255},
	.Forest    = {40, 104, 52, 255},
	.Hills     = {140, 118, 80, 255},
	.Mountains = {150, 146, 142, 255},
}

// Мировые координаты: центр гекса (0, 0) — в начале координат.
draw_map :: proc(world: Map) {
	for row in 0 ..< world.height {
		for col in 0 ..< world.width {
			h := hex_from_offset(col, row)
			tile := map_get(world, h)
			center := hex_to_pixel(h, HEX_SIZE)

			// В raylib поворот 30° делает гекс "вершиной вверх".
			rl.DrawPoly(center, 6, HEX_SIZE, 30, TERRAIN_COLORS[tile.terrain])
			rl.DrawPolyLines(center, 6, HEX_SIZE, 30, HEX_OUTLINE_COLOR)
		}
	}
}

draw_hex_highlight :: proc(h: Hex, zoom: f32) {
	center := hex_to_pixel(h, HEX_SIZE)
	rl.DrawPoly(center, 6, HEX_SIZE, 30, HOVER_FILL_COLOR)
	// Толщина контура — 2 пикселя экрана при любом зуме.
	rl.DrawPolyLinesEx(center, 6, HEX_SIZE, 30, 2 / zoom, HOVER_OUTLINE_COLOR)
}

// Прямоугольник, который карта занимает в мировых координатах.
map_world_rect :: proc(world: Map) -> rl.Rectangle {
	hex_width: f32 = HEX_SIZE * math.SQRT_THREE
	return {
		x      = -hex_width / 2,
		y      = -HEX_SIZE,
		width  = hex_width * (f32(world.width) + 0.5), // +0.5: сдвиг нечётных строк
		height = HEX_SIZE * (1.5 * f32(world.height) + 0.5),
	}
}
