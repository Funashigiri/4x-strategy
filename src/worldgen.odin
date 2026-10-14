package game

import "core:math"
import "core:math/noise"
import "core:math/rand"
import "core:slice"

// Пропорции местности. Пороги считаются по перцентилям,
// поэтому доли одинаковы на любом зерне.
LAND_SHARE     :: 0.40 // суша от всей карты
MOUNTAIN_SHARE :: 0.08 // горы от суши
HILLS_SHARE    :: 0.15 // холмы от суши
// Ровная суша делится по влажности (от сухой к влажной), остаток — лес.
DESERT_SHARE    :: 0.15
PLAINS_SHARE    :: 0.30
GRASSLAND_SHARE :: 0.30

// Частота шума в единицах "гекс радиуса 1": меньше — крупнее пятна.
HEIGHT_FREQUENCY   :: 0.05
MOISTURE_FREQUENCY :: 0.08
NOISE_OCTAVES      :: 4

random_seed :: proc() -> i64 {
	return i64(rand.int_max(1_000_000))
}

// Заполняет карту местностью. Одно и то же зерно — одна и та же карта.
map_generate :: proc(world: ^Map, seed: i64) {
	n := len(world.tiles)
	height := make([]f32, n)
	defer delete(height)
	moisture := make([]f32, n)
	defer delete(moisture)

	for i in 0 ..< n {
		col, row := i32(i) % world.width, i32(i) / world.width
		p := hex_to_pixel(hex_from_offset(col, row), 1)
		height[i] = fbm(seed, p * HEIGHT_FREQUENCY) - edge_falloff(world^, col, row)
		moisture[i] = fbm(seed + 1000, p * MOISTURE_FREQUENCY)
	}

	// Уровни высоты.
	sea_level := percentile(height, 1 - LAND_SHARE)
	land_height: [dynamic]f32
	defer delete(land_height)
	for h in height do if h >= sea_level do append(&land_height, h)
	mountain_level := percentile(land_height[:], 1 - MOUNTAIN_SHARE)
	hills_level := percentile(land_height[:], 1 - MOUNTAIN_SHARE - HILLS_SHARE)

	// Уровни влажности — только среди ровной суши.
	flat_moisture: [dynamic]f32
	defer delete(flat_moisture)
	for h, i in height do if h >= sea_level && h < hills_level do append(&flat_moisture, moisture[i])
	desert_level := percentile(flat_moisture[:], DESERT_SHARE)
	plains_level := percentile(flat_moisture[:], DESERT_SHARE + PLAINS_SHARE)
	grassland_level := percentile(flat_moisture[:], DESERT_SHARE + PLAINS_SHARE + GRASSLAND_SHARE)

	for &tile, i in world.tiles {
		h, m := height[i], moisture[i]
		switch {
		case h < sea_level:       tile.terrain = .Ocean
		case h >= mountain_level: tile.terrain = .Mountains
		case h >= hills_level:    tile.terrain = .Hills
		case m < desert_level:    tile.terrain = .Desert
		case m < plains_level:    tile.terrain = .Plains
		case m < grassland_level: tile.terrain = .Grassland
		case:                     tile.terrain = .Forest
		}
	}

	// Мелководье — вода, граничащая с сушей.
	buf: [6]Hex
	for &tile, i in world.tiles {
		if tile.terrain != .Ocean do continue
		col, row := i32(i) % world.width, i32(i) / world.width
		for nb in map_neighbors(world^, hex_from_offset(col, row), &buf) {
			if !terrain_is_water(map_get(world^, nb).terrain) {
				tile.terrain = .Coast
				break
			}
		}
	}
}

// Фрактальный шум: октавы всё мельче и слабее. Результат примерно в [-1, 1].
fbm :: proc(seed: i64, p: [2]f32) -> f32 {
	sum, amplitude, total: f32 = 0, 1, 0
	frequency: f64 = 1
	for octave in 0 ..< NOISE_OCTAVES {
		coord := noise.Vec2{f64(p.x), f64(p.y)} * frequency
		sum += amplitude * noise.noise_2d(seed + i64(octave), coord)
		total += amplitude
		amplitude *= 0.5
		frequency *= 2
	}
	return sum / total
}

// Понижение высоты у краёв карты (до 2 — больше всего размаха шума),
// поэтому по краям всегда океан.
edge_falloff :: proc(world: Map, col, row: i32) -> f32 {
	nx := abs((f32(col) + 0.5) / f32(world.width) * 2 - 1)
	ny := abs((f32(row) + 0.5) / f32(world.height) * 2 - 1)
	return 2 * math.smoothstep(f32(0.6), 1, max(nx, ny))
}

// Значение, меньше которого примерно доля share всех значений.
percentile :: proc(values: []f32, share: f32) -> f32 {
	if len(values) == 0 do return 0
	sorted := slice.clone(values)
	defer delete(sorted)
	slice.sort(sorted)
	return sorted[clamp(int(share * f32(len(sorted))), 0, len(sorted) - 1)]
}
