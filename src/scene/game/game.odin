package game_scene

import "core:log"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import sarr "core:container/small_array"

import rl "vendor:raylib"

import "src:config"
import "src:input"
import "src:timer"
import "src:asset"
import "src:scene_manager"

import "src:particle"

GRAVITY :: 375

RECHARGE_PARTICLE_RADIUS :: 5
FUEL_PER_RECHARGE_PARTICLE :: 25

WORLD_SIZE :: 6000
WALL_THICKNESS :: 250

Player :: struct
{
	state: enum{ NORMAL, TASK },

	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
	collision_radius: f32,

	rotation: f32,
	prev_rotation: f32,

	max_vel_x: f32,
	max_vel_y_up: f32,
	max_vel_y_down: f32,
	vel: linalg.Vector2f32,
	accel: linalg.Vector2f32,

	fuel: f32,
	max_fuel: f32,
	fuel_reduce_rate: f32,  // how much fuel is reduced per second

	activated_task_device: ^Task_Device,

	fire_emitter: particle.Emitter_Handle,
	smoke_emitter: particle.Emitter_Handle,
}

Recharge_Particle :: struct
{
	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
}

Asteroid_Type :: enum{ SMALL, BIG }
Asteroid :: struct
{
	type: Asteroid_Type,
	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
	lin_vel: linalg.Vector2f32,
	ang_vel: f32,  // amount the asteroid rotate per second (in degrees)
	rotation: f32,
	prev_rotation: f32,
}

ASTEROID_RADIUS := [Asteroid_Type]f32{
	.SMALL  = 20,
	.BIG    = 40,
}
ASTEROID_TEXTURE := [Asteroid_Type]asset.Texture_ID{
	.SMALL  = .SMALL_ASTEROID,
	.BIG    = .BIG_ASTEROID,
}

Data :: struct
{
	fb: rl.RenderTexture,
	camera: rl.Camera2D,

	player: Player,

	recharge_particles: [dynamic]Recharge_Particle,
	asteroids: [dynamic]Asteroid,
	task_devices: sarr.Small_Array(16, Task_Device),

	emitter: particle.Emitter_Handle,
}
this: ^Data

init :: proc(_data: rawptr)
{
	this = cast(^Data)_data

	particle.init_manager()

	rand.set_global_seed(u64(time.time_to_unix(time.now())))

	asset.load_texture(..REQUIRED_TEXTURES)
	asset.load_shader(..REQUIRED_SHADERS)

	this.fb = rl.LoadRenderTexture(config.GAME_WIDTH, config.GAME_HEIGHT)

	this.camera.zoom = 1.0
	this.camera.offset = { config.GAME_WIDTH*0.5, config.GAME_HEIGHT*0.5 }

	this.player.collision_radius = 14.0
	this.player.max_vel_x = 160.0
	this.player.max_vel_y_up = -200
	this.player.max_vel_y_down = 600
	this.player.accel = { 225, -750 }
	this.player.max_fuel = 100.0
	this.player.fuel = this.player.max_fuel
	this.player.fuel_reduce_rate = 5.0

	this.player.fire_emitter = particle.add_emitter({
		z_index = 10,
		particle_shape = .RECTANGLE,
		max_particle_count = 16,
		is_one_shot = false,
		spread = 25,
		min_life_time = 0.3,
		max_life_time = 0.5,
		min_lin_vel = 100,
		max_lin_vel = 200,
		min_angle = 0,
		max_angle = 360,
		min_ang_vel = 80,
		max_ang_vel = 100,
		min_size = 5,
		max_size = 8,
		start_color = rl.YELLOW,
		end_color = rl.MAROON,
	})

	this.player.smoke_emitter = particle.add_emitter({
		z_index = 9,
		particle_shape = .CIRCLE,
		max_particle_count = 16,
		is_one_shot = false,
		spread = 30,
		min_life_time = 0.8,
		max_life_time = 1.0,
		min_lin_vel = 60,
		max_lin_vel = 90,
		min_size = 8,
		max_size = 10,
		start_color = rl.DARKGRAY,
		end_color = rl.LIGHTGRAY,
	})

	particle.start_emission(this.player.smoke_emitter)

	// TODO: better world generation (maybe perlin noise??)

	// TODO: max number decrease as the day increase
	for i in 0..<256
	{
		append(&this.recharge_particles, Recharge_Particle{
			center = {
				rand.float32_range(-WORLD_SIZE*0.5 + RECHARGE_PARTICLE_RADIUS, WORLD_SIZE*0.5 - RECHARGE_PARTICLE_RADIUS),
				rand.float32_range(-WORLD_SIZE*0.5 + RECHARGE_PARTICLE_RADIUS, WORLD_SIZE*0.5 - RECHARGE_PARTICLE_RADIUS),
			},
		})
	}

	// TODO: max number decrease as the day increase
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

	for i in 0..<2
	{
		device: Task_Device
		device.center = { f32(i)*40, 0 }
		device.prev_center = { f32(i)*40, 0 }
		init_task_data(&device, rand.choice_enum(Task_Type))
		sarr.append(&this.task_devices, device)
	}

	this.emitter = particle.add_emitter({
		z_index = 0,
		particle_shape = .SPARK,
		max_particle_count = 32,
		is_one_shot = false,
		dir = { 1, 0 },
		spread = 180,
		min_life_time = 0.5,
		max_life_time = 1.5,
		min_lin_vel = 100,
		max_lin_vel = 200,
		min_angle = 0,
		max_angle = 360,
		min_ang_vel = 60,
		max_ang_vel = 100,
		min_size = 4,
		max_size = 8,
		start_color = rl.MAGENTA,
		end_color = rl.GREEN,
	})
}

