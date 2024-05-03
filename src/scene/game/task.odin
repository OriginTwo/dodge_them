package game_scene

import "core:log"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:config"
import "src:input"
import "src:timer"

// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations

on_task_completed :: proc()
{
	this.player.state = .NORMAL

	// TODO: play sfx, draw text, etc.
}

TASK_DEVICE_INTERACTION_RADIUS :: 30
Task_Device :: struct
{
	data: Task_Data,

	is_activated: bool,
	is_completed: bool,

	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
	/*
	lin_vel: linalg.Vector2f32,
	ang_vel: f32,
	rotation: f32,
	prev_rotation: f32,
	*/
}

Task_Type :: enum
{
	SWITCH,
	PUMP,
}

Task_Data :: union
{
	Switch_Task_Data,
	Pump_Task_Data,
}

// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup
// TODO: this file needs a big cleanup


SWITCH_TASK_ROW_COUNT :: 4  // TODO: maybe make this variable
SWITCH_TASK_COL_COUNT :: 2  // TODO: maybe make this variable
Switch_Task_Data :: struct
{
	x_index: int,
	y_index: int,
	toggled: [SWITCH_TASK_ROW_COUNT*SWITCH_TASK_COL_COUNT]bool,
}

PUMP_TASK_PLAYER_EXTENT :: 0.1                // TODO: maybe make this variable
PUMP_TASK_TARGET_EXTENT :: 0.2                // TODO: maybe make this variable
PUMP_TASK_TARGET_VEL_MIN :: 0.05              // TODO: maybe make this variable
PUMP_TASK_TARGET_VEL_MAX :: 0.2               // TODO: maybe make this variable
PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN :: 0.5  // TODO: maybe make this variable
PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX :: 1.2  // TODO: maybe make this variable
Pump_Task_Data :: struct
{
	progress: f32,
	target_vel_change_timer: f32,
	target_pos: f32,
	target_vel: f32,
	player_pos: f32,
	player_vel: f32,
}

init_task_data :: proc(device: ^Task_Device, type: Task_Type)
{
	switch type
	{
	case .SWITCH:
		device.data = Switch_Task_Data{}
		data := &device.data.(Switch_Task_Data)

		for y in 0..<SWITCH_TASK_ROW_COUNT
		{
			for x in 0..<SWITCH_TASK_COL_COUNT
			{
				if rand.float32() < 0.35
				{
					data.toggled[y*SWITCH_TASK_COL_COUNT + x] = true
				}
			}
		}

	case .PUMP:
		device.data = Pump_Task_Data{}
		data := &device.data.(Pump_Task_Data)
		data.target_pos = rand.float32_range(0, 1 - PUMP_TASK_TARGET_EXTENT)
		data.player_pos = 1 - PUMP_TASK_PLAYER_EXTENT
		timer.set_timer(&data.target_vel_change_timer, rand.float32_range(PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN, PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX))
	}
}

update_task :: proc(device: ^Task_Device, dt: f32)
{
	switch &data in device.data
	{
	case Switch_Task_Data:
		if input.is_action_pressed(.UI_DOWN) && data.y_index < SWITCH_TASK_ROW_COUNT - 1
		{
			data.y_index += 1
		}
		if input.is_action_pressed(.UI_UP) && data.y_index > 0
		{
			data.y_index -= 1
		}

		if input.is_action_pressed(.UI_RIGHT) && data.x_index < SWITCH_TASK_COL_COUNT - 1
		{
			data.x_index += 1
		}
		if input.is_action_pressed(.UI_LEFT) && data.x_index > 0
		{
			data.x_index -= 1
		}

		if input.is_action_pressed(.UI_INTERACT)
		{
			data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index] = !data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index]
		}

		if !device.is_completed && linalg.all(data.toggled)
		{
			device.is_completed = true
			on_task_completed()
		}

	case Pump_Task_Data:
		if data.player_pos < 1 - PUMP_TASK_PLAYER_EXTENT
		{
			data.player_vel += 0.005
		}
		if input.is_action_pressed(.UI_INTERACT)
		{
			data.player_vel -= 0.1
		}
		data.player_vel = clamp(data.player_vel, -0.4, 0.4)
		data.player_pos += data.player_vel*dt
		data.player_pos = clamp(data.player_pos, 0, 1 - PUMP_TASK_PLAYER_EXTENT)

		if timer.is_timeout(data.target_vel_change_timer)
		{
			timer.set_timer(&data.target_vel_change_timer, rand.float32_range(PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN, PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX))
			// TODO: make it so that if it's at the top, it's more likely to go to the bottom,
			// and if it's at the bottom, it's more likely to go the top
			dir := rand.choice([]f32{ -1, 1 })
			data.target_vel = dir*rand.float32_range(PUMP_TASK_TARGET_VEL_MIN, PUMP_TASK_TARGET_VEL_MAX)
		}

		data.target_pos += data.target_vel*dt
		data.target_pos = clamp(data.target_pos, 0, 1 - PUMP_TASK_TARGET_EXTENT)

		if (data.player_pos < data.target_pos + PUMP_TASK_TARGET_EXTENT &&
			data.player_pos + PUMP_TASK_PLAYER_EXTENT > data.target_pos)
		{
			data.progress += 0.15*dt
		}
		else
		{
			data.progress -= 0.1*dt
		}
		data.progress = clamp(data.progress, 0, 1)

		if !device.is_completed && data.progress == 1
		{
			device.is_completed = true
			on_task_completed()
		}
	}
}

render_task :: proc(device: ^Task_Device, alpha: f32)
{
	width := config.GAME_WIDTH/2
	height := config.GAME_HEIGHT*3/4
	x := (config.GAME_WIDTH - width)/2
	y := (config.GAME_HEIGHT - height)/2

	center_x := x + width/2
	center_y := y + height/2

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.DARKGRAY)

	rl.BeginScissorMode(i32(x), i32(y), i32(width), i32(height))

	switch &data in device.data
	{
	case Switch_Task_Data:
		for row in 0..<SWITCH_TASK_ROW_COUNT
		{
			for col in 0..<SWITCH_TASK_COL_COUNT
			{
				color := rl.GREEN if data.toggled[row*SWITCH_TASK_COL_COUNT + col] else rl.RED
				if data.x_index == col && data.y_index == row
				{
					color = rl.ColorTint(color, rl.GRAY)
				}

				rl.DrawCircle(
					i32(center_x + (col*2 - 1)*30),
					i32(center_y - (SWITCH_TASK_ROW_COUNT*24)/2 + 24*row) + 8,
					8, color)
			}
		}

	case Pump_Task_Data:
		w := 24
		h := height/2
		rl.DrawRectangle(i32(center_x - w - 16), i32(center_y - h/2), i32(w), i32(h), rl.GRAY)
		rl.DrawRectangle(i32(center_x - w - 16), i32(center_y - h/2) + i32(f32(h)*data.target_pos), i32(w), i32(f32(h)*PUMP_TASK_TARGET_EXTENT), rl.RED)
		rl.DrawRectangle(i32(center_x - w - 16), i32(center_y - h/2) + i32(f32(h)*data.player_pos), i32(w), i32(f32(h)*PUMP_TASK_PLAYER_EXTENT), rl.GREEN)

		// progress bar
		rl.DrawRectangle(i32(center_x + 16), i32(center_y - h/2), i32(w), i32(h), rl.GRAY)
		rl.DrawRectangle(i32(center_x + 16), i32(center_y - h/2), i32(w), i32(f32(h)*data.progress), rl.YELLOW)
	}

	rl.EndScissorMode()
}
