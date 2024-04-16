package test_scene

import "core:log"
import "core:fmt"
import "core:math"
import "core:math/ease"

import rl "vendor:raylib"

import "src:input_manager"
import "src:scene_manager"

SCALE :: 2

Data :: struct
{
	anim: Animation,
}

Animation :: struct
{
	is_playing: bool,

	playback_speed: f32,

	curr_time: f32,
	clip_start_time: f32,
	last_clip_duration: f32,
}

// NOTE: this needs to be called at the start of the frame
prepare_animation :: proc(anim: ^Animation)
{
	anim.clip_start_time = 0.0
}

reset_animation :: proc(anim: ^Animation)
{
	anim.curr_time = 0.0
}

update_animation :: proc(anim: ^Animation, dt: f32)
{
	if anim.is_playing
	{
		anim.curr_time += dt*anim.playback_speed
	}
}

calculate_clip_time :: proc(anim: ^Animation, clip_duration: f32, easing: ease.Ease) -> f32
{
	time_passed_since_clip_start := anim.curr_time - anim.clip_start_time
	linear_t := clamp(time_passed_since_clip_start/clip_duration, 0.0, 1.0)
	anim_t := ease.ease(easing, linear_t)

	anim.last_clip_duration = clip_duration
	return anim_t
}

wait_until_finish :: proc(anim: ^Animation)
{
	anim.clip_start_time += anim.last_clip_duration
}

wait_until_finish_plus_delay :: proc(anim: ^Animation, delay: f32)
{
	anim.clip_start_time += anim.last_clip_duration + delay
}

wait_until_fraction_finish :: proc(anim: ^Animation, t: f32)
{
	anim.clip_start_time += anim.last_clip_duration*t
}

wait :: proc(anim: ^Animation, wait_time: f32)
{
	anim.clip_start_time += wait_time
}

update :: proc(_data: rawptr, dt: f32)
{
	this := cast(^Data)_data

	if input_manager.is_action_pressed(.DEBUG_CHANGE_SCENE)
	{
		scene_manager.change_scene(.GAME)
	}

	// if input_manager.is_key_pressed(.E)
	// {
	// 	this.anim.is_playing = !this.anim.is_playing
	// }

	// if input_manager.is_key_pressed(.R)
	// {
	// 	reset_animation(&this.anim)
	// }

	// if input_manager.is_key_pressed(.EQUAL)
	// {
	// 	this.anim.playback_speed += 0.5
	// }

	// if input_manager.is_key_pressed(.MINUS)
	// {
	// 	this.anim.playback_speed -= 0.5
	// }

	update_animation(&this.anim, dt)
}

render :: proc(_data: rawptr)
{
	this := cast(^Data)_data

	rl.BeginDrawing()
		rl.ClearBackground(rl.BLANK)

		rl.DrawRing(
			{ f32(rl.GetScreenWidth())*0.5, f32(rl.GetScreenHeight())*0.5 },
			(math.sin(f32(rl.GetTime()))*0.5 + 0.5)*128,
			(math.cos(f32(rl.GetTime()))*0.5 + 0.5)*128,
			0, 360, 0, rl.MAGENTA)

		prepare_animation(&this.anim)

		clip_time := calculate_clip_time(&this.anim, 5.0, .Linear)
		rl.DrawRectangle(i32(16.0 + f32(rl.GetScreenWidth() - 96)*clip_time), 16, 64, 64, rl.MAROON)
		wait_until_fraction_finish(&this.anim, 0.25)

		clip_time = calculate_clip_time(&this.anim, 3.75, .Exponential_In_Out)
		rl.DrawRectangle(i32(16.0 + f32(rl.GetScreenWidth() - 96)*clip_time), rl.GetScreenHeight() - 80, 64, 64, rl.ORANGE)
		wait(&this.anim, 2.0)

		clip_time = calculate_clip_time(&this.anim, 4.0, .Bounce_In_Out)
		rl.DrawRectangle(
			i32(16.0 + f32(rl.GetScreenWidth() - 96)*(1.0 - clip_time)),
			i32(16.0 + f32(rl.GetScreenHeight() - 96)*clip_time),
			64, 64, rl.BLUE)
		wait_until_finish(&this.anim)

		clip_time = calculate_clip_time(&this.anim, 4.0, .Quintic_In_Out)
		rl.DrawRectangle(
			16,
			i32(16.0 + f32(rl.GetScreenHeight() - 96)*(1.0 - clip_time)),
			64, 64, rl.VIOLET)

		rl.DrawText("Press E to play/stop animation", 16, 128, 24, rl.RAYWHITE)
		rl.DrawText("Press R to reset animation", 16, 156, 24, rl.RAYWHITE)
		rl.DrawText(fmt.ctprintf("Playback speed: %f", this.anim.playback_speed), 16, 184, 24, rl.RAYWHITE)

		rl.DrawFPS(2, 2)
	rl.EndDrawing()
}