uninit :: proc(_data: rawptr)
{
	delete(this.asteroids)
	delete(this.recharge_particles)

	rl.UnloadRenderTexture(this.fb)

	asset.unload_shader(..REQUIRED_SHADERS)
	asset.unload_texture(..REQUIRED_TEXTURES)

	particle.uninit_manager()

	this = nil
}

update :: proc(_data: rawptr, dt: f32)
{
	this.camera.zoom += rl.GetMouseWheelMove()*0.05

	if input.is_action_pressed(.DEBUG_CHANGE_SCENE)
	{
		scene_manager.change_scene(.TEST)
	}

	switch this.player.state
	{
	case .NORMAL:
		action_strength := int(input.is_action_down(.PLAYER_MOVE_RIGHT)) - int(input.is_action_down(.PLAYER_MOVE_LEFT))
		this.player.vel.x += f32(action_strength)*this.player.accel.x*dt

		this.player.vel.y += GRAVITY*dt
		if input.is_action_down(.PLAYER_BOOST)
		{
			this.player.vel.y += this.player.accel.y*dt
			particle.start_emission(this.player.fire_emitter)
		}
		else
		{
			particle.stop_emission(this.player.fire_emitter)
		}

		this.player.vel.x = clamp(this.player.vel.x, -this.player.max_vel_x, this.player.max_vel_x)
		this.player.vel.y = clamp(this.player.vel.y, this.player.max_vel_y_up, this.player.max_vel_y_down)

		if this.player.fuel > 0.0
		{
			this.player.fuel -= this.player.fuel_reduce_rate*dt
		}

		{
			closest_device: ^Task_Device
			closest_dist_sqr: f32 = math.F32_MAX

			for i in 0..<sarr.len(this.task_devices)
			{
				device := sarr.get_ptr(&this.task_devices, i)

				radius := this.player.collision_radius + TASK_DEVICE_INTERACTION_RADIUS
				dist_sqr := linalg.length2(this.player.center - device.center)

				if dist_sqr <= radius*radius && dist_sqr < closest_dist_sqr
				{
					closest_device = device
					closest_dist_sqr = dist_sqr
				}
			}

			if closest_device != nil
			{
				if this.player.activated_task_device != closest_device
				{
					if this.player.activated_task_device != nil
					{
						this.player.activated_task_device.is_activated = false
					}
					this.player.activated_task_device = closest_device
					closest_device.is_activated = true
				}

				if input.is_action_pressed(.PLAYER_INTERACT)
				{
					this.player.state = .TASK
					this.player.vel = {}
				}
			}
			else if this.player.activated_task_device != nil
			{
				this.player.activated_task_device.is_activated = false
				this.player.activated_task_device = nil
			}
		}

		player_vel_dir := linalg.normalize0(this.player.vel)
		player_emit_pos := this.player.center - player_vel_dir*15
		particle.set_emission_pos_dir(this.player.fire_emitter, player_emit_pos, -player_vel_dir)
		particle.set_emission_pos_dir(this.player.smoke_emitter, player_emit_pos, -player_vel_dir)

	case .TASK:
		dist_sqr := linalg.length2(this.player.center - this.player.activated_task_device.center)
		if input.is_action_pressed(.UI_BACK) || dist_sqr > TASK_DEVICE_INTERACTION_RADIUS*TASK_DEVICE_INTERACTION_RADIUS
		{
			this.player.state = .NORMAL
		}

		update_task(this.player.activated_task_device, dt)
	}

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

		asteroid.prev_center = asteroid.center
		asteroid.center += asteroid.lin_vel*dt

		asteroid.prev_rotation = asteroid.rotation
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

	this.player.prev_center = this.player.center
	this.player.center += this.player.vel*dt

	{
		rot_vec := (this.player.center + this.player.vel) - this.player.center
		this.player.prev_rotation = this.player.rotation
		this.player.rotation = linalg.atan2(rot_vec.y, rot_vec.x)*math.DEG_PER_RAD
	}

	particle.update(dt)
	timer.tick(dt)
}

