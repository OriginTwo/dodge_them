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

GRAVITY :: 375

DOT_RADIUS :: 3

WORLD_SIZE :: 6000
WALL_THICKNESS :: 250

Player :: struct
{
	center: linalg.Vector2f32,
	size: linalg.Vector2f32,

	max_vel_x: f32,
	max_vel_y_up: f32,
	max_vel_y_down: f32,
	vel: linalg.Vector2f32,
	accel: linalg.Vector2f32,
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

	// TODO: more particles on earlier days
	recharge_particles: [256]Dot,
}

init :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rand.set_global_seed(u64(time.time_to_unix(time.now())))

	asset.load_texture(..REQUIRED_TEXTURES)

	// this.fb = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
	this.fb = rl.LoadRenderTexture(rl.GetScreenWidth()/SCALE, rl.GetScreenHeight()/SCALE)

	this.camera.zoom = 1.0
	// this.camera.offset = { f32(rl.GetScreenWidth())*0.5, f32(rl.GetScreenHeight())*0.5 }
	this.camera.offset = { f32(rl.GetScreenWidth())*0.5/SCALE, f32(rl.GetScreenHeight())*0.5/SCALE }

	// this.player.size = { 48, 48 }
	this.player.size = { 22, 22 }
	this.player.max_vel_x = 160.0
	this.player.max_vel_y_up = -200
	this.player.max_vel_y_down = 600
	// this.player.accel = { 3, -10 }
	this.player.accel = { 225, -750 }

	for i in 0..<len(this.recharge_particles)
	{
		this.recharge_particles[i].pos = {
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
	this.player.vel.x += f32(action_strength)*this.player.accel.x*dt

	this.player.vel.y += GRAVITY*dt
	if input_manager.is_action_down(.MOVE_FLY)
	{
		this.player.vel.y += this.player.accel.y*dt
	}

	this.player.vel.x = clamp(this.player.vel.x, -this.player.max_vel_x, this.player.max_vel_x)
	this.player.vel.y = clamp(this.player.vel.y, this.player.max_vel_y_up, this.player.max_vel_y_down)

	this.player.center += this.player.vel*dt
	this.camera.target += (this.player.center - this.camera.target)*dt*10.0
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

		rl.DrawCircleV(this.player.center, 14, rl.RED)

		{
			pos := this.player.center
			target := this.player.center + this.player.vel
			rot := linalg.atan2(target.y - pos.y, target.x - pos.x)*math.DEG_PER_RAD + 90

			tex := asset.get_texture(.ROCKET)
			rl.DrawTexturePro(
				tex,
				{ 0, 0, f32(tex.width), f32(tex.height) },
				{ pos.x, pos.y, f32(tex.width), f32(tex.height) },
				{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
				rot,
				rl.WHITE)
		}

		for i in 0..<len(this.recharge_particles)
		{
			rl.DrawCircleV(this.recharge_particles[i].pos, DOT_RADIUS, { 96, 156, 79, 255 })
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
