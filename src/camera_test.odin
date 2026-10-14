package game

import "core:math/linalg"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_camera_zoom_keeps_anchor :: proc(t: ^testing.T) {
	cam := rl.Camera2D{offset = {640, 360}, target = {100, 50}, zoom = 1}

	// Точка мира под курсором не сдвигается ни при приближении, ни при отдалении.
	for zoom in ([]f32{2.5, 0.7, 1.3}) {
		anchor := rl.Vector2{200, 500}
		before := rl.GetScreenToWorld2D(anchor, cam)
		camera_zoom_at(&cam, anchor, zoom)
		after := rl.GetScreenToWorld2D(anchor, cam)

		testing.expect_value(t, cam.zoom, zoom)
		testing.expectf(t, linalg.distance(before, after) < 0.01, "zoom %v: %v moved to %v", zoom, before, after)
	}
}

@(test)
test_camera_zoom_clamped :: proc(t: ^testing.T) {
	cam := rl.Camera2D{offset = {640, 360}, zoom = 1}

	camera_zoom_at(&cam, {0, 0}, 100)
	testing.expect_value(t, cam.zoom, CAMERA_ZOOM_MAX)

	camera_zoom_at(&cam, {0, 0}, 0.01)
	testing.expect_value(t, cam.zoom, CAMERA_ZOOM_MIN)
}
