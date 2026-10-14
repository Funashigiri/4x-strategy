package game

import rl "vendor:raylib"

VERSION :: "0.005"
TITLE   :: "4X Strategy v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

MAP_WIDTH  :: 40
MAP_HEIGHT :: 24

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

UI_PANEL_COLOR :: rl.Color{0, 0, 0, 150}

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

	game: Game
	game.world = map_make(MAP_WIDTH, MAP_HEIGHT)
	defer map_destroy(&game.world)
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

	// Интерфейс — поверх, в экранных координатах.
	// Стандартный шрифт raylib не знает кириллицу, поэтому текст на экране пока по-английски.
	rl.DrawRectangle(0, 0, 420, 110, UI_PANEL_COLOR)
	rl.DrawText(TITLE, 10, 10, 20, rl.RAYWHITE)
	rl.DrawFPS(10, 36)
	rl.DrawText(
		rl.TextFormat("Map: %dx%d hexes   Zoom: x%.2f", game.world.width, game.world.height, game.camera.zoom),
		10, 60, 20, rl.LIGHTGRAY,
	)
	if h, ok := game.hovered.?; ok {
		col, row := hex_to_offset(h)
		rl.DrawText(rl.TextFormat("Hex: q=%d r=%d  (col %d, row %d)", h.q, h.r, col, row), 10, 84, 20, rl.LIGHTGRAY)
	} else {
		rl.DrawText("Hex: -", 10, 84, 20, rl.LIGHTGRAY)
	}

	HELP :: "WASD / arrows / right mouse drag - move,  wheel - zoom"
	screen_h := rl.GetScreenHeight()
	rl.DrawRectangle(0, screen_h - 36, rl.MeasureText(HELP, 20) + 20, 36, UI_PANEL_COLOR)
	rl.DrawText(HELP, 10, screen_h - 28, 20, rl.LIGHTGRAY)
}
