package game

import "core:math"

// Гекс в осевых (axial) координатах. Гексы "pointy-top" (вершиной вверх).
// Третья, кубическая, координата вычисляется: s = -q - r.
// Подробно про гексовую математику: https://www.redblobgames.com/grids/hexagons/
Hex :: struct {
	q, r: i32,
}

// Направления к шести соседям (ось r смотрит вниз-вправо).
Hex_Direction :: enum u8 {
	E,
	NE,
	NW,
	W,
	SW,
	SE,
}

@(rodata)
HEX_DIRECTIONS := [Hex_Direction]Hex {
	.E  = {+1,  0},
	.NE = {+1, -1},
	.NW = { 0, -1},
	.W  = {-1,  0},
	.SW = {-1, +1},
	.SE = { 0, +1},
}

hex_add :: proc(a, b: Hex) -> Hex {
	return {a.q + b.q, a.r + b.r}
}

hex_neighbor :: proc(h: Hex, dir: Hex_Direction) -> Hex {
	return hex_add(h, HEX_DIRECTIONS[dir])
}

// Центр гекса в пикселях относительно центра гекса (0, 0).
// size — радиус гекса (от центра до вершины).
hex_to_pixel :: proc(h: Hex, size: f32) -> [2]f32 {
	q, r := f32(h.q), f32(h.r)
	return {
		size * math.SQRT_THREE * (q + r / 2),
		size * 1.5 * r,
	}
}

// Гекс, в который попадает точка (обратное к hex_to_pixel).
hex_from_pixel :: proc(p: [2]f32, size: f32) -> Hex {
	q := (math.SQRT_THREE / 3 * p.x - p.y / 3) / size
	r := (2.0 / 3 * p.y) / size
	return hex_round(q, r)
}

// Округляет дробные осевые координаты до ближайшего гекса.
// Округлять q и r по отдельности нельзя — у границ получится чужой гекс.
// Поэтому округляем все три кубические координаты и чиним ту, что ушла дальше всех.
hex_round :: proc(q, r: f32) -> Hex {
	s := -q - r
	rq, rr, rs := math.round(q), math.round(r), math.round(s)
	dq, dr, ds := abs(rq - q), abs(rr - r), abs(rs - s)
	if dq > dr && dq > ds {
		rq = -rr - rs
	} else if dr > ds {
		rr = -rq - rs
	}
	return {i32(rq), i32(rr)}
}

// Карта хранится прямоугольником в offset-координатах "odd-r":
// нечётные строки сдвинуты на полгекса вправо.
hex_from_offset :: proc(col, row: i32) -> Hex {
	return {col - (row - (row & 1)) / 2, row}
}

hex_to_offset :: proc(h: Hex) -> (col, row: i32) {
	return h.q + (h.r - (h.r & 1)) / 2, h.r
}
