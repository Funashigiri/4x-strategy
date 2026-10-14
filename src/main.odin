package game

import rl "vendor:raylib"

VERSION :: "0.003"
TITLE   :: "4X Strategy v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

MAP_WIDTH  :: 40
MAP_HEIGHT :: 24

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	world := map_make(MAP_WIDTH, MAP_HEIGHT)
	defer map_destroy(&world)

	// Игровой цикл: ввод/логика -> отрисовка. Esc закрывает окно (по умолчанию в raylib).
	for !rl.WindowShouldClose() {
		update(rl.GetFrameTime())

		rl.BeginDrawing()
		draw(world)
		rl.EndDrawing()
	}
}

update :: proc(dt: f32) {
	// Пока пусто: здесь появятся камера, выбор тайла, логика хода.
}

draw :: proc(world: Map) {
	rl.ClearBackground(BACKGROUND_COLOR)

	draw_map(world)

	// Стандартный шрифт raylib не знает кириллицу, поэтому текст на экране пока по-английски.
	rl.DrawText(TITLE, 10, 10, 20, rl.RAYWHITE)
	rl.DrawFPS(10, 36)
	rl.DrawText(rl.TextFormat("Map: %dx%d hexes", world.width, world.height), 10, 60, 20, rl.LIGHTGRAY)
}
