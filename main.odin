package breakout

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

WINDOW_HEIGHT :: 720
WINDOW_WIDTH :: 1280

PLAYER_WIDTH :: 120
PLAYER_HEIGHT :: 16

PLAYER_INITIAL_X :: (WINDOW_WIDTH / 2) - (PLAYER_WIDTH / 2)
PLAYER_INITIAL_Y :: WINDOW_HEIGHT - PLAYER_HEIGHT - 10
PLAYER_SPEED :: 500

BALL_RADIUS :: 10
BALL_INITIAL_X :: (WINDOW_WIDTH / 2)
BALL_INITIAL_Y :: PLAYER_INITIAL_Y - BALL_RADIUS

BRICK_ROWS :: 8
BRICK_COLS :: 16
BRICK_WIDTH :: 60
BRICK_HEIGHT :: 25

BALL_SPEED_START :: 400
BALL_SPEED_MAX :: BALL_SPEED_START * 2
BALL_SPEED_GAIN :: 1.05
MAX_BOUNCE_ANGLE :: 60 * math.PI / 180

Input :: struct {
	move:          f32,
	space_pressed: bool,
}

Ball :: struct {
	pos:    rl.Vector2,
	speed:  rl.Vector2,
	radius: f32,
	color:  rl.Color,
}

Player :: struct {
	pos:   rl.Vector2,
	size:  rl.Vector2,
	color: rl.Color,
}

Brick :: struct {
	pos:   rl.Vector2,
	size:  rl.Vector2,
	color: rl.Color,
	hp:    uint,
}

Game_State :: enum {
	Startup,
	Paused,
	Playing,
	Game_Over,
}

Game :: struct {
	player: Player,
	ball:   Ball,
	bricks: [BRICK_ROWS][BRICK_COLS]Brick,
	state:  Game_State,
	level:  uint,
	score:  uint,
	lives:  uint,
}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "BreakOut")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	game := Game {
		level = 1,
		player = {
			pos = {PLAYER_INITIAL_X, PLAYER_INITIAL_Y},
			size = {PLAYER_WIDTH, PLAYER_HEIGHT},
			color = rl.WHITE,
		},
		ball = {
			pos = {BALL_INITIAL_X, BALL_INITIAL_Y},
			speed = {0, -BALL_SPEED_START},
			radius = BALL_RADIUS,
			color = rl.WHITE,
		},
		lives = 2,
		state = .Startup,
	}
	game.bricks = create_bricks()

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		dt := min(rl.GetFrameTime(), 0.05)

		input := read_input()

		update(&game, input, dt)

		draw(&game)
	}
}

create_bricks :: proc(gap := 5) -> [BRICK_ROWS][BRICK_COLS]Brick {
	bricks: [BRICK_ROWS][BRICK_COLS]Brick

	offset_x := (WINDOW_WIDTH - BRICK_COLS * (BRICK_WIDTH + gap)) / 2
	offset_y := f32(100)

	color := rl.BLUE

	for i in 0 ..< BRICK_ROWS {
		switch i {
		case 2:
			color = rl.GREEN
		case 4:
			color = rl.RED
		case 6:
			color = rl.YELLOW
		}
		for j in 0 ..< BRICK_COLS {
			brick := Brick {
				pos   = {
					f32(offset_x + j * (BRICK_WIDTH + gap)),
					offset_y + f32(i * (BRICK_HEIGHT + gap)),
				},
				size  = {BRICK_WIDTH, BRICK_HEIGHT},
				hp    = 1,
				color = color,
			}
			bricks[i][j] = brick
		}
	}

	return bricks
}

read_input :: proc() -> Input {
	input: Input

	if rl.IsKeyDown(.A) do input.move -= 1
	if rl.IsKeyDown(.D) do input.move += 1

	input.move = clamp(input.move, -1, 1)

	input.space_pressed = rl.IsKeyPressed(.SPACE)

	return input
}