render :: proc(_data: rawptr, alpha: f32)
{
	rl.BeginTextureMode(this.fb)
		rl.ClearBackground(rl.BLACK)

		inv_alpha := 1 - alpha

		{
			pos := this.player.prev_center*inv_alpha + this.player.center*alpha
			rate := (1 - math.pow_f32(2, -20*config.SECONDS_PER_TICK))
			this.camera.target += (pos - this.camera.target)*rate
		}

		rl.BeginMode2D(this.camera)

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
			pos := asteroid.prev_center*inv_alpha + asteroid.center*alpha
			rl.DrawTexturePro(
				tex,
				{ 0, 0, f32(tex.width), f32(tex.height) },
				{ pos.x, pos.y, f32(tex.width), f32(tex.height) },
				{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
				asteroid.prev_rotation*inv_alpha + asteroid.rotation*alpha,
				rl.WHITE)
		}

		for i in 0..<sarr.len(this.task_devices)
		{
			device := sarr.get_ptr(&this.task_devices, i)

			pos := device.prev_center*inv_alpha + device.center*alpha

			rl.DrawCircleV(pos, TASK_DEVICE_INTERACTION_RADIUS, rl.Fade(rl.GREEN, 0.4))

			tex := asset.get_texture(.TASK_DEVICE)

			if device.is_activated
			{
				outline_shader := asset.get_shader(.OUTLINE)
				rl.BeginShaderMode(outline_shader)

				tex_size := linalg.Vector2f32{ f32(tex.width), f32(tex.height) }
				outline_color := rl.ColorNormalize(rl.GREEN) if device.is_completed else rl.ColorNormalize(rl.WHITE)
				rl.SetShaderValue(outline_shader, rl.GetShaderLocation(outline_shader, "textureSize"), &tex_size, .VEC2)
				rl.SetShaderValue(outline_shader, rl.GetShaderLocation(outline_shader, "outlineColor"), &outline_color, .VEC4)
			}

			rl.DrawTexturePro(
				tex,
				{ 0, 0, f32(tex.width), f32(tex.height) },
				{ pos.x, pos.y, f32(tex.width), f32(tex.height) },
				{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
				f32(rl.GetTime())*10.0,
				rl.WHITE)

			if device.is_activated
			{
				rl.EndShaderMode()
			}
		}

		{
			pos := this.player.prev_center*inv_alpha + this.player.center*alpha

			rl.DrawCircleV(pos, this.player.collision_radius, rl.Fade(rl.RED, 0.4))

			// NOTE: this is to fix the stutter when the angle is close to 0 & 360
			curr_rot := this.player.rotation
			diff := this.player.rotation - this.player.prev_rotation
			if diff < -180
			{
				curr_rot += 360
			}
			else if diff >= 180
			{
				curr_rot -= 360
			}


			tex := asset.get_texture(.ROCKET)

			rl.DrawTexturePro(
				tex,
				{ 0, 0, f32(tex.width), f32(tex.height) },
				{ pos.x, pos.y, f32(tex.width), f32(tex.height) },
				{ f32(tex.width)*0.5, f32(tex.height)*0.5 },
				this.player.prev_rotation*inv_alpha + curr_rot*alpha,
				rl.WHITE)
		}

		for i in 0..<len(this.recharge_particles)
		{
			rl.DrawCircleV(this.recharge_particles[i].center, RECHARGE_PARTICLE_RADIUS, { 96, 156, 79, 255 })
		}

		particle.draw(alpha)

		rl.EndMode2D()

		rl.DrawRectangle(4, 4, 160, 16, { 69, 43, 63, 255 })
		rl.DrawRectangle(4, 4, i32(160.0*(this.player.fuel/this.player.max_fuel)), 16, { 250, 191, 97, 255 })

		if this.player.state == .TASK
		{
			render_task(this.player.activated_task_device, alpha)
		}
	rl.EndTextureMode()

	rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		screen_width := f32(rl.GetScreenWidth())
		screen_height := f32(rl.GetScreenHeight())
		scale_x := screen_width/config.DISPLAY_WIDTH
		scale_y := screen_height/config.DISPLAY_HEIGHT
		scale := min(scale_x, scale_y)
		scaled_width := config.DISPLAY_WIDTH*scale
		scaled_height := config.DISPLAY_HEIGHT*scale

		rl.DrawTexturePro(
			this.fb.texture,
			{ 0, f32(this.fb.texture.height), f32(this.fb.texture.width), -f32(this.fb.texture.height) },
			{ (screen_width - scaled_width)*0.5, (screen_height - scaled_height)*0.5, scaled_width, scaled_height },
			{ 0, 0 }, 0, rl.WHITE)

		rl.DrawFPS(2, 2)
	rl.EndDrawing()
}
