package game

import rl "vendor:raylib"

UI_FONT_SIZE   :: 20
UI_PANEL_COLOR :: rl.Color{0, 0, 0, 150}

// Шрифт PT Sans (лицензия OFL, см. assets/fonts/OFL.txt) вшит прямо в exe.
UI_FONT_DATA := #load("../assets/fonts/PT_Sans-Web-Regular.ttf")

ui_font: rl.Font

// Вызывать после InitWindow: шрифт загружается в видеопамять.
ui_init :: proc() {
	// В атлас шрифта попадают только перечисленные символы.
	codepoints: [dynamic]rune
	defer delete(codepoints)
	for r in rune(32) ..= 126 do append(&codepoints, r) // латиница, цифры, знаки
	for r in rune(0x410) ..= 0x44F do append(&codepoints, r) // А..я
	append(&codepoints, 'Ё', 'ё', '×', '—', '«', '»', '…')

	ui_font = rl.LoadFontFromMemory(
		".ttf",
		raw_data(UI_FONT_DATA),
		i32(len(UI_FONT_DATA)),
		UI_FONT_SIZE,
		raw_data(codepoints),
		i32(len(codepoints)),
	)
}

ui_shutdown :: proc() {
	rl.UnloadFont(ui_font)
}

draw_text :: proc(text: cstring, x, y: f32, color: rl.Color) {
	rl.DrawTextEx(ui_font, text, {x, y}, UI_FONT_SIZE, 0, color)
}

measure_text :: proc(text: cstring) -> f32 {
	return rl.MeasureTextEx(ui_font, text, UI_FONT_SIZE, 0).x
}

// Интерфейс поверх карты, в экранных координатах.
draw_ui :: proc(game: Game) {
	rl.DrawRectangle(0, 0, 420, 110, UI_PANEL_COLOR)
	draw_text(TITLE, 10, 8, rl.RAYWHITE)
	draw_text(rl.TextFormat("FPS: %d", rl.GetFPS()), 10, 32, rl.LIME)
	draw_text(
		rl.TextFormat("Карта %d×%d   Масштаб ×%.2f", game.world.width, game.world.height, game.camera.zoom),
		10, 56, rl.LIGHTGRAY,
	)
	if h, ok := game.hovered.?; ok {
		col, row := hex_to_offset(h)
		draw_text(rl.TextFormat("Гекс q=%d r=%d   (столбец %d, строка %d)", h.q, h.r, col, row), 10, 80, rl.LIGHTGRAY)
	} else {
		draw_text("Гекс —", 10, 80, rl.LIGHTGRAY)
	}

	HELP :: "WASD / стрелки / правая кнопка мыши — двигать карту,   колёсико — масштаб"
	screen_h := f32(rl.GetScreenHeight())
	rl.DrawRectangleV({0, screen_h - 34}, {measure_text(HELP) + 20, 34}, UI_PANEL_COLOR)
	draw_text(HELP, 10, screen_h - 28, rl.LIGHTGRAY)
}
