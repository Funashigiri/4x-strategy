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

UNIT_RADIUS        :: HEX_SIZE * 0.55
UNIT_OUTLINE_COLOR :: rl.Color{20, 20, 20, 255}
UNIT_ICON_COLOR    :: rl.RAYWHITE
PLAYER_COLOR       :: rl.Color{196, 40, 40, 255} // пока игрок один

// Юнит — фишка цвета игрока со значком типа.
draw_units :: proc(units: []Unit) {
	for u in units {
		center := hex_to_pixel(u.pos, HEX_SIZE)
		rl.DrawCircleV(center, UNIT_RADIUS + 1, UNIT_OUTLINE_COLOR)
		rl.DrawCircleV(center, UNIT_RADIUS, PLAYER_COLOR)
		draw_unit_icon(u.kind, center)
	}
}

SELECTION_COLOR   :: rl.RAYWHITE
MOVE_TARGET_COLOR :: rl.Color{255, 255, 255, 170}

// Куда может сходить выбранный юнит — точки в центрах соседних гексов.
draw_move_targets :: proc(world: Map, units: []Unit, unit_index: int) {
	buf: [6]Hex
	for nb in map_neighbors(world, units[unit_index].pos, &buf) {
		if can_move_to(world, units, unit_index, nb) {
			rl.DrawCircleV(hex_to_pixel(nb, HEX_SIZE), HEX_SIZE * 0.2, MOVE_TARGET_COLOR)
		}
	}
}

// Выбранный юнит: белый контур гекса и пульсирующее кольцо вокруг фишки.
draw_selection :: proc(unit: Unit, zoom: f32) {
	center := hex_to_pixel(unit.pos, HEX_SIZE)
	rl.DrawPolyLinesEx(center, 6, HEX_SIZE, 30, 2.5 / zoom, SELECTION_COLOR)

	pulse := 0.5 + 0.5 * math.sin(f32(rl.GetTime()) * 5) // 0..1, меньше раза в секунду
	inner: f32 = UNIT_RADIUS + 1
	rl.DrawRing(center, inner, inner + 2 / zoom, 0, 360, 36, rl.Fade(SELECTION_COLOR, 0.4 + 0.6 * pulse))
}

// Значки рисуются линиями, поэтому чёткие при любом зуме.
draw_unit_icon :: proc(kind: Unit_Kind, c: rl.Vector2) {
	switch kind {
	case .Warrior:
		// Скрещённые мечи: два клинка и две гарды у рукоятей.
		S :: UNIT_RADIUS * 0.55 // полудлина клинка по осям
		G :: S * 0.3            // полуширина гарды
		H :: S * 0.55           // где гарда
		W :: 1.5                // толщина линий
		rl.DrawLineEx(c + {-S, -S}, c + {S, S}, W, UNIT_ICON_COLOR)
		rl.DrawLineEx(c + {S, -S}, c + {-S, S}, W, UNIT_ICON_COLOR)
		rl.DrawLineEx(c + {H - G, H + G}, c + {H + G, H - G}, W, UNIT_ICON_COLOR)
		rl.DrawLineEx(c + {-H - G, H - G}, c + {-H + G, H + G}, W, UNIT_ICON_COLOR)
	}
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
