package game

import rl "vendor:raylib"

VERSION :: "0.011"
TITLE   :: "4X Стратегия v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

MAP_WIDTH  :: 40
MAP_HEIGHT :: 24

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

Game :: struct {
	world:   Map,
	seed:    i64, // зерно генерации текущей карты
	units:   [dynamic]Unit,
	camera:   rl.Camera2D,
	hovered:  Maybe(Hex), // гекс под курсором; nil, если курсор не над картой
	selected: Maybe(int), // индекс выбранного юнита в units
	quit:     bool,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL) // Esc обрабатываем сами: сначала снимает выбор

	ui_init()
	defer ui_shutdown()

	game: Game
	game.world = map_make(MAP_WIDTH, MAP_HEIGHT)
	defer map_destroy(&game.world)
	defer delete(game.units)
	start_new_map(&game, random_seed())
	game.camera = camera_make(game.world)

	// Игровой цикл: ввод/логика -> отрисовка.
	for !rl.WindowShouldClose() && !game.quit {
		update(&game, rl.GetFrameTime())

		rl.BeginDrawing()
		draw(game)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}

// Генерирует карту по зерну и заново расставляет юнитов.
start_new_map :: proc(game: ^Game, seed: i64) {
	game.seed = seed
	map_generate(&game.world, seed)

	game.selected = nil
	clear(&game.units)
	if pos, ok := find_start_position(game.world); ok {
		append(&game.units, Unit{kind = .Warrior, pos = pos})
	}
}

update :: proc(game: ^Game, dt: f32) {
	camera_update(&game.camera, game.world, dt)

	if rl.IsKeyPressed(.N) do start_new_map(game, random_seed())

	game.hovered = nil
	if rl.IsCursorOnScreen() {
		mouse_world := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
		h := hex_from_pixel(mouse_world, HEX_SIZE)
		if map_contains(game.world, h) do game.hovered = h
	}

	if rl.IsMouseButtonPressed(.LEFT) do click_hex(game, game.hovered)

	if rl.IsKeyPressed(.ESCAPE) {
		if game.selected != nil {
			game.selected = nil
		} else {
			game.quit = true
		}
	}
}

// Клик левой кнопкой: сходить выбранным юнитом на соседний гекс,
// иначе выбрать юнит на гексе (или снять выбор, если там никого).
click_hex :: proc(game: ^Game, clicked: Maybe(Hex)) {
	i, selected := game.selected.?
	h, on_map := clicked.?
	if selected && on_map && can_move_to(game.world, game.units[:], i, h) {
		game.units[i].pos = h // юнит остаётся выбранным
		return
	}
	game.selected = pick_unit(game.units[:], clicked)
}

draw :: proc(game: Game) {
	rl.ClearBackground(BACKGROUND_COLOR)

	// Мир — через камеру.
	rl.BeginMode2D(game.camera)
	draw_map(game.world)
	if h, ok := game.hovered.?; ok do draw_hex_highlight(h, game.camera.zoom)
	if i, ok := game.selected.?; ok do draw_move_targets(game.world, game.units[:], i)
	draw_units(game.units[:])
	if i, ok := game.selected.?; ok do draw_selection(game.units[i], game.camera.zoom)
	rl.EndMode2D()

	draw_ui(game)
}
