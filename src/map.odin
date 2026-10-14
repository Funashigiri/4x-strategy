package game

Terrain :: enum u8 {
	Ocean,
	Coast,
	Grassland,
	Plains,
	Desert,
	Forest,
	Hills,
	Mountains,
}

@(rodata)
TERRAIN_NAMES := [Terrain]string {
	.Ocean     = "Океан",
	.Coast     = "Мелководье",
	.Grassland = "Луга",
	.Plains    = "Равнина",
	.Desert    = "Пустыня",
	.Forest    = "Лес",
	.Hills     = "Холмы",
	.Mountains = "Горы",
}

terrain_is_water :: proc(t: Terrain) -> bool {
	return t == .Ocean || t == .Coast
}

// Сколько очков движения стоит войти на местность. 0 — войти нельзя.
@(rodata)
TERRAIN_MOVE_COST := [Terrain]i32 {
	.Ocean     = 0,
	.Coast     = 0,
	.Grassland = 1,
	.Plains    = 1,
	.Desert    = 1,
	.Forest    = 2,
	.Hills     = 2,
	.Mountains = 0,
}

// Может ли наземный юнит стоять на местности: суша, кроме гор.
terrain_is_passable :: proc(t: Terrain) -> bool {
	return TERRAIN_MOVE_COST[t] > 0
}

Tile :: struct {
	terrain: Terrain,
}

Map :: struct {
	width, height: i32,
	tiles:         []Tile, // по строкам: index = row * width + col
}

map_make :: proc(width, height: i32, allocator := context.allocator) -> Map {
	assert(width > 0 && height > 0)
	return {
		width  = width,
		height = height,
		tiles  = make([]Tile, width * height, allocator),
	}
}

map_destroy :: proc(m: ^Map, allocator := context.allocator) {
	delete(m.tiles, allocator)
	m^ = {}
}

map_contains :: proc(m: Map, h: Hex) -> bool {
	col, row := hex_to_offset(h)
	return col >= 0 && col < m.width && row >= 0 && row < m.height
}

// Тайл гекса или nil, если гекс за пределами карты.
map_get :: proc(m: Map, h: Hex) -> ^Tile {
	if !map_contains(m, h) do return nil
	col, row := hex_to_offset(h)
	return &m.tiles[row * m.width + col]
}

// Соседи гекса, лежащие внутри карты. Возвращает срез буфера out.
map_neighbors :: proc(m: Map, h: Hex, out: ^[6]Hex) -> []Hex {
	n := 0
	for dir in Hex_Direction {
		nb := hex_neighbor(h, dir)
		if map_contains(m, nb) {
			out[n] = nb
			n += 1
		}
	}
	return out[:n]
}
