package game

import rl "vendor:raylib"

VERSION :: "0.004"
TITLE   :: "4X Strategy v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

MAP_WIDTH  :: 40
MAP_HEIGHT :: 24

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

Game :: struct {
	world:  Map,
	camera: rl.Camera2D,
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
}

draw :: proc(game: Game) {
	rl.ClearBackground(BACKGROUND_COLOR)

	// Мир — через камеру.
	rl.BeginMode2D(game.camera)
	draw_map(game.world)
	rl.EndMode2D()

	// Интерфейс — поверх, в экранных координатах.
	// Стандартный шрифт raylib не знает кириллицу, поэтому текст на экране пока по-английски.
	rl.DrawText(TITLE, 10, 10, 20, rl.RAYWHITE)
	rl.DrawFPS(10, 36)
	rl.DrawText(
		rl.TextFormat("Map: %dx%d hexes   Zoom: x%.2f", game.world.width, game.world.height, game.camera.zoom),
		10, 60, 20, rl.LIGHTGRAY,
	)
	rl.DrawText("WASD / arrows / right mouse drag - move,  wheel - zoom", 10, rl.GetScreenHeight() - 30, 20, rl.LIGHTGRAY)
}
