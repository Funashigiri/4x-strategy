package game

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

CAMERA_PAN_SPEED :: 600 // пикселей экрана в секунду
CAMERA_ZOOM_MIN  :: 0.5
CAMERA_ZOOM_MAX  :: 4.0
CAMERA_ZOOM_STEP :: 0.1 // за одно деление колёсика (логарифмическая шкала)

// Камера смотрит на центр карты, масштаб 1:1.
camera_make :: proc(world: Map) -> rl.Camera2D {
	bounds := map_world_rect(world)
	return {
		offset = screen_center(),
		target = {bounds.x + bounds.width / 2, bounds.y + bounds.height / 2},
		zoom   = 1,
	}
}

camera_update :: proc(cam: ^rl.Camera2D, world: Map, dt: f32) {
	// target (точка мира) всегда в центре экрана, даже после изменения размера окна.
	cam.offset = screen_center()

	// Клавиатура: WASD или стрелки. Скорость постоянна на экране при любом зуме.
	dir: rl.Vector2
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)    do dir.y -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)  do dir.y += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)  do dir.x -= 1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do dir.x += 1
	if dir.x != 0 || dir.y != 0 {
		cam.target += linalg.normalize(dir) * CAMERA_PAN_SPEED * dt / cam.zoom
	}

	// Перетаскивание правой или средней кнопкой мыши (левая пойдёт на выбор гекса).
	if rl.IsMouseButtonDown(.RIGHT) || rl.IsMouseButtonDown(.MIDDLE) {
		cam.target -= rl.GetMouseDelta() / cam.zoom
	}

	// Зум колёсиком к курсору.
	if wheel := rl.GetMouseWheelMove(); wheel != 0 {
		camera_zoom_at(cam, rl.GetMousePosition(), cam.zoom * math.exp(wheel * CAMERA_ZOOM_STEP))
	}

	// Не даём улететь от карты: центр экрана всегда над картой.
	bounds := map_world_rect(world)
	cam.target.x = clamp(cam.target.x, bounds.x, bounds.x + bounds.width)
	cam.target.y = clamp(cam.target.y, bounds.y, bounds.y + bounds.height)
}

// Меняет масштаб так, чтобы точка мира под anchor (экранные координаты) осталась на месте.
camera_zoom_at :: proc(cam: ^rl.Camera2D, anchor: rl.Vector2, zoom: f32) {
	before := rl.GetScreenToWorld2D(anchor, cam^)
	cam.zoom = clamp(zoom, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	after := rl.GetScreenToWorld2D(anchor, cam^)
	cam.target += before - after
}

screen_center :: proc() -> rl.Vector2 {
	return {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())} / 2
}