update :: proc(game: ^Game, input: Input, dt: f32) {
	p := &game.player
	b := &game.ball
	bricks := &game.bricks

	if game.state == .Game_Over do return

	move_player(p, input.move, PLAYER_SPEED, dt)

	if game.state == .Startup {
		b.pos.x = p.pos.x + p.size.x / 2

		if input.space_pressed do game.state = .Playing
		return
	}

	move_ball(b, dt)
	if b.pos.y > WINDOW_HEIGHT - b.radius {
		game.lives -= 1
		if game.lives <= 0 {
			game.state = .Game_Over
			return
		}
		x := rl.GetRandomValue(-40, 40)
		game.state = .Startup
		b.pos.y = BALL_INITIAL_Y
		b.pos.x = p.pos.x + p.size.x / 2
		b.speed = {f32(x), -BALL_SPEED_START}
		return
	}

	p_rec := rl.Rectangle{p.pos.x, p.pos.y, p.size.x, p.size.y}
	if b.speed.y > 0 && rl.CheckCollisionCircleRec(b.pos, b.radius, p_rec) {
		bounce_with_player(b, p^)
	}

	brick_col: for &row in bricks {
		for &brick in row {
			if brick.hp == 0 do continue
			rec := rl.Rectangle{brick.pos.x, brick.pos.y, brick.size.x, brick.size.y}
			if rl.CheckCollisionCircleRec(b.pos, b.radius, rec) {
				bounce_with_brick(b, &brick)
				game.score += 1
				break brick_col
			}
		}
	}

}

move_player :: proc(p: ^Player, mov, speed, dt: f32) {
	if mov != 0 do p.pos.x += speed * dt * mov
	if p.pos.x < 0 do p.pos.x = 0
	if p.pos.x + p.size.x > WINDOW_WIDTH do p.pos.x = WINDOW_WIDTH - p.size.x
}

move_ball :: proc(b: ^Ball, dt: f32) {
	b.pos += b.speed * dt

	if b.pos.x < b.radius || b.pos.x > WINDOW_WIDTH - b.radius {
		b.pos.x = b.speed.x < 0 ? b.radius : WINDOW_WIDTH - b.radius
		b.speed.x *= -1
	}
	if b.pos.y < b.radius {
		b.pos.y = b.radius
		b.speed.y *= -1
	}
}

bounce_with_brick :: proc(b: ^Ball, brick: ^Brick) {
	dir := math.sign(b.speed.y)

	b.speed.y *= -1
	// b.pos.y = dir > 0 ? brick.pos.y - b.radius : brick.pos.y + brick.size.y + b.radius

	brick.hp -= 1
}

bounce_with_player :: proc(b: ^Ball, p: Player) {
	center := p.pos.x + p.size.x / 2
	offset := (b.pos.x - center) / (p.size.x / 2)
	offset = clamp(offset, -1, 1)

	angle := offset * MAX_BOUNCE_ANGLE

	// speed := min(linalg.length(b.speed) * BALL_SPEED_GAIN, BALL_SPEED_MAX)
	speed := linalg.length(b.speed)

	b.speed = {speed * math.sin(angle), speed * -math.cos(angle)}
	b.pos.y = p.pos.y - b.radius
}

draw :: proc(game: ^Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	p := game.player
	b := game.ball

	rl.DrawRectangleV(p.pos, p.size, p.color)

	rl.DrawCircleV(b.pos, b.radius, b.color)

	for row in game.bricks {
		for brick in row {
			if brick.hp == 0 do continue
			rec := rl.Rectangle{brick.pos.x, brick.pos.y, BRICK_WIDTH, BRICK_HEIGHT}
			rl.DrawRectangleRec(rec, brick.color)
			// rl.DrawRectangleLinesEx(rec, 1, rl.GRAY)
		}
	}

	rl.DrawText(fmt.ctprint("Score: ", game.score), 50, 40, 40, rl.WHITE)
}
