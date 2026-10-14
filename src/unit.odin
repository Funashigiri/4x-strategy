package game

Unit_Kind :: enum u8 {
	Warrior,
}

@(rodata)
UNIT_NAMES := [Unit_Kind]string {
	.Warrior = "Воин",
}

// Очки движения за ход.
@(rodata)
UNIT_MOVES := [Unit_Kind]i32 {
	.Warrior = 2,
}

Unit :: struct {
	kind:       Unit_Kind,
	pos:        Hex,
	moves_left: i32, // сколько очков движения осталось на этот ход
}

unit_make :: proc(kind: Unit_Kind, pos: Hex) -> Unit {
	return {kind = kind, pos = pos, moves_left = UNIT_MOVES[kind]}
}

unit_index_at :: proc(units: []Unit, h: Hex) -> (index: int, ok: bool) {
	for u, i in units {
		if u.pos == h do return i, true
	}
	return
}

// Юнит на гексе или nil.
unit_at :: proc(units: []Unit, h: Hex) -> ^Unit {
	if i, ok := unit_index_at(units, h); ok do return &units[i]
	return nil
}

// Какой юнит выбрать по клику на гекс: индекс юнита на нём, иначе nil (снять выбор).
pick_unit :: proc(units: []Unit, clicked: Maybe(Hex)) -> Maybe(int) {
	if h, ok := clicked.?; ok {
		if i, found := unit_index_at(units, h); found do return i
	}
	return nil
}

// Может ли юнит сходить на гекс: остались очки движения,
// гекс соседний, проходимый и не занят другим юнитом.
can_move_to :: proc(world: Map, units: []Unit, unit_index: int, target: Hex) -> bool {
	if units[unit_index].moves_left <= 0 do return false
	if hex_distance(units[unit_index].pos, target) != 1 do return false
	tile := map_get(world, target)
	if tile == nil || !terrain_is_passable(tile.terrain) do return false
	_, occupied := unit_index_at(units, target)
	return !occupied
}

// Сходить на соседний гекс (проверять заранее через can_move_to).
// Как в Civ 5: если очков меньше стоимости местности, войти всё равно можно —
// просто потратятся все оставшиеся.
move_unit :: proc(world: Map, unit: ^Unit, target: Hex) {
	cost := TERRAIN_MOVE_COST[map_get(world, target).terrain]
	unit.pos = target
	unit.moves_left = max(0, unit.moves_left - cost)
}

// Стартовая клетка: проходимая суша, ближайшая к центру карты.
// ok = false, если суши нет вовсе.
find_start_position :: proc(world: Map) -> (pos: Hex, ok: bool) {
	center := hex_from_offset(world.width / 2, world.height / 2)
	best := max(i32)
	for tile, i in world.tiles {
		if !terrain_is_passable(tile.terrain) do continue
		h := hex_from_offset(i32(i) % world.width, i32(i) / world.width)
		if d := hex_distance(h, center); d < best {
			best, pos, ok = d, h, true
		}
	}
	return
}
