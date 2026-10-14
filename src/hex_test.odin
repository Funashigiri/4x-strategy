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

@(test)
test_hex_from_pixel :: proc(t: ^testing.T) {
	SIZE :: 10
	INNER_RADIUS :: SIZE * math.SQRT_THREE / 2 // от центра до середины ребра

	for q in i32(-4) ..< 4 {
		for r in i32(-4) ..< 4 {
			h := Hex{q, r}
			center := hex_to_pixel(h, SIZE)

			// Центр гекса.
			testing.expect_value(t, hex_from_pixel(center, SIZE), h)

			// Любая точка внутри вписанной окружности — тот же гекс.
			for deg := f32(0); deg < 360; deg += 15 {
				a := math.to_radians(deg)
				p := center + 0.95 * INNER_RADIUS * [2]f32{math.cos(a), math.sin(a)}
				testing.expectf(t, hex_from_pixel(p, SIZE) == h, "%v at %v deg", h, deg)
			}

			// Чуть дальше середины ребра — уже сосед.
			for dir in Hex_Direction {
				nb := hex_neighbor(h, dir)
				to_nb := linalg.normalize(hex_to_pixel(nb, SIZE) - center)
				p := center + 1.05 * INNER_RADIUS * to_nb
				testing.expectf(t, hex_from_pixel(p, SIZE) == nb, "%v towards %v", h, dir)
			}
		}
	}
}
