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

RECHARGE_PARTICLE_RADIUS :: 5
FUEL_PER_RECHARGE_PARTICLE :: 25

WORLD_SIZE :: 6000
WALL_THICKNESS :: 250

Player :: struct
{
	center: linalg.Vector2f32,
	collision_radius: f32,

	max_vel_x: f32,
	max_vel_y_up: f32,
	max_vel_y_down: f32,
	vel: linalg.Vector2f32,
	accel: linalg.Vector2f32,

	fuel: f32,
	max_fuel: f32,
	fuel_reduce_rate: f32,  // how much fuel is reduced per second
}

Recharge_Particle :: struct
{
	center: linalg.Vector2f32,
}

Asteroid_Type :: enum{ SMALL, MEDIUM, BIG }
Asteroid :: struct
{
	type: Asteroid_Type,
	center: linalg.Vector2f32,
	lin_vel: linalg.Vector2f32,
	ang_vel: f32,  // amount the asteroid rotate per second (in degrees)
	rotation: f32,
}

ASTEROID_RADIUS := [Asteroid_Type]f32{
	.SMALL  = 20,
	.MEDIUM = 40,
	.BIG    = 55,
}
ASTEROID_TEXTURE := [Asteroid_Type]asset.Texture_ID{
	.SMALL  = .SMALL_ASTEROID,
	.MEDIUM = .MEDIUM_ASTEROID,
	.BIG    = .BIG_ASTEROID,
}

Data :: struct
{
	fb: rl.RenderTexture,
	camera: rl.Camera2D,

	player: Player,

	// TODO: more particles on earlier days
	recharge_particles: [dynamic]Recharge_Particle,

	asteroids: [dynamic]Asteroid,
}

init :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rand.set_global_seed(u64(time.time_to_unix(time.now())))

	asset.load_texture(..REQUIRED_TEXTURES)

	this.fb = rl.LoadRenderTexture(rl.GetScreenWidth()/SCALE, rl.GetScreenHeight()/SCALE)

	this.camera.zoom = 1.0
	this.camera.offset = { f32(rl.GetScreenWidth())*0.5/SCALE, f32(rl.GetScreenHeight())*0.5/SCALE }

	this.player.collision_radius = 14.0
	this.player.max_vel_x = 160.0
	this.player.max_vel_y_up = -200
	this.player.max_vel_y_down = 600
	this.player.accel = { 225, -750 }
	this.player.max_fuel = 100.0
	this.player.fuel = this.player.max_fuel
	this.player.fuel_reduce_rate = 5.0

	for i in 0..<256
	{
		append(&this.recharge_particles, Recharge_Particle{
			center = {
				rand.float32_range(-WORLD_SIZE*0.5 + RECHARGE_PARTICLE_RADIUS, WORLD_SIZE*0.5 - RECHARGE_PARTICLE_RADIUS),
				rand.float32_range(-WORLD_SIZE*0.5 + RECHARGE_PARTICLE_RADIUS, WORLD_SIZE*0.5 - RECHARGE_PARTICLE_RADIUS),
			},
		})
	}

	for i in 0..<128
	{
		append(&this.asteroids, Asteroid{
			type = rand.choice_enum(Asteroid_Type),
			center = {
				rand.float32_range(-WORLD_SIZE*0.5 + ASTEROID_RADIUS[.BIG], WORLD_SIZE*0.5 - ASTEROID_RADIUS[.BIG]),
				rand.float32_range(-WORLD_SIZE*0.5 + ASTEROID_RADIUS[.BIG], WORLD_SIZE*0.5 - ASTEROID_RADIUS[.BIG]),
			},
			lin_vel = {
				rand.float32_range(-20, 20),
				rand.float32_range(-20, 20),
			},
			ang_vel = rand.float32_range(6, 12),
			rotation = rand.float32_range(0, 360),
		})
	}
}

