package particle

import "core:math"
import "core:math/rand"
import "core:math/linalg"
import sarr "core:container/small_array"

import rl "vendor:raylib"

// NOTE: maybe the performance settings could change the max particle count??
Emitter :: struct($N: int)
{
	is_emitting: bool,
	is_one_shot: bool,

	particle_spawn_cooldown: f32,  // seconds to wait to spawn new particle
	particle_spawn_timer: f32,     // timer to keep track of when to spawn new particle

	center: linalg.Vector2f32,
	dir: linalg.Vector2f32,

	// emission angle
	spread: f32,

	// particle life time (in seconds)
	min_life_time: f32,
	max_life_time: f32,

	/*
	4, 8 -> 6  // median life time
	32  // max_particle

	32/6 -> 5.33 particles per second
	6/32 -> 0.1875 seconds per particle
	*/

	// particle linear velocity
	min_lin_vel: f32,
	max_lin_vel: f32,

	// particle initial rotation
	min_rotation: f32,
	max_rotation: f32,

	// particle angular velocity
	min_ang_vel: f32,
	max_ang_vel: f32,

	// particle side length
	min_size: f32,
	max_size: f32,

	// particle color
	start_color: rl.Color,
	end_color: rl.Color,

	particles: sarr.Small_Array(N, Particle),
}

Particle :: struct
{
	life_time: f32,
	prev_time_since_emit: f32,
	time_since_emit: f32,
	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
	size: f32,
	lin_vel: linalg.Vector2f32,
	ang_vel: f32,
	rotation: f32,
	prev_rotation: f32,
}

start_emission :: proc(emitter: ^Emitter($N))
{
	if emitter.is_emitting
	{
		return
	}

	emitter.is_emitting = true
	emitter.particle_spawn_cooldown = (emitter.min_life_time + emitter.max_life_time)*0.5/f32(N)
	emitter.particle_spawn_timer = 0

	if emitter.is_one_shot
	{
		for i in 0..<N
		{
			sarr.append(&emitter.particles, spawn_particle(emitter))
		}
	}
}

stop_emission :: proc(emitter: ^Emitter($N))
{
	emitter.is_emitting = false
}

update_particles :: proc(emitter: ^Emitter($N), dt: f32)
{
	if emitter.is_emitting && !emitter.is_one_shot
	{
		emitter.particle_spawn_timer += dt
		if emitter.particle_spawn_timer >= emitter.particle_spawn_cooldown
		{
			emitter.particle_spawn_timer -= emitter.particle_spawn_cooldown
			sarr.append(&emitter.particles, spawn_particle(emitter))
		}
	}

	#reverse for &particle, i in sarr.slice(&emitter.particles)
	{
		particle.prev_time_since_emit = particle.time_since_emit
		particle.time_since_emit += dt

		if particle.time_since_emit >= particle.life_time
		{
			sarr.ordered_remove(&emitter.particles, i)
			continue
		}

		particle.prev_center = particle.center
		particle.center += particle.lin_vel*dt
		particle.prev_rotation = particle.rotation
		particle.rotation += particle.ang_vel*dt
	}

	if emitter.is_one_shot && sarr.len(emitter.particles) == 0
	{
		emitter.is_emitting = false
	}
}

draw_particles :: proc(emitter: ^Emitter($N), alpha: f32)
{
	inv_alpha := 1 - alpha

	for i in 0..<sarr.len(emitter.particles)
	{
		particle := sarr.get_ptr(&emitter.particles, i)

		time_since_emit := (particle.prev_time_since_emit*inv_alpha + particle.time_since_emit*alpha)
		t := time_since_emit/particle.life_time
		inv_t := 1 - t

		color: rl.Color
		color.r = u8(f32(emitter.end_color.r - emitter.start_color.r)*t + f32(emitter.start_color.r))
		color.g = u8(f32(emitter.end_color.g - emitter.start_color.g)*t + f32(emitter.start_color.g))
		color.b = u8(f32(emitter.end_color.b - emitter.start_color.b)*t + f32(emitter.start_color.b))
		color.a = u8(f32(emitter.end_color.a - emitter.start_color.a)*t + f32(emitter.start_color.a))

		pos := particle.prev_center*inv_alpha + particle.center*alpha

		rl.DrawRectanglePro(
			{ pos.x, pos.y, particle.size*inv_t, particle.size*inv_t },
			{ particle.size, particle.size }*inv_t*0.5,
			particle.prev_rotation*inv_alpha + particle.rotation*alpha,
			color)
	}
}

@(private)
spawn_particle :: proc(emitter: ^Emitter($N)) -> Particle
{
	spread_angle := rand.float32_range(-emitter.spread, emitter.spread)*math.RAD_PER_DEG
	c := math.cos(spread_angle)
	s := math.sin(spread_angle)
	dir := linalg.Vector2f32{
		emitter.dir.x*c - emitter.dir.y*s,
		emitter.dir.x*s + emitter.dir.y*c,
	}

	return {
		life_time = rand.float32_range(emitter.min_life_time, emitter.max_life_time),
		center = emitter.center,
		size = rand.float32_range(emitter.min_size, emitter.max_size),
		lin_vel = dir*{
			rand.float32_range(emitter.min_lin_vel, emitter.max_lin_vel),
			rand.float32_range(emitter.min_lin_vel, emitter.max_lin_vel),
		},
		ang_vel = rand.float32_range(emitter.min_ang_vel, emitter.max_ang_vel),
		rotation = rand.float32_range(emitter.min_rotation, emitter.max_rotation),
	}
}
