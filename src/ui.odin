package game

import "core:fmt"
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

Ui_Line :: struct {
	text:  cstring,
	color: rl.Color,
}

// Интерфейс поверх карты, в экранных координатах.
// Строки форматируются во временный аллокатор, он очищается каждый кадр.
draw_ui :: proc(game: Game) {
	lines := make([dynamic]Ui_Line, context.temp_allocator)
	append(&lines, Ui_Line{TITLE, rl.RAYWHITE})
	append(&lines, Ui_Line{fmt.ctprintf("FPS: %d", rl.GetFPS()), rl.LIME})
	append(&lines, Ui_Line{
		fmt.ctprintf("Карта %d×%d   Зерно %d   Масштаб ×%.2f", game.world.width, game.world.height, game.seed, game.camera.zoom),
		rl.LIGHTGRAY,
	})
	if h, ok := game.hovered.?; ok {
		col, row := hex_to_offset(h)
		append(&lines, Ui_Line{fmt.ctprintf("Местность: %s", TERRAIN_NAMES[map_get(game.world, h).terrain]), rl.RAYWHITE})
		if unit := unit_at(game.units[:], h); unit != nil {
			append(&lines, Ui_Line{fmt.ctprintf("Юнит: %s", UNIT_NAMES[unit.kind]), rl.RAYWHITE})
		}
		append(&lines, Ui_Line{fmt.ctprintf("Гекс q=%d r=%d   (столбец %d, строка %d)", h.q, h.r, col, row), rl.LIGHTGRAY})
	} else {
		append(&lines, Ui_Line{"Местность: —", rl.LIGHTGRAY})
	}
	draw_info_panel(lines[:])

	HELP :: "WASD / стрелки / правая кнопка мыши — двигать карту,   колёсико — масштаб,   N — новая карта"
	screen_h := f32(rl.GetScreenHeight())
	rl.DrawRectangleV({0, screen_h - 34}, {measure_text(HELP) + 2 * UI_PADDING, 34}, UI_PANEL_COLOR)
	draw_text(HELP, UI_PADDING, screen_h - 28, rl.LIGHTGRAY)
}

UI_PADDING       :: 10
UI_LINE_HEIGHT   :: 24
UI_PANEL_MIN_WIDTH :: 400 // чтобы панель не дёргалась по ширине при движении мыши

// Панель в левом верхнем углу: по высоте — по числу строк, по ширине — по самой длинной.
draw_info_panel :: proc(lines: []Ui_Line) {
	width: f32 = UI_PANEL_MIN_WIDTH
	for line in lines do width = max(width, measure_text(line.text) + 2 * UI_PADDING)
	height := f32(len(lines)) * UI_LINE_HEIGHT + 14
	rl.DrawRectangleV({0, 0}, {width, height}, UI_PANEL_COLOR)
	for line, i in lines {
		draw_text(line.text, UI_PADDING, 8 + f32(i) * UI_LINE_HEIGHT, line.color)
	}
}
