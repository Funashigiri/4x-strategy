package game

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

// Карта хранится прямоугольником в offset-координатах "odd-r":
// нечётные строки сдвинуты на полгекса вправо.
hex_from_offset :: proc(col, row: i32) -> Hex {
	return {col - (row - (row & 1)) / 2, row}
}

hex_to_offset :: proc(h: Hex) -> (col, row: i32) {
	return h.q + (h.r - (h.r & 1)) / 2, h.r
}
