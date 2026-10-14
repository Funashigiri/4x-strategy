package game

import "core:math"
import "core:testing"

// Прямоугольник карты в точности охватывает крайние гексы.
@(test)
test_map_world_rect :: proc(t: ^testing.T) {
	m := map_make(10, 8)
	defer map_destroy(&m)

	half_width: f32 = HEX_SIZE * math.SQRT_THREE / 2
	min_x, min_y: f32 = math.F32_MAX, math.F32_MAX
	max_x, max_y: f32 = -math.F32_MAX, -math.F32_MAX
	for row in 0 ..< m.height {
		for col in 0 ..< m.width {
			c := hex_to_pixel(hex_from_offset(col, row), HEX_SIZE)
			min_x = min(min_x, c.x - half_width)
			max_x = max(max_x, c.x + half_width)
			min_y = min(min_y, c.y - HEX_SIZE)
			max_y = max(max_y, c.y + HEX_SIZE)
		}
	}

	r := map_world_rect(m)
	EPS :: 0.001
	testing.expectf(t, abs(r.x - min_x) < EPS, "left %v, expected %v", r.x, min_x)
	testing.expectf(t, abs(r.y - min_y) < EPS, "top %v, expected %v", r.y, min_y)
	testing.expectf(t, abs(r.x + r.width - max_x) < EPS, "right %v, expected %v", r.x + r.width, max_x)
	testing.expectf(t, abs(r.y + r.height - max_y) < EPS, "bottom %v, expected %v", r.y + r.height, max_y)
}
