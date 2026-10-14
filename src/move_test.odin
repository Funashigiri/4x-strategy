package game

import "core:testing"

// Карта 10×8 (всё океан), юнит 0 в центре, вокруг — по соседу каждого вида.
@(private = "file")
make_move_test_game :: proc() -> Game {
	game: Game
	game.world = map_make(10, 8)
	u := hex_from_offset(4, 4)
	set :: proc(m: Map, h: Hex, t: Terrain) {map_get(m, h).terrain = t}
	set(game.world, u, .Grassland)
	set(game.world, hex_neighbor(u, .E), .Grassland)
	set(game.world, hex_neighbor(u, .W), .Mountains)
	set(game.world, hex_neighbor(u, .NE), .Grassland) // здесь стоит юнит 1
	set(game.world, hex_neighbor(u, .NW), .Forest)
	set(game.world, hex_neighbor(u, .SW), .Hills)
	// .SE остаётся водой.
	set(game.world, hex_neighbor(hex_neighbor(u, .E), .E), .Grassland) // через один гекс

	append(&game.units, Unit{.Warrior, u}, Unit{.Warrior, hex_neighbor(u, .NE)})
	return game
}

@(private = "file")
destroy_move_test_game :: proc(game: ^Game) {
	map_destroy(&game.world)
	delete(game.units)
}

@(test)
test_can_move_to :: proc(t: ^testing.T) {
	game := make_move_test_game()
	defer destroy_move_test_game(&game)
	units := game.units[:]
	u := units[0].pos

	testing.expect(t, can_move_to(game.world, units, 0, hex_neighbor(u, .E)))   // луга
	testing.expect(t, can_move_to(game.world, units, 0, hex_neighbor(u, .NW)))  // лес
	testing.expect(t, can_move_to(game.world, units, 0, hex_neighbor(u, .SW)))  // холмы
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(u, .W)))  // горы
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(u, .SE))) // вода
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(u, .NE))) // занято
	testing.expect(t, !can_move_to(game.world, units, 0, u))                    // на месте
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(hex_neighbor(u, .E), .E))) // далеко
}

@(test)
test_can_move_off_map :: proc(t: ^testing.T) {
	game: Game
	game.world = map_make(10, 8)
	defer map_destroy(&game.world)
	corner := hex_from_offset(0, 0)
	map_get(game.world, corner).terrain = .Grassland
	units := []Unit{{.Warrior, corner}}
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(corner, .W)))
}

@(test)
test_click_hex :: proc(t: ^testing.T) {
	game := make_move_test_game()
	defer destroy_move_test_game(&game)
	start := game.units[0].pos
	east := hex_neighbor(start, .E)

	// Клик по юниту — выбор.
	click_hex(&game, start)
	testing.expect_value(t, game.selected, Maybe(int)(0))

	// Клик по соседней лугам — ход, юнит остаётся выбранным.
	click_hex(&game, east)
	testing.expect_value(t, game.units[0].pos, east)
	testing.expect_value(t, game.selected, Maybe(int)(0))

	// Клик по воде рядом — не ход, а снятие выбора.
	click_hex(&game, hex_neighbor(east, .SE))
	testing.expect_value(t, game.units[0].pos, east)
	testing.expect_value(t, game.selected, Maybe(int)(nil))

	// Клик по другому юниту — выбор его.
	click_hex(&game, game.units[1].pos)
	testing.expect_value(t, game.selected, Maybe(int)(1))

	// Клик мимо карты — снятие выбора.
	click_hex(&game, nil)
	testing.expect_value(t, game.selected, Maybe(int)(nil))
}
