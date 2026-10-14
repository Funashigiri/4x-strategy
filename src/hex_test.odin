package game

import "core:math"
import "core:math/linalg"
import "core:testing"

@(test)
test_offset_round_trip :: proc(t: ^testing.T) {
	for row in i32(-5) ..< 5 {
		for col in i32(-5) ..< 5 {
			c, r := hex_to_offset(hex_from_offset(col, row))
			testing.expect_value(t, c, col)
			testing.expect_value(t, r, row)
		}
	}
}

@(test)
test_hex_to_pixel :: proc(t: ^testing.T) {
	SIZE :: 10

	testing.expect_value(t, hex_to_pixel({0, 0}, SIZE), [2]f32{0, 0})

	// Pointy-top: восточный сосед лежит строго справа.
	east := hex_to_pixel(hex_neighbor({0, 0}, .E), SIZE)
	testing.expect(t, east.x > 0 && east.y == 0)

	// Все шесть соседей на одинаковом расстоянии: sqrt(3) * size.
	h := Hex{3, -2}
	center := hex_to_pixel(h, SIZE)
	for dir in Hex_Direction {
		d := linalg.distance(center, hex_to_pixel(hex_neighbor(h, dir), SIZE))
		testing.expectf(t, abs(d - SIZE * math.SQRT_THREE) < 0.001, "%v: distance %v", dir, d)
	}
}
