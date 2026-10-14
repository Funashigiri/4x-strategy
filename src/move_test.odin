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

	append(&game.units, unit_make(.Warrior, u), unit_make(.Warrior, hex_neighbor(u, .NE)))
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
	units := []Unit{unit_make(.Warrior, corner)}
	testing.expect(t, !can_move_to(game.world, units, 0, hex_neighbor(corner, .W)))
}

@(test)
test_move_costs :: proc(t: ^testing.T) {
	game := make_move_test_game()
	defer destroy_move_test_game(&game)
	units := game.units[:]
	u := units[0].pos
	testing.expect_value(t, units[0].moves_left, UNIT_MOVES[.Warrior])

	// Луга стоят 1: было 2, стало 1.
	move_unit(game.world, &units[0], hex_neighbor(u, .E))
	testing.expect_value(t, units[0].moves_left, 1)

	// Обратно на луга — 0, и ходить больше нельзя никуда.
	move_unit(game.world, &units[0], u)
	testing.expect_value(t, units[0].moves_left, 0)
	for dir in Hex_Direction {
		testing.expectf(t, !can_move_to(game.world, units, 0, hex_neighbor(u, dir)), "moved %v with 0 moves", dir)
	}

	// Лес стоит 2: с полными очками — сразу 0.
	units[0].moves_left = 2
	move_unit(game.world, &units[0], hex_neighbor(u, .NW))
	testing.expect_value(t, units[0].moves_left, 0)

	// Правило Civ 5: с 1 очком в холмы (стоимость 2) войти можно, очков станет 0.
	units[0] = unit_make(.Warrior, u)
	units[0].moves_left = 1
	testing.expect(t, can_move_to(game.world, units, 0, hex_neighbor(u, .SW)))
	move_unit(game.world, &units[0], hex_neighbor(u, .SW))
	testing.expect_value(t, units[0].moves_left, 0)
}

@(test)
test_terrain_move_cost :: proc(t: ^testing.T) {
	// Проходимо (стоимость > 0) ровно то же, что раньше: суша, кроме гор.
	for terrain in Terrain {
		expected := !terrain_is_water(terrain) && terrain != .Mountains
		testing.expectf(t, terrain_is_passable(terrain) == expected, "%v: cost %v", terrain, TERRAIN_MOVE_COST[terrain])
	}
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