uninit :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	delete(this.asteroids)
	delete(this.recharge_particles)

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

	// TODO: can this be optimized??
	for i in 0..<len(this.recharge_particles)
	{
		particle := this.recharge_particles[i]
		if rl.CheckCollisionCircles(
			particle.center, RECHARGE_PARTICLE_RADIUS,
			this.player.center, this.player.collision_radius)
		{
			unordered_remove(&this.recharge_particles, i)
			this.player.fuel += FUEL_PER_RECHARGE_PARTICLE
			this.player.fuel = min(this.player.fuel, this.player.max_fuel)
		}
	}

	// TODO: can this be optimized??
	for i in 0..<len(this.asteroids)
	{
		asteroid := &this.asteroids[i]

		asteroid.center += asteroid.lin_vel*dt
		asteroid.rotation += asteroid.ang_vel*dt

		asteroid_radius := ASTEROID_RADIUS[asteroid.type]

		if rl.CheckCollisionCircles(
			asteroid.center, asteroid_radius,
			this.player.center, this.player.collision_radius)
		{
			this.player.fuel -= 10.0
			dir_to_player := linalg.normalize0(this.player.center - asteroid.center)
			this.player.center = asteroid.center + dir_to_player*(asteroid_radius + this.player.collision_radius)
			this.player.vel = dir_to_player*160.0
		}
	}

	if this.player.fuel > 0.0
	{
		this.player.fuel -= this.player.fuel_reduce_rate*dt
	}
}

render :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rl.BeginTextureMode(this.fb)
		rl.ClearBackground(rl.BLANK)

		rl.BeginMode2D(this.camera)

		// // big asteroid
		// rl.DrawCircle(200, 0, 55, rl.MAGENTA)
		// {
		// 	tex := asset.get_texture(.BIG_ASTEROID)
		// 	rl.DrawCircle(200, 0, 55, rl.MAGENTA)
		// 	rl.DrawTexturePro(
		// 		tex,
		// 		{ 0, 0, f32(tex.width), f32(tex.height) },
		// 		{ 200, 0, f32(tex.width), f32(tex.height) },
		// 		{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
		// 		f32(rl.GetTime()*8),
		// 		rl.WHITE)
		// }

		// // medium asteroid
		// rl.DrawCircle(0, 200, 40, rl.MAGENTA)
		// {
		// 	tex := asset.get_texture(.MEDIUM_ASTEROID)
		// 	rl.DrawCircle(0, 200, 40, rl.MAGENTA)
		// 	rl.DrawTexturePro(
		// 		tex,
		// 		{ 0, 0, f32(tex.width), f32(tex.height) },
		// 		{ 0, 200, f32(tex.width), f32(tex.height) },
		// 		{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
		// 		f32(rl.GetTime()*8),
		// 		rl.WHITE)
		// }

		// // small asteroid
		// {
		// 	tex := asset.get_texture(.SMALL_ASTEROID)
		// 	rl.DrawCircle(200, 200, 20, rl.MAGENTA)
		// 	rl.DrawTexturePro(
		// 		tex,
		// 		{ 0, 0, f32(tex.width), f32(tex.height) },
		// 		{ 200, 200, f32(tex.width), f32(tex.height) },
		// 		{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
		// 		f32(rl.GetTime()*8),
		// 		rl.WHITE)
		// }

		{
			half_size := i32(WORLD_SIZE/2)
			rl.DrawRectangle(-half_size - WALL_THICKNESS, -half_size - WALL_THICKNESS, WORLD_SIZE + WALL_THICKNESS*2, WALL_THICKNESS, rl.MAGENTA) // top
			rl.DrawRectangle(-half_size - WALL_THICKNESS, half_size, WORLD_SIZE + WALL_THICKNESS*2, WALL_THICKNESS, rl.MAGENTA) // bottom
			rl.DrawRectangle(-half_size - WALL_THICKNESS, -half_size, WALL_THICKNESS, WORLD_SIZE, rl.MAGENTA) // left
			rl.DrawRectangle( half_size, -half_size, WALL_THICKNESS, WORLD_SIZE, rl.MAGENTA) // right
		}

		for &asteroid in this.asteroids
		{
			tex := asset.get_texture(ASTEROID_TEXTURE[asteroid.type])
			rl.DrawTexturePro(
				tex,
				{ 0, 0, f32(tex.width), f32(tex.height) },
				{ asteroid.center.x, asteroid.center.y, f32(tex.width), f32(tex.height) },
				{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
				asteroid.rotation,
				rl.WHITE)
		}

		rl.DrawCircleV(this.player.center, this.player.collision_radius, rl.RED)

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
			rl.DrawCircleV(this.recharge_particles[i].center, RECHARGE_PARTICLE_RADIUS, { 96, 156, 79, 255 })
		}

		rl.EndMode2D()

		rl.DrawRectangle(4, 4, 160, 16, { 69, 43, 63, 255 })
		rl.DrawRectangle(4, 4, i32(160.0*(this.player.fuel/this.player.max_fuel)), 16, { 250, 191, 97, 255 })
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
