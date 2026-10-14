package game

import rl "vendor:raylib"

VERSION :: "0.001"
TITLE   :: "4X Strategy v" + VERSION

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720

BACKGROUND_COLOR :: rl.Color{20, 24, 32, 255}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	// Игровой цикл: ввод/логика -> отрисовка. Esc закрывает окно (по умолчанию в raylib).
	for !rl.WindowShouldClose() {
		update(rl.GetFrameTime())

		rl.BeginDrawing()
		draw()
		rl.EndDrawing()
	}
}

update :: proc(dt: f32) {
	// Пока пусто: здесь появятся камера, выбор тайла, логика хода.
}

draw :: proc() {
	rl.ClearBackground(BACKGROUND_COLOR)

	rl.DrawText(TITLE, 10, 10, 20, rl.RAYWHITE)
	rl.DrawFPS(10, 36)
}
