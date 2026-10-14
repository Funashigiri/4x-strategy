package game

import rl "vendor:raylib"

VERSION :: "0.007"
TITLE   :: "4X Стратегия v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

MAP_WIDTH  :: 40
MAP_HEIGHT :: 24

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

Game :: struct {
	world:   Map,
	camera:  rl.Camera2D,
	hovered: Maybe(Hex), // гекс под курсором; nil, если курсор не над картой
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	ui_init()
	defer ui_shutdown()

	game: Game
	game.world = map_make(MAP_WIDTH, MAP_HEIGHT)
	defer map_destroy(&game.world)
	map_fill_demo_island(&game.world)
	game.camera = camera_make(game.world)

	// Игровой цикл: ввод/логика -> отрисовка. Esc закрывает окно (по умолчанию в raylib).
	for !rl.WindowShouldClose() {
		update(&game, rl.GetFrameTime())

		rl.BeginDrawing()
		draw(game)
		rl.EndDrawing()
	}
}

update :: proc(game: ^Game, dt: f32) {
	camera_update(&game.camera, game.world, dt)

	game.hovered = nil
	if rl.IsCursorOnScreen() {
		mouse_world := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
		h := hex_from_pixel(mouse_world, HEX_SIZE)
		if map_contains(game.world, h) do game.hovered = h
	}
}

draw :: proc(game: Game) {
	rl.ClearBackground(BACKGROUND_COLOR)

	// Мир — через камеру.
	rl.BeginMode2D(game.camera)
	draw_map(game.world)
	if h, ok := game.hovered.?; ok do draw_hex_highlight(h, game.camera.zoom)
	rl.EndMode2D()

	draw_ui(game)
}
