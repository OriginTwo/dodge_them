package game_scene

import "core:log"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:input_manager"
import "src:asset"
import "src:scene_manager"

SCALE :: 3

PLAYER_ACCEL :: 1.5
PLAYER_MAX_VEL :: linalg.Vector2f32{ 200.0, 1000.0 }
PLAYER_JUMP_STRENGTH :: 150.0
PLAYER_GRAVITY :: 6.0

DOT_RADIUS :: 6

WORLD_SIZE :: 8000
WALL_THICKNESS :: 500

Player :: struct
{
	pos: linalg.Vector2f32,
	size: linalg.Vector2f32,
	vel: linalg.Vector2f32,
}

Dot :: struct
{
	pos: linalg.Vector2f32,
}

Data :: struct
{
	fb: rl.RenderTexture,
	camera: rl.Camera2D,

	player: Player,

	// TODO: more dots should spawn in the more the player level is
	collectible_dots: [256]Dot,
	harmful_dots: [512]Dot,
}

init :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rand.set_global_seed(u64(time.time_to_unix(time.now())))

	asset.load_texture(..REQUIRED_TEXTURES)

	this.fb = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())

	this.camera.zoom = 1.0
	this.camera.offset = { f32(rl.GetScreenWidth())*0.5, f32(rl.GetScreenHeight())*0.5 }

	this.player.size = { 48, 48 }

	for i in 0..<len(this.collectible_dots)
	{
		this.collectible_dots[i].pos = {
			rand.float32_range(-WORLD_SIZE*0.5 + DOT_RADIUS, WORLD_SIZE*0.5 - DOT_RADIUS),
			rand.float32_range(-WORLD_SIZE*0.5 + DOT_RADIUS, WORLD_SIZE*0.5 - DOT_RADIUS),
		}
	}

	for i in 0..<len(this.harmful_dots)
	{
		this.harmful_dots[i].pos = {
			rand.float32_range(-WORLD_SIZE*0.5 + DOT_RADIUS, WORLD_SIZE*0.5 - DOT_RADIUS),
			rand.float32_range(-WORLD_SIZE*0.5 + DOT_RADIUS, WORLD_SIZE*0.5 - DOT_RADIUS),
		}
	}
}

uninit :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rl.UnloadRenderTexture(this.fb)

	asset.unload_texture(..REQUIRED_TEXTURES)
}

update :: proc(_data: rawptr, dt: f32)
{
	this := cast(^Data)_data

	if rl.IsWindowResized()
	{
		rl.UnloadRenderTexture(this.fb)
		this.fb = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
		this.camera.offset = { f32(rl.GetScreenWidth())*0.5, f32(rl.GetScreenHeight())*0.5 }
	}

	this.camera.zoom += rl.GetMouseWheelMove()*0.05

	if input_manager.is_action_pressed(.DEBUG_CHANGE_SCENE)
	{
		scene_manager.change_scene(.TEST)
	}

	action_strength := int(input_manager.is_action_down(.MOVE_RIGHT)) - int(input_manager.is_action_down(.MOVE_LEFT))
	this.player.vel.x += f32(action_strength)*PLAYER_ACCEL

	this.player.vel.y += PLAYER_GRAVITY
	if input_manager.is_action_pressed(.MOVE_JUMP)
	{
		this.player.vel.y -= PLAYER_JUMP_STRENGTH
	}

	// NOTE: doing it like this instead of using array programming because don't
	// want to use shadowing
	this.player.vel.x = clamp(this.player.vel.x, -PLAYER_MAX_VEL.x, PLAYER_MAX_VEL.x)
	this.player.vel.y = clamp(this.player.vel.y, -PLAYER_MAX_VEL.y, PLAYER_MAX_VEL.y)

	this.player.pos += this.player.vel*dt
	this.camera.target += (this.player.pos + this.player.size*0.5 - this.camera.target)*0.1
}

render :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rl.BeginTextureMode(this.fb)
		rl.ClearBackground(rl.BLANK)

		rl.BeginMode2D(this.camera)
		rl.DrawCircle(0, 0, 96, rl.MAGENTA)

		{
			half_size := i32(WORLD_SIZE/2)
			rl.DrawRectangle(-half_size - WALL_THICKNESS, -half_size - WALL_THICKNESS, WORLD_SIZE + WALL_THICKNESS*2, WALL_THICKNESS, rl.MAGENTA) // top
			rl.DrawRectangle(-half_size - WALL_THICKNESS, half_size, WORLD_SIZE + WALL_THICKNESS*2, WALL_THICKNESS, rl.MAGENTA) // bottom
			rl.DrawRectangle(-half_size - WALL_THICKNESS, -half_size, WALL_THICKNESS, WORLD_SIZE, rl.MAGENTA) // left
			rl.DrawRectangle( half_size, -half_size, WALL_THICKNESS, WORLD_SIZE, rl.MAGENTA) // right
		}

		rl.DrawRectangleV(this.player.pos, this.player.size, { 224, 211, 200, 255 })

		for i in 0..<len(this.collectible_dots)
		{
			rl.DrawCircleV(this.collectible_dots[i].pos, DOT_RADIUS, { 96, 156, 79, 255 })
		}

		for i in 0..<len(this.harmful_dots)
		{
			rl.DrawCircleV(this.harmful_dots[i].pos, DOT_RADIUS, { 240, 91, 91, 255 })
		}

		rl.EndMode2D()
	rl.EndTextureMode()

	rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawTexturePro(
			this.fb.texture,
			{ 0, f32(this.fb.texture.height), f32(this.fb.texture.width), -f32(this.fb.texture.height) },
			{ 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
			{ 0, 0 }, 0, rl.WHITE)

		rl.DrawFPS(2, 2)
	rl.EndDrawing()
}
